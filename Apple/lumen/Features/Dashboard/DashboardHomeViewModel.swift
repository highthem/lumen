import Foundation
import Observation

@MainActor
@Observable
final class DashboardHomeViewModel {
    var snapshot: DashboardSnapshot?
    var hasRitualToday: Bool = false
    var hasAnyRitual: Bool = false
    var hasAnyAlarm: Bool = false
    /// Earliest active alarm's time-of-day, formatted "HH:mm". Powers the
    /// idle-state tagline ("Ta première alarme à 07:00"). Nil = no active alarm.
    var nextAlarmLabel: String?
    /// "Quote du jour" displayed on the idle dashboard per `handoff/sections/screens.html`.
    /// Refreshed once per dashboard load; stable for the user's morning glance.
    var quote: Quote?

    let sleepService: any SleepHealthProviding
    private let buildDashboard: BuildDashboardSnapshot
    private let alarmRepository: any AlarmRepository
    private let quoteProvider: any QuoteProviding

    init(
        buildDashboard: BuildDashboardSnapshot,
        alarmRepository: any AlarmRepository,
        sleepService: any SleepHealthProviding,
        quoteProvider: any QuoteProviding
    ) {
        self.buildDashboard = buildDashboard
        self.alarmRepository = alarmRepository
        self.sleepService = sleepService
        self.quoteProvider = quoteProvider
        self.hasAnyRitual = UserDefaults.standard.bool(forKey: "lumen.hasAnyRitual")
    }

    func load() async {
        hasAnyRitual = UserDefaults.standard.bool(forKey: "lumen.hasAnyRitual")
        let alarms = (try? await alarmRepository.all()) ?? []
        hasAnyAlarm = !alarms.isEmpty
        nextAlarmLabel = Self.computeNextAlarmLabel(from: alarms)
        if quote == nil {
            quote = await quoteProvider.random(lang: "fr")
        }
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

    /// Picks the earliest active alarm by time-of-day (sorted hour, minute).
    /// Returns nil if no alarm is active. We don't currently project to the
    /// next concrete fire date — the dashboard tagline only shows the wall
    /// time, not the day, so HH:mm of the soonest enabled alarm is sufficient.
    private static func computeNextAlarmLabel(from alarms: [Alarm]) -> String? {
        let active = alarms.filter(\.isActive)
        guard !active.isEmpty else { return nil }
        let sorted = active.sorted { lhs, rhs in
            let lh = Calendar.current.dateComponents([.hour, .minute], from: lhs.time)
            let rh = Calendar.current.dateComponents([.hour, .minute], from: rhs.time)
            if lh.hour != rh.hour { return (lh.hour ?? 0) < (rh.hour ?? 0) }
            return (lh.minute ?? 0) < (rh.minute ?? 0)
        }
        guard let first = sorted.first else { return nil }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: first.time)
    }
}
