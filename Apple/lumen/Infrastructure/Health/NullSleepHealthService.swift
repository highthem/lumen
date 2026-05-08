import Foundation

/// Always-empty implementation. Used in Maestro/preview/test contexts and as a
/// last-ditch fallback if the real `SleepHealthService` needs to be debranched.
struct NullSleepHealthService: SleepHealthProviding {
    var isAuthorized: Bool { get async { false } }
    func fetchLastNight() async -> SleepSummary? { nil }
    func requestAuthorization() async -> Bool { false }
}
