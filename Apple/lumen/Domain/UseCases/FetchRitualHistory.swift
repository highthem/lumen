import Foundation

/// Builds a 7-day `WeekHistory` ending at `reference` (default: now).
/// Performs a single repository round-trip via `fetchSince(_:)` then folds
/// the rituals into start-of-day buckets.
struct FetchRitualHistory: Sendable {
    let repository: any RitualRepository

    init(repository: any RitualRepository) {
        self.repository = repository
    }

    func execute(reference: Date = Date()) async throws -> WeekHistory {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: reference)
        // Window: today-6 … today (7 days, ascending)
        let windowStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let dates: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: windowStart)
        }

        let rituals = try await repository.fetchSince(windowStart)

        // Bucket completed-state rituals by start-of-day.
        var completedByDay: Set<Date> = []
        for ritual in rituals where ritual.state == .completed {
            completedByDay.insert(calendar.startOfDay(for: ritual.date))
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE"

        let days: [WeekHistory.DayStatus] = dates.map { date in
            let initial = String(formatter.string(from: date).prefix(1)).uppercased()
            return WeekHistory.DayStatus(
                date: date,
                dayInitial: initial,
                isCompleted: completedByDay.contains(date),
                isToday: calendar.isDate(date, inSameDayAs: today)
            )
        }

        let completedCount = days.reduce(into: 0) { $0 += $1.isCompleted ? 1 : 0 }

        // Consecutive streak: count back from today (or yesterday if today not completed).
        // Walk from end-of-array backward, stopping at the first non-completed day —
        // except the head edge: if today is not completed, the streak still counts the
        // tail of completed days ending at yesterday.
        let consecutive = Self.computeConsecutiveStreak(days: days)

        return WeekHistory(
            days: days,
            completedCount: completedCount,
            consecutiveStreak: consecutive
        )
    }

    private static func computeConsecutiveStreak(days: [WeekHistory.DayStatus]) -> Int {
        guard let last = days.last else { return 0 }
        // Skip today if it's not yet completed — the streak keeps yesterday's count.
        var index = days.count - 1
        if !last.isCompleted { index -= 1 }
        var streak = 0
        while index >= 0 && days[index].isCompleted {
            streak += 1
            index -= 1
        }
        return streak
    }
}
