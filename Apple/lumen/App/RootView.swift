import SwiftUI

// MARK: - Ritual flow state machine

enum RitualFlowState: Equatable {
    case none
    case timer
    /// Optional hint — non-nil when the presence timer already created today's
    /// ritual and we want the questionnaire to skip its redundant fetch. The
    /// QuestionnaireFlowViewModel still calls `startRitual.execute()` as a
    /// safety net (the use case is idempotent for the day).
    case questionnaire(UUID?)
    case synthesis(UUID)

    var isActive: Bool { self != .none }
}

// MARK: - RootView

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState: AppStateMachine.State = .idle
    @State private var hasCompletedOnboarding: Bool = OnboardingFlag.isCompleted
    @State private var ritualFlow: RitualFlowState = .none
    @State private var questionnaireInitialStep: QuestionnaireStep = .mood
    @State private var selectedTab: Int = 0
    @State private var showAskLumen = false
    @State private var dashboardRefreshKey: Int = 0
    @State private var splashFinished: Bool = false
    /// Live-bound to the same UserDefaults key SettingsViewModel writes to —
    /// so the user's "Apparence" choice is applied immediately to the whole app.
    @AppStorage(AppAppearance.storageKey) private var appearanceRaw: String = AppAppearance.system.rawValue
    private let composition: CompositionRoot

    init(composition: CompositionRoot = CompositionRoot()) {
        self.composition = composition
        _splashFinished = State(initialValue: composition.testMode.isMaestro)
    }

    private var isAlarmRinging: Bool {
        if case .alarmRinging = appState { return true }
        return false
    }

    private var ringingAlarmId: UUID? {
        if case .alarmRinging(let id) = appState { return id }
        return nil
    }

    /// Gate the ringing fullScreenCover on scene activation: when the user taps
    /// the notification while locked, the app launches headless and SwiftUI
    /// asserts inside _performBlockAfterCATransactionCommitSynchronizes if we
    /// try to mount a cover before the window scene is connected.
    private var shouldShowAlarmCover: Bool {
        isAlarmRinging && scenePhase == .active
    }

    var body: some View {
        rootBody
            .preferredColorScheme(currentAppearance.preferredColorScheme)
            .onOpenURL { url in
                Task { await handleDeepLink(url) }
            }
    }

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .system
    }

    @ViewBuilder
    private var rootBody: some View {
        if !splashFinished {
            SplashView(onComplete: {
                withAnimation(LumenAnimation.quick) {
                    splashFinished = true
                }
            })
            .transition(.opacity)
        } else if !hasCompletedOnboarding {
            OnboardingFlowView(
                vm: OnboardingViewModel(
                    scheduler: composition.alarmScheduler,
                    scheduleAlarm: composition.scheduleAlarm
                ),
                onComplete: { hasCompletedOnboarding = true }
            )
            .transition(.opacity)
        } else {
            mainTabView
                .task {
                    for await state in await composition.appStateMachine.observeState() {
                        appState = state
                    }
                }
                .fullScreenCover(isPresented: .constant(shouldShowAlarmCover)) {
                    if let alarmId = ringingAlarmId {
                        AlarmRingingView(
                            alarmId: alarmId,
                            alarmRepository: composition.alarmRepository,
                            audioPlayer: composition.audioPlayer,
                            onSnooze: {
                                Task {
                                    composition.audioPlayer.stop()
                                    _ = try? await composition.snoozeAlarm.execute(alarmId: alarmId)
                                    await composition.appStateMachine.send(.alarmSilenced)
                                }
                            },
                            onSilence: {
                                Task {
                                    composition.audioPlayer.stop()
                                    try? await composition.cancelAlarm.execute(alarmId: alarmId)
                                    await composition.appStateMachine.send(.alarmSilenced)
                                }
                            }
                        )
                    }
                }
                .fullScreenCover(isPresented: Binding(
                    get: { ritualFlow.isActive },
                    set: { if !$0 { ritualFlow = .none } }
                )) {
                    ritualFlowCover
                }
                .sheet(isPresented: $showAskLumen) {
                    AskLumenView(
                        vm: AskLumenViewModel(
                            category: nil,
                            aiSynthesis: composition.aiSynthesisService,
                            rateLimiter: composition.rateLimiter,
                            dictation: composition.dictateAnswer
                        ),
                        isPresented: $showAskLumen
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(28)
                }
        }
    }

    // MARK: - Main tab view

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            dashboardTab
                .tabItem {
                    Label("Matin", systemImage: "sun.horizon")
                }
                .tag(0)

            alarmsTab
                .tabItem {
                    Label("Réveil", systemImage: "alarm")
                }
                .tag(1)

            settingsTab
                .tabItem {
                    Label("Réglages", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(LumenColor.accent)
    }

    private var dashboardTab: some View {
        DashboardHomeView(
            vm: DashboardHomeViewModel(
                buildDashboard: composition.buildDashboardSnapshot,
                fetchHistory: composition.fetchRitualHistory,
                alarmRepository: composition.alarmRepository,
                sleepService: composition.sleepHealthService,
                quoteProvider: composition.quoteProvider
            ),
            refreshKey: dashboardRefreshKey,
            onStartRitual: { ritualFlow = .timer },
            onNavigateToAlarms: { selectedTab = 1 },
            onAskLumen: { showAskLumen = true }
        )
    }

    private var alarmsTab: some View {
        AlarmListView(
            vm: AlarmListViewModel(
                repo: composition.alarmRepository,
                scheduler: composition.alarmScheduler,
                cancelUseCase: composition.cancelAlarm
            ),
            makeEditVM: { alarm in
                AlarmEditViewModel(
                    alarm: alarm,
                    repo: composition.alarmRepository,
                    scheduler: composition.alarmScheduler,
                    scheduleUseCase: composition.scheduleAlarm,
                    soundProvider: composition.soundProvider,
                    audioPlayer: composition.audioPlayer
                )
            }
        )
    }

    private var settingsTab: some View {
        SettingsView(
            vm: SettingsViewModel(
                tts: composition.speechSynthesizer,
                exportLogs: composition.exportEthicalLogs,
                eraseLogs: composition.eraseEthicalLogs,
                eraseRituals: composition.eraseAllRituals,
                soundProvider: composition.soundProvider,
                audioPlayer: composition.audioPlayer
            ),
            makeAdvancedVM: {
                SettingsAdvancedViewModel(
                    keyStore: composition.userAPIKeyStore,
                    openAIClient: composition.openAIClient,
                    anthropicClient: composition.anthropicClient,
                    usesDeterministicValidation: composition.testMode.isMaestro
                )
            },
            keyStore: composition.userAPIKeyStore
        )
    }

    // MARK: - Ritual flow cover

    @ViewBuilder
    private var ritualFlowCover: some View {
        switch ritualFlow {
        case .none:
            EmptyView()

        case .timer:
            PresenceTimerView(
                vm: PresenceTimerViewModel(
                    quoteProvider: composition.quoteProvider,
                    audioPlayer: composition.audioPlayer,
                    soundProvider: composition.soundProvider,
                    ritualRepository: composition.ritualRepository
                ),
                onComplete: { ritualId in
                    // Thread the real ritual ID — the timer VM already created
                    // today's ritual via fetchOrCreateToday, so the questionnaire
                    // can skip its own redundant fetch.
                    ritualFlow = .questionnaire(ritualId)
                }
            )

        case .questionnaire(let presetRitualId):
            QuestionnaireFlowView(
                vm: QuestionnaireFlowViewModel(
                    startRitual: composition.startRitual,
                    saveAnswer: composition.saveQuestionnaireAnswer,
                    dictation: composition.dictateAnswer,
                    initialStep: questionnaireInitialStep,
                    presetRitualId: presetRitualId
                ),
                onComplete: { ritualId in
                    ritualFlow = .synthesis(ritualId)
                }
            )

        case .synthesis(let ritualId):
            SynthesisView(
                vm: SynthesisViewModel(
                    ritualId: ritualId,
                    generateSynthesis: composition.generateMorningSynthesis,
                    speakSynthesis: composition.speakSynthesis,
                    rateLimiter: composition.rateLimiter
                ),
                onComplete: {
                    ritualFlow = .none
                    // Force the dashboard's .task(id:) to re-run so the newly
                    // saved ritual appears immediately without a tab switch.
                    dashboardRefreshKey &+= 1
                }
            )
        }
    }

    @MainActor
    private func handleDeepLink(_ url: URL) async {
        #if DEBUG
        guard composition.testMode.isMaestro, let testState = composition.maestroTestState else { return }
        guard let route = await MaestroTestSupport.route(for: url, composition: composition, state: testState) else { return }

        splashFinished = true
        hasCompletedOnboarding = true

        switch route {
        case .dashboard:
            ritualFlow = .none
            selectedTab = 0
            dashboardRefreshKey &+= 1

        case .timer:
            questionnaireInitialStep = .mood
            ritualFlow = .timer

        case .questionnaire(let step):
            questionnaireInitialStep = step
            ritualFlow = .questionnaire(nil)

        case .synthesis(let ritualId):
            ritualFlow = .synthesis(ritualId)

        case .alarmRinging(let alarmId):
            appState = .alarmRinging(alarmId: alarmId)
        }
        #else
        _ = url
        #endif
    }
}

#Preview("Dark") {
    RootView()
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    RootView()
        .preferredColorScheme(.light)
}
