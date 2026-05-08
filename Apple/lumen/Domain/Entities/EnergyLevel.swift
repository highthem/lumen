import Foundation

enum EnergyLevel: String, Sendable, Codable, Hashable, CaseIterable {
    case flat
    case low
    case medium
    case charged
    case top

    nonisolated var displayName: String {
        switch self {
        case .flat:    return "À plat"
        case .low:     return "Faiblard"
        case .medium:  return "Moyen"
        case .charged: return "Bien chargé"
        case .top:     return "Au top"
        }
    }

    nonisolated var subtitle: String {
        switch self {
        case .flat:    return "le corps demande encore du repos"
        case .low:     return "ça démarre lentement"
        case .medium:  return "présent, sans plus"
        case .charged: return "le moteur tourne bien"
        case .top:     return "plein régime, prêt à avancer"
        }
    }
}
