import Foundation
import Observation

@MainActor
@Observable
final class DashboardHomeViewModel {
    var snapshot: DashboardSnapshot?
    var hasRitualToday: Bool = false
    var hasAnyRitual: Bool = false
    var hasAnyAlarm: Bool = false

    let sleepService: any SleepHealthProviding
    private let buildDashboard: BuildDashboardSnapshot
    private let alarmRepository: any AlarmRepository

    init(
        buildDashboard: BuildDashboardSnapshot,
        alarmRepository: any AlarmRepository,
        sleepService: any SleepHealthProviding
    ) {
        self.buildDashboard = buildDashboard
        self.alarmRepository = alarmRepository
        self.sleepService = sleepService
        self.hasAnyRitual = UserDefaults.standard.bool(forKey: "lumen.hasAnyRitual")
    }

    func load() async {
        hasAnyRitual = UserDefaults.standard.bool(forKey: "lumen.hasAnyRitual")
        let alarms = (try? await alarmRepository.all()) ?? []
        hasAnyAlarm = !alarms.isEmpty
        do {
            let loaded = try await buildDashboard.execute(date: Date())
            let hasContent = loaded.mood != nil
                || loaded.energy != nil
                || loaded.priority != nil
                || loaded.gratitude != nil
                || loaded.presence != .notStarted
            if hasContent {
                snapshot = loaded
                hasRitualToday = true
            } else {
                snapshot = loaded
                hasRitualToday = false
            }
        } catch {
            snapshot = nil
            hasRitualToday = false
        }
    }
}
