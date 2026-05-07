import Testing
import Foundation
@testable import lumen

actor MockAlarmRepository: AlarmRepository {
    private(set) var alarms: [UUID: Alarm] = [:]

    func all() async throws -> [Alarm] { Array(alarms.values) }
    func fetch(id: UUID) async throws -> Alarm? { alarms[id] }
    func save(_ alarm: Alarm) async throws { alarms[alarm.id] = alarm }
    func update(_ alarm: Alarm) async throws {
        guard alarms[alarm.id] != nil else { return }
        alarms[alarm.id] = alarm
    }
    func delete(id: UUID) async throws { alarms.removeValue(forKey: id) }
    func setActive(id: UUID, isActive: Bool) async throws {
        if var alarm = alarms[id] {
            alarm.isActive = isActive
            alarms[id] = alarm
        }
    }
}

actor MockAlarmScheduler: AlarmScheduling {
    private(set) var scheduledIds: [UUID] = []
    private(set) var cancelledIds: [UUID] = []
    private(set) var snoozedIds: [UUID] = []
    private(set) var authRequested = false

    var shouldThrowOnCancel = false

    func setShouldThrowOnCancel(_ value: Bool) { shouldThrowOnCancel = value }

    func requestAuthorizationIfNeeded() async throws -> Bool {
        authRequested = true
        return true
    }

    func schedule(_ alarm: Alarm) async throws {
        scheduledIds.append(alarm.id)
    }

    func cancel(id: UUID) async throws {
        if shouldThrowOnCancel { throw AlarmError.notFound }
        cancelledIds.append(id)
    }

    func cancelAll() async throws {
        cancelledIds.removeAll()
        scheduledIds.removeAll()
    }

    func snooze(id: UUID, minutes: Int) async throws {
        snoozedIds.append(id)
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

        let repoAlarm = await repo.alarms[alarm.id]
        let schedIds = await scheduler.scheduledIds
        #expect(repoAlarm != nil)
        #expect(schedIds.contains(alarm.id))
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

        let snoozedIds = await scheduler.snoozedIds
        #expect(count == 1)
        #expect(snoozedIds.contains(alarm.id))
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
        await scheduler.setShouldThrowOnCancel(true)

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
