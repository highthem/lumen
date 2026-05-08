import Foundation

enum EnergyLevel: String, Sendable, Codable, Hashable, CaseIterable {
    case flat
    case low
    case medium
    case charged
    case top

    /// Numeric ordering used by the Q2 slider (0…4). Mirror of the
    /// design's slider-tick scale.
    nonisolated var sliderIndex: Int {
        switch self {
        case .flat: 0; case .low: 1; case .medium: 2; case .charged: 3; case .top: 4
        }
    }

    nonisolated init(sliderIndex: Int) {
        switch max(0, min(4, sliderIndex)) {
        case 0: self = .flat
        case 1: self = .low
        case 2: self = .medium
        case 3: self = .charged
        default: self = .top
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .flat:    return "à plat"
        case .low:     return "faiblard"
        case .medium:  return "moyen"
        case .charged: return "bien chargé"
        case .top:     return "au top"
        }
    }

    nonisolated var subtitle: String {
        switch self {
        case .flat:    return "le corps demande lenteur"
        case .low:     return "tout est un peu loin"
        case .medium:  return "présent, pas encore lancé"
        case .charged: return "le moteur est prêt"
        case .top:     return "on peut bouger des montagnes"
        }
    }
}
