import Foundation

enum AIError: Error, Sendable {
    case rateLimited
    case offline
    case providerFailed(String)
    case decodeFailed
    case unsupportedLocale
    case missingAPIKey
    case selfHarmCue
}
