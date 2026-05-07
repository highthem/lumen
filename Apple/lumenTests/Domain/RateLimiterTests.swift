import XCTest
@testable import lumen

/// Immutable Sendable clock — for tests that need to "advance time", create
/// a new `MockClock` and a new `RateLimiter` over the same UserDefaults suite.
/// (Persisted counters survive across instances; the clock is the only thing
/// that changes.)
struct MockClock: LumenClock {
    let date: Date
    init(_ date: Date = Date()) { self.date = date }
    func now() -> Date { date }
}

@MainActor
final class RateLimiterTests: XCTestCase {

    private func makeSuiteName() -> String {
        "lumen.tests.rate.\(UUID().uuidString)"
    }

    // MARK: - Test 1: auto synthesis cap is 1 per day

    func testAutoSynthesisCappedAt1() async {
        let suite = makeSuiteName()
        let sut = RateLimiter(clock: MockClock(), suiteName: suite)

        let first = await sut.canProceed(action: .autoSynthesis)
        XCTAssertTrue(first, "First auto synthesis should be allowed")

        await sut.consume(action: .autoSynthesis)

        let second = await sut.canProceed(action: .autoSynthesis)
        XCTAssertFalse(second, "Second auto synthesis same day should be blocked")
    }

    // MARK: - Test 2: manual regen and askLumen each have their own cap of 3

    func testManualAndAskLumenAreSeparateBuckets() async {
        let sut = RateLimiter(clock: MockClock(), suiteName: makeSuiteName())

        for _ in 0..<3 { await sut.consume(action: .manualRegeneration) }

        let manualBlocked = await sut.canProceed(action: .manualRegeneration)
        XCTAssertFalse(manualBlocked, "manualRegeneration should be capped after 3")

        let askStillOpen = await sut.canProceed(action: .askLumenDashboard)
        XCTAssertTrue(askStillOpen, "askLumenDashboard should be independent of manual regen")
    }

    // MARK: - Test 5: remainingSlots reflects consumed count

    func testRemainingSlotsDecrements() async {
        let sut = RateLimiter(clock: MockClock(), suiteName: makeSuiteName())

        let r0 = await sut.remainingSlots(action: .manualRegeneration)
        XCTAssertEqual(r0, 3, "fresh bucket should have 3 slots")

        await sut.consume(action: .manualRegeneration)
        let r1 = await sut.remainingSlots(action: .manualRegeneration)
        XCTAssertEqual(r1, 2)

        await sut.consume(action: .manualRegeneration)
        await sut.consume(action: .manualRegeneration)
        let r3 = await sut.remainingSlots(action: .manualRegeneration)
        XCTAssertEqual(r3, 0, "exhausted bucket should report 0")

        let rAsk = await sut.remainingSlots(action: .askLumenDashboard)
        XCTAssertEqual(rAsk, 3)
    }

    // MARK: - Test 3: counters reset on new day

    func testResetsOnNewDay() async {
        let suite = makeSuiteName()
        let today = Date()
        let tomorrow = today.addingTimeInterval(25 * 3600)

        let sutToday = RateLimiter(clock: MockClock(today), suiteName: suite)
        await sutToday.consume(action: .autoSynthesis)
        let blockedToday = await sutToday.canProceed(action: .autoSynthesis)
        XCTAssertFalse(blockedToday)

        // New clock = tomorrow; same suite so the persisted state survives.
        // The first `canProceed` triggers `resetIfNeeded()`, which compares the
        // last-reset timestamp to the new clock and clears yesterday's counters.
        let sutTomorrow = RateLimiter(clock: MockClock(tomorrow), suiteName: suite)
        let allowedTomorrow = await sutTomorrow.canProceed(action: .autoSynthesis)
        XCTAssertTrue(allowedTomorrow, "Should reset on a new calendar day")
    }

    // MARK: - Test 4: explicit reset() clears counters

    func testExplicitReset() async {
        let sut = RateLimiter(clock: MockClock(), suiteName: makeSuiteName())

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
