import Foundation
import AVFoundation

// Separate delegate object to avoid @MainActor crossing issue on SpeechSynthesizer
private final class SynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    var onFinish: (() -> Void)?
    var onCancel: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onCancel?()
    }
}

final class SpeechSynthesizer: TextToSpeeching, @unchecked Sendable {

    private let synthesizer = AVSpeechSynthesizer()
    private let delegate = SynthesizerDelegate()
    private let lock = NSLock()
    nonisolated(unsafe) private var _isSpeaking = false

    init() {
        synthesizer.delegate = delegate
        delegate.onFinish = { [weak self] in self?.lock.withLock { self?._isSpeaking = false } }
        delegate.onCancel = { [weak self] in self?.lock.withLock { self?._isSpeaking = false } }
    }

    var isSpeaking: Bool {
        lock.withLock { _isSpeaking }
    }

    func availableVoices() -> [TTSVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { voice in
                voice.language.hasPrefix("fr") || voice.language.hasPrefix("en")
            }
            .map { voice in
                TTSVoice(
                    id: voice.identifier,
                    name: voice.name,
                    lang: String(voice.language.prefix(2)),
                    quality: mapQuality(voice.quality)
                )
            }
            .sorted { $0.quality > $1.quality }
    }

    func speak(_ text: String, voiceId: String?, rate: Double) async throws {
        let utterance = AVSpeechUtterance(string: text)

        if let voiceId, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        }

        // Map 0.8/1.0/1.2 → AVSpeechUtterance scale (~0.45 * rate, clamped 0–1)
        let mappedRate = max(0.0, min(1.0, 0.45 * rate))
        utterance.rate = Float(mappedRate)

        lock.withLock { _isSpeaking = true }
        synthesizer.speak(utterance)
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        lock.withLock { _isSpeaking = false }
    }

    // MARK: - Helpers

    private func mapQuality(_ quality: AVSpeechSynthesisVoiceQuality) -> TTSVoiceQuality {
        switch quality {
        case .premium:  return .premium
        case .enhanced: return .enhanced
        default:        return .default
        }
    }
}
