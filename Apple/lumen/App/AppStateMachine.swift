import Foundation

actor AppStateMachine {
    enum State: Equatable, Sendable {
        case idle
        case alarmRinging(alarmId: UUID)
        case ritualActive(ritualId: UUID)
        case ritualPartial(ritualId: UUID)
        case ritualDone(ritualId: UUID)
        case offline
    }

    enum Event: Sendable {
        case alarmFired(alarmId: UUID)
        case alarmSilenced
        case ritualStarted(ritualId: UUID)
        case ritualPaused(ritualId: UUID)
        case ritualResumed(ritualId: UUID)
        case ritualCompleted(ritualId: UUID)
        case networkLost
        case networkRestored
        case reset
    }

    private(set) var state: State = .idle
    private var streamContinuations: [AsyncStream<State>.Continuation] = []

    func observeState() -> AsyncStream<State> {
        AsyncStream(State.self, bufferingPolicy: .bufferingNewest(1)) { continuation in
            continuation.yield(state)
            streamContinuations.append(continuation)
            let index = streamContinuations.count - 1
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(at: index) }
            }
        }
    }

    private func removeContinuation(at index: Int) {
        guard index < streamContinuations.count else { return }
        streamContinuations.remove(at: index)
    }

    func send(_ event: Event) {
        switch (state, event) {
        case (.idle, .alarmFired(let id)),
             (.ritualDone, .alarmFired(let id)):
            state = .alarmRinging(alarmId: id)

        case (.alarmRinging, .alarmSilenced):
            state = .idle

        case (.alarmRinging, .ritualStarted(let id)),
             (.idle, .ritualStarted(let id)):
            state = .ritualActive(ritualId: id)

        case (.ritualActive(let id), .ritualPaused):
            state = .ritualPartial(ritualId: id)

        case (.ritualPartial(let id), .ritualResumed):
            state = .ritualActive(ritualId: id)

        case (_, .ritualCompleted(let id)):
            state = .ritualDone(ritualId: id)

        case (_, .networkLost):
            state = .offline

        case (.offline, .networkRestored):
            state = .idle

        case (_, .reset):
            state = .idle

        default:
            break
        }
        let current = state
        for continuation in streamContinuations {
            continuation.yield(current)
        }
    }
}
