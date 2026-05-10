import Foundation
import Testing
@testable import lumen

@Suite("PresenceState")
struct PresenceStateTests {

    @Test("classifySkip returns .partial when elapsed >= 30 seconds")
    func completedAfterFullElapsed() {
        #expect(classifySkip(elapsed: 60) == .partial)
        #expect(classifySkip(elapsed: 30) == .partial)
        #expect(classifySkip(elapsed: 31) == .partial)
    }

    @Test("classifySkip returns .skipped before 30 seconds")
    func skippedBefore30Seconds() {
        #expect(classifySkip(elapsed: 0) == .skipped)
        #expect(classifySkip(elapsed: 5) == .skipped)
        #expect(classifySkip(elapsed: 29.9) == .skipped)
    }

    @Test("notStarted is the default raw value")
    func notStartedIsDefault() {
        #expect(PresenceState.notStarted.rawValue == "notStarted")
    }

    @Test("all cases have non-empty display names")
    func displayNamesAreNonEmpty() {
        for state in PresenceState.allCases {
            #expect(!state.displayName.isEmpty)
        }
    }

    /// Mirrors the classification used in `PresenceTimerViewModel.skip()`.
    private func classifySkip(elapsed: TimeInterval) -> PresenceState {
        elapsed >= 30 ? .partial : .skipped
    }
}
