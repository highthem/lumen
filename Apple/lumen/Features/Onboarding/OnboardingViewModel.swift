import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable, Sendable {
    case welcome = 0
    case pitch
    case permissions
    case firstAlarm
}

@MainActor
@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome
    var notificationsAuthorized: Bool = false
    var notificationsDenied: Bool = false
    var firstAlarmTime: Date = {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 7; c.minute = 0; c.second = 0
        return Calendar.current.date(from: c) ?? Date()
    }()

    private let scheduler: any AlarmScheduling
    private let scheduleAlarmUseCase: ScheduleAlarm
    private let audioPlayer: any AudioPlaying
    private let soundProvider: any SoundProviding

    init(
        scheduler: any AlarmScheduling,
        scheduleAlarm: ScheduleAlarm,
        audioPlayer: any AudioPlaying,
        soundProvider: any SoundProviding
    ) {
        self.scheduler = scheduler
        self.scheduleAlarmUseCase = scheduleAlarm
        self.audioPlayer = audioPlayer
        self.soundProvider = soundProvider
    }

    func advance() {
        step = OnboardingStep(rawValue: step.rawValue + 1) ?? step
    }

    func goBack() {
        step = OnboardingStep(rawValue: step.rawValue - 1) ?? step
    }

    func requestNotificationAuthorization() async {
        let granted = (try? await scheduler.requestAuthorizationIfNeeded()) ?? false
        notificationsAuthorized = granted
        notificationsDenied = !granted
    }

    func previewAlarmSound() async {
        let soundId = soundProvider.defaultSound(for: .alarm)?.id ?? "alarm-aube"
        try? await audioPlayer.play(soundId: soundId, fadeIn: false)
    }

    func scheduleFirstAlarm() async throws {
        let alarm = Alarm(time: firstAlarmTime, recurrence: .everyday)
        try await scheduleAlarmUseCase.execute(alarm)
        OnboardingFlag.markCompleted()
    }

}
