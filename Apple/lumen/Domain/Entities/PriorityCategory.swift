import Foundation

/// Categories the user can pick as their daily priority during Q3 of the ritual.
/// Distinct from `DashboardCategory` (which describes dashboard slots).
enum PriorityCategory: String, CaseIterable, Sendable, Codable, Hashable {
    case energy
    case work
    case relations
    case body
    case gratitude

    nonisolated var displayName: String {
        switch self {
        case .energy:    return "Énergie"
        case .work:      return "Travail"
        case .relations: return "Relations"
        case .body:      return "Corps"
        case .gratitude: return "Gratitude"
        }
    }

    nonisolated var prompt: String {
        switch self {
        case .energy:    return "Une priorité d'énergie aujourd'hui ?"
        case .work:      return "Une priorité de travail ?"
        case .relations: return "Une relation à soigner ?"
        case .body:      return "Quelque chose pour ton corps ?"
        case .gratitude: return "Quelque chose te tient à cœur ?"
        }
    }
}
