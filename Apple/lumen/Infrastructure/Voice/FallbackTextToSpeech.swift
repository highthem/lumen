import Foundation
import os.log

/// TTS decorator: tries the primary synthesizer; on throw, transparently falls back.
/// The fallback is resolved at *each call*, not init-time — so a transient ElevenLabs
/// outage gracefully degrades to AVSpeech without an app restart.
actor FallbackTextToSpeech: TextToSpeeching {
    private let primary: any TextToSpeeching
    private let fallback: any TextToSpeeching
    private let ethicalLogger: EthicalLogger?
    private let isPrimaryEnabled: @Sendable () -> Bool
    private let osLog = Logger(subsystem: "com.highthem.lumen", category: "tts.fallback")

    private var activeProvider: ActiveProvider = .none

    enum ActiveProvider: Sendable { case none, primary, fallback }

    init(
        primary: any TextToSpeeching,
        fallback: any TextToSpeeching,
        logger: EthicalLogger? = nil,
        isPrimaryEnabled: @escaping @Sendable () -> Bool = { true }
    ) {
        self.primary = primary
        self.fallback = fallback
        self.ethicalLogger = logger
        self.isPrimaryEnabled = isPrimaryEnabled
    }

    var isSpeaking: Bool {
        get async {
            switch activeProvider {
            case .primary:  return await primary.isSpeaking
            case .fallback: return await fallback.isSpeaking
            case .none:     return false
            }
        }
    }

    func availableVoices() async -> [TTSVoice] {
        await primary.availableVoices()
    }

    func speak(_ text: String, voiceId: String?, rate: Double) async throws {
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

    func pause() async {
        switch activeProvider {
        case .primary:  await primary.pause()
        case .fallback: await fallback.pause()
        case .none:     break
        }
    }

    func resume() async {
        switch activeProvider {
        case .primary:  await primary.resume()
        case .fallback: await fallback.resume()
        case .none:     break
        }
    }

    func stop() async {
        await primary.stop()
        await fallback.stop()
        activeProvider = .none
    }

    private func logTTS(provider: String, success: Bool, fallbackReason: String?) async {
        guard let ethicalLogger else { return }
        try? await ethicalLogger.logTTS(provider: provider, success: success, fallbackReason: fallbackReason)
    }
}
