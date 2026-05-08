import Foundation
import AVFoundation

private final class SynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate, Sendable {
    let onFinishOrCancel: @Sendable () -> Void

    init(onFinishOrCancel: @escaping @Sendable () -> Void) {
        self.onFinishOrCancel = onFinishOrCancel
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinishOrCancel()
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinishOrCancel()
    }
}

@MainActor
final class SpeechSynthesizer: TextToSpeeching {

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: SynthesizerDelegate?
    private var _isSpeaking = false

    var isSpeaking: Bool { _isSpeaking }

    init() {}

    private func installDelegateIfNeeded() {
        guard delegate == nil else { return }
        let d = SynthesizerDelegate(onFinishOrCancel: { [weak self] in
            Task { @MainActor [weak self] in self?._isSpeaking = false }
        })
        self.delegate = d
        synthesizer.delegate = d
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
                    quality: Self.mapQuality(voice.quality)
                )
            }
            .sorted { $0.quality > $1.quality }
    }

    func speak(_ text: String, voiceId: String?, rate: Double) async throws {
        installDelegateIfNeeded()
        let utterance = AVSpeechUtterance(string: text)
        if let voiceId, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        }
        utterance.rate = Float(max(0.0, min(1.0, 0.45 * rate)))
        _isSpeaking = true
        synthesizer.speak(utterance)
    }

    func pause()  { synthesizer.pauseSpeaking(at: .word) }
    func resume() { synthesizer.continueSpeaking() }
    func stop()   { synthesizer.stopSpeaking(at: .immediate); _isSpeaking = false }

    private static func mapQuality(_ quality: AVSpeechSynthesisVoiceQuality) -> TTSVoiceQuality {
        switch quality {
        case .premium:  return .premium
        case .enhanced: return .enhanced
        default:        return .default
        }
    }
}
