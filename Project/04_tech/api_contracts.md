# API contracts

## Providers IA

### Apple Intelligence — Foundation Models framework (on-device, iOS 26+)

**Disponibilité :**
- iOS 26+ uniquement
- Devices A17 Pro+ chip (iPhone 15 Pro/Max, iPhone 16+, iPhone 17+)
- 7 GB free storage requis pour le modèle ~3B parameters

**Check de disponibilité :**
```swift
@available(iOS 26.0, *)
var isAvailable: Bool {
    SystemLanguageModel.default.availability == .available
}
```

**Appel :**
```swift
@available(iOS 26.0, *)
func synthesize(_ answers: [QuestionnaireAnswer]) async throws -> AIResponse {
    let session = LanguageModelSession()
    let prompt = PromptBuilder.build(answers: answers)
    
    // Generable type permet de typer la réponse directement
    let response = try await session.respond(
        to: prompt,
        generating: AIResponse.self
    )
    return response.content
}
```

**Privacy :** 100% on-device. Aucun appel réseau, aucune donnée envoyée à Apple.

**Latence cible :** < 2s sur A17 Pro+.

**Fallback si non dispo :** voir queue offline (ADR-004).

### OpenAI — Chat Completions

**Endpoint :** `POST https://api.openai.com/v1/chat/completions`

**Headers :**
```
Authorization: Bearer $OPENAI_API_KEY
Content-Type: application/json
```

**Body :**
```json
{
  "model": "gpt-4o-mini",
  "messages": [
    {"role": "system", "content": "{{system_prompt}}"},
    {"role": "user", "content": "{{user_answers_formatted}}"}
  ],
  "max_tokens": 250,
  "temperature": 0.7,
  "response_format": {"type": "json_object"}
}
```

