import Foundation

enum ContentSafetyFlag: String, Sendable, Codable, Hashable {
    case selfHarmCue
    case violentLanguage
    case medicalAdviceRequest
    case legalAdviceRequest
}
