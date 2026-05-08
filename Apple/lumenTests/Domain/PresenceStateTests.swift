import XCTest
@testable import lumen

@MainActor
final class PresenceStateTests: XCTestCase {

    func testCompletedAfterFullElapsed() {
        XCTAssertEqual(classifySkip(elapsed: 60), .partial)
        XCTAssertEqual(classifySkip(elapsed: 30), .partial)
        XCTAssertEqual(classifySkip(elapsed: 31), .partial)
    }

    func testSkippedBefore30Seconds() {
        XCTAssertEqual(classifySkip(elapsed: 0), .skipped)
        XCTAssertEqual(classifySkip(elapsed: 5), .skipped)
        XCTAssertEqual(classifySkip(elapsed: 29.9), .skipped)
    }

    func testNotStartedIsDefault() {
        XCTAssertEqual(PresenceState.notStarted.rawValue, "notStarted")
    }

    func testDisplayNamesAreNonEmpty() {
        for state in PresenceState.allCases {
            XCTAssertFalse(state.displayName.isEmpty, "Empty display name for \(state)")
        }
    }

    /// Mirrors the classification used in `PresenceTimerViewModel.skip()`.
    private func classifySkip(elapsed: TimeInterval) -> PresenceState {
        elapsed >= 30 ? .partial : .skipped
    }
}
