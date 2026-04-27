import Foundation
import Observation

@MainActor
@Observable
final class DashboardHomeViewModel {
    var snapshot: DashboardSnapshot?
    var hasRitualToday: Bool = false
    var hasAnyRitual: Bool = false
    var hasAnyAlarm: Bool = false

    private let buildDashboard: BuildDashboardSnapshot
    private let alarmRepository: any AlarmRepository

    init(buildDashboard: BuildDashboardSnapshot, alarmRepository: any AlarmRepository) {
        self.buildDashboard = buildDashboard
        self.alarmRepository = alarmRepository
        self.hasAnyRitual = UserDefaults.standard.bool(forKey: "lumen.hasAnyRitual")
    }

    func load() async {
        hasAnyRitual = UserDefaults.standard.bool(forKey: "lumen.hasAnyRitual")
        let alarms = (try? await alarmRepository.all()) ?? []
        hasAnyAlarm = !alarms.isEmpty
        do {
            let loaded = try await buildDashboard.execute(date: Date())
            let hasContent = loaded.energy != nil
                || loaded.intention != nil
                || loaded.gratitude != nil
                || loaded.work != nil
                || loaded.relations != nil
            if hasContent {
                snapshot = loaded
                hasRitualToday = true
            } else {
                snapshot = nil
                hasRitualToday = false
            }
        } catch {
            snapshot = nil
            hasRitualToday = false
        }
    }
}
