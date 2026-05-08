import Foundation

/// Reads sleep data from HealthKit. Designed to be debranchable: callers must
/// tolerate `nil`/`false` returns (HealthKit unavailable, not authorized, no
/// data) without throwing. Errors are swallowed inside the implementation.
protocol SleepHealthProviding: Sendable {
    /// Returns `nil` if HealthKit is unavailable, not authorized, or no asleep
    /// samples were recorded in the last 24h. Never throws.
    func fetchLastNight() async -> SleepSummary?

    /// Triggers the system permission dialog. Returns `true` only if the
    /// resulting status is `.sharingAuthorized`. Never throws.
    func requestAuthorization() async -> Bool

    /// Cheap synchronous-ish check for current authorization status.
    var isAuthorized: Bool { get async }
}
