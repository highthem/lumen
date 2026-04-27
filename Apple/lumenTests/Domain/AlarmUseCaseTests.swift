import Testing
import Foundation
@testable import lumen

final class MockAlarmRepository: AlarmRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _alarms: [UUID: Alarm] = [:]

    var alarms: [UUID: Alarm] {
        lock.withLock { _alarms }
    }

    func all() async throws -> [Alarm] {
        lock.withLock { Array(_alarms.values) }
    }

    func fetch(id: UUID) async throws -> Alarm? {
        lock.withLock { _alarms[id] }
    }

    func save(_ alarm: Alarm) async throws {
        lock.withLock { _alarms[alarm.id] = alarm }
    }

    func update(_ alarm: Alarm) async throws {
        lock.withLock {
            guard _alarms[alarm.id] != nil else { return }
            _alarms[alarm.id] = alarm
        }
    }

    func delete(id: UUID) async throws {
        lock.withLock { _alarms.removeValue(forKey: id) }
    }

    func setActive(id: UUID, isActive: Bool) async throws {
        lock.withLock {
            if var alarm = _alarms[id] {
                alarm.isActive = isActive
                _alarms[id] = alarm
            }
        }
    }
}

final class MockAlarmScheduler: AlarmScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var _scheduledIds: [UUID] = []
    private var _cancelledIds: [UUID] = []
    private var _snoozedIds: [UUID] = []
    private var _authRequested = false

    var scheduledIds: [UUID] { lock.withLock { _scheduledIds } }
    var cancelledIds: [UUID] { lock.withLock { _cancelledIds } }
    var snoozedIds: [UUID] { lock.withLock { _snoozedIds } }
    var authRequested: Bool { lock.withLock { _authRequested } }

    var shouldThrowOnCancel = false

    func requestAuthorizationIfNeeded() async throws -> Bool {
        lock.withLock { _authRequested = true }
        return true
    }

    func schedule(_ alarm: Alarm) async throws {
        lock.withLock { _scheduledIds.append(alarm.id) }
    }

    func cancel(id: UUID) async throws {
        if shouldThrowOnCancel { throw AlarmError.notFound }
        lock.withLock { _cancelledIds.append(id) }
    }

    func cancelAll() async throws {
        lock.withLock {
            _cancelledIds.removeAll()
            _scheduledIds.removeAll()
        }
    }

    func snooze(id: UUID, minutes: Int) async throws {
        lock.withLock { _snoozedIds.append(id) }
    }
}

@Suite("ScheduleAlarm use case")
struct ScheduleAlarmTests {

    @Test("execute calls both save and schedule")
    func executeSavesAndSchedules() async throws {
        let repo = MockAlarmRepository()
        let scheduler = MockAlarmScheduler()
        let useCase = ScheduleAlarm(repository: repo, scheduler: scheduler)
        let alarm = Alarm(time: Date())

        try await useCase.execute(alarm)

        #expect(repo.alarms[alarm.id] != nil)
        #expect(scheduler.scheduledIds.contains(alarm.id))
    }
}

@Suite("SnoozeAlarm use case")
struct SnoozeAlarmTests {

    @Test("increments count 0→1")
    func incrementsFromZero() async throws {
        let repo = MockAlarmRepository()
        let scheduler = MockAlarmScheduler()
        let alarm = Alarm(time: Date(), snoozeCount: 0)
        try await repo.save(alarm)

        let useCase = SnoozeAlarm(repository: repo, scheduler: scheduler)
        let count = try await useCase.execute(alarmId: alarm.id)

        #expect(count == 1)
        #expect(scheduler.snoozedIds.contains(alarm.id))
    }

    @Test("increments count 1→2")
    func incrementsFromOne() async throws {
        let repo = MockAlarmRepository()
        let scheduler = MockAlarmScheduler()
        let alarm = Alarm(time: Date(), snoozeCount: 1)
        try await repo.save(alarm)

        let useCase = SnoozeAlarm(repository: repo, scheduler: scheduler)
        let count = try await useCase.execute(alarmId: alarm.id)

        #expect(count == 2)
    }

    @Test("increments count 2→3")
    func incrementsFromTwo() async throws {
        let repo = MockAlarmRepository()
        let scheduler = MockAlarmScheduler()
        let alarm = Alarm(time: Date(), snoozeCount: 2)
        try await repo.save(alarm)

        let useCase = SnoozeAlarm(repository: repo, scheduler: scheduler)
        let count = try await useCase.execute(alarmId: alarm.id)

        #expect(count == 3)
    }

    @Test("throws snoozeCapReached when count is 3")
    func throwsWhenCapReached() async throws {
        let repo = MockAlarmRepository()
        let scheduler = MockAlarmScheduler()
        let alarm = Alarm(time: Date(), snoozeCount: 3)
        try await repo.save(alarm)

        let useCase = SnoozeAlarm(repository: repo, scheduler: scheduler)

        await #expect(throws: AlarmError.snoozeCapReached) {
            try await useCase.execute(alarmId: alarm.id)
        }
    }
}

@Suite("CancelAlarm use case")
struct CancelAlarmTests {

    @Test("is idempotent when alarm was never scheduled")
    func idempotentWhenNeverScheduled() async throws {
        let repo = MockAlarmRepository()
        let scheduler = MockAlarmScheduler()
        scheduler.shouldThrowOnCancel = true

        let useCase = CancelAlarm(repository: repo, scheduler: scheduler)
        let alarmId = UUID()

        await #expect(throws: Never.self) {
            try await useCase.execute(alarmId: alarmId)
        }
        await #expect(throws: Never.self) {
            try await useCase.execute(alarmId: alarmId)
        }
    }
}
