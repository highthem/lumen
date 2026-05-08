import Foundation

enum SleepQuality: String, Sendable, Codable, Hashable {
    case low
    case medium
    case high

    nonisolated var displayName: String {
        switch self {
        case .low:    return "qualité courte"
        case .medium: return "qualité moyenne"
        case .high:   return "qualité solide"
        }
    }
}

struct SleepSummary: Sendable, Codable, Hashable {
    let bedtime: Date
    let wakeTime: Date
    let totalAsleep: TimeInterval
    let deep: TimeInterval
    let rem: TimeInterval
    let core: TimeInterval
    let awake: TimeInterval

    nonisolated var quality: SleepQuality {
        switch totalAsleep {
        case ..<(5 * 3600):  return .low
        case ..<(7 * 3600):  return .medium
        default:             return .high
        }
    }

    /// Human-readable duration: "7 h 12 min" / "5 h 0 min".
    nonisolated var durationLabel: String {
        let hours = Int(totalAsleep) / 3600
        let minutes = (Int(totalAsleep) % 3600) / 60
        return "\(hours) h \(minutes) min"
    }
}
