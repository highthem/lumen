# Lumen — Morning Ritual

> iOS app guiding the first 5 minutes of the day, from a gentle alarm to a reflective AI-powered dashboard.
>
> Technical exercise for **PALO IT Labs** — AI / Mobile Native iOS role.

## Quick start

### Requirements
- macOS Sequoia 15.2+ (or Sonoma 14.5+ with Xcode 16.0–16.2)
- Xcode 16+ (developed on Xcode 26.4 for Foundation Models, CI verifies Xcode 16 compatibility)
- Apple Developer Program account
- OpenAI API key — [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
- Anthropic API key — [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)

### Setup
```bash
git clone git@github.com:highthem/lumen.git
cd lumen
cp lumen/Config/Secrets.xcconfig.sample lumen/Config/Secrets.xcconfig
# Edit lumen/Config/Secrets.xcconfig with your real API keys
open lumen.xcodeproj
```

In Xcode → Project → Info → Configurations: set `Secrets` as Base Configuration for Debug and Release.

### Build & test
```bash
xcodebuild -project lumen.xcodeproj -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild -project lumen.xcodeproj -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## What's in this repo

| File / Folder | Description |
|---|---|
| `lumen.xcodeproj` | Xcode project (iOS 17+ deployment target, Swift 6) |
| `lumen/` | App sources (App, Features, Domain, Data, Infrastructure, Shared) |
| `lumenTests/` | Unit tests (Domain layer ≥60% coverage) |
| `lumenUITests/` | UI tests (1–2 critical user journeys) |
| `ci_scripts/` | Xcode Cloud post-clone script (secrets injection) |
| `ARCHITECTURE.md` | MVVM + Clean architecture details |
| `TECHNICAL_DECISIONS.md` | 6 ADRs (alarm, persistence, concurrency, AI waterfall, ethical monitoring, CI/CD) |
| `ETHICAL_MONITORING.md` | AI usage logging, privacy policy, JSON export schema |
| `ARTIFACTS.md` | Diagrams, AI prompts used during development, screenshots, test data |
| `lumen/Config/Secrets.xcconfig.sample` | Template for API keys (the real one is gitignored) |

## Tech stack

- **iOS 17+**, **SwiftUI** (no UIKit), **MVVM + Clean Architecture**
- **Swift 6** with strict concurrency checking (Complete)
- **Swift Concurrency** (async/await, actors) — see ADR-003
- **SwiftData** for persistence — see ADR-002
- **UserNotifications + AVFoundation** for the background alarm
- **AI waterfall**: OpenAI (primary) → Anthropic Claude (cloud fallback) → Apple Intelligence on-device (iOS 26+ with A17 Pro+) → offline queue with deferred generation
- **Voice I/O on-device** (ADR-007): `SFSpeechRecognizer` (`requiresOnDeviceRecognition = true`) for dictation on Q3/Q4 + `AVSpeechSynthesizer` (neural voices) for synthesis playback

## CI/CD

[Xcode Cloud](https://developer.apple.com/xcode-cloud/) with two workflows:
1. **Tests on push (Xcode 16)** — compatibility check matching brief requirements
2. **Tests on push (Xcode 26)** — Apple Intelligence path validation

API keys provided as Environment Variables (Secret) in Xcode Cloud workflow settings.

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

- **TestFlight**: link shared via email
- **Loom video** (5 min walkthrough): link shared via email
- **Ethical monitoring JSON export**: attached to email

## Contact

Haithem Ben Hamouda — `ceo@highthem.com`
