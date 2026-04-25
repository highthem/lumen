# ADR-003 — Swift Concurrency vs Combine

## Statut
Accepté

## Contexte

Le brief demande "Combine **ou** Swift Concurrency (à justifier)". Choix binaire.

## Options

### Option A — Combine
- Framework réactif Apple (iOS 13+)
- Mature, éprouvé, nombreux opérateurs
- Syntaxe verbale (publishers, subscribers, type erasure)
- Pas d'évolution significative depuis iOS 15 (Apple a clairement pivot Swift Concurrency)

### Option B — Swift Concurrency (async/await, actors, Sendable)
- Intégré au langage (Swift 5.5+), pas un framework
- Modèle structuré (Task trees, cancellation propagée)
- `actor` pour la sécurité d'état concurrent
- Strict concurrency checking en Swift 6 = safety compile-time
- Alignement avec les APIs Apple 2024+ qui migrent massivement vers async/await

## Décision

**Swift Concurrency**, Swift 6 strict mode activé.

## Justification

1. **Alignement plateforme** : iOS 17+ et Swift 6 (disponible Xcode 16) font de Swift Concurrency le choix par défaut attendu d'un code moderne. Combine en 2026 c'est du legacy acceptable, pas un choix proactif.

2. **Safety** : le strict concurrency checking détecte les data races à la compilation. Pour une app avec alarme en background + IA cloud + persistance, la sûreté concurrente est critique. Combine ne donne pas ce niveau de garantie.

3. **Lisibilité** : un flow linéaire async/await est significativement plus lisible qu'une chaîne Combine équivalente. L'audit de code en soutenance en bénéficiera.

4. **Tests** : tester une fonction `async` via `XCTest` / SwiftTesting est direct (`async` test methods). Tester un `Publisher` nécessite soit `sink` + `XCTestExpectation`, soit un util d'await.

5. **Interop SwiftUI** : `@Observable` (iOS 17+) remplace avantageusement les `@Published` + `ObservableObject` combinés à Combine. Moins de boilerplate, meilleure performance.

## Implications

### Usage typique
```swift
// Dans un use case
func generateMorningSynthesis(for ritualId: UUID) async throws -> AIResponse {
    let answers = try await ritualRepo.answers(for: ritualId)
    let response = try await aiService.synthesize(answers)
    try await ritualRepo.save(response: response, ritualId: ritualId)
    return response
}

// Dans un ViewModel (@MainActor @Observable)
@MainActor
@Observable
final class SynthesisViewModel {
    var state: LoadableState<AIResponse> = .idle
    private let useCase: GenerateMorningSynthesis
    
    func load(ritualId: UUID) async {
        state = .loading
        do {
            let response = try await useCase.execute(ritualId: ritualId)
            state = .loaded(response)
        } catch {
            state = .error(error)
        }
    }
}
```

### Actors pour l'état partagé
- `RateLimiter`: actor, accès concurrent au compteur.
- `AppStateMachine`: actor, transitions d'état cohérentes.

### `@ModelActor` pour SwiftData
Les writes SwiftData hors MainActor passent par un `@ModelActor` custom (pattern documenté Apple). Cela évite les data races sur `ModelContext`.

### Sendable
Toutes les entités Domain sont `Sendable` (structs immutables). Tous les protocols repository renvoient du `Sendable`.

### Cancellation
Les `Task` sont structurés. Si l'utilisateur quitte l'écran synthèse pendant la génération IA, on annule la Task (`.task` modifier gère ça automatiquement).

## Conséquences

### Positives
- Code concis et safe.
- Meilleure lisibilité en revue de code.
- Alignement plateforme 2026.
- Test simple.

### Négatives
- Courbe d'apprentissage `@ModelActor` / strict concurrency sur des cas limites.
- Certaines APIs Apple 2026 exposent encore Combine (ex: `NotificationCenter.Publisher`). On convertit avec `values` (AsyncSequence) plutôt que d'ajouter Combine.
- Debug des `Task` trees moins outillé qu'un publisher chain (mais ça progresse).

### Risques
- Strict concurrency peut bloquer des lib tierces (mais on n'en utilise pas).
- SwiftData + concurrency : quelques edge cases documentés, mitigés par `@ModelActor`.

## Références

- [Swift Concurrency — Apple docs](https://developer.apple.com/documentation/swift/concurrency)
- [Meet Swift Concurrency — WWDC21](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [Combine — Apple docs](https://developer.apple.com/documentation/combine) (pour référence, non utilisé)
