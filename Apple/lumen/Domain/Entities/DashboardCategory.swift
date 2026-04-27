import Foundation

enum DashboardCategory: String, CaseIterable, Sendable, Codable, Hashable {
    case energy
    case intention
    case body
    case relations
    case work
    case gratitude

    nonisolated var displayName: String {
        switch self {
        case .energy:    return "Énergie"
        case .intention: return "Intention"
        case .body:      return "Corps"
        case .relations: return "Relations"
        case .work:      return "Travail"
        case .gratitude: return "Gratitude"
        }
    }
}
