import Foundation
import Observation

@MainActor
@Observable
final class AlarmEditViewModel {
    var time: Date
    var recurrence: AlarmRecurrence
    var soundId: String
    var isActive: Bool

    private let existingAlarm: Alarm?
    private let repo: any AlarmRepository
    private let scheduler: any AlarmScheduling
    private let scheduleUseCase: ScheduleAlarm

    init(
        alarm: Alarm? = nil,
        repo: any AlarmRepository,
        scheduler: any AlarmScheduling,
        scheduleUseCase: ScheduleAlarm
    ) {
        self.existingAlarm = alarm
        self.repo = repo
        self.scheduler = scheduler
        self.scheduleUseCase = scheduleUseCase

        if let alarm {
            self.time = alarm.time
            self.recurrence = alarm.recurrence
            self.soundId = alarm.soundId
            self.isActive = alarm.isActive
        } else {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 7
            components.minute = 0
            components.second = 0
            self.time = Calendar.current.date(from: components) ?? Date()
            self.recurrence = .none
            self.soundId = "lumen_dawn"
            self.isActive = true
        }
    }

    @discardableResult
    func save() async throws -> Alarm {
        if let existing = existingAlarm {
            let updated = Alarm(
                id: existing.id,
                time: time,
                recurrence: recurrence,
                soundId: soundId,
                isActive: isActive,
                snoozeCount: existing.snoozeCount,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
            try await repo.update(updated)
            try await scheduler.schedule(updated)
            return updated
        } else {
            let alarm = Alarm(
                time: time,
                recurrence: recurrence,
                soundId: soundId,
                isActive: isActive
            )
            try await scheduleUseCase.execute(alarm)
            return alarm
        }
    }
}
