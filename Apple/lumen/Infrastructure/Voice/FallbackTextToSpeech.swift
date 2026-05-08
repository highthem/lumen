import Foundation
import os.log

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
    private let osLog = Logger(subsystem: "com.highthem.lumen", category: "tts.fallback")

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
            osLog.warning("Primary TTS failed: \(String(describing: error)) — falling back")
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
