import Foundation

struct ScheduleAlarm: Sendable {
    let repository: any AlarmRepository
    let scheduler: any AlarmScheduling

    func execute(_ alarm: Alarm) async throws {
        try await repository.save(alarm)
        try await scheduler.schedule(alarm)
    }
}