**Response shape attendu (parseé par l'app) :**
```json
{
  "intention": "Une phrase claire qui cadre la journée.",
  "focus": ["Action 1 concrète.", "Action 2 concrète."],
  "reminder": "Une phrase présence ancrée sur la gratitude."
}
```

**Gestion d'erreurs :**
- HTTP 429 (rate limit) → fallback Anthropic
- HTTP 5xx → fallback Anthropic
- Timeout (10s) → fallback Anthropic
- JSON invalide → retry 1× puis fallback offline

### Anthropic — Messages API

**Endpoint :** `POST https://api.anthropic.com/v1/messages`

**Headers :**
```
x-api-key: $ANTHROPIC_API_KEY
anthropic-version: 2023-06-01
Content-Type: application/json
```

**Body :**
```json
{
  "model": "claude-haiku-4-5-20251001",
  "max_tokens": 250,
  "system": "{{system_prompt}}",
  "messages": [
    {"role": "user", "content": "{{user_answers_formatted}}"}
  ]
}
```

**Response shape :** texte structuré attendu dans `content[0].text`, parsé en JSON.

**Gestion d'erreurs :** idem OpenAI → fallback offline.

## Prompt builder

### System prompt (ES1)

```
Tu es Lumen, un compagnon matinal silencieux. Tu reçois 4 réponses d'un utilisateur qui vient de se réveiller :
- son ressenti (emoji + tag)
- sa priorité (catégorie + note optionnelle)
- une gratitude (texte court)
- une intention (un mot)

Tu produis une synthèse STRICTEMENT au format JSON suivant :
{
  "intention": string (1-2 phrases, reprend l'intention user enrichie),
  "focus": string[] (1-2 actions concrètes alignées sur la priorité et le ressenti),
  "reminder": string (1 phrase de présence, ancrée sur la gratitude)
}

RÈGLES :
- Ton chaleureux, non-prescriptif, jamais motivant-toxique.
- Pas de "tu dois", "il faut", "bravo".
- Langue : celle de l'utilisateur (détectée via l'input).
- Pas d'emojis sauf si l'utilisateur en a utilisé.
- Sortie uniquement le JSON, rien d'autre.
```

### User prompt template

```
Ressenti : {mood_emoji} ({mood_tag})
Priorité : {category} — {note}
Gratitude : {gratitude_text}
Intention : {intention_word}
```

### Hashing du prompt (monitoring éthique)

```swift
let concatenated = systemPrompt + userPrompt
let hash = SHA256.hash(data: concatenated.data(using: .utf8)!)
let promptHash = "sha256:\(hash.compactMap { String(format: "%02x", $0) }.joined())"
```

## Clés API et secrets

### Fichier `.xcconfig` (non commité)

```
OPENAI_API_KEY = sk-proj-...
ANTHROPIC_API_KEY = sk-ant-...
```

### Chargement Info.plist

```xml
<key>OPENAI_API_KEY</key>
<string>$(OPENAI_API_KEY)</string>
<key>ANTHROPIC_API_KEY</key>
<string>$(ANTHROPIC_API_KEY)</string>
```

### Accès dans code

```swift
enum Secrets {
    static var openAIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    }
    static var anthropicKey: String {
        Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
    }
}
```

## Rate limiting local — contrat

```swift
protocol RateLimiting {
    func canPerform(action: AIAction) -> Bool
    func record(action: AIAction)
    func remaining(for action: AIAction) -> Int
    func reset()
}

enum AIAction {
    case autoSynthesis           // 1 / jour
    case manualRegeneration      // 3 / jour
    case askLumenDashboard       // 3 / jour (partagé avec manualRegeneration)
}
```

Persistence : `UserDefaults` ou `SwiftData` (UserDefaults suffit pour un compteur simple).

Reset : à minuit local (monitoring `Calendar.current.startOfDay` comparé au dernier reset).

## Notifications — contrats iOS

### Catégories déclarées

```swift
enum LumenNotificationCategory: String {
    case alarm = "LUMEN_ALARM"
}

enum LumenNotificationAction: String {
    case snooze = "LUMEN_SNOOZE"
    case silence = "LUMEN_SILENCE"
}
```

### UNNotificationCategory

```swift
let snooze = UNNotificationAction(
    identifier: LumenNotificationAction.snooze.rawValue,
    title: NSLocalizedString("alarm.snooze", comment: ""),
    options: []
)
let silence = UNNotificationAction(
    identifier: LumenNotificationAction.silence.rawValue,
    title: NSLocalizedString("alarm.silence", comment: ""),
    options: [.foreground]   // pour ouvrir l'app au tap
)

let category = UNNotificationCategory(
    identifier: LumenNotificationCategory.alarm.rawValue,
    actions: [snooze, silence],
    intentIdentifiers: [],
    options: [.customDismissAction]
)
```

### UNNotificationRequest (scheduling)

- `UNCalendarNotificationTrigger` avec components heure+minute, repeat selon recurrence
- `UNNotificationSound.init(named:)` pointant sur le fichier `.caf` embedded
- `content.categoryIdentifier = "LUMEN_ALARM"` pour afficher les actions

### Contrainte plateforme — son

- Fichier audio : `.caf`, `.aiff`, `.wav` (formats supportés UN)
- Durée : souvent documentée comme limitée à 30s dans la notification (à vérifier empiriquement)
- Solution si réveil plus long voulu : app foreground + AVAudioPlayer prend le relais après l'interaction

## Audio session contract

```swift
protocol AudioPlaying {
    func configureSession() async throws
    func play(soundId: String, fadeIn: Bool) async throws
    func stop() async
    func duckOthers(_ duck: Bool) async
}
```

Implementation utilise `AVAudioSession.sharedInstance()` avec category `.playback` et option `.duckOthers`.

## Network reachability

```swift
protocol NetworkReachability {
    var isReachable: Bool { get async }
    var reachabilityUpdates: AsyncStream<Bool> { get }
}
```

Implementation via `NWPathMonitor`.
