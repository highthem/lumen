import Foundation

struct UserDefaultsRitualSettings: RitualSettingsReading {
    private static let key = "lumen.settings.presenceDurationSeconds"
    private static let allowed = [30, 60, 90, 120]

    var presenceDurationSeconds: Int {
        let stored = UserDefaults.standard.object(forKey: Self.key) as? Int ?? 60
        return Self.allowed.contains(stored) ? stored : 60
    }
}
