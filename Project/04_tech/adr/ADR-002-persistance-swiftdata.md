# ADR-002 — SwiftData vs Core Data

## Statut
Accepté

## Contexte

Le brief PALO IT impose "SwiftData / Core Data pour la persistance (pas de lib tierce)". Choix binaire entre les deux.

## Options

### Option A — SwiftData
- API moderne Swift-first (iOS 17+)
- `@Model` macro, moins de boilerplate
- Types-safe, Observable natif
- Interop Core Data possible (NSManagedObject accessible si besoin)
- Connu pour avoir eu des bugs jeunesse (iOS 17.0-17.3), largement stabilisés en iOS 17.4+

### Option B — Core Data
- Mature, éprouvé
- Plus de boilerplate (NSManagedObject, context, fetch requests verbeux)
- Moins alignement avec la posture "modern Swift" qu'un CTO 2026 attend

## Décision

**SwiftData**, avec une stratégie de secours Core Data documentée.

Raisons :
- iOS 17+ = cible du brief, SwiftData est natif et attendu.
- Signal de modernité technique (aligne avec l'usage d'async/await et du strict concurrency).
- Moins de code, plus de lisibilité sur la couche Data.
- Les bugs connus (CloudKit sync, batch operations) ne nous impactent pas : pas de sync cloud en V1, pas de batch massif.

## Implémentation

### Principe
Les entités SwiftData `@Model` vivent en couche `Data`. La couche `Domain` expose des entités Swift pures (structs) et des protocols repository. Les repos SwiftData font la conversion bidirectionnelle.

### ModelContainer
Un seul `ModelContainer` partagé, injecté depuis le Composition Root. Accès :
- Écritures : via `@ModelActor` pour éviter les data races en strict concurrency
- Lectures simples : via `ModelContext` sur `@MainActor`

### Schéma versionné
```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        AlarmEntity.self,
        RitualEntity.self,
        QuestionnaireAnswerEntity.self,
        DashboardSnapshotEntity.self,
        EthicalLogEntity.self
    ]
}
```

Migrations futures via `SchemaMigrationPlan` (lightweight par défaut).

### Test strategy
- Tests unitaires de repo : `ModelContainer` en mémoire (`isStoredInMemoryOnly: true`)
- Pas de fixtures dans le vrai store pour éviter les conflits test ↔ app

## Conséquences

### Positives
- Code Data compact, lisible.
- Alignement avec les attentes 2026 côté stack iOS.
- Bonne intégration SwiftUI (`@Query`, `@Environment(\.modelContext)`).

### Négatives
- SwiftData encore jeune : certains edge cases (relations complexes, `@Transient`, performance sur grandes collections) peu documentés.
- Migration CoreData → SwiftData plus complexe si besoin un jour.

### Fallback documenté
Si en cours de dev on rencontre un bug bloquant SwiftData :
- Basculer les repositories concernés vers Core Data.
- Impact limité car les protocols Domain ne changent pas.
- Décision prise au niveau repo, pas au niveau domain.

## Références

- [SwiftData — Apple Developer Documentation](https://developer.apple.com/documentation/SwiftData)
- [Meet SwiftData — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10187/)
