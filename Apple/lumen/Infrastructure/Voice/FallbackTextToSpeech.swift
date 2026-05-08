import Foundation

/// TTS decorator: tries the primary synthesizer; on throw, transparently falls back.
/// The fallback is resolved at *each call*, not init-time — so a transient ElevenLabs
/// outage gracefully degrades to AVSpeech without an app restart.
@MainActor
final class FallbackTextToSpeech: TextToSpeeching {
    private let primary: any TextToSpeeching
    private let fallback: any TextToSpeeching
    private let session: AudioSessionManager
    private let ethicalLogger: EthicalLogger?
    private let isPrimaryEnabled: @Sendable () -> Bool

    private var activeProvider: ActiveProvider = .none

    enum ActiveProvider: Sendable { case none, primary, fallback }

    init(
        primary: any TextToSpeeching,
        fallback: any TextToSpeeching,
        session: AudioSessionManager = AudioSessionManager(),
        logger: EthicalLogger? = nil,
        isPrimaryEnabled: @escaping @Sendable () -> Bool = { true }
    ) {
        self.primary = primary
        self.fallback = fallback
        self.session = session
        self.ethicalLogger = logger
        self.isPrimaryEnabled = isPrimaryEnabled
    }

    var isSpeaking: Bool {
        switch activeProvider {
        case .primary:  return primary.isSpeaking
        case .fallback: return fallback.isSpeaking
        case .none:     return false
        }
    }

    func availableVoices() -> [TTSVoice] {
        primary.availableVoices()
    }

    /// The synthesis screen subscribes BEFORE calling `speak(...)`, so we
    /// don't yet know whether primary or fallback will end up active. We
    /// merge both child streams into a single one — only one of them will
    /// actually emit during a given session, and the inactive one finishes
    /// quickly when its `speak()` isn't called.
    func progress() -> AsyncStream<TTSProgress> {
        AsyncStream(TTSProgress.self, bufferingPolicy: .bufferingNewest(1)) { cont in
            let primaryStream = primary.progress()
            let fallbackStream = fallback.progress()
            Task { @MainActor in
                for await p in primaryStream {
                    cont.yield(p)
                }
            }
            Task { @MainActor in
                for await p in fallbackStream {
                    cont.yield(p)
                }
            }
            // Caller cancellation finishes the stream (the child Tasks above
            // exit naturally when their child streams complete or the parent
            // continuation is gone).
        }
    }

    func speak(_ text: String, voiceId: String?, rate: Double) async throws {
        // Configure the audio session for `.playback` before delegating. The
        // dictation pipeline leaves the session at `.record` + inactive, and
        // a cold-start synthesis call may have no category set at all — both
        // produce silent playback unless we set this here.
        try? await session.configureSession()
        defer { activeProvider = .none }

        if !isPrimaryEnabled() {
            activeProvider = .fallback
            try await fallback.speak(text, voiceId: nil, rate: rate)
            await logTTS(provider: "apple-on-device", success: true, fallbackReason: nil)
            return
        }

        do {
            activeProvider = .primary
            try await primary.speak(text, voiceId: voiceId, rate: rate)
            await logTTS(provider: "elevenlabs", success: true, fallbackReason: nil)
        } catch {
            LumenLog.textToSpeech.warning("Primary TTS failed; falling back", error: error)
            activeProvider = .fallback
            try await fallback.speak(text, voiceId: nil, rate: rate)
            await logTTS(provider: "apple-on-device", success: true, fallbackReason: "\(error)")
        }
    }

    func pause() {
        switch activeProvider {
        case .primary:  primary.pause()
        case .fallback: fallback.pause()
        case .none:     break
        }
    }

    func resume() {
        switch activeProvider {
        case .primary:  primary.resume()
        case .fallback: fallback.resume()
        case .none:     break
        }
    }

    func stop() {
        primary.stop()
        fallback.stop()
        activeProvider = .none
    }

    private func logTTS(provider: String, success: Bool, fallbackReason: String?) async {
        guard let ethicalLogger else { return }
        try? await ethicalLogger.logTTS(provider: provider, success: success, fallbackReason: fallbackReason)
    }
}
