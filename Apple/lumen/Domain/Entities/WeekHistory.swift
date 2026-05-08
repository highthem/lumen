import Foundation

/// 7-day completion window powering the dashboard streak strip + footer.
/// `days` is chronological (oldest first); the last entry is always today.
/// `isCompleted` mirrors `Ritual.state == .completed` for that day.
struct WeekHistory: Sendable, Hashable, Codable {
    struct DayStatus: Sendable, Hashable, Codable, Identifiable {
        let date: Date           // start-of-day, local calendar
        let dayInitial: String   // FR weekday initial: "L","M","M","J","V","S","D"
        let isCompleted: Bool
        let isToday: Bool

        var id: Date { date }
    }

    let days: [DayStatus]
    let completedCount: Int
    let consecutiveStreak: Int

    init(days: [DayStatus], completedCount: Int, consecutiveStreak: Int) {
        self.days = days
        self.completedCount = completedCount
        self.consecutiveStreak = consecutiveStreak
    }

    static let empty = WeekHistory(days: [], completedCount: 0, consecutiveStreak: 0)
}
