# Architecture

Lumen follows **MVVM + Clean Architecture** with strict layer separation.

## Layers

```
┌─────────────────────────────────────────────────────────────┐
│                        App Target                           │
│  Entry point, DI composition root, app/scene delegate       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Features layer                         │
│  Alarm / Timer / Questionnaire / Synthesis / Dashboard /    │
│            Onboarding / Settings / AskLumen                 │
│       (SwiftUI views + ViewModels + Navigation)             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       Domain layer                          │
│    Use cases / Entities / Domain services / Protocols       │
│               (Pure Swift, zero UI imports)                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                        Data layer                           │
│  Repositories (Domain protocol implementations)             │
│  Local: SwiftData stores                                    │
│  Remote: AI clients (OpenAI, Anthropic, Apple Intelligence) │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Infrastructure layer                      │
│  AlarmScheduler (UNUserNotificationCenter)                  │
│  AudioPlayer (AVFoundation)                                 │
│  NetworkMonitor (NWPathMonitor)                             │
│  Logger (os.log + EthicalMonitorStore)                      │
│  HTTPClient (URLSession)                                    │
└─────────────────────────────────────────────────────────────┘
```

## Dependency rules

- **Features** → Domain (allowed)
- **Features** → Data (forbidden — must go through Domain)
- **Domain** depends only on Foundation (no UI, no Data, no Infrastructure)
- **Data** implements Domain protocols and may depend on Infrastructure
- **Infrastructure** is autonomous and exposes protocols consumed by Data
- **App** is the Composition Root that wires everything together

## Folder structure

```
lumen/
├── App/
│   ├── lumenApp.swift
│   ├── AppDelegate.swift           // notification action handling
│   ├── RootView.swift
│   ├── CompositionRoot.swift       // manual DI wiring
│   └── AppStateMachine.swift       // global states: idle, ritual_active, etc.
├── Features/
│   ├── Alarm/
│   ├── Timer/
│   ├── Questionnaire/
│   ├── Synthesis/
│   ├── Dashboard/
│   ├── Onboarding/
│   ├── Settings/
│   └── AskLumen/
├── Domain/
│   ├── Entities/                   // pure Swift structs (Alarm, Ritual, AIResponse, …)
│   ├── UseCases/                   // ScheduleAlarm, GenerateMorningSynthesis, …
│   ├── Services/                   // RateLimiter, QuoteProvider
│   └── Protocols/                  // AlarmRepository, AISynthesisService, …
├── Data/
│   ├── Repositories/               // SwiftData implementations of Domain protocols
│   ├── AI/                         // WaterfallAISynthesisService + provider clients
│   └── Models/                     // @Model SwiftData entities
├── Infrastructure/
│   ├── Notifications/
│   ├── Audio/
│   ├── Voice/                      // ADR-007: SpeechRecognizer + SpeechSynthesizer (on-device)
│   ├── Network/
│   └── Logging/
├── Shared/
│   ├── DesignSystem/
│   ├── Resources/                  // Quotes.json, Sounds, Localizable.xcstrings
│   └── Utils/
└── Config/
    ├── Secrets.xcconfig            // gitignored
    └── Secrets.xcconfig.sample     // committed template
```

## Dependency Injection

A single `CompositionRoot` (`@MainActor` class) owns the wiring:

```swift
@MainActor
final class CompositionRoot {
    init(modelContainer: ModelContainer) {
        let httpClient = URLSessionHTTPClient()
        let openAI = OpenAIClient(http: httpClient, apiKey: Secrets.openAIKey)
        let anthropic = AnthropicClient(http: httpClient, apiKey: Secrets.anthropicKey)
        let appleIntelligence = AppleIntelligenceProvider() // iOS 26+ only
        let queue = SynthesisQueue(persistedIn: modelContainer)

        let aiService = WaterfallAISynthesisService(
            cloudProviders: [openAI, anthropic],
            onDeviceProvider: appleIntelligence,
            synthesisQueue: queue,
            rateLimiter: RateLimiter.defaults(),
            ethicalLogger: SwiftDataEthicalLogger(container: modelContainer),
            reachability: NWPathReachability()
        )

        // … wire ViewModels and use cases …
    }
}
```

