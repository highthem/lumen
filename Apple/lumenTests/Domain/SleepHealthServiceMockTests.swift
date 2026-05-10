import Foundation
import Testing
@testable import lumen

@Suite("MockSleepHealthService")
@MainActor
struct SleepHealthServiceMockTests {

    @Test("mock returns nil summary and false authorized by default")
    func mockReturnsNilByDefault() async {
        let mock = MockSleepHealthService()
        let summary = await mock.fetchLastNight()
        #expect(summary == nil)
        let authorized = await mock.isAuthorized
        #expect(!authorized)
    }

    @Test("mock returns the configured summary when set")
    func mockReturnsConfiguredSummary() async {
        let fixed = SleepSummary(
            bedtime: Date().addingTimeInterval(-8 * 3600),
            wakeTime: Date(),
            totalAsleep: 7 * 3600,
            deep: 60 * 60,
            rem: 90 * 60,
            core: 5 * 3600,
            awake: 15 * 60
        )
        let mock = MockSleepHealthService(summary: fixed, authorized: true)
        let summary = await mock.fetchLastNight()
        #expect(summary?.totalAsleep == fixed.totalAsleep)
        #expect(summary?.quality == .high)
    }

    @Test("requestAuthorization flips the authorized flag")
    func requestAuthorizationFlipsFlag() async {
        let mock = MockSleepHealthService(summary: nil, authorized: false)
        let granted = await mock.requestAuthorization()
        #expect(granted)
        let authorized = await mock.isAuthorized
        #expect(authorized)
    }

    @Test("quality thresholds map sleep duration to correct quality level")
    func qualityThresholds() {
        let short = SleepSummary(bedtime: Date(), wakeTime: Date(), totalAsleep: 4 * 3600, deep: 0, rem: 0, core: 4 * 3600, awake: 0)
        #expect(short.quality == .low)
        let medium = SleepSummary(bedtime: Date(), wakeTime: Date(), totalAsleep: 6 * 3600, deep: 0, rem: 0, core: 6 * 3600, awake: 0)
        #expect(medium.quality == .medium)
        let solid = SleepSummary(bedtime: Date(), wakeTime: Date(), totalAsleep: 8 * 3600, deep: 0, rem: 0, core: 8 * 3600, awake: 0)
        #expect(solid.quality == .high)
    }
}
