# CLAUDE.md

Lumen is an iOS morning ritual app (alarm → 5-minute guided questionnaire → AI synthesis → dashboard). It is simultaneously:

## Project context

**PALO IT technical exercise** — delivered to Sami Henchiri by 11 May 2026. No monetisation, no analytics, privacy-first.

**Status:** pre-development. Architecture, ADRs, product specs, and design docs are complete; code is almost complete and yet still to polish for delivery.

## Repository layout

```
Apple/             iOS Xcode project (the actual iOS app code)
Design/            Design kit + PALO deliverable docs (ARCHITECTURE, TECHNICAL_DECISIONS, etc.)
Project/           Full product/tech/business documentation
  00_brief/        PALO brief + assumptions
  02_product/      User stories, flows, acceptance criteria
  04_tech/         Stack, architecture, data model, API contracts, 5 ADRs
  06_roadmap/      Sprint breakdown (3 sprints, demi-journée granularity)
  …
Lumen.xcworkspace  Workspace pointing to Apple/lumen.xcodeproj
scripts/           Utility scripts
```

## Build & run

```bash
# First-time setup
cp Apple/lumen/Config/Secrets.xcconfig.sample Apple/lumen/Config/Secrets.xcconfig
# Fill in OPENAI_API_KEY and ANTHROPIC_API_KEY in Secrets.xcconfig

# Open project
open Apple/lumen.xcodeproj
# — or —
open Lumen.xcworkspace
```

In Xcode, set `Secrets.xcconfig` as **Base Configuration** for both Debug and Release under Project → Info → Configurations.

Always use **Xcode MCP** to build, run and test the project.

CI/CD runs on **Xcode Cloud** (3 workflows: "Xcode 16 - Build", "Test on push (iOS 26/Apple Intelligence)", "TestFlight on `v*` tag"). Secrets are injected by `ci_scripts/ci_post_clone.sh`.

## Architecture

MVVM + Clean Architecture with strict layer rules:

```
App (CompositionRoot, DI wiring)
  ↓
Features (SwiftUI views + @MainActor @Observable ViewModels)
  ↓
Domain (pure Swift — use cases, entities, protocols — zero UI imports)
  ↓
Data (SwiftData repositories + AI clients implementing Domain protocols)
  ↓
Infrastructure (AlarmScheduler, AudioPlayer, NetworkMonitor, Logger, HTTPClient)
```

**Critical dependency rule:** Features → Domain is allowed; Features → Data is **forbidden**. Domain must never import SwiftUI, SwiftData, or any Apple framework beyond Foundation.

**Folder structure inside `Apple/lumen/`** (to be created during Sprint 1):
```
App/           lumenApp.swift, CompositionRoot.swift, AppStateMachine.swift (actor)
Features/      Alarm/ Timer/ Questionnaire/ Synthesis/ Dashboard/ Onboarding/ Settings/ AskLumen/
Domain/        Entities/ UseCases/ Services/ Protocols/
Data/          Repositories/ AI/ Models/   (@Model SwiftData classes live here only)
Infrastructure/Notifications/ Audio/ Network/ Logging/
Shared/        DesignSystem/ Resources/ Utils/
Config/        Secrets.xcconfig (gitignored), Secrets.xcconfig.sample
```

## Swift patterns (non-negotiable)

- **Swift 6 strict concurrency, mode Complete.** Zero data races at compile time. (use swift-concurrency:swift-concurrency skill)
- **ViewModels:** `@MainActor @Observable final class`.
- **Shared mutable state:** `actor` (e.g. `RateLimiter`, `AppStateMachine`).
- **SwiftData writes off main thread:** `@ModelActor`. (use swiftdata-pro skill)
- **Domain entities:** immutable `Sendable` structs.
- **No Combine.** Only async/await + `Task` + `AsyncStream` where needed.
- **SwiftTesting** preferred over *XCTest*. (use swift-testing-pro skill)
- **No third-party libraries.** URLSession for networking, SwiftData for persistence, manual constructor DI.
- **iOS 26+ APIs** (Foundation Models / Apple Intelligence) must be gated with `#if canImport(FoundationModels)` AND `@available(iOS 26.0, *)`. Do not use `MeshGradient` (iOS 18+) or Liquid Glass APIs.

## AI synthesis waterfall

```
User completes questionnaire Q4
  → GenerateMorningSynthesis use case
    → RateLimiter check (1 auto/day, 3 manual/day — reset at local midnight)
    → NWPathMonitor check
    ┌─ Online:
    │   1. OpenAI GPT-4o-mini (timeout 10 s)
    │   2. Anthropic Claude Haiku 4.5 (on failure)
    │   3. Apple Intelligence / Foundation Models (on failure, iOS 26+ A17 Pro+ only)
    └─ Offline or all cloud failed:
        → Apple Intelligence if available
        → SynthesisQueue (deferred generation on reconnect)
  → Persist EthicalLog (always — SHA-256 prompt hash, never raw prompt)
```

Rate limit hits and offline states show calm copy ("Come back tomorrow") — never technical errors.

## Ethical monitoring

Every AI call (success or failure) writes an `EthicalLog` to SwiftData:
- `promptHash` (SHA-256) — never the raw prompt
- `provider`, `mode`, `latencyMs`, `tokenIn`, `tokenOut`, `contentSafetyFlags`, `userFeedback`, `privacyScope`

Pre-flight content safety regex runs before every cloud call. `selfHarmCue` detection **replaces** the AI call with a localized support-resources message — no cloud request is made.

Settings exposes "Export my logs" (JSON via ShareSheet) and "Erase my logs" (SwiftData purge). No remote upload ever.

## Testing strategy

- **Domain layer ≥ 60% coverage** Pure Swift — no mocks needed for UI.
- **Data layer:** in-memory `ModelContainer` + mocked `HTTPClient` protocol.
- **Feature ViewModels:** mocked Domain protocol implementations, `async` test methods.
- **E2E:** maestro testing workflows.
- Use `swift-testing` and fallback to `XCTest` if not available.

## Alarm constraints

- No Critical Alerts entitlement (requires Apple approval). Alarm is best-effort in Silent/Focus/DND — document this in onboarding.
- 64 scheduled notifications iOS limit: re-schedule recurring alarms on each trigger, never pre-schedule in bulk.
- Snooze capped at 3 consecutive snoozes, then auto-silence.
- `AVAudioSession` category `.playback` + option `.duckOthers`.

## Secrets

API keys are never hardcoded. Access via `Bundle.main.object(forInfoDictionaryKey:)` using keys defined in `Secrets.xcconfig`. The sample file `Secrets.xcconfig.sample` is committed; the real file is gitignored.

## Key documentation

*These documents must always be updated to reflect current codebase*

- **Architecture detail:** `Apple/docs/ARCHITECTURE.md`
- **Artifacts details** `Apple/docs/ARTIFACTS.md`
- **ADRs:** `Apple/docs/TECHNICAL_DECISIONS.md`
- **Monitoring** `Apple/docs/ETHICAL_MONITORING.md`