import Foundation
import os.log

/// TTS decorator: tries the primary synthesizer; on throw, transparently falls back.
/// The fallback is resolved at *each call*, not init-time — so a transient ElevenLabs
/// outage gracefully degrades to AVSpeech without an app restart.
final class FallbackTextToSpeech: TextToSpeeching, @unchecked Sendable {
    private let primary: any TextToSpeeching
    private let fallback: any TextToSpeeching
    private let logger: EthicalLogger?
    private let isPrimaryEnabled: @Sendable () -> Bool
    private let osLog = Logger(subsystem: "com.highthem.lumen", category: "tts.fallback")

    private let lock = NSLock()
    nonisolated(unsafe) private var activeProvider: ActiveProvider = .none

    enum ActiveProvider { case none, primary, fallback }

    nonisolated init(
        primary: any TextToSpeeching,
        fallback: any TextToSpeeching,
        logger: EthicalLogger? = nil,
        isPrimaryEnabled: @escaping @Sendable () -> Bool = { true }
    ) {
        self.primary = primary
        self.fallback = fallback
        self.logger = logger
        self.isPrimaryEnabled = isPrimaryEnabled
    }

    var isSpeaking: Bool {
        let provider: ActiveProvider = lock.withLock { activeProvider }
        switch provider {
        case .primary:  return primary.isSpeaking
        case .fallback: return fallback.isSpeaking
        case .none:     return false
        }
    }

    func availableVoices() -> [TTSVoice] {
        // Primary defines the catalog; fallback is opaque to the user.
        primary.availableVoices()
    }

    func speak(_ text: String, voiceId: String?, rate: Double) async throws {
        defer { lock.withLock { activeProvider = .none } }

        // User has disabled premium — bypass primary entirely and stay 100% on-device.
        if !isPrimaryEnabled() {
            lock.withLock { activeProvider = .fallback }
            try await fallback.speak(text, voiceId: nil, rate: rate)
            await logTTS(provider: "apple-on-device", success: true, fallbackReason: nil)
            return
        }

        do {
            lock.withLock { activeProvider = .primary }
            try await primary.speak(text, voiceId: voiceId, rate: rate)
            await logTTS(provider: "elevenlabs", success: true, fallbackReason: nil)
        } catch {
            osLog.warning("Primary TTS failed: \(String(describing: error)) — falling back")
            lock.withLock { activeProvider = .fallback }
            try await fallback.speak(text, voiceId: nil, rate: rate)
            await logTTS(provider: "apple-on-device", success: true, fallbackReason: "\(error)")
        }
    }

    func pause() {
        let provider: ActiveProvider = lock.withLock { activeProvider }
        switch provider {
        case .primary:  primary.pause()
        case .fallback: fallback.pause()
        case .none:     break
        }
    }

    func resume() {
        let provider: ActiveProvider = lock.withLock { activeProvider }
        switch provider {
        case .primary:  primary.resume()
        case .fallback: fallback.resume()
        case .none:     break
        }
    }

    func stop() {
        primary.stop()
        fallback.stop()
        lock.withLock { activeProvider = .none }
    }

    private func logTTS(provider: String, success: Bool, fallbackReason: String?) async {
        guard let logger else { return }
        try? await logger.logTTS(provider: provider, success: success, fallbackReason: fallbackReason)
    }
}
