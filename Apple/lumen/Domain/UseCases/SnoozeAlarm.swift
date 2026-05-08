import Foundation

struct SnoozeAlarm: Sendable {
    let repository: any AlarmRepository
    let scheduler: any AlarmScheduling

    @discardableResult
    func execute(alarmId: UUID) async throws -> Int {
        guard var alarm = try await repository.fetch(id: alarmId) else {
            throw AlarmError.notFound
        }
        guard alarm.snoozeCount < 3 else {
            throw AlarmError.snoozeCapReached
        }
        alarm.snoozeCount += 1
        alarm.updatedAt = Date()
        try await repository.update(alarm)
        try await scheduler.snooze(alarm, minutes: 5)
        return alarm.snoozeCount
    }
}
