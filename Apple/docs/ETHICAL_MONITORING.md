# Ethical Monitoring

How Lumen makes AI usage visible, auditable, and bounded — with privacy by design.

## Why this exists

The PALO brief asks for "AI synthesis with offline fallback and ethical monitoring". The term "ethical monitoring" is loosely defined; this document captures our interpretation, the implementation, and the guarantees.

We treat ethical monitoring as four obligations:
1. **Visibility** — every AI interaction is logged.
2. **Auditability** — the user can export and inspect those logs at any time.
3. **Bounded usage** — local rate limiting prevents runaway cost or abuse.
4. **Privacy by design** — no PII in logs, no remote upload, prompts hashed.

## What gets logged

Every AI interaction (success or failure) creates an `EthicalLog` entry persisted locally via SwiftData:

| Field | Type | Description |
|---|---|---|
| `id` | UUID | Local identifier, no user ID |
| `timestamp` | ISO 8601 | When the interaction happened |
| `provider` | String | `openai` / `anthropic` / `apple` / `queued` |
| `mode` | String | `auto` / `manualRegenerate` / `fallbackOnDevice` / `fallbackQueued` |
| `latencyMs` | Int | Round-trip time (omitted for queued entries) |
| `tokenIn` | Int? | Input tokens (cloud only, when API returns the value) |
| `tokenOut` | Int? | Output tokens (cloud only) |
| `promptHash` | String | `sha256:...` of the concatenated system + user prompt — never the raw prompt |
| `contentSafetyFlags` | [String] | Pre-flight detection results (e.g. `selfHarmCue`) |
| `userFeedback` | String? | `positive` / `negative` / nil — only stored if explicitly given |
| `privacyScope` | String | `user_input_only` (cloud) / `device_only` (Apple Intelligence) / `pending` (queue) |
| `ttsProvider` | String? | `elevenlabs` / `apple-on-device` — which TTS rendered a synthesis (nil for non-TTS log entries) |

**Out of the log on purpose:** email, account ID, location, IP address, device identifier, prompt content in clear, **and the text being read aloud** — only the provider identifier is recorded.

## TTS privacy

Voice output uses ElevenLabs as the premium primary and `AVSpeechSynthesizer` as a runtime fallback. The synthesis text is transmitted to ElevenLabs **only** when the Settings toggle "Voix premium ElevenLabs" is on. When off, every synthesis is rendered 100 % on-device. No audio is ever cached on disk. The `tts_provider` field in the JSON export tells the user, after the fact, which provider rendered each synthesis.

## Pre-flight content safety

Before any cloud call, the app runs a lightweight regex-based safety check on the user's input:

```swift
enum ContentSafetyFlag: String {
    case violentLanguage
    case selfHarmCue
    case medicalAdviceRequest
    case legalAdviceRequest
}
```

If a `selfHarmCue` is detected, the AI call is **replaced** by a routing template that surfaces localized support resources. No cloud request is made — no chance of an inappropriate generated response on a sensitive topic.

This is intentionally simple (regex, not classifier) for V1. Limitations are acknowledged: false negatives on non-French/English inputs. Roadmap V1.1 may upgrade to an on-device classifier.

## Rate limiting

Enforced client-side, persisted in `UserDefaults`:

| Action | Daily limit |
|---|---|
| Automatic morning synthesis | 1 |
| Manual regeneration | 3 (shared budget) |
| "Ask Lumen" from dashboard | 3 (shared budget with regeneration) |

Reset at local midnight (`Calendar.current.startOfDay` comparison). On hit:
- Calm UX message: *"Come back tomorrow for a fresh question."*
- Never a technical error or alarming alert.

## JSON export schema

Settings → **Export my logs** writes a JSON file and surfaces a `ShareSheet`. The user picks the destination — nothing is uploaded automatically.