No third-party DI library: pure constructor injection through Composition Root.

## Global state machine

`AppStateMachine` is an `actor` that orchestrates the app's high-level states:

| State | Trigger | UI |
|---|---|---|
| `idle` | App opened, no alarm pending | Dashboard |
| `alarmRinging` | Scheduled alarm fires | Notification + ringing screen if foreground |
| `ritualActive` | User silenced the alarm and starts the ritual | Timer → Questionnaire → Synthesis |
| `ritualPartial` | Ritual interrupted | Dashboard with "Resume" banner |
| `ritualDone` | Ritual completed today | Dashboard with all 6 categories filled |
| `offline` | No network detected | Offline badge, AI fallback path |

Transitions are event-driven and unit-testable.

## Synthesis flow (AI generation)

```
User completes Q4 Gratitude → QuestionnaireViewModel
(Ritual flow: Mood → Energy → Priority → Gratitude)
                         ↓
                  SaveQuestionnaireAnswer (use case)
                         ↓
                  GenerateMorningSynthesis (use case)
                         ↓
                AISynthesisService.synthesize()
                         ↓
                  Check RateLimiter
                         ↓
                  Check NetworkReachability
                         ↓
                Online → try OpenAI → Anthropic → Apple Intelligence (on-device)
                Offline → Apple Intelligence (if available) → SynthesisQueue (deferred)
                         ↓
                  Persist EthicalLog (always)
                         ↓
                  Return result to ViewModel
                         ↓
                       SynthesisView
```

## Background execution model

- **Alarm trigger**: `UNCalendarNotificationTrigger` schedules the local notification. iOS wakes the app via the system; no code runs without user interaction.
- **User taps Snooze / Silence** from notification: handled by `NotificationActionsHandler` within a short `UIBackgroundTask`.
- **App launch from notification**: `AppDelegate` routes to the appropriate ritual screen.
- **Foreground audio**: `AVAudioSession` with category `.playback` and option `.duckOthers` to gracefully attenuate concurrent audio.

## Notable platform constraints

- **No Critical Alerts entitlement**: alarm reliability is best-effort outside Silent / Focus / DND modes (documented in ADR-001).
- **64 scheduled notifications limit**: recurring alarms are re-scheduled on each trigger, not pre-scheduled in bulk.
- **Apple Intelligence requires iOS 26+ and A17 Pro+**: gated by `#if canImport(FoundationModels)` and `@available(iOS 26.0, *)` checks. On unsupported devices, offline synthesis is queued and delivered when the network returns.
- **Voice (ADR-007)**: Speech recognition forced on-device (`requiresOnDeviceRecognition = true`). If user's language isn't supported on-device, fallback to typing — never cloud Apple speech. Audio never persisted or logged. AVSpeechSynthesizer for TTS, fully on-device with iOS 17+ neural voices.

## Testing strategy

- **Domain layer**: unit-test target ≥60% coverage. Pure Swift, no UI mocks needed.
- **Data layer**: in-memory SwiftData containers, mocked HTTP clients.
- **Infrastructure**: thin wrappers, tested via integration on actual `UNUserNotificationCenter` / `AVAudioSession` where feasible.
- **Features (ViewModels)**: tested with mocked Domain protocols, async/await test methods.
- **UI**: 1–2 XCUITests for the critical happy path (alarm → ritual → dashboard).

## Build configurations

Two configurations: `Debug` and `Release`. Both inherit from `Secrets.xcconfig` (Base Configuration), which provides `OPENAI_API_KEY` and `ANTHROPIC_API_KEY` at build time. In CI (Xcode Cloud), `Secrets.xcconfig` is generated by `ci_scripts/ci_post_clone.sh` from environment variables.
