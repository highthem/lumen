import Foundation
import Observation

@MainActor
@Observable
final class AlarmEditViewModel {
    var time: Date
    var recurrence: AlarmRecurrence
    var soundId: String
    var isActive: Bool
    var previewingSoundId: String?

    private let existingAlarm: Alarm?
    private let repo: any AlarmRepository
    private let scheduler: any AlarmScheduling
    private let scheduleUseCase: ScheduleAlarm
    private let soundProvider: any SoundProviding
    private let audioPlayer: any AudioPlaying

    init(
        alarm: Alarm? = nil,
        repo: any AlarmRepository,
        scheduler: any AlarmScheduling,
        scheduleUseCase: ScheduleAlarm,
        soundProvider: any SoundProviding,
        audioPlayer: any AudioPlaying
    ) {
        self.existingAlarm = alarm
        self.repo = repo
        self.scheduler = scheduler
        self.scheduleUseCase = scheduleUseCase
        self.soundProvider = soundProvider
        self.audioPlayer = audioPlayer

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
            self.soundId = soundProvider.defaultSound(for: .alarm)?.id ?? "alarm-aube"
            self.isActive = true
        }
    }

    var alarmSounds: [SoundEntry] {
        soundProvider.sounds(for: .alarm)
    }

    func previewSound(_ id: String) {
        previewingSoundId = id
        Task {
            await audioPlayer.stop()
            try? await audioPlayer.play(soundId: id, fadeIn: false)
        }
    }

    func stopPreview() {
        previewingSoundId = nil
        Task { await audioPlayer.stop() }
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