```json
{
  "exported_at": "2026-05-11T07:42:00Z",
  "app_version": "1.0.0",
  "device_locale": "fr_FR",
  "privacy_scope": "local_user_data_only",
  "logs": [
    {
      "id": "8c3e5f9b-...",
      "timestamp": "2026-05-11T07:05:23Z",
      "provider": "openai",
      "mode": "auto",
      "latency_ms": 1842,
      "token_in": 247,
      "token_out": 98,
      "prompt_hash": "sha256:9f4c2b1a7e...",
      "content_safety_flags": [],
      "user_feedback": null,
      "privacy_scope": "user_input_only"
    },
    {
      "id": "a7d2c8e4-...",
      "timestamp": "2026-05-11T07:05:25Z",
      "provider": "apple",
      "mode": "fallbackOnDevice",
      "latency_ms": 1523,
      "token_in": null,
      "token_out": null,
      "prompt_hash": "sha256:9f4c2b1a7e...",
      "content_safety_flags": [],
      "user_feedback": "positive",
      "privacy_scope": "device_only"
    }
  ]
}
```

## Producing the JSON export for the PALO deliverable

The brief asks for "Un export JSON des logs de monitoring éthique" attached to the recap email. To produce it from a running build:

1. Open the app → **Settings** tab.
2. Tap **Export my logs**.
3. iOS opens the standard `ShareSheet` — pick **Save to Files** (or AirDrop to your Mac).
4. The resulting `.json` file is what gets attached to the PALO recap email.

A pre-recorded, anonymised version of this export — usable to inspect the schema without running the app — is committed at [`samples/ethical-monitoring-export.json`](samples/ethical-monitoring-export.json) and referenced from [`ARTIFACTS.md`](ARTIFACTS.md).

**Code anchors:**
- Use case: `Apple/lumen/Domain/UseCases/ExportEthicalLogs.swift`
- Repository (JSON encoder): `Apple/lumen/Data/Repositories/SwiftDataEthicalLogRepository.swift`
- Settings UI: `Apple/lumen/Features/Settings/`

## Rate limiting — code anchor

PALO asked for "rate limiting local". The implementation is a Swift `actor` to keep budget reads/writes data-race-free under Swift 6 strict concurrency:

- Service: `Apple/lumen/Domain/Services/RateLimiter.swift`
- Tests: `Apple/lumenTests/Domain/RateLimiterTests.swift` (covers the daily reset at local midnight and both budgets — 1 auto + 3 manual/Ask Lumen shared)

## Right to erasure

Settings → **Erase my logs** purges all `EthicalLog` rows from SwiftData. Confirmation dialog before deletion. No remote copy — once deleted, the data is gone.

## Privacy guarantees, summarised

- **Nothing leaves the device** without an explicit user action (export).
- **The prompt is hashed**, never stored in clear. Anyone reading the logs cannot reconstruct what the user wrote in their morning questionnaire.
- **Cloud requests carry only the questionnaire answers** — no email, no ID, no IP enrichment.
- **Apple Intelligence requests are 100 % on-device** — a "perfect privacy" tier when the device supports it.
- **Pre-flight safety check** prevents sensitive content from reaching cloud providers.
- **Calm copy**: rate limit hits and offline state are framed as gentle nudges, never as failures or punishments — consistent with Lumen's anti-streak posture.

## What we are not doing (acknowledged limitations)

- No formal classifier for content safety (regex-based, V1).
- No A/B testing of prompt variants in V1 (no remote experimentation backbone).
- No automatic adversarial prompt detection beyond the safety regex.
- No formal third-party privacy audit before publication; we rely on documentation and code transparency.
- No data residency claim beyond "device-local". Cloud provider terms (OpenAI, Anthropic) apply to the prompt at request time.

## Roadmap (post-V1)

- On-device content safety classifier (Core ML model).
- Aggregated personal stats accessible to the user (token usage trend, average latency).
- Optional on-device differential privacy if behavioural metrics are added.
