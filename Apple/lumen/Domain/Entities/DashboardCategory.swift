import Foundation

/// Slots displayed on the post-ritual dashboard. Distinct from `PriorityCategory`
/// (which represents what the user picks at Q3 Priority).
enum DashboardCategory: String, CaseIterable, Sendable, Codable, Hashable {
    case mood
    case energy
    case priority
    case gratitude
    case presence
    case sleep

    nonisolated var displayName: String {
        switch self {
        case .mood:      return "Humeur"
        case .energy:    return "Énergie"
        case .priority:  return "Priorité"
        case .gratitude: return "Gratitude"
        case .presence:  return "Présence"
        case .sleep:     return "Sommeil"
        }
    }
}
