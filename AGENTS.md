# Repository Guidelines

## Project Structure & Module Organization

This repository contains the Lumen iOS app plus product, design, and delivery documentation. The current implementation is an Xcode scaffold, while the product and architecture direction is documented in detail.

- `Apple/` contains the iOS project. App source lives in `Apple/lumen/`, unit tests in `Apple/lumenTests/`, and UI tests in `Apple/lumenUITests/`.
- `Apple/lumen/Assets.xcassets/` stores app icons, colors, and image assets.
- `Apple/lumen/Config/` stores configuration samples. Commit `Secrets.xcconfig.sample`; keep the real `Secrets.xcconfig` local.
- `Project/` contains product, technical, roadmap, and ADR documentation.
- `Design/` contains the design kit and PALO deliverables.
- `ci_scripts/` and `scripts/` contain Xcode Cloud and utility scripts.

As implementation grows, follow the planned layout under `Apple/lumen/`: `App/`, `Features/`, `Domain/`, `Data/`, `Infrastructure/`, and `Shared/`. Keep feature code grouped by user workflow, for example `Features/Alarm/`, `Features/Questionnaire/`, and `Features/Dashboard/`.

## Build, Test, and Development Commands

```bash
cp Apple/lumen/Config/Secrets.xcconfig.sample Apple/lumen/Config/Secrets.xcconfig
open Apple/lumen.xcodeproj
```

Use these for first-time local setup, then fill in API keys in `Secrets.xcconfig`. Xcode is the primary development environment.

```bash
xcodebuild test -project Apple/lumen.xcodeproj -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 16'
```

Runs tests through the shared `lumen` scheme. Xcode Cloud handles CI, with secret injection performed by `ci_scripts/ci_post_clone.sh`.

## Coding Style & Naming Conventions

Use Swift 6 with strict concurrency checking. Prefer SwiftUI, async/await, `Task`, `AsyncStream`, `actor`, and `@MainActor`. Do not introduce Combine or third-party dependencies. Use native frameworks: SwiftData, URLSession, UserNotifications, AVFoundation, Speech, os.log, and `.xcstrings` localization.

View models should be `@MainActor @Observable final class`. Shared mutable state belongs in actors, for example `RateLimiter` or `AppStateMachine`. Domain entities should be immutable `Sendable` structs. Use clear intent-revealing type names such as `GenerateMorningSynthesis`, `AlarmScheduler`, `DashboardViewModel`, and `SpeechRecognizer`.

Keep text out of views where localization is expected. Use semantic localization keys instead of hardcoded user-facing copy.

## Architecture & Dependency Rules

The app follows MVVM + Clean Architecture. `App` wires dependencies through a manual Composition Root. `Features` contain SwiftUI views, view models, and navigation. `Domain` contains use cases, entities, services, and protocols. `Data` implements Domain protocols using SwiftData or AI clients. `Infrastructure` wraps platform services such as notifications, audio, voice, networking, and logging.

Dependency direction is strict: Features may depend on Domain, but not concrete Data implementations. Domain must not import SwiftUI, SwiftData, or app infrastructure. Data may depend on Infrastructure when implementing Domain protocols. Infrastructure should expose small, testable interfaces.

iOS 26+ Foundation Models or Apple Intelligence code must be conditionally compiled with `#if canImport(FoundationModels)` and protected with `@available(iOS 26.0, *)`.

## Testing Guidelines

Use XCTest as the primary framework. Keep Domain tests fast, deterministic, and independent of UI or persistence, with at least 60% Domain coverage. Test files should live in `Apple/lumenTests/` and mirror production type names, for example `AlarmUseCaseTests.swift` or `RateLimiterTests.swift`.

Use in-memory SwiftData containers and mocked protocols for Data and ViewModel tests. UI tests belong in `Apple/lumenUITests/`; prioritize one or two critical flows such as alarm to ritual to dashboard. Add focused tests for failure states: offline AI fallback, rate limiting, notification actions, denied permissions, and voice fallback to typing.

## Commit & Pull Request Guidelines

Recent history uses short Conventional Commit-style messages, such as `feat: bootstrap Xcode Cloud CI setup` and `fix: resolve Xcode Cloud build failure`. Continue with `feat:`, `fix:`, `docs:`, `test:`, or `refactor:` followed by a concise summary.

Pull requests should include a brief description, linked issue or task when applicable, test results, and screenshots or screen recordings for UI changes. Explicitly call out changes to secrets, entitlements, CI, architecture decisions, or privacy behavior.

## Security, Privacy & Configuration

Never commit real API keys, raw prompts, audio captures, transcripts not required by product behavior, or user logs. `Secrets.xcconfig` stays local; Xcode Cloud secrets live in App Store Connect environment variables. Swift code should read keys from the app bundle configuration, never hardcode them.

AI monitoring must persist hashed prompt data only, following `Project/04_tech/adr/ADR-005-monitoring-ethique.md`. Voice input uses `SFSpeechRecognizer` with on-device recognition required; if unsupported, fall back to typing rather than cloud transcription. Voice output uses `AVSpeechSynthesizer` on device. Audio captured for dictation must never be persisted or logged.

## Agent-Specific Instructions

Before editing, read the relevant docs in `CLAUDE.md`, `Project/04_tech/`, and feature-specific user stories. Keep changes scoped to the requested task and do not rewrite unrelated files. Respect existing uncommitted work as user-owned. When adding files under the Xcode synchronized source tree, keep paths aligned with the architecture above and verify with `xcodebuild test` when feasible.
