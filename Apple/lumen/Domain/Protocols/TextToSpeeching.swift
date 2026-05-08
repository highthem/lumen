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

// `@MainActor` because every conforming impl wraps a UIKit / AVFoundation
// API (`AVSpeechSynthesizer`, `AVAudioPlayer`) that requires main-thread
// invocation on iOS 17+. Conformers can stay simple `@MainActor final class`
// types without per-method isolation annotations.
@MainActor
protocol TextToSpeeching: Sendable {
    func availableVoices() -> [TTSVoice]
    func speak(_ text: String, voiceId: String?, rate: Double) async throws
    func pause()
    func resume()
    func stop()
    var isSpeaking: Bool { get }
}
