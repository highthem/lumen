# Lumen — Morning Ritual

> iOS app guiding the first 5 minutes of the day, from a gentle alarm to a reflective AI-powered dashboard.
>
> Technical exercise for **PALO IT Labs** — AI / Mobile Native iOS role.

## Quick start

### Requirements
- Xcode 16+ for the PALO-compatible build; local development currently uses Xcode 26.4 for Foundation Models checks
- Apple Developer Program account
- OpenAI API key — [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
- Anthropic API key — [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
- Optional ElevenLabs API key — [elevenlabs.io/app/api/api-keys](https://elevenlabs.io/app/api/api-keys)

### Setup
```bash
git clone git@github.com:highthem/lumen.git
cd Lumen
cp Apple/lumen/Config/Secrets.xcconfig.sample Apple/lumen/Config/Secrets.xcconfig
# Edit Apple/lumen/Config/Secrets.xcconfig with your real API keys
open Lumen.xcworkspace
```

In Xcode → Project → Info → Configurations: set `Secrets` as Base Configuration for Debug and Release.

### Build & test
```bash
xcodebuild -workspace Lumen.xcworkspace -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -workspace Lumen.xcworkspace -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The Domain test target lives in `lumenTests/Domain/`. Per the PALO brief, the **alarm/snooze logic is the priority test surface** — see `lumenTests/Domain/AlarmUseCaseTests.swift` and `lumenTests/Domain/RateLimiterTests.swift`.

## What's in this repo

| File / Folder | Description |
|---|---|
| `Apple/lumen.xcodeproj` | Xcode project (iOS 17+ deployment target, Swift 6) |
| `Lumen.xcworkspace` | Root workspace used by Xcode Cloud and local setup |
| `Apple/lumen/` | App sources (`App`, `Features`, `Domain`, `Data`, `Infrastructure`, `Shared`) |
| `Apple/lumenTests/` | Unit tests mirroring production layers |
| `Apple/.maestro/` | Declarative E2E flows for smoke/regression/edge cases |
| `ci_scripts/` | Xcode Cloud post-clone script (secrets injection) |
| `Apple/docs/ARCHITECTURE.md` | MVVM + Clean architecture details |
| `Apple/docs/TECHNICAL_DECISIONS.md` | ADR summary |
| `Apple/docs/ETHICAL_MONITORING.md` | AI usage logging, privacy policy, JSON export schema |
| `Apple/docs/ARTIFACTS.md` | Deliverables, diagrams, design/audio/test artifacts |
| `Apple/docs/samples/ethical-monitoring-export.json` | Anonymised Settings export sample |
| `Apple/lumen/Config/Secrets.xcconfig.sample` | Template for API keys; the real file is gitignored |

## Tech stack

- **iOS 17+**, **SwiftUI** (no UIKit), **MVVM + Clean Architecture**
- **Swift 6** with strict concurrency checking (Complete)
- **Swift Concurrency** (async/await, actors) — see ADR-003
- **SwiftData** for persistence — see ADR-002
- **UserNotifications + AVFoundation** for the background alarm
- **AI waterfall**: OpenAI (primary) → Anthropic Claude (cloud fallback) → Apple Intelligence on-device (iOS 26+ with A17 Pro+) → offline queue with deferred generation
- **Voice I/O** (ADR-007): `SFSpeechRecognizer` for Q3/Q4 dictation with typing fallback on permission/audio failures, plus ElevenLabs or `AVSpeechSynthesizer` for synthesis playback

## PALO-IT requirements coverage

Direct mapping of every bullet in the brief (Sami Henchiri, 21 Apr 2026) to the concrete answer in this repo. Code paths are relative to `Apple/`.

### Flux complet
| Requirement | Where it lives | Status |
|---|---|---|
| Réveil doux avec Snooze/Silence (background) | `lumen/Infrastructure/Notifications/NotificationScheduler.swift`, `NotificationCategories.swift`, `lumen/Domain/UseCases/SnoozeAlarm.swift`, `lumen/Features/Alarm/AlarmRingingView.swift` — see ADR-001 | ✅ |
| Timer de présence avec citation inspirante | `lumen/Features/Timer/PresenceTimerView.swift` + `PresenceTimerViewModel.swift`, quotes in `lumen/Shared/Resources/Quotes.json` | ✅ |
| Questionnaire matinal en 4 étapes (persistance locale) | `lumen/Features/Questionnaire/Q1MoodView.swift` … `Q4GratitudeView.swift`, `lumen/Domain/UseCases/SaveQuestionnaireAnswer.swift`, SwiftData via `lumen/Data/Models/` | ✅ |
| Synthèse IA (fallback hors-ligne + monitoring éthique) | `lumen/Data/AI/WaterfallAISynthesisService.swift` — see ADR-004 + `ETHICAL_MONITORING.md` | ✅ |
| Dashboard ≥6 catégories + accès rapide IA | `lumen/Domain/Entities/DashboardCategory.swift` (6 cases), `lumen/Features/Dashboard/`, AskLumen FAB in `lumen/Features/AskLumen/` | ✅ |

### Repo & files
| Requirement | Where it lives | Status |
|---|---|---|
| Repo GitHub privé Xcode 16+, build direct | This repo, `Apple/lumen.xcodeproj`, CI workflow "Tests on push (Xcode 16)" | ✅ |
| Partagé avec `shenchiri@palo-it.com` | GitHub repo settings — collaborator added | ✅ |
| `README.md` | This file | ✅ |
| `ARCHITECTURE.md` | [`ARCHITECTURE.md`](ARCHITECTURE.md) | ✅ |
| `TECHNICAL_DECISIONS.md` (≥5 ADRs) | [`TECHNICAL_DECISIONS.md`](TECHNICAL_DECISIONS.md) — 8 ADRs | ✅ |
| `ETHICAL_MONITORING.md` | [`ETHICAL_MONITORING.md`](ETHICAL_MONITORING.md) | ✅ |
| `ARTIFACTS.md` | [`ARTIFACTS.md`](ARTIFACTS.md) | ✅ |

### Tests, démo, livrables
| Requirement | Where it lives | Status |
|---|---|---|
| Tests ≥60 % Domain, alarme/snooze prioritaire | `lumenTests/Domain/AlarmUseCaseTests.swift`, `RateLimiterTests.swift`, `WaterfallAISynthesisServiceTests.swift`, `BuildDashboardSnapshotTests.swift`, `ContentSafetyDetectorTests.swift`, `FetchRitualHistoryTests.swift`, `PresenceStateTests.swift` — ~66 % raw LOC | ✅ |
| Export JSON des logs de monitoring éthique | `lumen/Domain/UseCases/ExportEthicalLogs.swift` + Settings UI; sample at [`samples/ethical-monitoring-export.json`](samples/ethical-monitoring-export.json) | ✅ |
| Démo Loom (≤ 5 min) ou TestFlight | TestFlight build via Xcode Cloud "TestFlight on `v*` tag" workflow + Loom backup | 📧 link sent in recap email |
| Présentation 10–15 slides | `Design/designs/Design/slides/soutenance-lumen.html` (HTML deck) | ✅ |

### Contraintes techniques
| Constraint | Where it lives | Status |
|---|---|---|
| iOS 17+, SwiftUI (pas d'UIKit pur) | `IPHONEOS_DEPLOYMENT_TARGET = 17.0`; SwiftUI first, with minimal UIKit interop only for system integration | ✅ |
| MVVM + Clean | `ARCHITECTURE.md` — Features → Domain → Data → Infrastructure | ✅ |
| Combine ou Swift Concurrency (justifié) | Swift Concurrency, justified in [ADR-003](TECHNICAL_DECISIONS.md#adr-003--swift-concurrency-vs-combine) | ✅ |
| SwiftData/Core Data (pas de lib tierce) | SwiftData chosen — see [ADR-002](TECHNICAL_DECISIONS.md#adr-002--swiftdata-vs-core-data); zero third-party SPM deps | ✅ |
| UserNotifications + AVFoundation pour l'alarme | `lumen/Infrastructure/Notifications/`, `lumen/Infrastructure/Audio/AudioPlayer.swift` — see [ADR-001](TECHNICAL_DECISIONS.md#adr-001--alarm-in-background-strategy) | ✅ |
| IA via OpenAI ou Anthropic + journalisation + rate limiting local | `lumen/Data/AI/WaterfallAISynthesisService.swift`, `lumen/Domain/Services/RateLimiter.swift`, `EthicalLog` SwiftData entity — see [ADR-004](TECHNICAL_DECISIONS.md#adr-004--ai-waterfall-with-apple-intelligence-and-offline-queue) + [ADR-005](TECHNICAL_DECISIONS.md#adr-005--ethical-monitoring) | ✅ |

## CI/CD

[Xcode Cloud](https://developer.apple.com/xcode-cloud/) with two workflows:
1. **Tests on push (Xcode 16)** — compatibility check matching brief requirements
2. **Tests on push (Xcode 26)** — Apple Intelligence path validation

API keys provided as Environment Variables (Secret) in Xcode Cloud workflow settings.
Required keys: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `ELEVENLABS_API_KEY`.

## Architecture overview

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full picture. Brief summary:

```
App → Features (SwiftUI + ViewModels)
        ↓
      Domain (Use Cases, Entities, Protocols — pure Swift)
        ↓
      Data (Repositories, AI clients, SwiftData models)
        ↓
      Infrastructure (Notifications, Audio, Network, Logging)
```

## Demo

Per PALO's *Modalités de restitution*, the recap email to `shenchiri@palo-it.com` carries:

- **TestFlight invite** (primary) — built by Xcode Cloud "TestFlight on `v*` tag" workflow.
- **Loom video** (≤ 5 min walkthrough, backup) — covers alarm → ritual → synthesis → dashboard → settings export.
- **Ethical monitoring JSON export** — attached; schema documented in [`ETHICAL_MONITORING.md`](ETHICAL_MONITORING.md), sample at [`samples/ethical-monitoring-export.json`](samples/ethical-monitoring-export.json).

## Contact

Haithem Ben Hamouda — `ceo@highthem.com`
Repo shared (private) with `shenchiri@palo-it.com`.
