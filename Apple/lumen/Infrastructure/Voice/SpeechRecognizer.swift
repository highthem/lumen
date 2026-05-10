import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechRecognizer: VoiceTranscribing {

    private let permissions = VoicePermissions()

    // Reassigned at the start of each transcription session so the input
    // audio unit lazy-initializes under the freshly-configured
    // .playAndRecord session. Reusing a single engine across sessions
    // strands a stale 0-Hz audio unit when an earlier `inputNode` access
    // happened under .playback (TTS / alarms) — manifests as
    // `AURemoteIO -10851` on engine.start.
    private var audioEngine = AVAudioEngine()
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

                let recognizer = self.resolveRecognizer(locale: locale)
                guard let recognizer, recognizer.isAvailable else {
                    LumenLog.speechRecognition.error("startTranscription: recognizer unavailable")
                    continuation.yield(.error(.unsupportedLocale))
                    continuation.finish()
                    return
                }

                do {
                    try self.configureSpeechAudioSessionForRecording()
                } catch {
                    continuation.yield(.error(.audioEngineFailed))
                    continuation.finish()
                    return
                }

                let request = SFSpeechAudioBufferRecognitionRequest()
                // false = let SFSpeechRecognizer pick on-device when the locale
                // model is installed, otherwise fall back to Apple's cloud
                // service. true would force on-device-only and silently fail
                // on simulator and on devices without the fr_FR model.
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
                    await self.cancelTranscription()
                    continuation.finish()
                    return
                }

                self.recognitionTask = task
                LumenLog.speechRecognition.info("startTranscription: pipeline live")
            }
        }
    }

    nonisolated func finishTranscription() async {
        await MainActor.run {
            self.finishCapturePreservingRecognition()
        }
    }

    nonisolated func cancelTranscription() async {
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

    @MainActor
    private func configureSpeechAudioSessionForRecording() throws {
        // Cancel any in-flight recognition before reconfiguring the session.
        // These are Speech.framework-only calls — they don't touch the audio
        // engine, so it's safe to run them before the session category flip.
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.duckOthers, .defaultToSpeaker, Self.bluetoothHandsFree]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            sessionConfigured = true

            logAudioSessionState(prefix: "startTranscription: audio session configured (.playAndRecord)")

            guard session.isInputAvailable else {
                LumenLog.speechRecognition.error("startTranscription: audio session has no available input")
                throw VoiceTranscribingError.audioEngineFailed
            }

            // Recreate the engine *after* the session is in .playAndRecord so
            // the input audio unit lazy-initializes under the recording
            // category (48 kHz from the device, not the 0 Hz it inherits
            // from .playback). The old engine releases naturally; we never
            // installed a tap on the new one, so no cleanup needed.
            audioEngine = AVAudioEngine()
        } catch {
            LumenLog.speechRecognition.error("startTranscription: audio session error", error: error)
            // Don't call tearDownAndDeactivateSession here — it would touch
            // audioEngine.inputNode and could create a stale audio unit
            // under .playback if setCategory failed. Just unwind the session.
            if sessionConfigured {
                try? session.setActive(false, options: .notifyOthersOnDeactivation)
                try? session.setCategory(.playback, options: [.duckOthers])
                sessionConfigured = false
            }
            throw VoiceTranscribingError.audioEngineFailed
        }
    }

    @MainActor
    private func logAudioSessionState(prefix: String) {
        let session = AVAudioSession.sharedInstance()
        let inputs = session.currentRoute.inputs
            .map { "\($0.portType.rawValue):\($0.portName)" }
            .joined(separator: ",")
        let outputs = session.currentRoute.outputs
            .map { "\($0.portType.rawValue):\($0.portName)" }
            .joined(separator: ",")
        let availableInputs = session.availableInputs?
            .map { "\($0.portType.rawValue):\($0.portName)" }
            .joined(separator: ",") ?? "none"
        LumenLog.speechRecognition.info(
            "\(prefix); sampleRate=\(session.sampleRate), ioBuffer=\(session.ioBufferDuration), inputAvailable=\(session.isInputAvailable), routeInputs=\(inputs), routeOutputs=\(outputs), availableInputs=\(availableInputs)"
        )
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

        guard isValidInputFormat(format) else {
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

    nonisolated static func isValidInputFormat(_ format: AVAudioFormat) -> Bool {
        format.sampleRate > 0 && format.channelCount > 0
    }

    private static var bluetoothHandsFree: AVAudioSession.CategoryOptions {
        // Xcode 16's Swift overlay does not expose `.allowBluetoothHFP`,
        // while newer SDKs map it to the legacy Bluetooth bit. Use the raw
        // option value so CI and local SDKs compile with the same behavior.
        AVAudioSession.CategoryOptions(rawValue: 0x4)
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

    @MainActor
    private func finishCapturePreservingRecognition() {
        recognitionRequest?.endAudio()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        // Watchdog: if Speech.framework doesn't deliver a final transcript or
        // error within 3s, force the session reset so the next dictation
        // attempt isn't blocked by a stale .playAndRecord session.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self, self.sessionConfigured else { return }
            self.tearDownAndDeactivateSession()
        }
    }
}
