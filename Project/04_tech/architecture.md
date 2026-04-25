# Architecture

## Vue d'ensemble

MVVM + Clean, organisé en modules avec règles de dépendance strictes.

```
┌─────────────────────────────────────────────────────────────┐
│                        App Target                           │
│  (Entry point, DI composition root, app delegate / scene)  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Features layer                         │
│  Alarm / Timer / Questionnaire / Synthesis / Dashboard /   │
│            Onboarding / Settings / AskLumen                 │
│       (SwiftUI views + ViewModels + Navigation)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Domain layer                          │
│    Use cases / Entities / Domain services / Protocols       │
│               (Swift pure, zero import UI)                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Data layer                           │
│  Repositories (impl des protocols Domain)                   │
│  Local : SwiftData stores                                   │
│  Remote : IA clients (OpenAI, Anthropic)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Infrastructure layer                      │
│  AlarmScheduler (UNUserNotificationCenter)                  │
│  AudioPlayer (AVFoundation)                                 │
│  NetworkMonitor (NWPathMonitor)                             │
│  Logger (os.log + EthicalMonitorStore)                      │
│  HTTPClient (URLSession)                                    │
└─────────────────────────────────────────────────────────────┘
```

## Règles de dépendance

- **Features** → Domain (OK)
- **Features** → Data (❌ interdit, passe par Domain)
- **Domain** ne dépend de rien d'autre que Foundation + swift-log-like primitives
- **Data** implémente les protocols de Domain, peut dépendre de Infrastructure
- **Infrastructure** est autonome, expose des protocols consommés par Data
- **App** compose tout (Composition Root)

## Structure de dossiers réelle (monorepo)

Le repo `highthem/lumen` est un monorepo iOS + Android (futur) + docs.

```
Lumen/                              # racine du repo Git (highthem/lumen)
├── README.md
├── .gitignore
├── ci_scripts/                     # Convention Xcode Cloud
│   ├── ci_post_clone.sh           # injection des Secrets.xcconfig depuis env vars
│   ├── ci_pre_xcodebuild.sh       # éventuel
│   └── ci_post_xcodebuild.sh      # éventuel
├── Project/                        # documentation produit/design/tech (ce pack)
│   ├── 00_brief/ ... 07_ecosystem/
├── Apple/                          # projet iOS
│   ├── lumen.xcodeproj
│   ├── lumen/                     # sources principales
│   │   ├── lumenApp.swift
│   │   ├── App/
│   │   │   ├── RootView.swift
│   │   │   ├── CompositionRoot.swift
│   │   │   └── AppStateMachine.swift
│   │   ├── Features/
│   │   │   └── Alarm/
│   │   │       ├── AlarmListView.swift
│   │   ├── AlarmListViewModel.swift
│   │   ├── AlarmEditView.swift
│   │   ├── AlarmEditViewModel.swift
│   │   └── AlarmRingingView.swift
│   ├── Timer/
│   │   ├── PresenceTimerView.swift
│   │   └── PresenceTimerViewModel.swift
│   ├── Questionnaire/
│   │   ├── QuestionnaireFlowView.swift
│   │   ├── QuestionnaireFlowCoordinator.swift
│   │   ├── Q1MoodView.swift / Q2PriorityView.swift / ...
│   │   └── QuestionnaireViewModel.swift
│   ├── Synthesis/
│   │   ├── SynthesisView.swift
│   │   └── SynthesisViewModel.swift
│   ├── Dashboard/
│   │   ├── DashboardHomeView.swift
│   │   ├── DashboardHomeViewModel.swift
│   │   ├── CategoryDetailView.swift
│   │   └── CategoryDetailViewModel.swift
│   ├── Onboarding/
│   └── Settings/
├── Domain/
│   ├── Entities/
│   │   ├── Alarm.swift
│   │   ├── Ritual.swift
│   │   ├── QuestionnaireAnswer.swift
│   │   ├── AIResponse.swift
│   │   ├── DashboardSnapshot.swift
│   │   └── EthicalLog.swift
│   ├── UseCases/
│   │   ├── ScheduleAlarm.swift
│   │   ├── SnoozeAlarm.swift
│   │   ├── StartRitual.swift
│   │   ├── SaveQuestionnaireAnswer.swift
│   │   ├── GenerateMorningSynthesis.swift
│   │   ├── BuildDashboardSnapshot.swift
│   │   └── ExportEthicalLogs.swift
│   ├── Services/
│   │   ├── RateLimiter.swift
│   │   └── QuoteProvider.swift
│   └── Protocols/
│       ├── AlarmRepository.swift
│       ├── RitualRepository.swift
│       ├── AISynthesisService.swift
│       ├── EthicalLogRepository.swift
│       ├── AlarmScheduling.swift
│       ├── AudioPlaying.swift
│       └── NetworkReachability.swift
├── Data/
│   ├── Repositories/
│   │   ├── SwiftDataAlarmRepository.swift
│   │   ├── SwiftDataRitualRepository.swift
│   │   └── SwiftDataEthicalLogRepository.swift
│   ├── AI/
│   │   ├── WaterfallAISynthesisService.swift
│   │   ├── OpenAIClient.swift
│   │   ├── AnthropicClient.swift
│   │   ├── OfflineTemplateSynthesis.swift
│   │   └── PromptBuilder.swift
│   └── Models/  (SwiftData @Model classes)
│       ├── AlarmEntity.swift
│       ├── RitualEntity.swift
│       ├── QuestionnaireAnswerEntity.swift
│       ├── DashboardSnapshotEntity.swift
│       └── EthicalLogEntity.swift
├── Infrastructure/
│   ├── Notifications/
│   │   ├── NotificationScheduler.swift
│   │   ├── NotificationActionsHandler.swift
│   │   └── NotificationCategories.swift
│   ├── Audio/
│   │   ├── AudioPlayer.swift
│   │   └── AudioSessionManager.swift
│   ├── Network/
│   │   ├── HTTPClient.swift
│   │   └── NetworkMonitor.swift
│   └── Logging/
│       └── Logger.swift
├── Shared/
│   ├── DesignSystem/
│   │   ├── Colors.swift / Typography.swift / Spacing.swift / Components.swift
│   ├── Resources/
│   │   ├── Quotes.json
│   │   ├── Sounds/ (3 x .caf)
│   │   └── Localizable.xcstrings
│   └── Utils/
│   │   └── Config/
│   │       ├── Secrets.xcconfig          # gitignored (clés OpenAI, Anthropic)
│   │       └── Secrets.xcconfig.sample   # committed (placeholders)
│   ├── lumenTests/                # tests unitaires (Domain prioritaire)
│   └── lumenUITests/              # tests UI (1-2 parcours critiques optionnel)
└── Android/                        # placeholder app Android (V2+)
```

