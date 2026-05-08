import XCTest
@testable import lumen

@MainActor
final class SleepHealthServiceMockTests: XCTestCase {

    func testMockReturnsNilByDefault() async {
        let mock = MockSleepHealthService()
        let summary = await mock.fetchLastNight()
        XCTAssertNil(summary)
        let authorized = await mock.isAuthorized
        XCTAssertFalse(authorized)
    }

    func testMockReturnsConfiguredSummary() async {
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
        XCTAssertEqual(summary?.totalAsleep, fixed.totalAsleep)
        XCTAssertEqual(summary?.quality, .high)
    }

    func testRequestAuthorizationFlipsFlag() async {
        let mock = MockSleepHealthService(summary: nil, authorized: false)
        let granted = await mock.requestAuthorization()
        XCTAssertTrue(granted)
        let authorized = await mock.isAuthorized
        XCTAssertTrue(authorized)
    }

    func testQualityThresholds() {
        let short = SleepSummary(bedtime: Date(), wakeTime: Date(), totalAsleep: 4 * 3600, deep: 0, rem: 0, core: 4 * 3600, awake: 0)
        XCTAssertEqual(short.quality, .low)
        let medium = SleepSummary(bedtime: Date(), wakeTime: Date(), totalAsleep: 6 * 3600, deep: 0, rem: 0, core: 6 * 3600, awake: 0)
        XCTAssertEqual(medium.quality, .medium)
        let solid = SleepSummary(bedtime: Date(), wakeTime: Date(), totalAsleep: 8 * 3600, deep: 0, rem: 0, core: 8 * 3600, awake: 0)
        XCTAssertEqual(solid.quality, .high)
    }
}
