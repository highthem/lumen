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
        case alarmSnoozed
        case ritualStarted(ritualId: UUID)
        case ritualPaused(ritualId: UUID)
        case ritualResumed(ritualId: UUID)
        case ritualCompleted(ritualId: UUID)
        case networkLost
        case networkRestored
        case reset
    }

    private(set) var state: State = .idle

    /// Alarms that fire while a ritual is in progress are not silently dropped —
    /// they're queued here and replayed once `.ritualCompleted` lands. This keeps
    /// the user from missing a recurring alarm whose schedule overlapped the
    /// presence/questionnaire/synthesis window.
    private(set) var pendingAlarmId: UUID?

    /// Continuations keyed by a stable UUID rather than an index, so the
    /// onTermination cleanup can find its entry even if other observers
    /// have come and gone. (The previous index-based array silently corrupted
    /// when subscribers terminated out-of-order.)
    private var streamContinuations: [UUID: AsyncStream<State>.Continuation] = [:]

    func observeState() -> AsyncStream<State> {
        AsyncStream(State.self, bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            continuation.yield(state)
            streamContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id: id) }
            }
        }
    }

    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }

    func send(_ event: Event) {
        switch (state, event) {
        // Alarm fires while idle or after a completed ritual: surface immediately.
        case (.idle, .alarmFired(let id)),
             (.ritualDone, .alarmFired(let id)):
            state = .alarmRinging(alarmId: id)

        // Alarm fires while a ritual is active or paused: queue it and
        // surface once the ritual completes (or the user explicitly resets).
        case (.ritualActive, .alarmFired(let id)),
             (.ritualPartial, .alarmFired(let id)):
            pendingAlarmId = id

        // Alarm fires while another alarm is already ringing: keep the
        // current ringing alarm; ignore the duplicate (no stacked covers).
        case (.alarmRinging, .alarmFired):
            break

        case (.alarmRinging, .alarmSilenced):
            state = .idle
            pendingAlarmId = nil

        case (.alarmRinging, .alarmSnoozed):
            state = .idle
            pendingAlarmId = nil

        case (.alarmRinging, .ritualStarted(let id)),
             (.idle, .ritualStarted(let id)):
            state = .ritualActive(ritualId: id)

        case (.ritualActive(let id), .ritualPaused):
            state = .ritualPartial(ritualId: id)

        case (.ritualPartial(let id), .ritualResumed):
            state = .ritualActive(ritualId: id)

        case (_, .ritualCompleted(let id)):
            // If an alarm fired during the ritual, drain it now — the
            // ringing cover takes priority over the ritualDone state.
            if let queued = pendingAlarmId {
                pendingAlarmId = nil
                state = .alarmRinging(alarmId: queued)
            } else {
                state = .ritualDone(ritualId: id)
            }

        case (_, .networkLost):
            state = .offline

        case (.offline, .networkRestored):
            state = .idle

        case (_, .reset):
            state = .idle
            pendingAlarmId = nil

        default:
            break
        }
        let current = state
        for continuation in streamContinuations.values {
            continuation.yield(current)
        }
    }
}
