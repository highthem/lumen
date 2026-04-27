import Foundation

struct CancelAlarm: Sendable {
    let repository: any AlarmRepository
    let scheduler: any AlarmScheduling

    func execute(alarmId: UUID) async throws {
        do {
            try await scheduler.cancel(id: alarmId)
        } catch AlarmError.notFound {
            // idempotent
        }
        do {
            try await repository.setActive(id: alarmId, isActive: false)
        } catch AlarmError.notFound {
            // idempotent
        }
    }
}
