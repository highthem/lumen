import Foundation
import Speech
import AVFoundation
import OSLog

nonisolated(unsafe) private let log = Logger(subsystem: "com.highthem.lumen", category: "SpeechRecognizer")

final class SpeechRecognizer: VoiceTranscribing, @unchecked Sendable {

    private let permissions = VoicePermissions()

    @MainActor private let audioEngine = AVAudioEngine()
    @MainActor private var recognizer: SFSpeechRecognizer?
    @MainActor private var cachedLocale: Locale?
    @MainActor private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @MainActor private var recognitionTask: SFSpeechRecognitionTask?
    @MainActor private var sessionConfigured = false

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
                Task { @MainActor in
                    await self?.stop()
                }
            }

            Task { @MainActor [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                log.info("startTranscription: requesting permissions")
                guard await self.permissions.bothGranted() else {
                    log.error("startTranscription: permissions denied")
                    continuation.yield(.error(.permissionDenied))
                    continuation.finish()
                    return
                }

                guard self.isOnDeviceSupported(locale: locale) else {
                    log.notice("startTranscription: locale not supported on-device — falling back via unsupportedLocale")
                    continuation.yield(.error(.unsupportedLocale))
                    continuation.finish()
                    return
                }

                let recognizer = self.resolveRecognizer(locale: locale)
                guard let recognizer, recognizer.isAvailable else {
                    log.error("startTranscription: recognizer unavailable")
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
                    log.info("startTranscription: audio session configured (.record)")
                } catch {
                    log.error("startTranscription: audio session error \(String(describing: error))")
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
                    // this strictly. The fix is to install the pipeline via a
                    // nonisolated helper so the captured closures inherit no actor
                    // isolation.
                    task = try Self.installAudioPipeline(
                        engine: self.audioEngine,
                        recognizer: recognizer,
                        request: request,
                        onListening: {
                            continuation.yield(.listening)
                        },
                        onPartial: { text, isFinal in
                            continuation.yield(.transcribed(text))
                            if isFinal {
                                continuation.finish()
                            }
                        },
                        onError: { isUserStop in
                            if !isUserStop {
                                continuation.yield(.error(.recognitionFailed))
                            }
                            continuation.finish()
                        }
                    )
                } catch {
                    log.error("startTranscription: audio pipeline failed \(String(describing: error))")
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    continuation.yield(.error(.audioEngineFailed))
                    await self.stop()
                    continuation.finish()
                    return
                }

                self.recognitionTask = task
                log.info("startTranscription: pipeline live")
            }
        }
    }

    nonisolated func stop() async {
        await MainActor.run {
            self.teardownActiveSessionPreservingEngine()
            if self.sessionConfigured {
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                self.sessionConfigured = false
            }
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
            log.error("installAudioPipeline: invalid input format \(String(describing: format))")
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
            log.error("installAudioPipeline: engine.start failed \(String(describing: error))")
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

    @MainActor
    private func resolveRecognizer(locale: Locale) -> SFSpeechRecognizer? {
        if let recognizer, cachedLocale == locale {
            return recognizer
        }
        let fresh = SFSpeechRecognizer(locale: locale)
        recognizer = fresh
        cachedLocale = locale
        return fresh
    }

    @MainActor
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
