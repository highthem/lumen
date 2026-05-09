import Testing
import Foundation
@testable import lumen

actor MockOnboardingScheduler: AlarmScheduling {
    private(set) var scheduledAlarms: [Alarm] = []
    private(set) var authRequested = false
    var authorizationResult: Bool = true

    func setAuthorizationResult(_ value: Bool) { authorizationResult = value }

    func requestAuthorizationIfNeeded() async throws -> Bool {
        authRequested = true
        return authorizationResult
    }

    func schedule(_ alarm: Alarm) async throws {
        scheduledAlarms.append(alarm)
    }

    func cancel(id: UUID) async throws {}
    func cancelAll() async throws {}
    func snooze(_ alarm: Alarm, minutes: Int) async throws {}
}

@MainActor
final class MockOnboardingAudioPlayer: AudioPlaying {
    func configureSession() async throws {}
    func play(soundId: String, fadeIn: Bool) async throws {}
    func stop() {}
    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {}
}

struct MockOnboardingSoundProvider: SoundProviding {
    func sounds(for kind: SoundKind) -> [SoundEntry] { [] }
    func defaultSound(for kind: SoundKind) -> SoundEntry? { nil }
    func sound(id: String) -> SoundEntry? { nil }
}

@Suite("OnboardingViewModel")
struct OnboardingViewModelTests {
    @MainActor
    private func makeViewModel(
        scheduler: MockOnboardingScheduler = MockOnboardingScheduler(),
        repo: MockAlarmRepository = MockAlarmRepository()
    ) -> OnboardingViewModel {
        OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: ScheduleAlarm(repository: repo, scheduler: scheduler),
            audioPlayer: MockOnboardingAudioPlayer(),
            soundProvider: MockOnboardingSoundProvider()
        )
    }

    @Test("default step is welcome")
    @MainActor
    func defaultStepIsWelcome() {
        let vm = makeViewModel()
        #expect(vm.step == .welcome)
    }

    @Test("advance cycles through all steps")
    @MainActor
    func advanceCyclesThroughSteps() {
        let vm = makeViewModel()
        #expect(vm.step == .welcome)
        vm.advance()
        #expect(vm.step == .pitch)
        vm.advance()
        #expect(vm.step == .permissions)
        vm.advance()
        #expect(vm.step == .firstAlarm)
        vm.advance()
        #expect(vm.step == .firstAlarm)
    }

    @Test("goBack from welcome stays at welcome")
    @MainActor
    func goBackFromWelcomeStaysAtWelcome() {
        let vm = makeViewModel()
        vm.goBack()
        #expect(vm.step == .welcome)
    }

    @Test("requestNotificationAuthorization sets authorized true when granted")
    @MainActor
    func notificationAuthorizationGranted() async {
        let scheduler = MockOnboardingScheduler()
        await scheduler.setAuthorizationResult(true)
        let vm = makeViewModel(scheduler: scheduler)
        await vm.requestNotificationAuthorization()
        #expect(vm.notificationsAuthorized == true)
        let requested = await scheduler.authRequested
        #expect(requested == true)
    }

    @Test("requestNotificationAuthorization sets authorized false when denied")
    @MainActor
    func notificationAuthorizationDenied() async {
        let scheduler = MockOnboardingScheduler()
        await scheduler.setAuthorizationResult(false)
        let vm = makeViewModel(scheduler: scheduler)
        await vm.requestNotificationAuthorization()
        #expect(vm.notificationsAuthorized == false)
    }

    @Test("scheduleFirstAlarm saves repo and schedules")
    @MainActor
    func scheduleFirstAlarmPersistsAndSchedules() async throws {
        OnboardingFlag.reset()
        let scheduler = MockOnboardingScheduler()
        let repo = MockAlarmRepository()
        let vm = makeViewModel(scheduler: scheduler, repo: repo)
        try await vm.scheduleFirstAlarm()
        let alarmCount = await repo.alarms.count
        let schedCount = await scheduler.scheduledAlarms.count
        #expect(alarmCount == 1)
        #expect(schedCount == 1)
        OnboardingFlag.reset()
    }

    @Test("scheduleFirstAlarm marks onboarding completed")
    @MainActor
    func scheduleFirstAlarmMarksCompleted() async throws {
        OnboardingFlag.reset()
        let scheduler = MockOnboardingScheduler()
        let repo = MockAlarmRepository()
        let vm = makeViewModel(scheduler: scheduler, repo: repo)
        try await vm.scheduleFirstAlarm()
        #expect(OnboardingFlag.isCompleted == true)
        OnboardingFlag.reset()
    }
}
