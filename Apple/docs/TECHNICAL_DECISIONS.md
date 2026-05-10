# Technical Decisions

Architecture Decision Records (ADRs) — every non-trivial technical choice in Lumen, with context, decision, and trade-offs.

| ADR | Subject | Status |
|---|---|---|
| [ADR-001](#adr-001--alarm-in-background-strategy) | Alarm in background strategy | Accepted |
| [ADR-002](#adr-002--swiftdata-vs-core-data) | SwiftData vs Core Data | Accepted |
| [ADR-003](#adr-003--swift-concurrency-vs-combine) | Swift Concurrency vs Combine | Accepted |
| [ADR-004](#adr-004--ai-waterfall-with-apple-intelligence-and-offline-queue) | AI waterfall with Apple Intelligence and offline queue | Accepted |
| [ADR-005](#adr-005--ethical-monitoring) | Ethical monitoring | Accepted |
| [ADR-006](#adr-006--cicd-via-xcode-cloud-with-dual-xcode-version-strategy) | CI/CD via Xcode Cloud, dual Xcode version | Accepted |
| [ADR-007](#adr-007--voice-integration-input--output) | Voice integration (input + output, on-device) | Accepted |
| [ADR-008](#adr-008--ui-testing-with-maestro--xcuitest-minimal) | UI testing with Maestro + XCUITest minimal | Accepted |

---

## ADR-001 — Alarm in background strategy

*PALO brief requirement: "Réveil doux avec Snooze/Silence (fonctionnel en background)" + "UserNotifications + AVFoundation pour l'alarme en background".*

**Context.** PALO brief requires iOS 17+, with `UserNotifications + AVFoundation` for the background alarm, no third-party libraries. Verified platform constraints:
- **AlarmKit** is iOS 26+ only (WWDC 2025) — out of scope.
- **Critical Alerts** require an Apple-approved entitlement (manual review, health/safety use cases only). Approval delay is incompatible with the 11 May deadline.
- `UNNotificationSound` duration via the notification path is platform-constrained (~30 s, to be verified empirically).

**Decision.** Build the alarm on:
- `UNUserNotificationCenter` + `UNCalendarNotificationTrigger` for scheduling
- `UNNotificationCategory` with `Snooze` and `Silence` actions (lock-screen accessible)
- `UNNotificationSound` pointing to an embedded `.caf` file (works background)
- `AVAudioSession` category `.playback` + `.duckOthers` and `AVAudioPlayer` to extend the sound when the app is foregrounded after user interaction

**Reliability assumed.** Without Critical Alerts, the alarm is **not guaranteed** in Silent / Focus / DND modes. This limit is documented in onboarding and Settings ("To wake reliably, disable silent mode"). Best-effort otherwise.

**Edge cases.**
| Case | Handling |
|---|---|
| Concurrent audio (Spotify, podcast) | `.duckOthers` attenuates during alarm, restores after |
| Incoming call | System interrupts; user re-opens app to resume ritual manually |
| Bluetooth / AirPods | Sound follows the active audio route (no forced override in V1) |
| App force-quit | Notification still fires; `UNNotificationAction` handles snooze/silence |
| Snooze loop | Capped at 3 successive snoozes, then auto-silence |
| `64 notifications limit` | Recurring alarms re-scheduled on each trigger, not in bulk |

---

## ADR-002 — SwiftData vs Core Data

*PALO brief requirement: "SwiftData/Core Data pour la persistance (pas de lib tierce)".*

**Context.** PALO brief mandates SwiftData or Core Data, no third-party. Binary choice.

**Decision.** **SwiftData**, with a documented Core Data fallback path.

**Rationale.**
- iOS 17+ target = SwiftData is native and expected.
- `@Model` macro, `@Observable` integration with SwiftUI — significantly less boilerplate than Core Data.
- Type-safe at compile time.
- Signal of modern stack (aligned with Swift 6, async/await).

**Mitigation for known SwiftData edge cases.** Domain layer uses pure Swift entities; SwiftData `@Model` classes live in `Data/Models/`. If a SwiftData blocker emerges (relations, performance), the affected repository can fall back to Core Data without touching Domain protocols.

**Concurrency.** Writes off the main actor go through `@ModelActor` to prevent data races under Swift 6 strict concurrency.

---

## ADR-003 — Swift Concurrency vs Combine

*PALO brief requirement: "Combine ou Swift Concurrency (à justifier)".*

**Context.** PALO brief asks for "Combine or Swift Concurrency (justified)". Binary choice.

**Decision.** **Swift Concurrency** (async/await, `Task`, `actor`, `Sendable`), Swift 6 strict mode `Complete`.

**Rationale.**
1. **Platform alignment.** iOS 17+ and Swift 6 make Swift Concurrency the default expected from a modern codebase. Combine in 2026 is acceptable legacy, not a proactive choice.
2. **Safety.** Strict concurrency catches data races at compile time. Critical for an app with background alarms + cloud AI + persistence.
3. **Readability.** A linear async/await flow is easier to read in code review than an equivalent Combine chain.
4. **Test ergonomics.** `XCTest` / `swift-testing` natively support `async` test methods.
5. **SwiftUI integration.** `@Observable` (iOS 17+) replaces `@Published` + `ObservableObject` with less ceremony.

**Implementation patterns.**
- ViewModels are `@MainActor @Observable`.
- Shared mutable state lives in `actor`s (`RateLimiter`, `AppStateMachine`).
- SwiftData writes use a custom `@ModelActor`.
- All Domain entities are `Sendable` (immutable structs).

---

## ADR-004 — AI waterfall with Apple Intelligence and offline queue

*PALO brief requirement: "Synthèse générée par IA (avec fallback hors-ligne et monitoring éthique)" + "Intégration IA via OpenAI ou Anthropic, avec journalisation et rate limiting local".*

**Context.** Brief: "AI synthesis with offline fallback and ethical monitoring", "OpenAI or Anthropic with logging and rate limiting". Verified: Apple Intelligence (Foundation Models framework) is **iOS 26+ only** and requires an A17 Pro+ chip — many devices in our iOS 17+ target will never have it.

**Decision.** Three-tier waterfall + deterministic offline queue:

```
1. Cloud primary  : OpenAI GPT-4o-mini
       ↓ (timeout 10 s, HTTP 4xx/5xx, invalid JSON)
2. Cloud secondary: Anthropic Claude Haiku 4.5
       ↓ (failure)
3. On-device fallback:
       ├─ Apple Intelligence available (iOS 26+ + A17 Pro+) → Foundation Models
       └─ Apple Intelligence unavailable → SynthesisQueue + deferred generation on reconnection
```

**No pre-written templates.** Quality stays consistent (always LLM output, cloud or on-device) or the synthesis is queued until network returns. The user is informed of the queue state with a calm message ("Your synthesis will arrive when your connection is back").

**Cost & abuse control.**
- Local rate limiting: 1 automatic synthesis per day, 3 manual interactions (regenerate + Ask Lumen) per day.
- Reset at local midnight.
- No retry within a single provider; on failure, move to the next tier immediately.

**Privacy.** Foundation Models requests are 100 % on-device — no data leaves the device when used. Cloud requests send only the questionnaire answers (no PII), prompt is hashed for monitoring.

**Prompt schema update.** The morning synthesis now uses a richer literary schema: `imageKey`, `intention`, `focus`, `reminder`, and optional `categoryInsights` keyed by dashboard category. `imageKey` is synthesis-screen only, while `categoryInsights` propagates to the dashboard cards and category details. The decoder remains tolerant so legacy provider outputs without the new optional fields do not crash the waterfall.

**Demo plan.** Three scenarios in the technical defence: normal cloud path, airplane-mode on A17 Pro+ iOS 26 (Apple Intelligence path), airplane-mode on incompatible device (queue + deferred completion).

---

## ADR-005 — Ethical monitoring

*PALO brief requirement: "monitoring éthique" + "Un export JSON des logs de monitoring éthique" + "rate limiting local".*

**Context.** Brief: monitor AI usage with logging, rate limiting, and JSON export. "Ethical monitoring" is loosely defined; we interpret it as making AI usage **visible, auditable, and bounded**, with a privacy-first stance.

**Decision.** Four-pillar implementation:

### Pillar 1 — Local logging
Every AI interaction (success or failure) writes an `EthicalLog` to SwiftData with:
- `id`, `timestamp`, `provider`, `mode`, `latencyMs`, `tokenIn`, `tokenOut`
- `promptHash` (SHA-256, never the raw prompt)
- `contentSafetyFlags` (regex-based pre-flight check)
- `userFeedback` (optional thumbs up/down)
- `privacyScope` (`user_input_only` for cloud, `device_only` for Apple Intelligence)

### Pillar 2 — Pre-flight content safety
Before any cloud call, basic regex detection for sensitive cues (self-harm, medical/legal advice). On `selfHarmCue`, the AI call is **replaced** by a routing message with localized support resources — no cloud call, no risk of inappropriate response.

### Pillar 3 — Local rate limiting
1 automatic synthesis / day, 3 manual interactions / day. Reset at local midnight. On limit hit, calm UX message ("Come back tomorrow"), never a technical error.

### Pillar 4 — Transparency
Settings → "Export my logs" generates a JSON file via `ShareSheet`. Settings → "Erase my logs" purges everything.

### Privacy guarantees
- No PII in logs (no email, no remote ID, no geolocation).
- Prompt hashed, never stored in clear.
- No remote upload of logs.
- Cloud requests carry only the user's questionnaire answers.

---

## ADR-006 — CI/CD via Xcode Cloud, with dual Xcode version strategy

*Not a direct PALO brief requirement (the brief only asks for "Xcode 16+, build direct"); this ADR documents the internal CI/CD choice that backs that constraint.*

**Context.** PALO brief requires Xcode 16+ for direct build. Development environment runs Xcode 26.4 (needed for Foundation Models). The repository must build cleanly on Xcode 16 to match the brief.

**Decision.** **Xcode Cloud** as primary CI/CD with two parallel workflows:

| Workflow | Xcode version | Trigger | Purpose |
|---|---|---|---|
| **Tests on push (Xcode 16)** | 16.x latest | Any branch push | Compatibility check matching brief requirements |
| **Tests on push (Xcode 26)** | 26.x latest | `main` branch push | Validates iOS 26 paths (Apple Intelligence) |
| **TestFlight on tag** | 16.x | `v*` tag | Archive + TestFlight distribution to PALO |

**Rationale.** Xcode Cloud's free tier (25 hours/month, included in Apple Developer Program) is 5× more generous than GitHub Actions' macOS allowance (≈5 effective hours/month). Native TestFlight integration saves ≈1 day vs scripted Fastlane. Code signing and provisioning are handled automatically.

**Discipline imposed.** To keep the Xcode 16 workflow green while developing on Xcode 26:
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0` enforced
- `#if canImport(FoundationModels)` + `@available(iOS 26.0, *)` gating any iOS 26+ API usage
- No `MeshGradient` (iOS 18+), no Liquid Glass APIs (iOS 26+)
- Mental check before every push to `main`: "does this compile on Xcode 16?"

**Secrets handling.** `OPENAI_API_KEY` and `ANTHROPIC_API_KEY` live as Xcode Cloud Environment Variables (marked Secret). `ci_scripts/ci_post_clone.sh` injects them into `lumen/Config/Secrets.xcconfig` at build time. Locally, developers copy `Secrets.xcconfig.sample` and fill their own keys; the real `Secrets.xcconfig` is gitignored.

---

## ADR-007 — Voice integration (input + output)

**Context.** The morning ritual relies on two free-form questions — Q3 Priority and Q4 Gratitude. Typing on iOS at wake-up is high friction: tired eyes, clumsy fingers, the keyboard takes 50 % of the screen and breaks the calm posture. Symmetrically, forcing the user to read the AI synthesis on-screen keeps them locked to the device when they should be transitioning to the rest of their morning (coffee, brushing teeth).

**Decision.** Add **voice input (dictation)** for Q3 Priority + Q4 Gratitude and **voice output (TTS)** for the AI synthesis — in V1.

| Capability | Framework | Cost | Privacy |
|---|---|---|---|
| Voice input | `Speech` (`SFSpeechRecognizer`) | 0 | On-device required (`requiresOnDeviceRecognition = true`) |
| Voice output (premium) | ElevenLabs HTTP API | API key | Synthesis text sent to ElevenLabs only when toggle is on |
| Voice output (fallback) | `AVFoundation` (`AVSpeechSynthesizer`) | 0 | 100 % on-device, neural voices iOS 17+ |

**Voice output — runtime fallback.** ElevenLabs is the primary TTS, with `AVSpeechSynthesizer` as a runtime fallback resolved at every `speak()` call. On any ElevenLabs failure (network, 4xx, 5xx, 8 s timeout) the `FallbackTextToSpeech` decorator transparently falls back to AVSpeech without restarting the app. The active provider is recorded in the `EthicalLog` (`tts_provider` field). A Settings toggle ("Voix premium ElevenLabs") lets the user force the on-device path.

**Strict privacy stance.** `SFSpeechRecognitionRequest.requiresOnDeviceRecognition = true`. If on-device recognition isn't supported for the user's language (varies by device + language), **fallback to typing** rather than sending audio to Apple. Audio captured is **never persisted nor logged** — only the transcribed text is stored.

**UX.**
- Voice input (Q3 + Q4): central large microphone button (thumb-sized), subtle pulse animation during listening (consistent with the timer's breathing circle — `style_guide.md` motion level 2 "signature"). Auto-stop after 2 s of silence. Transcribed text displayed in serif. "Edit" button discreet (switches to keyboard for manual correction). Skip always available.
- Voice output (synthesis): "Listen" button (`speaker.wave.2` icon) next to the synthesis text. Reads with iOS 17+ neural voice. Bluetooth / AirPods compatible. Pause / Resume.
- Settings: toggle "Voice mode by default" (true), choice of TTS voice, playback speed (0.8x / 1x / 1.2x).

**Justification.**
1. **Strong product differentiator.** None of the four competitors (Fabulous, Alarmy, Opal, Rise) has voice I/O on the morning ritual. Clear market gap.
2. **Aligned with "respect of the moment"** product posture — typing is an exception, not the rule.
3. **Aligned with "ethical AI" stance** — audio never leaves the device, reinforces privacy promise.
4. **Reasonable effort**: ~1.7 days total. Fits in Sprint 2.
5. **Brief constraints respected**: zero third-party libs, native Apple frameworks, iOS 17+.

**Permissions added to Info.plist:** `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`. AudioSession coordination handled by `AudioSessionManager` to avoid conflict with the alarm sound (ADR-001).

---

## ADR-008 — UI testing with Maestro + XCUITest minimal

**Context.** The brief asks for Domain unit tests ≥ 60 % (XCTest) and "1-2 XCUITest for critical paths (optional V1)". To raise the bar without falling into XCUITest brittleness, **Maestro** is adopted as the modern declarative UI testing standard for mobile in 2026.

**Decision.** Three-layer testing strategy:

| Layer | Tool | Coverage |
|---|---|---|
| Domain logic (use cases, services, rate limiter, AI waterfall) | **XCTest** | ≥ 60 % (brief constraint) |
| UI flows (rituel, navigation, settings, typing fallback) | **Maestro** | 15-20 YAML flows over time, V1 starts with 5 smoke |
| Hardware-dependent (background alarm, real mic, AVAudioSession real-device) | **XCUITest** | 2-3 tests max, requires real device |

**Why Maestro over XCUITest only.**
1. **Readability**: a 20-line YAML flow vs ~150 lines Swift XCUITest for the same test.
2. **Maintainability**: UI changes require only YAML tweaks, not whole Swift refactors.
3. **Cross-platform**: ready for V2 Android with the same flows.
4. **Zero-wait**: Maestro auto-handles animations and network delays.
5. **Studio visual debugger**: faster authoring.

**Why complement with XCUITest.**
- iOS Maestro is simulators-only. Background alarm reliability requires a real device (UNUserNotificationCenter). Real-mic recognition and AVAudioSession ducking only behave realistically on physical hardware.

**V1 PALO scope:**
- 5 smoke flows Maestro (`app-launch`, `onboarding-complete`, `create-alarm`, `ritual-happy-path`, `settings-export-json`)
- 3 XCUITest hardware-dependent (background alarm, mic permission, audio session conflict)
- Local CLI run, CI integration (Xcode Cloud post-script) deferred to V1.1
- Total V1 effort: ~2 days

**V1.1 scope:**
- 10 regression flows (snooze, voice fallback, TTS, queued, rate limit, BYO key, …)
- 5 edge-case flows (permissions refused, reduce motion, app background, BYO invalid)
- CI integration on Xcode Cloud or GitHub Actions
- Total V1.1 effort: +3 days

**Scenarios source of truth**: `Project/04_tech/testing/maestro-scenarios.md`. Implementation: `Apple/.maestro/flows/`.

**Permissions / setup notes:**
- Java 17+ required for Maestro CLI (`brew tap mobile-dev-inc/tap && brew install mobile-dev-inc/tap/maestro`)
- Debug-only deep links exposed (`lumen://ritual/start`, `lumen://alarm/test-ringing`, etc.) gated by `#if DEBUG`
- iOS simulator state manipulation via `xcrun simctl` for airplane mode and reduce-motion testing
