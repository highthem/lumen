import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechRecognizer: VoiceTranscribing {

    private let permissions = VoicePermissions()

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var cachedLocale: Locale?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var sessionConfigured = false

    nonisolated func isOnDeviceSupported(locale: Locale) -> Bool {
        SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition ?? false
    }

    nonisolated func startTranscription(locale: Locale) -> AsyncStream<VoiceTranscribingState> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            continuation.onTermination = { [weak self] _ in
                // The stream may terminate from any thread (caller cancels its
                // for-await, or Speech.framework finishes). Hop to MainActor
                // exactly once, then run the (idempotent) teardown.
                Task { @MainActor in
                    self?.tearDownAndDeactivateSession()
                }
            }

            Task { @MainActor [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                LumenLog.speechRecognition.info("startTranscription: requesting permissions")
                guard await self.permissions.bothGranted() else {
                    LumenLog.speechRecognition.error("startTranscription: permissions denied")
                    continuation.yield(.error(.permissionDenied))
                    continuation.finish()
                    return
                }

                guard self.isOnDeviceSupported(locale: locale) else {
                    LumenLog.speechRecognition.notice("startTranscription: locale not supported on-device; falling back via unsupportedLocale")
                    continuation.yield(.error(.unsupportedLocale))
                    continuation.finish()
                    return
                }

                let recognizer = self.resolveRecognizer(locale: locale)
                guard let recognizer, recognizer.isAvailable else {
                    LumenLog.speechRecognition.error("startTranscription: recognizer unavailable")
                    continuation.yield(.error(.unsupportedLocale))
                    continuation.finish()
                    return
                }

                self.teardownActiveSessionPreservingEngine()

                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try session.setActive(true, options: .notifyOthersOnDeactivation)
                    self.sessionConfigured = true
                    LumenLog.speechRecognition.info("startTranscription: audio session configured (.record)")
                } catch {
                    LumenLog.speechRecognition.error("startTranscription: audio session error", error: error)
                    continuation.yield(.error(.audioEngineFailed))
                    continuation.finish()
                    return
                }

                let request = SFSpeechAudioBufferRecognitionRequest()
                request.requiresOnDeviceRecognition = false
                request.shouldReportPartialResults = true
                self.recognitionRequest = request

                let task: SFSpeechRecognitionTask
                do {
                    // The audio-pipeline closures (tap callback + recognitionTask
                    // handler) MUST be created in a non-isolated context. If they're
                    // declared inside this @MainActor Task, Swift gives them implicit
                    // @MainActor isolation, and when AVFoundation/Speech.framework
                    // invokes them on their own serial queues, Swift's runtime calls
                    // `swift_task_checkIsolated(@MainActor)` → `dispatch_assert_queue
                    // (mainQueue)` → crashes the audio thread. iPhone OS 26 enforces
                    // this strictly. The fix is to construct the closures via
                    // `nonisolated static` factory helpers so they inherit no actor
                    // isolation regardless of the caller's lexical scope.
                    task = try Self.installAudioPipeline(
                        engine: self.audioEngine,
                        recognizer: recognizer,
                        request: request,
                        onListening: Self.makeListeningCallback(continuation: continuation),
                        onPartial:   Self.makePartialCallback(continuation: continuation),
                        onError:     Self.makeErrorCallback(continuation: continuation)
                    )
                } catch {
                    LumenLog.speechRecognition.error("startTranscription: audio pipeline failed", error: error)
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    continuation.yield(.error(.audioEngineFailed))
                    await self.stop()
                    continuation.finish()
                    return
                }

                self.recognitionTask = task
                LumenLog.speechRecognition.info("startTranscription: pipeline live")
            }
        }
    }

    nonisolated func stop() async {
        await MainActor.run {
            self.tearDownAndDeactivateSession()
        }
    }

    /// Idempotent teardown — safe to call from anywhere on MainActor (direct,
    /// from `stop()`, or from the AsyncStream's `onTermination` hop). The
    /// underlying mutators (`recognitionTask?.cancel()`, `removeTap`, etc.)
    /// all tolerate being invoked on already-cleaned state.
    @MainActor
    private func tearDownAndDeactivateSession() {
        teardownActiveSessionPreservingEngine()
        if sessionConfigured {
            let session = AVAudioSession.sharedInstance()
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            // Restore `.playback` so the next non-recording audio (TTS,
            // alarm fade-in) finds a sane category. `.record` left over
            // from dictation produces silent playback.
            try? session.setCategory(.playback, options: [.duckOthers])
            sessionConfigured = false
        }
    }

    // MARK: - Nonisolated callback factories

    /// Constructed in nonisolated static context so the returned closure
    /// has no inherited actor isolation. Required for callbacks that
    /// AVFoundation / Speech.framework invoke from their own queues.
    nonisolated private static func makeListeningCallback(
        continuation: AsyncStream<VoiceTranscribingState>.Continuation
    ) -> @Sendable () -> Void {
        { continuation.yield(.listening) }
    }

    nonisolated private static func makePartialCallback(
        continuation: AsyncStream<VoiceTranscribingState>.Continuation
    ) -> @Sendable (String, Bool) -> Void {
        { text, isFinal in
            continuation.yield(.transcribed(text))
            if isFinal { continuation.finish() }
        }
    }

    nonisolated private static func makeErrorCallback(
        continuation: AsyncStream<VoiceTranscribingState>.Continuation
    ) -> @Sendable (Bool) -> Void {
        { isUserStop in
            if !isUserStop { continuation.yield(.error(.recognitionFailed)) }
            continuation.finish()
        }
    }

    // MARK: - Nonisolated audio pipeline

    /// Install the audio tap and start the recognition task. The closures captured
    /// here are non-isolated by virtue of this being a `nonisolated` static method.
    /// They never capture self or any @MainActor state — only Sendable callbacks.
    /// This is what the Speech framework and AVFoundation invoke on their internal
    /// serial queues; running it from a @MainActor context would produce a Swift
    /// runtime isolation crash on iPhone OS 26.
    nonisolated private static func installAudioPipeline(
        engine: AVAudioEngine,
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        onListening: @escaping @Sendable () -> Void,
        onPartial: @escaping @Sendable (String, Bool) -> Void,
        onError: @escaping @Sendable (Bool) -> Void
    ) throws -> SFSpeechRecognitionTask {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            LumenLog.speechRecognition.error("installAudioPipeline: invalid input format \(String(describing: format))")
            throw VoiceTranscribingError.audioEngineFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            // Runs on AVFoundation's render thread. SFSpeechAudioBufferRecognition
            // Request.append is documented thread-safe.
            request.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            LumenLog.speechRecognition.error("installAudioPipeline: engine.start failed", error: error)
            throw VoiceTranscribingError.audioEngineFailed
        }

        onListening()

        return recognizer.recognitionTask(with: request) { result, error in
            // Runs on Speech.framework's RealtimeMessenger.mServiceQueue.
            if let result {
                onPartial(result.bestTranscription.formattedString, result.isFinal)
            } else if let error {
                let nsError = error as NSError
                let isUserStop = nsError.domain == "kLSRErrorDomain" && nsError.code == 301
                onError(isUserStop)
            }
        }
    }

    private func resolveRecognizer(locale: Locale) -> SFSpeechRecognizer? {
        if let recognizer, cachedLocale == locale {
            return recognizer
        }
        let fresh = SFSpeechRecognizer(locale: locale)
        recognizer = fresh
        cachedLocale = locale
        return fresh
    }

    private func teardownActiveSessionPreservingEngine() {
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
