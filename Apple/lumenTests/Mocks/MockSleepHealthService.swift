import Foundation
@testable import lumen

/// Test double for `SleepHealthProviding`. Configurable per test case.
actor MockSleepHealthService: SleepHealthProviding {
    private var summary: SleepSummary?
    private var authorized: Bool

    init(summary: SleepSummary? = nil, authorized: Bool = false) {
        self.summary = summary
        self.authorized = authorized
    }

    var isAuthorized: Bool {
        get async { authorized }
    }

    func fetchLastNight() async -> SleepSummary? { summary }

    func requestAuthorization() async -> Bool {
        authorized = true
        return true
    }

    func setSummary(_ summary: SleepSummary?) {
        self.summary = summary
    }

    func setAuthorized(_ value: Bool) {
        self.authorized = value
    }
}
