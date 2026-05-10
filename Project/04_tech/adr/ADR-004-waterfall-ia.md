# ADR-004 — Stratégie IA en waterfall avec Apple Intelligence et queue offline

## Statut
Accepté (révisé 24 avr 2026 : suppression des templates pré-écrits, ajout Apple Intelligence + queue offline)

## Contexte

Le brief PALO impose :
- "Synthèse générée par IA (avec fallback hors-ligne et monitoring éthique)"
- "Intégration IA via OpenAI ou Anthropic, avec journalisation et rate limiting local"

Contraintes vérifiées :
- **Apple Intelligence (Foundation Models framework)** : disponible iOS 26+ uniquement, devices A17 Pro+ (iPhone 15 Pro/Max, iPhone 16+, iPhone 17+), 7 GB de free storage. Source : [Apple Developer Documentation](https://developer.apple.com/documentation/FoundationModels).
- Cible iOS 17+ du brief = beaucoup de devices supportés (iPhone 11, 12, 13, 14, 15 non-Pro) **n'auront jamais Apple Intelligence**.

## Décision

**Waterfall à 3 niveaux + queue offline déterministe :**

```
1. Cloud primaire : OpenAI GPT-4o-mini
       │  (si échec : timeout 10s, HTTP 4xx/5xx, JSON invalide)
       ▼
2. Cloud secondaire : Anthropic Claude Haiku 4.5
       │  (si échec)
       ▼
3. On-device fallback (offline) :
       ├─ Apple Intelligence dispo (iOS 26+ + A17 Pro+) → Foundation Models
       └─ Apple Intelligence indispo → Queue + génération différée au retour réseau
```

Pre-check `NetworkReachability` : si offline détecté dès le départ, on saute 1 et 2 directement vers 3.

**Pas de templates pré-écrits.** L'expérience offline doit rester de qualité IA générée — soit en local (Apple Intelligence), soit différée (queue).

Pattern hérité du projet **Skoul** où le waterfall a été éprouvé en prod (OpenAI → Gemini Firebase → Apple Intelligence). Ici simplifié et adapté au brief.

### Rebrand "Lumen AI" (UI seulement)

Dans l'UI, la chaîne cloud (OpenAI + Anthropic) est exposée comme un seul service nommé **"Lumen AI"**. L'utilisateur ne voit pas les noms de providers, sauf dans une mention légale discrète ("Lumen AI s'appuie sur OpenAI et Anthropic").

Bénéfice : on peut changer de provider cloud sans toucher l'UI, et le framing produit est plus simple ("Lumen AI / Apple Intelligence / File d'attente" — 3 niveaux clairs au lieu de 4 services nommés).

### Mode BYO API key (Bring Your Own)

L'utilisateur peut entrer sa propre clé OpenAI ou Anthropic dans Settings → Mode avancé. Quand activé :
- Les appels Lumen AI partent directement avec la clé utilisateur (jamais via nos serveurs).
- **Rate limit levé** côté app (l'utilisateur paie son usage au provider).
- Le `EthicalLog` continue à fonctionner normalement, avec un nouveau champ `usingPersonalKey: true`.
- La clé est stockée dans **Keychain iOS** (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, pas de sync iCloud).
- À la suppression de la clé : retour automatique au mode Lumen AI standard avec rate limit.

Voir US-AI8 pour les critères d'acceptation détaillés.

## Détail d'implémentation

### Protocole Domain

```swift
protocol AISynthesisService {
    func synthesize(_ answers: [QuestionnaireAnswer]) async throws -> AIResponseResult
}

enum AIResponseResult {
    case ready(AIResponse)
    case queued(estimatedDelivery: Date?)   // queue offline, pas de réseau et pas d'AI on-device
}
```

### Implémentation `WaterfallAISynthesisService`

```swift
final class WaterfallAISynthesisService: AISynthesisService {
    private let cloudProviders: [any AIProviderClient]   // [OpenAI, Anthropic]
    private let onDeviceProvider: AppleIntelligenceProvider?  // nil si device non compatible
    private let synthesisQueue: SynthesisQueue
    private let rateLimiter: RateLimiting
    private let ethicalLogger: EthicalLogging
    private let reachability: NetworkReachability
    
    func synthesize(_ answers: [QuestionnaireAnswer]) async throws -> AIResponseResult {
        guard await rateLimiter.canPerform(action: .autoSynthesis) else {
            throw AIError.rateLimited
        }
        
        let isOnline = await reachability.isReachable
        
        if isOnline {
            for provider in cloudProviders {
                if let response = try? await provider.synthesize(answers) {
                    await ethicalLogger.log(response: response, provider: provider.name, mode: .auto)
                    await rateLimiter.record(action: .autoSynthesis)
                    return .ready(response)
                }
            }
        }
        
        // Offline OU tous les cloud ont fail
        if let onDevice = onDeviceProvider {
            let response = try await onDevice.synthesize(answers)
            await ethicalLogger.log(response: response, provider: "apple", mode: .fallbackOnDevice)
            return .ready(response)
        }
        
        // Pas d'on-device dispo : queue
        await synthesisQueue.enqueue(answers, ritualId: ...)
        return .queued(estimatedDelivery: nil)
    }
}
```

### Apple Intelligence — implémentation

```swift
import FoundationModels  // iOS 26+ uniquement

final class AppleIntelligenceProvider {
    static var isAvailable: Bool {
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.availability == .available
        }
        return false
    }
    
    func synthesize(_ answers: [QuestionnaireAnswer]) async throws -> AIResponse {
        let session = LanguageModelSession()
        let prompt = PromptBuilder.build(answers: answers)
        let response = try await session.respond(to: prompt, generating: AIResponse.self)
        return response.content
    }
}
```

Compilation conditionnelle : on importe `FoundationModels` derrière `#if canImport(FoundationModels)` et `@available(iOS 26.0, *)` pour ne pas casser le build sur SDK plus anciens.

### Queue offline

Pour les devices iOS 17-18 ou < A17 Pro, sans réseau au moment du rituel :

```swift
actor SynthesisQueue {
    private var pending: [PendingSynthesis] = []
    
    func enqueue(_ answers: [QuestionnaireAnswer], ritualId: UUID) async {
        let item = PendingSynthesis(
            id: UUID(),
            ritualId: ritualId,
            answers: answers,
            createdAt: Date()
        )
        pending.append(item)
        await persistToSwiftData(item)
    }
    
    func processOnReachability() async {
        // Triggered by NetworkReachability AsyncStream
        for item in pending {
            if let response = try? await waterfall.synthesizeWithCloudOnly(item.answers) {
                await ritualRepo.save(response: response, ritualId: item.ritualId)
                await notifyUser(item.ritualId)
                await dequeue(item.id)
            }
        }
    }
}
```

UX :
- À la fin du questionnaire, si en queue : écran "Ta synthèse arrive — on te notifie dès que ton réseau revient." avec accès direct au dashboard sans synthèse.
- Local notification quand la synthèse arrive : "Ta synthèse de ce matin est prête."
- Si l'utilisateur n'a pas eu de réseau de toute la journée : la synthèse arrive le lendemain (ou expiration à J+1 si pas pertinente).

### Timeouts et retries

- Timeout par provider cloud : 10s
- Pas de retry automatique sur le même provider — on passe au suivant
- Apple Intelligence : pas de timeout (on-device, latence prévisible <2s)
- Queue : pas de retry agressif, basé sur reachability stream

## Monitoring éthique

Chaque tentative — réussie ou échouée, cloud ou on-device ou queued — logue :
- provider (`openai` / `anthropic` / `apple` / `queued`)
- mode (`auto` / `manualRegenerate` / `fallbackOnDevice` / `fallbackQueued`)
- latency (sauf queued)
- tokens (cloud uniquement)
- prompt hash
- safety flags
- privacy scope (`user_input_only` cloud, `device_only` Apple Intelligence, `pending` queue)

Voir ADR-005 pour détail.

**Note Apple Intelligence privacy :** les requêtes Foundation Models sont 100% on-device, jamais envoyées à Apple. Confirmer dans la doc Apple à l'implémentation.

## Conséquences

### Positives
- **Qualité IA constante** : pas de dégradation vers un template pauvre, toujours du LLM (cloud ou on-device).
- **Privacy boost** : sur device compatible, l'offline = aucune donnée ne quitte le device.
- **Robustesse** : 3 niveaux + queue, zéro écran d'erreur définitif.
- **Cost reduction long terme** : sur iOS 26+ A17 Pro+, l'usage on-device est gratuit (pas d'appel cloud).
- **Différenciateur concurrents** : aucun des 4 (Fabulous, Alarmy, Opal, Rise) ne fait ça.

### Négatives
- **Complexité accrue** : 4 chemins à tester (cloud, on-device, queue immédiate, queue différée).
- **Apple Intelligence exclusif iOS 26+** : la plupart des devices iOS 17-24 utiliseront la queue offline plutôt qu'on-device.
- **Code conditionnel** (`#available(iOS 26, *)`) à maintenir.
- **Latence ressentie variable** : 2s on-device vs 4s cloud vs "plus tard" en queue.

### Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Foundation Models API breaking changes (framework jeune) | Wrap dans `AppleIntelligenceProvider`, test versionné |
| Queue oubliée par l'utilisateur (synthèse jamais consultée) | Notif locale au retour réseau + badge dashboard |
| Apple Intelligence indisponible alors que device théoriquement supporté | `availability` check à chaque appel + fallback queue |
| OpenAI + Anthropic down + device incompatible Apple Intelligence | Queue inévitable, UX claire |
| Modèle on-device (~3B) qualité inférieure à GPT-4o-mini | Acceptable pour synthèse courte ; le format JSON strict mitige |

## Démo en soutenance

Démo recommandée :
1. Mode normal (réseau dispo) → OpenAI répond, synthèse en 3s.
2. Couper réseau (avion mode) sur device A17 Pro+ iOS 26 → Apple Intelligence répond on-device.
3. Couper réseau sur device sans Apple Intelligence (simulateur iPhone 12) → queue affichée + notif locale + démo de la complétion au retour réseau.

Cette démo couvre les 3 chemins en 2 min — argument fort en revue de code.

## Références

- [Foundation Models framework — Apple Developer Documentation](https://developer.apple.com/documentation/FoundationModels)
- [Apple newsroom — Foundation Models framework](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)
- [Meet the Foundation Models framework — WWDC25](https://developer.apple.com/videos/play/wwdc2025/286/)
- [OpenAI Chat Completions](https://platform.openai.com/docs/api-reference/chat)
- [Anthropic Messages API](https://docs.anthropic.com/en/api/messages)
- Projet Skoul (référence Highthem interne)
