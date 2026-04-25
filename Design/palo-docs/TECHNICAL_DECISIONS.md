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

---

## ADR-001 — Alarm in background strategy

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

**Demo plan.** Three scenarios in the technical defence: normal cloud path, airplane-mode on A17 Pro+ iOS 26 (Apple Intelligence path), airplane-mode on incompatible device (queue + deferred completion).

---

## ADR-005 — Ethical monitoring

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
