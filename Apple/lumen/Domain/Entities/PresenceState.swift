import Foundation

enum PresenceState: String, Sendable, Codable, Hashable, CaseIterable {
    case completed
    case partial
    case skipped
    case notStarted

    nonisolated var displayName: String {
        switch self {
        case .completed:  return "60 secondes prises"
        case .partial:    return "Quelques secondes"
        case .skipped:    return "Pas de présence ce matin"
        case .notStarted: return "—"
        }
    }
}
