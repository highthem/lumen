# Stack technique

## Plateforme

- **iOS 17+** (contrainte brief PALO)
- **Xcode 16+** (contrainte brief PALO)
- **Swift 6** (avec `SwiftSettings.enableUpcomingFeature` pour strict concurrency)

## Framework UI

- **SwiftUI pur** (pas d'UIKit pur, contrainte brief)
- Interop UIKit autorisée uniquement si indispensable (ex: `UIApplication` pour routing notif)

## Architecture

- **MVVM + Clean Architecture** (contrainte brief)
- Couches : `App`, `Features`, `Domain`, `Data`, `Infrastructure`, `Shared`

## Concurrency

- **Swift Concurrency** (async/await, `Task`, `actor`, `@MainActor`)
- Pas de Combine (justifié ADR-003)
- Strict concurrency checking : **Complete**

## Persistance

- **SwiftData** (contrainte brief, pas de lib tierce)
- Core Data en fallback si problème iOS 17 ou complexité imprévue (SwiftData a eu des bugs jeunesse)

## Notifications & Audio

- **UserNotifications** : scheduling et actions Snooze/Silence (contrainte brief)
- **AVFoundation** : audio en background, session `.playback` + `.duckOthers` (contrainte brief)
- **Background Modes** : Audio, UIBackgroundTask pour clean-up court

## Voice (input + output) — voir ADR-007

- **Speech framework (`SFSpeechRecognizer`)** : input vocal (dictation Q3/Q4) avec fallback typing si permissions/audio indisponibles. L'audio capté n'est jamais persisté ni loggé.
- **ElevenLabs + AVFoundation (`AVSpeechSynthesizer`)** : output vocal (TTS synthèse IA). ElevenLabs est utilisé si une clé est configurée, avec fallback local AVSpeech.
- Permissions Info.plist : `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`.
- Si la dictée échoue → fallback typing transparent.

## IA

- **OpenAI GPT-4o-mini** (primaire cloud) — via appel REST direct (URLSession), pas de SDK
- **Anthropic Claude Haiku 4.5** (fallback cloud) — via appel REST direct
- **Apple Intelligence / Foundation Models framework** (on-device fallback) — iOS 26+ uniquement, A17 Pro+ chip requis
- **Queue offline** (dernier recours) — si pas de réseau ET pas d'Apple Intelligence dispo : queue persistante, génération différée au retour réseau

Voir ADR-004 pour détail du waterfall.

**Compilation conditionnelle :** `import FoundationModels` derrière `#if canImport(FoundationModels)` + `@available(iOS 26.0, *)` pour ne pas casser le build sur SDK plus anciens.

## Réseau

- **URLSession** natif
- Pas d'Alamofire, pas de Moya (hypothèse H2 en attente validation)

## Logging & monitoring

- **os.log** (Apple natif) pour debug
- **Logger custom** dédié au monitoring éthique (persisté SwiftData, exportable JSON)

## Tests

- **SwiftTesting** (iOS 17+) unitaires
- **Maestro.dev** pour les parcours, non regression, edge-cases.
- **Couverture cible :** ≥ 60% sur Domain (contrainte brief)

## DI (Dependency Injection)

- **Manuel via Composition Root** (pas de lib tierce) — hypothèse H2
- Injection par constructeur
- Protocols pour chaque service infra

## Build & CI

- **Xcode Cloud** (CI/CD principal) — 25 h/mois free tier inclus dans Apple Developer Program
- 3 workflows : Tests on push / TestFlight on tag / Build on push (Xcode 16 - Device/Simulator)
- Build numbers auto-incrémentés
- Provisioning + signing géré automatiquement
- Voir ADR-006 pour détail

**Note dev local :** Xcode 16 n'étant pas dispo locallement, on utilise la Xcode Cloud pour s'assurer du respect du biref.

## Secrets

- **`Apple/lumen/Config/Secrets.xcconfig`** non commité (gitignored) — contient les clés API
- **`Apple/lumen/Config/Secrets.xcconfig.sample`** versionné avec placeholders pour onboarding dev
- **Xcode Cloud Environment Variables** (marquées Secret) pour CI/CD
- **`ci_scripts/ci_post_clone.sh`** génère le `.xcconfig` à partir des env vars en CI
- Clés API jamais hardcodées dans le code Swift
- Accès dans le code via `Bundle.main.object(forInfoDictionaryKey:)`

Voir ADR-006 pour détail.

## Analytics

- **Aucune** en V1 (privacy-first)
- Logging monitoring éthique = local uniquement

## Crashlytics / Error reporting

- **Aucun** en V1 (pas de Firebase, privacy-first)
- `os_log` pour les erreurs critiques, review manuelle

## Design system

- Tokens SwiftUI custom basés sur `style_guide.md`
- Pas de lib design (pas de AirBnB SkeletonView, etc.)

## Localization

- `.xcstrings` natif iOS 16+, catalogue FR + EN
- Clés sémantiques (pas de texte hardcodé)