**Note convention :** dossier source en minuscule `lumen` (généré par Xcode), bundle ID `com.highthem.lumen`. Le projet Xcode utilise `PBXFileSystemSynchronizedRootGroup` (Xcode 16+) — les fichiers ajoutés dans le filesystem sont auto-détectés par Xcode, pas besoin d'updater manuellement le `project.pbxproj` à chaque ajout.

## Injection de dépendances

- Composition Root dans `CompositionRoot.swift`
- Exemple :

```swift
@MainActor
final class CompositionRoot {
    let alarmViewModel: AlarmListViewModel
    // ...
    init(modelContainer: ModelContainer) {
        let httpClient = URLSessionHTTPClient()
        let openAI = OpenAIClient(http: httpClient, apiKey: Secrets.openAIKey)
        let anthropic = AnthropicClient(http: httpClient, apiKey: Secrets.anthropicKey)
        let offline = OfflineTemplateSynthesis()
        let aiService = WaterfallAISynthesisService(
            providers: [openAI, anthropic],
            fallback: offline,
            rateLimiter: RateLimiter.defaults(),
            ethicalLogRepo: SwiftDataEthicalLogRepository(container: modelContainer)
        )
        // ...
    }
}
```

## Gestion d'état global

- `AppStateMachine` (actor) : idle / ritual_active / ritual_partial / ritual_done / offline
- Transitions event-driven, testables unitairement
- Consommé par `RootView` via `@Observable`

## Flow d'une synthèse IA (diagramme séquence simplifié)

```
User ── completes Q4 ──► QuestionnaireViewModel
                              │
                              ▼
                       SaveQuestionnaireAnswer (use case)
                              │
                              ▼
                       GenerateMorningSynthesis (use case)
                              │
                              ▼
                   AISynthesisService.synthesize()
                              │
                              ├─► Check RateLimiter
                              │     ├─ OK → continue
                              │     └─ blocked → return .rateLimited
                              │
                              ├─► Check NetworkReachability
                              │     ├─ offline → OfflineTemplateSynthesis
                              │     └─ online  → try cloud
                              │
                              ├─► Try OpenAIClient
                              │     ├─ success → return + log
                              │     └─ fail    → try Anthropic
                              │
                              ├─► Try AnthropicClient
                              │     ├─ success → return + log
                              │     └─ fail    → fallback offline
                              │
                              └─► Persist EthicalLog (always)
                              │
                              ▼
                        Stream/return to VM
                              │
                              ▼
                         SynthesisView
```

## Background execution model

- **Alarm trigger** : UN scheduled local notification → system réveille l'app si nécessaire, pas d'exécution code sans user tap
- **User tape une action (Snooze / Silence)** depuis la notif → `NotificationActionsHandler` traite (background task court, UIBackgroundTaskIdentifier)
- **App launch depuis notif** : `AppDelegate` redirige vers le bon écran (rituel start)

## Points de vigilance

- **SwiftData + concurrency** : `@ModelActor` obligatoire pour accès hors MainActor, documenté ADR.
- **Background audio** : l'app doit avoir `UIBackgroundModes: audio` dans Info.plist, et activer/désactiver l'AudioSession proprement pour ne pas consommer batterie.
- **Notification limits** : iOS limite le nombre de notifications programmées en avance à 64. Si l'utilisateur a plusieurs alarmes récurrentes, on replanifie à chaque trigger, pas en masse à l'avance.
- **xcconfig** : bien exclu du repo public (`.gitignore`).
