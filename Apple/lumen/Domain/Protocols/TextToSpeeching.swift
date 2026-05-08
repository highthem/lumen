import Foundation

struct TTSVoice: Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let lang: String
    let quality: TTSVoiceQuality
}

enum TTSVoiceQuality: String, Sendable, Comparable, Hashable {
    case `default`
    case enhanced
    case premium

    private var rank: Int {
        switch self {
        case .default:  return 0
        case .enhanced: return 1
        case .premium:  return 2
        }
    }

    static func < (lhs: TTSVoiceQuality, rhs: TTSVoiceQuality) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// Progress emitted by a TextToSpeeching impl while speech is in flight.
/// Subscribers (the synthesis view's listen-player) read this to drive the
/// progress bar + elapsed / remaining countdown labels.
struct TTSProgress: Sendable, Equatable {
    let elapsedSeconds: Double
    let totalSeconds: Double
}

// `@MainActor` because every conforming impl wraps a UIKit / AVFoundation
// API (`AVSpeechSynthesizer`, `AVAudioPlayer`) that requires main-thread
// invocation on iOS 17+. Conformers can stay simple `@MainActor final class`
// types without per-method isolation annotations.
@MainActor
protocol TextToSpeeching: Sendable {
    func availableVoices() -> [TTSVoice]
    /// Starts and awaits the full narration. Throws on start failure (the
    /// FallbackTextToSpeech decorator catches and falls through to fallback).
    func speak(_ text: String, voiceId: String?, rate: Double) async throws
    /// AsyncStream of progress updates emitted while speech is in flight.
    /// Yields once per word boundary (AVSpeech) or ~10Hz (ElevenLabs / audio
    /// player). Stream finishes on speech completion or `stop()`.
    /// Subscribers must subscribe BEFORE calling `speak(...)`.
    func progress() -> AsyncStream<TTSProgress>
    func pause()
    func resume()
    func stop()
    var isSpeaking: Bool { get }
}
