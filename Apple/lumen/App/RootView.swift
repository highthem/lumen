import SwiftUI

// MARK: - Ritual flow state machine

enum RitualFlowState: Equatable {
    case none
    case timer
    case questionnaire(UUID)
    case synthesis(UUID)

    var isActive: Bool { self != .none }
}

// MARK: - RootView

struct RootView: View {
    @State private var appState: AppStateMachine.State = .idle
    @State private var hasCompletedOnboarding: Bool = OnboardingFlag.isCompleted
    @State private var ritualFlow: RitualFlowState = .none
    @State private var selectedTab: Int = 0
    @State private var showAskLumen = false
    private let composition: CompositionRoot

    init(composition: CompositionRoot = CompositionRoot()) {
        self.composition = composition
    }

    private var isAlarmRinging: Bool {
        if case .alarmRinging = appState { return true }
        return false
    }

    private var ringingAlarmId: UUID? {
        if case .alarmRinging(let id) = appState { return id }
        return nil
    }

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingFlowView(
                vm: OnboardingViewModel(
                    scheduler: composition.alarmScheduler,
                    scheduleAlarm: composition.scheduleAlarm
                ),
                onComplete: { hasCompletedOnboarding = true }
            )
        } else {
            mainTabView
                .task {
                    for await state in await composition.appStateMachine.observeState() {
                        appState = state
                    }
                }
                .fullScreenCover(isPresented: .constant(isAlarmRinging)) {
                    if let alarmId = ringingAlarmId {
                        AlarmRingingView(
                            alarm: Alarm(id: alarmId, time: Date()),
                            onSnooze: {
                                Task {
                                    try? await composition.snoozeAlarm.execute(alarmId: alarmId)
                                }
                            },
                            onSilence: {
                                Task {
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
                            aiSynthesis: composition.aiSynthesisService
                        ),
                        isPresented: $showAskLumen
                    )
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
                alarmRepository: composition.alarmRepository
            ),
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
                    scheduleUseCase: composition.scheduleAlarm
                )
            }
        )
    }

    private var settingsTab: some View {
        SettingsView(
            vm: SettingsViewModel(
                tts: composition.speechSynthesizer,
                exportLogs: composition.exportEthicalLogs,
                eraseLogs: composition.eraseEthicalLogs
            )
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
                vm: PresenceTimerViewModel(quoteProvider: composition.quoteProvider),
                onComplete: {
                    // Move to questionnaire with a placeholder ritual ID (startRitual will create it)
                    ritualFlow = .questionnaire(UUID())
                }
            )

        case .questionnaire:
            QuestionnaireFlowView(
                vm: QuestionnaireFlowViewModel(
                    startRitual: composition.startRitual,
                    saveAnswer: composition.saveQuestionnaireAnswer,
                    dictation: composition.dictateAnswer
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
                }
            )
        }
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
