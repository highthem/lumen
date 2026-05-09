#if DEBUG
import Foundation

// Static `preview` factories on every feature ViewModel so each Feature
// view can render in Xcode previews without touching CompositionRoot.

@MainActor
extension AlarmListViewModel {
    static var preview: AlarmListViewModel {
        let repo = PreviewAlarmRepository()
        let scheduler = MaestroAlarmScheduler()
        let cancel = CancelAlarm(repository: repo, scheduler: scheduler)
        let vm = AlarmListViewModel(repo: repo, scheduler: scheduler, cancelUseCase: cancel)
        vm.alarms = Alarm.previewList
        return vm
    }
}

@MainActor
extension AlarmEditViewModel {
    static var preview: AlarmEditViewModel {
        let repo = PreviewAlarmRepository(seed: [])
        let scheduler = MaestroAlarmScheduler()
        let schedule = ScheduleAlarm(repository: repo, scheduler: scheduler)
        return AlarmEditViewModel(
            alarm: nil,
            repo: repo,
            scheduler: scheduler,
            scheduleUseCase: schedule,
            soundProvider: JSONSoundProvider(),
            audioPlayer: MaestroAudioPlayer()
        )
    }
}

@MainActor
extension OnboardingViewModel {
    static var preview: OnboardingViewModel {
        let repo = PreviewAlarmRepository(seed: [])
        let scheduler = MaestroAlarmScheduler()
        let schedule = ScheduleAlarm(repository: repo, scheduler: scheduler)
        return OnboardingViewModel(
            scheduler: scheduler,
            scheduleAlarm: schedule,
            audioPlayer: MaestroAudioPlayer(),
            soundProvider: JSONSoundProvider()
        )
    }
}

@MainActor
extension QuestionnaireFlowViewModel {
    static var preview: QuestionnaireFlowViewModel {
        let ritualRepo = PreviewRitualRepository()
        let start = StartRitual(ritualRepository: ritualRepo)
        let save = SaveQuestionnaireAnswer(ritualRepository: ritualRepo)
        let dictate = DictateAnswer(transcriber: MaestroVoiceTranscriber())
        return QuestionnaireFlowViewModel(startRitual: start, saveAnswer: save, dictation: dictate)
    }
}

@MainActor
extension SynthesisViewModel {
    static var preview: SynthesisViewModel {
        let ritualRepo = PreviewRitualRepository()
        let ai = PreviewAISynthesisService()
        let generate = GenerateMorningSynthesis(ritualRepository: ritualRepo, aiService: ai)
        let speak = SpeakSynthesis(tts: MaestroTextToSpeech())
        return SynthesisViewModel(
            ritualId: Ritual.preview.id,
            generateSynthesis: generate,
            speakSynthesis: speak,
            rateLimiter: RateLimiter()
        )
    }
}

@MainActor
extension DashboardHomeViewModel {
    /// Builds an idle-state ViewModel: alarm scheduled, ritual not yet done.
    static var previewIdle: DashboardHomeViewModel {
        let blankRitual = Ritual(date: Calendar.current.startOfDay(for: Date()))
        let ritualRepo = PreviewRitualRepository(seed: blankRitual)
        let alarmRepo = PreviewAlarmRepository()
        let sleep = NullSleepHealthService()
        let build = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleep)
        let history = FetchRitualHistory(repository: ritualRepo)
        return DashboardHomeViewModel(
            buildDashboard: build,
            fetchHistory: history,
            alarmRepository: alarmRepo,
            sleepService: sleep,
            quoteProvider: JSONQuoteProvider()
        )
    }

    /// Builds an empty-state ViewModel: no alarm, no ritual.
    static var previewEmpty: DashboardHomeViewModel {
        let blankRitual = Ritual(date: Calendar.current.startOfDay(for: Date()))
        let ritualRepo = PreviewRitualRepository(seed: blankRitual)
        let alarmRepo = PreviewAlarmRepository(seed: [])
        let sleep = NullSleepHealthService()
        let build = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleep)
        let history = FetchRitualHistory(repository: ritualRepo)
        return DashboardHomeViewModel(
            buildDashboard: build,
            fetchHistory: history,
            alarmRepository: alarmRepo,
            sleepService: sleep,
            quoteProvider: JSONQuoteProvider()
        )
    }

    static var preview: DashboardHomeViewModel {
        let ritualRepo = PreviewRitualRepository()
        let alarmRepo = PreviewAlarmRepository()
        let sleep = NullSleepHealthService()
        let build = BuildDashboardSnapshot(ritualRepository: ritualRepo, sleepService: sleep)
        let history = FetchRitualHistory(repository: ritualRepo)
        let vm = DashboardHomeViewModel(
            buildDashboard: build,
            fetchHistory: history,
            alarmRepository: alarmRepo,
            sleepService: sleep,
            quoteProvider: JSONQuoteProvider()
        )
        vm.snapshot = .preview
        vm.hasAnyAlarm = true
        vm.hasAnyRitual = true
        vm.hasRitualToday = true
        // Seed a deterministic 7-day window for the streak visuals.
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let initials = ["L", "M", "M", "J", "V", "S", "D"]
        let pattern = [true, true, false, true, true, true, true]
        let days: [WeekHistory.DayStatus] = (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: -(6 - i), to: today) ?? today
            return WeekHistory.DayStatus(
                date: d,
                dayInitial: initials[i],
                isCompleted: pattern[i],
                isToday: i == 6
            )
        }
        vm.weekHistory = WeekHistory(
            days: days,
            completedCount: pattern.filter { $0 }.count,
            consecutiveStreak: 4
        )
        vm.nextAlarmLabel = "06:45"
        return vm
    }
}

@MainActor
extension SettingsViewModel {
    static var preview: SettingsViewModel {
        let logs = PreviewEthicalLogRepository()
        let rituals = PreviewRitualRepository()
        return SettingsViewModel(
            tts: MaestroTextToSpeech(),
            exportLogs: ExportEthicalLogs(logRepository: logs),
            eraseLogs: EraseEthicalLogs(logRepository: logs),
            eraseRituals: EraseAllRituals(repository: rituals),
            soundProvider: JSONSoundProvider(),
            audioPlayer: MaestroAudioPlayer()
        )
    }
}

@MainActor
extension AskLumenViewModel {
    static var preview: AskLumenViewModel {
        AskLumenViewModel(
            category: .energy,
            aiSynthesis: PreviewAISynthesisService(),
            rateLimiter: PreviewRateLimiter(),
            dictation: DictateAnswer(transcriber: MaestroVoiceTranscriber())
        )
    }
}

@MainActor
extension PresenceTimerViewModel {
    static var preview: PresenceTimerViewModel {
        let vm = PresenceTimerViewModel(
            quoteProvider: PreviewQuoteProvider(),
            audioPlayer: MaestroAudioPlayer(),
            soundProvider: JSONSoundProvider()
        )
        vm.quote = .preview
        return vm
    }
}
#endif
