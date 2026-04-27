import Foundation

enum VoiceTranscribingState: Sendable {
    case listening
    case transcribed(String)
    case error(VoiceTranscribingError)
    case finished
}

enum VoiceTranscribingError: Error, Sendable {
    case permissionDenied
    case unsupportedLocale
    case recognitionFailed
    case audioEngineFailed
}

protocol VoiceTranscribing: Sendable {
    func startTranscription(locale: Locale) -> AsyncStream<VoiceTranscribingState>
    func stop() async
    func isOnDeviceSupported(locale: Locale) -> Bool
}
