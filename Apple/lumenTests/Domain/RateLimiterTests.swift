import Foundation
import Testing
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

@Suite("RateLimiter")
@MainActor
struct RateLimiterTests {

    private func makeSuiteName() -> String {
        "lumen.tests.rate.\(UUID().uuidString)"
    }

    @Test("auto synthesis is capped at 1 per day")
    func autoSynthesisCappedAt1() async {
        let suite = makeSuiteName()
        let sut = RateLimiter(clock: MockClock(), suiteName: suite)

        let first = await sut.canProceed(action: .autoSynthesis)
        #expect(first)

        await sut.consume(action: .autoSynthesis)

        let second = await sut.canProceed(action: .autoSynthesis)
        #expect(!second)
    }

    @Test("manualRegeneration and askLumenDashboard use separate buckets")
    func manualAndAskLumenAreSeparateBuckets() async {
        let sut = RateLimiter(clock: MockClock(), suiteName: makeSuiteName())

        for _ in 0..<3 { await sut.consume(action: .manualRegeneration) }

        let manualBlocked = await sut.canProceed(action: .manualRegeneration)
        #expect(!manualBlocked)

        let askStillOpen = await sut.canProceed(action: .askLumenDashboard)
        #expect(askStillOpen)
    }

    @Test("remainingSlots decrements with each consume")
    func remainingSlotsDecrements() async {
        let sut = RateLimiter(clock: MockClock(), suiteName: makeSuiteName())

        let r0 = await sut.remainingSlots(action: .manualRegeneration)
        #expect(r0 == 3)

        await sut.consume(action: .manualRegeneration)
        let r1 = await sut.remainingSlots(action: .manualRegeneration)
        #expect(r1 == 2)

        await sut.consume(action: .manualRegeneration)
        await sut.consume(action: .manualRegeneration)
        let r3 = await sut.remainingSlots(action: .manualRegeneration)
        #expect(r3 == 0)

        let rAsk = await sut.remainingSlots(action: .askLumenDashboard)
        #expect(rAsk == 3)
    }

    @Test("counters reset on a new calendar day")
    func resetsOnNewDay() async {
        let suite = makeSuiteName()
        let today = Date()
        let tomorrow = today.addingTimeInterval(25 * 3600)

        let sutToday = RateLimiter(clock: MockClock(today), suiteName: suite)
        await sutToday.consume(action: .autoSynthesis)
        let blockedToday = await sutToday.canProceed(action: .autoSynthesis)
        #expect(!blockedToday)

        // New clock = tomorrow; same suite so the persisted state survives.
        // The first `canProceed` triggers `resetIfNeeded()`, which compares the
        // last-reset timestamp to the new clock and clears yesterday's counters.
        let sutTomorrow = RateLimiter(clock: MockClock(tomorrow), suiteName: suite)
        let allowedTomorrow = await sutTomorrow.canProceed(action: .autoSynthesis)
        #expect(allowedTomorrow)
    }

    @Test("explicit reset() clears all counters")
    func explicitReset() async {
        let sut = RateLimiter(clock: MockClock(), suiteName: makeSuiteName())

        await sut.consume(action: .autoSynthesis)
        await sut.consume(action: .manualRegeneration)
        await sut.consume(action: .manualRegeneration)
        await sut.consume(action: .manualRegeneration)

        await sut.reset()

        let autoOk = await sut.canProceed(action: .autoSynthesis)
        let manualOk = await sut.canProceed(action: .manualRegeneration)
        #expect(autoOk)
        #expect(manualOk)
    }
}
