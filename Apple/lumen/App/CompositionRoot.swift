import Foundation
import Observation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class CompositionRoot {
    // Sprint 1 — Alarm
    let appStateMachine: AppStateMachine
    let modelContainer: ModelContainer
    let alarmRepository: any AlarmRepository
    let alarmScheduler: any AlarmScheduling
    let audioPlayer: any AudioPlaying
    let scheduleAlarm: ScheduleAlarm
    let snoozeAlarm: SnoozeAlarm
    let cancelAlarm: CancelAlarm
    let notificationActionsHandler: NotificationActionsHandler

    // Sprint 2 — Ritual / AI
    let ritualRepository: any RitualRepository
    let ethicalLogRepository: any EthicalLogRepository
    let rateLimiter: RateLimiter
    let ethicalLogger: EthicalLogger
    let aiSynthesisService: any AISynthesisService
    let networkMonitor: NetworkMonitor
    let speechRecognizer: SpeechRecognizer
    let speechSynthesizer: SpeechSynthesizer
    let quoteProvider: any QuoteProviding
    let userAPIKeyStore: UserAPIKeyStore
    let openAIClient: OpenAIClient
    let anthropicClient: AnthropicClient

    // Use cases
    let startRitual: StartRitual
    let saveQuestionnaireAnswer: SaveQuestionnaireAnswer
    let generateMorningSynthesis: GenerateMorningSynthesis
    let buildDashboardSnapshot: BuildDashboardSnapshot
    let exportEthicalLogs: ExportEthicalLogs
    let eraseEthicalLogs: EraseEthicalLogs
    let dictateAnswer: DictateAnswer
    let speakSynthesis: SpeakSynthesis

    init() {
        let machine = AppStateMachine()
        self.appStateMachine = machine

        // SwiftData schema — includes Sprint 2 models
        let schema = Schema([
            AlarmEntity.self,
            RitualEntity.self,
            EthicalLogEntity.self,
            PendingSynthesisEntity.self
        ])
        let container: ModelContainer
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // On-disk store failed (corrupted, schema migration, low storage).
            // Fall back to in-memory so the app still launches; user can re-create alarms.
            print("⚠️ ModelContainer on-disk init failed — falling back to in-memory: \(error)")
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [memConfig])
        }
        self.modelContainer = container

        // Alarm (Sprint 1)
        let repo = SwiftDataAlarmRepository(modelContainer: container)
        self.alarmRepository = repo

        let scheduler = NotificationScheduler()
        self.alarmScheduler = scheduler

        let sessionManager = AudioSessionManager()
        self.audioPlayer = AudioPlayer(session: sessionManager)

        let schedule = ScheduleAlarm(repository: repo, scheduler: scheduler)
        self.scheduleAlarm = schedule

        let snooze = SnoozeAlarm(repository: repo, scheduler: scheduler)
        self.snoozeAlarm = snooze

        let cancel = CancelAlarm(repository: repo, scheduler: scheduler)
        self.cancelAlarm = cancel

        let handler = NotificationActionsHandler(snooze: snooze, cancel: cancel, appState: machine)
        self.notificationActionsHandler = handler

        LumenNotificationCategory.registerAll()
        UNUserNotificationCenter.current().delegate = handler

        // Ritual repository (Sprint 2)
        let ritualRepo = SwiftDataRitualRepository(modelContainer: container)
        self.ritualRepository = ritualRepo

        // Ethical log repository
        let logRepo = SwiftDataEthicalLogRepository(modelContainer: container)
        self.ethicalLogRepository = logRepo

        // Rate limiter & ethical logger.
        // One-shot migration: previous build used a shared counter for both
        // manual regen and ask-lumen. If a user hit 3 failed attempts on the
        // old build (e.g. because of missing API keys), they would land on a
        // "rate limited" state on first attempt today. Reset stale counters
        // once when this build first runs.
        let limiter = RateLimiter()
        self.rateLimiter = limiter
        let migrationKey = "lumen.ratelimiter.migrated.v2"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            UserDefaults.standard.set(true, forKey: migrationKey)
            Task { await limiter.resetAllForMigration() }
        }

        let logger = EthicalLogger(repository: logRepo)
        self.ethicalLogger = logger

        // Synthesis queue
        let synthQueue = SynthesisQueue(modelContainer: container, ritualRepository: ritualRepo)

        // Cloud AI clients
        let httpClient = URLSessionHTTPClient()
        let openaiClient = OpenAIClient(httpClient: httpClient)
        let anthropicClient = AnthropicClient(httpClient: httpClient)
        self.openAIClient = openaiClient
        self.anthropicClient = anthropicClient

        // User-provided API keys (BYOK). Loaded asynchronously after init so
        // the synthesis path picks up the user's key on the first attempt.
        let userKeyStore = UserAPIKeyStore()
        self.userAPIKeyStore = userKeyStore
        Task { await userKeyStore.load() }

        // On-device AI (canImport gate)
        let onDeviceClient: any AIProviderClient
        let onDeviceAvailable: @Sendable () -> Bool

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let provider = AppleIntelligenceProvider()
            onDeviceClient = provider
            onDeviceAvailable = { AppleIntelligenceProvider.isAvailable }
        } else {
            onDeviceClient = AppleIntelligenceProviderStub()
            onDeviceAvailable = { false }
        }
        #else
        onDeviceClient = AppleIntelligenceProviderStub()
        onDeviceAvailable = { false }
        #endif

        // Network monitor
        let monitor = NetworkMonitor()
        self.networkMonitor = monitor

        // Waterfall AI synthesis service
        let synthesisService = WaterfallAISynthesisService(
            cloudClients: [openaiClient, anthropicClient],
            onDevice: onDeviceClient,
            onDeviceAvailable: onDeviceAvailable,
            queue: synthQueue,
            rateLimiter: limiter,
            ethicalLogger: logger,
            contentSafety: ContentSafetyDetector(),
            supportResources: SupportResourcesProvider(),
            reachability: monitor
        )
        self.aiSynthesisService = synthesisService

        // Voice
        self.speechRecognizer = SpeechRecognizer()
        self.speechSynthesizer = SpeechSynthesizer()

        // Quote provider
        self.quoteProvider = JSONQuoteProvider()

        // Use cases
        self.startRitual = StartRitual(ritualRepository: ritualRepo)
        self.saveQuestionnaireAnswer = SaveQuestionnaireAnswer(ritualRepository: ritualRepo)
        self.generateMorningSynthesis = GenerateMorningSynthesis(ritualRepository: ritualRepo, aiService: synthesisService)
        self.buildDashboardSnapshot = BuildDashboardSnapshot(ritualRepository: ritualRepo)
        self.exportEthicalLogs = ExportEthicalLogs(logRepository: logRepo)
        self.eraseEthicalLogs = EraseEthicalLogs(logRepository: logRepo)
        self.dictateAnswer = DictateAnswer(transcriber: self.speechRecognizer)
        self.speakSynthesis = SpeakSynthesis(tts: self.speechSynthesizer)
    }
}
