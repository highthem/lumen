import Foundation
import AVFoundation

/// Average characters/second used to estimate utterance duration when AVSpeech
/// doesn't expose one. Calibrated empirically for FR Audrey at rate 1.0×.
private let kFrenchCharsPerSecond: Double = 13.0

/// AVSpeechSynthesizer delegate. Lives in nonisolated land — its callbacks
/// are dispatched from the framework's own queue, so any access to MainActor
/// state must hop. The owning `SpeechSynthesizer` passes Sendable callbacks
/// captured at speech-start time.
private final class SynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate, Sendable {
    private let onProgress: @Sendable (Double, Double) -> Void
    private let onFinish: @Sendable (Bool) -> Void  // success: true=finished, false=cancelled

    init(
        onProgress: @escaping @Sendable (Double, Double) -> Void,
        onFinish: @escaping @Sendable (Bool) -> Void
    ) {
        self.onProgress = onProgress
        self.onFinish = onFinish
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let total = estimatedDuration(for: utterance)
        let length = max(1, utterance.speechString.count)
        let elapsed = Double(characterRange.location) / Double(length) * total
        onProgress(elapsed, total)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish(true)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish(false)
    }

    private func estimatedDuration(for utterance: AVSpeechUtterance) -> Double {
        // AVSpeech rate is on a 0…1 scale where 0.5 is ~iOS default. Our
        // `speak(...)` maps user-supplied 1.0× to AVSpeech 0.45, so a rate
        // multiplier of `0.45 / utteranceRate` gives us "how much faster
        // than calibration" the actual playback runs.
        let baseRate: Double = 0.45
        let rateScale = baseRate / Double(max(0.05, utterance.rate))
        let charCount = max(1, utterance.speechString.count)
        return Double(charCount) / kFrenchCharsPerSecond * rateScale
    }
}

@MainActor
final class SpeechSynthesizer: TextToSpeeching {

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: SynthesizerDelegate?
    private var speakContinuation: CheckedContinuation<Void, Error>?
    private var progressContinuation: AsyncStream<TTSProgress>.Continuation?
    private var _isSpeaking = false

    var isSpeaking: Bool { _isSpeaking }

    init() {}

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

    func progress() -> AsyncStream<TTSProgress> {
        AsyncStream(TTSProgress.self, bufferingPolicy: .bufferingNewest(1)) { [weak self] cont in
            guard let self else { cont.finish(); return }
            // Replace any prior subscription — the synthesis screen owns
            // a single subscriber per speech session.
            self.progressContinuation?.finish()
            self.progressContinuation = cont
            cont.onTermination = { [weak self] _ in
                Task { @MainActor in self?.progressContinuation = nil }
            }
        }
    }

    func speak(_ text: String, voiceId: String?, rate: Double) async throws {
        // Tear down any prior session before starting a new one so the
        // continuation/delegate state is clean.
        if speakContinuation != nil {
            stop()
        }

        let utterance = AVSpeechUtterance(string: text)
        if let voiceId, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        }
        utterance.rate = Float(max(0.0, min(1.0, 0.45 * rate)))
        utterance.volume = 1.0

        // Capture references that delegate callbacks (nonisolated) need to
        // route updates back to MainActor state. The continuation closures
        // never capture self (they capture continuations + the progress
        // continuation closure which is itself Sendable-safe).
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.speakContinuation = cont
            let progressCont = self.progressContinuation
            let d = SynthesizerDelegate(
                onProgress: { elapsed, total in
                    progressCont?.yield(TTSProgress(elapsedSeconds: elapsed, totalSeconds: total))
                },
                onFinish: { [weak self] success in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self._isSpeaking = false
                        self.progressContinuation?.finish()
                        self.progressContinuation = nil
                        let pending = self.speakContinuation
                        self.speakContinuation = nil
                        // success or cancel both resume normally — speech is best-effort.
                        _ = success
                        pending?.resume()
                    }
                }
            )
            self.delegate = d
            self.synthesizer.delegate = d
            self._isSpeaking = true
            self.synthesizer.speak(utterance)
        }
    }

    func pause()  { synthesizer.pauseSpeaking(at: .word) }
    func resume() { synthesizer.continueSpeaking() }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        _isSpeaking = false
        progressContinuation?.finish()
        progressContinuation = nil
        speakContinuation?.resume()
        speakContinuation = nil
    }

    private static func mapQuality(_ quality: AVSpeechSynthesisVoiceQuality) -> TTSVoiceQuality {
        switch quality {
        case .premium:  return .premium
        case .enhanced: return .enhanced
        default:        return .default
        }
    }
}
