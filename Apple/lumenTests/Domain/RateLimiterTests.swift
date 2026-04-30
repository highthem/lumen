import XCTest
@testable import lumen

final class MockClock: LumenClock, @unchecked Sendable {
    private let lock = NSLock()
    private var _current: Date

    init(date: Date = Date()) {
        self._current = date
    }

    func now() -> Date {
        lock.withLock { _current }
    }

    func advance(by interval: TimeInterval) {
        lock.withLock { _current = _current.addingTimeInterval(interval) }
    }

    func set(date: Date) {
        lock.withLock { _current = date }
    }
}

@MainActor
final class RateLimiterTests: XCTestCase {

    private func makeSut(clock: MockClock) -> RateLimiter {
        let suiteName = "lumen.tests.rate.\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suiteName)!
        return RateLimiter(clock: clock, userDefaults: ud)
    }

    // MARK: - Test 1: auto synthesis cap is 1 per day

    func testAutoSynthesisCappedAt1() async {
        let clock = MockClock()
        let sut = makeSut(clock: clock)

        let first = await sut.canProceed(action: .autoSynthesis)
        XCTAssertTrue(first, "First auto synthesis should be allowed")

        await sut.consume(action: .autoSynthesis)

        let second = await sut.canProceed(action: .autoSynthesis)
        XCTAssertFalse(second, "Second auto synthesis same day should be blocked")
    }

    // MARK: - Test 2: manual regen and askLumen each have their own cap of 3

    func testManualAndAskLumenAreSeparateBuckets() async {
        let clock = MockClock()
        let sut = makeSut(clock: clock)

        // Burn the manual regen bucket
        for _ in 0..<3 { await sut.consume(action: .manualRegeneration) }

        let manualBlocked = await sut.canProceed(action: .manualRegeneration)
        XCTAssertFalse(manualBlocked, "manualRegeneration should be capped after 3")

        let askStillOpen = await sut.canProceed(action: .askLumenDashboard)
        XCTAssertTrue(askStillOpen, "askLumenDashboard should be independent of manual regen")
    }

    // MARK: - Test 5: remainingSlots reflects consumed count

    func testRemainingSlotsDecrements() async {
        let clock = MockClock()
        let sut = makeSut(clock: clock)

        let r0 = await sut.remainingSlots(action: .manualRegeneration)
        XCTAssertEqual(r0, 3, "fresh bucket should have 3 slots")

        await sut.consume(action: .manualRegeneration)
        let r1 = await sut.remainingSlots(action: .manualRegeneration)
        XCTAssertEqual(r1, 2)

        await sut.consume(action: .manualRegeneration)
        await sut.consume(action: .manualRegeneration)
        let r3 = await sut.remainingSlots(action: .manualRegeneration)
        XCTAssertEqual(r3, 0, "exhausted bucket should report 0")

        // askLumen unaffected
        let rAsk = await sut.remainingSlots(action: .askLumenDashboard)
        XCTAssertEqual(rAsk, 3)
    }

    // MARK: - Test 3: counters reset on new day

    func testResetsOnNewDay() async {
        let clock = MockClock()
        let sut = makeSut(clock: clock)

        await sut.consume(action: .autoSynthesis)
        let blockedToday = await sut.canProceed(action: .autoSynthesis)
        XCTAssertFalse(blockedToday)

        // Advance to tomorrow
        clock.advance(by: 25 * 3600)

        let allowedTomorrow = await sut.canProceed(action: .autoSynthesis)
        XCTAssertTrue(allowedTomorrow, "Should reset on a new calendar day")
    }

    // MARK: - Test 4: explicit reset() clears counters

    func testExplicitReset() async {
        let clock = MockClock()
        let sut = makeSut(clock: clock)

        await sut.consume(action: .autoSynthesis)
        await sut.consume(action: .manualRegeneration)
        await sut.consume(action: .manualRegeneration)
        await sut.consume(action: .manualRegeneration)

        await sut.reset()

        let autoOk = await sut.canProceed(action: .autoSynthesis)
        let manualOk = await sut.canProceed(action: .manualRegeneration)
        XCTAssertTrue(autoOk)
        XCTAssertTrue(manualOk)
    }
}
