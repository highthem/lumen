import Foundation
import Observation

enum DashboardState: Sendable {
    case empty       // no alarm scheduled — first-launch hero
    case idle        // alarm scheduled, ritual not done today
    case postRitual  // ritual completed today
}

@MainActor
@Observable
final class DashboardHomeViewModel {
    var snapshot: DashboardSnapshot?
    var hasRitualToday: Bool = false
    var hasAnyRitual: Bool = false
    var hasAnyAlarm: Bool = false
    /// Earliest active alarm's time-of-day, formatted "HH:mm".
    var nextAlarmLabel: String?
    /// Quote of the day — refreshed once per dashboard load, stable for the
    /// morning glance (kept for compatibility with downstream surfaces).
    var quote: Quote?
    /// 7-day completion window powering the streak strip + footer.
    var weekHistory: WeekHistory = .empty
    /// Non-nil when the user has a partial ritual today — drives the resume banner.
    var partialRitual: Ritual?

    /// Mutually-exclusive state used by the View's outer switch.
    var displayState: DashboardState {
        if hasRitualToday { return .postRitual }
        if hasAnyAlarm { return .idle }
        return .empty
    }

    let sleepService: any SleepHealthProviding
    private let buildDashboard: BuildDashboardSnapshot
    private let fetchHistory: FetchRitualHistory
    private let alarmRepository: any AlarmRepository
    private let ritualRepository: any RitualRepository
    private let quoteProvider: any QuoteProviding

    init(
        buildDashboard: BuildDashboardSnapshot,
        fetchHistory: FetchRitualHistory,
        alarmRepository: any AlarmRepository,
        ritualRepository: any RitualRepository,
        sleepService: any SleepHealthProviding,
        quoteProvider: any QuoteProviding
    ) {
        self.buildDashboard = buildDashboard
        self.fetchHistory = fetchHistory
        self.alarmRepository = alarmRepository
        self.ritualRepository = ritualRepository
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
            snapshot = loaded
            hasRitualToday = hasContent
        } catch {
            snapshot = nil
            hasRitualToday = false
        }
        weekHistory = (try? await fetchHistory.execute()) ?? .empty
        if let ritual = try? await ritualRepository.fetchByDate(Date()),
           ritual.state == .partial {
            partialRitual = ritual
        } else {
            partialRitual = nil
        }
    }

    /// Earliest active alarm by time-of-day. Returns nil if none.
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
