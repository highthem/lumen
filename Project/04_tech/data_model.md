# Data model

Modèles SwiftData (entités persistantes) et entités Domain (pures Swift).

## Entités Domain (pures Swift)

### Alarm
```swift
struct Alarm: Identifiable, Equatable {
    let id: UUID
    var time: Date      // heure du jour, composantes hour/minute utilisées
    var recurrence: AlarmRecurrence
    var soundId: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
}

enum AlarmRecurrence: Equatable {
    case none
    case weekdays            // Lun-Ven
    case everyday
    case custom(Set<Weekday>)
}

enum Weekday: Int, CaseIterable { case mon=1, tue, wed, thu, fri, sat, sun }
```

### Ritual
```swift
struct Ritual: Identifiable {
    let id: UUID
    let date: Date           // date locale (jour uniquement)
    var state: RitualState
    var questionnaireAnswers: [QuestionnaireAnswer]
    var synthesis: AIResponse?
    var completedAt: Date?
}

enum RitualState { case notStarted, partial, completed }
```

### QuestionnaireAnswer
```swift
struct QuestionnaireAnswer: Identifiable {
    let id: UUID
    let ritualId: UUID
    let step: QuestionnaireStep   // .mood, .priority, .gratitude, .intention
    var payload: AnswerPayload
    var createdAt: Date
}

enum QuestionnaireStep: String { case mood, priority, gratitude, intention }

enum AnswerPayload {
    case mood(level: Int, tag: String?)   // level 1..5
    case priority(category: DashboardCategory, note: String?)
    case gratitude(text: String)
    case intention(word: String)
}

enum DashboardCategory: String, CaseIterable {
    case energy, intention, body, relations, work, gratitude
}
```

### AIResponse
```swift
struct AIResponse: Identifiable {
    let id: UUID
    let ritualId: UUID
    let intention: String       // 1-2 phrases
    let focus: [String]         // 1-2 actions
    let reminder: String        // 1 phrase
    let provider: AIProvider
    let mode: AIResponseMode
    let generatedAt: Date
}

enum AIProvider: String { case openai, anthropic, apple, offlineTemplate }
enum AIResponseMode: String { case auto, manualRegenerate, fallbackOffline }
```

### DashboardSnapshot
```swift
struct DashboardSnapshot {
    let date: Date
    var energy: String?
    var intention: String?
    var body: BodyCheckin
    var relations: String?
    var work: String?
    var gratitude: String?
}

struct BodyCheckin {
    var sleepFeeling: SleepFeeling?   // enum .rested/.ok/.tired
    var hydrationNote: String?
}
```

### EthicalLog
```swift
struct EthicalLog: Identifiable {
    let id: UUID
    let timestamp: Date
    let provider: AIProvider
    let mode: AIResponseMode
    let latencyMs: Int
    let tokenIn: Int?
    let tokenOut: Int?
    let promptHash: String
    let contentSafetyFlags: [String]
    let userFeedback: UserFeedback?
    let privacyScope: String       // "user_input_only"
}

enum UserFeedback: String { case positive, negative }
```

## Entités SwiftData (@Model)

Mapping 1:1 avec Domain. Exemple :

```swift
@Model
final class AlarmEntity {
    @Attribute(.unique) var id: UUID
    var time: Date
    var recurrenceRaw: String   // serialization JSON de AlarmRecurrence
    var soundId: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(from domain: Alarm) { /* ... */ }
    func toDomain() -> Alarm { /* ... */ }
}
```

Idem pour `RitualEntity`, `QuestionnaireAnswerEntity`, `DashboardSnapshotEntity`, `EthicalLogEntity`.

## Schéma de relations

```
Ritual (1) ────── (0..4) QuestionnaireAnswer
   │
   └───── (0..1) AIResponse
   │
   └───── (0..1) DashboardSnapshot

Alarm : standalone

EthicalLog : standalone (reliable par timestamp)
```

## Migrations

V1 = schéma initial, pas de migration à ce stade. Prévoir :
- Wrapping dans `VersionedSchema` dès V1 pour permettre migrations futures.
- `SchemaMigrationPlan.lightweight` par défaut, `custom` si besoin post-V1.

## Export JSON — schéma monitoring éthique

```json
{
  "exported_at": "2026-05-14T07:42:00Z",
  "app_version": "1.0.0",
  "privacy_scope": "local_user_data_only",
  "logs": [
    {
      "id": "8c3e5f9b-...",
      "timestamp": "2026-05-14T07:05:23Z",
      "provider": "openai",
      "mode": "auto",
      "latency_ms": 1842,
      "token_in": 247,
      "token_out": 98,
      "prompt_hash": "sha256:...",
      "content_safety_flags": [],
      "user_feedback": null,
      "privacy_scope": "user_input_only"
    }
  ]
}
```

## Règles de privacy

- **Aucune PII dans les logs.** Pas d'email, pas d'ID user remote, pas de lat/long.
- **Prompt haché**, jamais stocké en clair.
- **User feedback optionnel**, stocké uniquement si explicitement donné.
- **Pas de sync iCloud** en V1 (tout reste device-local).
- **Pas de backup iTunes** des logs sensibles : marquer `protectionClass` approprié si besoin.
