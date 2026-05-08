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

@Suite("OnboardingViewModel")
struct OnboardingViewModelTests {

    @Test("default step is welcome")
    @MainActor
    func defaultStepIsWelcome() {
        let scheduler = MockOnboardingScheduler()
        let repo = MockAlarmRepository()
        let vm = OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: ScheduleAlarm(repository: repo, scheduler: scheduler)
        )
        #expect(vm.step == .welcome)
    }

    @Test("advance cycles through all steps")
    @MainActor
    func advanceCyclesThroughSteps() {
        let scheduler = MockOnboardingScheduler()
        let repo = MockAlarmRepository()
        let vm = OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: ScheduleAlarm(repository: repo, scheduler: scheduler)
        )
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
        let scheduler = MockOnboardingScheduler()
        let repo = MockAlarmRepository()
        let vm = OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: ScheduleAlarm(repository: repo, scheduler: scheduler)
        )
        vm.goBack()
        #expect(vm.step == .welcome)
    }

    @Test("requestNotificationAuthorization sets authorized true when granted")
    @MainActor
    func notificationAuthorizationGranted() async {
        let scheduler = MockOnboardingScheduler()
        await scheduler.setAuthorizationResult(true)
        let repo = MockAlarmRepository()
        let vm = OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: ScheduleAlarm(repository: repo, scheduler: scheduler)
        )
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
        let repo = MockAlarmRepository()
        let vm = OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: ScheduleAlarm(repository: repo, scheduler: scheduler)
        )
        await vm.requestNotificationAuthorization()
        #expect(vm.notificationsAuthorized == false)
    }

    @Test("scheduleFirstAlarm saves repo and schedules")
    @MainActor
    func scheduleFirstAlarmPersistsAndSchedules() async throws {
        OnboardingFlag.reset()
        let scheduler = MockOnboardingScheduler()
        let repo = MockAlarmRepository()
        let vm = OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: ScheduleAlarm(repository: repo, scheduler: scheduler)
        )
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
        let vm = OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: ScheduleAlarm(repository: repo, scheduler: scheduler)
        )
        try await vm.scheduleFirstAlarm()
        #expect(OnboardingFlag.isCompleted == true)
        OnboardingFlag.reset()
    }
}
