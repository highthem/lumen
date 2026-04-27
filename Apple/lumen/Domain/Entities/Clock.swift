import Foundation

protocol LumenClock: Sendable {
    nonisolated func now() -> Date
}

struct SystemClock: LumenClock {
    nonisolated func now() -> Date { Date() }
}
