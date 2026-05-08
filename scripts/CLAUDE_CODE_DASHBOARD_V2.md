# Claude Code task — Dashboard V2 + question reorder + Présence + HealthKit Sleep

> **Pour l'utilisateur** : ouvre ce dossier dans Claude Code et passe ce fichier comme prompt initial.
> Date contexte : 7 mai 2026. Deadline PALO : **11 mai 2026 (J-4)**. Cette tâche est planifiée pour **samedi 9 mai**, en parallèle du Loom.
> **Règle dure** : pas de scope creep au-delà de ce qui est listé ci-dessous. Si tu hésites entre faire bien et faire propre, fais bien et reporte.

---

## Étape 0 — La source de vérité visuelle

**Avant d'écrire la moindre ligne de SwiftUI, lis intégralement ces fichiers** — ils contiennent les mockups V2 produits par Claude Design et sont la **référence visuelle obligatoire** pour cette tâche.

### Mockups Claude Design (V2, livrés le 7 mai 2026)

- **URL Claude Design** : https://api.anthropic.com/v1/design/h/VictVjCHr3eqjkeucxvEdw?open_file=03-mockups.html
- **Fichiers locaux** (synchronisés depuis Claude Design — Haithem les a déjà downloadés/sync) :
  - `Design/designs/03-mockups.html` — fichier mockup principal, lis-le section par section
  - `Design/designs/screens/screens.jsx` — composants V2 consolidés (un seul fichier, plus de `-v2`/`-v3`/`-v4`)
  - `Design/designs/02-design-system.html` — design system de référence (couleurs, typo, spacing)
  - `Design/designs/handoff/tokens.json` — design tokens à respecter strictement
  - `Design/design-kit/19_workflow_v2.md` — brief design qui a guidé la production des mockups V2

**Si les fichiers locaux ne sont pas à jour avec ce que tu vois sur l'URL Claude Design ci-dessus, signale-le à Haithem et stoppe.** Pas de devinette, pas d'invention.

### Composants à transposer en SwiftUI (5 nouveaux)

- `Q2Energy` (nouveau écran rituel étape 2/4)
- `DashboardPost` V2 (6 cards : Humeur · Énergie · Priorité · Gratitude · Présence · Sommeil)
- `PresenceCard` (3 états : completed / partial / skipped)
- `SleepCard` (2 états : populated / empty)
- `SleepPermissionSheet` (half-sheet HealthKit permission)

### Composants existants redesignés (2 polishes — Haithem a itéré sur ces 2 dans la même livraison Claude Design)

- **Audio player progress** (synthèse IA, écran « Écouter ») — la barre de progression et l'état lecture/pause ont été redesignés. Le composant existe dans `Apple/lumen/Shared/DesignSystem/Components/ListenPlayer.swift`. **Ne pas réinventer** : tu compares visuellement le rendu actuel SwiftUI au mockup V2, et tu adaptes le `ListenPlayer` pour matcher exactement le nouveau visuel (forme de la barre, position des contrôles, treatment du texte, états idle/playing/paused).
- **Ask Lumen sheet** — la half-sheet « Ask Lumen » a été redesignée (input, bouton send, layout réponse). Le composant existe dans `Apple/lumen/Features/AskLumen/AskLumenView.swift`. Même règle : tu compares au mockup, tu adaptes pour matcher.

Pour ces 2 redesigns, **lis les composants Swift existants AVANT de toucher**, identifie ce qui change visuellement vs le mockup V2, et applique le diff. Garde la logique métier (ViewModel, bindings, accessibility identifiers) intacte — seul le visuel change.

### Règle d'or

**Toute divergence entre ton implémentation Swift et le mockup HTML est un bug à fixer.** Le visuel est figé par Claude Design ; tu n'as pas à inventer de hiérarchie, de typo, de spacing — tout est dans le mockup. Tu reproduis fidèlement avec les composants design system existants (`PrimaryCTA`, `Chip`, `DashboardCard`, `HalfSheet`, `Eyebrow`, `KineticText` etc.) en `Apple/lumen/Shared/DesignSystem/`.

Si un mockup n'existe pas pour un composant que tu dois implémenter, **stop et signale-le** — n'invente pas de design, demande à Haithem de le faire produire d'abord par Claude Design.

---

## Contexte produit

L'app Lumen Morning a aujourd'hui :
- 4 questions matinales : Mood (chips) → Priority (chips) → Gratitude (voix/texte) → Intention (voix/texte)
- 6 cards dashboard : Énergie · Intention · Corps · Relations · Travail · Gratitude
- **Problème UX réel** : 3 cards (Corps · Relations · Travail) restent vides après le rituel parce qu'aucune Q n'y mappe. L'utilisateur voit des `—` et ne sait pas quoi faire.

**Décision produit (validée par Haithem le 7 mai)** :
- **Reorder du rituel** vers : Mood → Energy → Priority → Gratitude (Intention est supprimée — Priority la remplace conceptuellement)
- **Refonte des 6 catégories dashboard** : Humeur · Énergie · Priorité · Gratitude · Présence · Sommeil
- Toutes les cards alimentées : 4 par les Q, 1 par le tracking du timer présence 60s, 1 par HealthKit sleep
- Si HealthKit non autorisé ou indisponible : la card Sommeil affiche un CTA « Active Apple Santé »

Brief Sami exige ≥ 4 Q + ≥ 6 catégories : ✅ tenu.

---

## Mission en 5 blocs indépendants

Tu peux les faire dans l'ordre listé. Si un bloc dérape, débranche-le et passe au suivant — ne bloque pas les blocs en aval.

### Bloc 1 — Reorder des 4 questions (~30 min)

**Sans renommer les fichiers existants**, change l'ordre dans `QuestionnaireFlowViewModel.swift` et ajoute une nouvelle vue Energy.

**Étapes :**

1. **Crée** `Apple/lumen/Features/Questionnaire/Q2EnergyView.swift` — duplication structurelle de `Q1MoodView.swift`, mais avec 5 chips :
   - `À plat` · `Faiblard` · `Moyen` · `Bien chargé` · `Au top`
   - `accessibilityIdentifier` : `energy-1` à `energy-5`
   - Clé d'enum dans `QuestionnaireAnswer` : `EnergyLevel` (cas `flat`, `low`, `medium`, `charged`, `top`)
   - Titre écran : « Quelle énergie ce matin ? »

2. **Modifie** `Apple/lumen/Domain/Entities/QuestionnaireAnswer.swift` :
   - Ajoute `var energy: EnergyLevel?` ou équivalent selon la structure existante
   - **Garde** `mood`, `priority`, `gratitude`
   - **Supprime** `intention` du modèle (et adapte les call sites — `SaveQuestionnaireAnswer`, `BuildDashboardSnapshot`, `Q4IntentionView` et son VM)

3. **Modifie** `Apple/lumen/Features/Questionnaire/QuestionnaireFlowViewModel.swift` :
   - Étape 1 : `Q1MoodView` (inchangée)
   - Étape 2 : `Q2EnergyView` (nouvelle)
   - Étape 3 : `Q2PriorityView` (existante, devient l'étape 3 dans le flow)
   - Étape 4 : `Q3GratitudeView` (existante, devient l'étape 4 — c'est la dernière, le bouton « Suivant » devient « Voir ma synthèse »)

4. **Supprime** `Q4IntentionView.swift` (et son VM s'il est séparé) — l'intention disparaît du produit.

5. **Renomme la barre de progression** : 4 dots, indices 1/4 à 4/4, inchangés visuellement mais aligne le label « Étape X / 4 » avec le nouvel ordre.

**Validation Bloc 1** : tu lances le simulator manuellement et tu fais le rituel — les 4 écrans s'enchaînent dans le bon ordre, tu termines sur Gratitude, et le `RitualEntity` persisté contient `mood + energy + priority + gratitude` et plus aucune intention.

---

### Bloc 2 — Refonte du dashboard (6 cards V2) (~45 min)

1. **Modifie** `Apple/lumen/Domain/Entities/DashboardCategory.swift` :

   ```swift
   enum DashboardCategory: String, CaseIterable, Sendable {
       case mood       // Humeur
       case energy     // Énergie
       case priority   // Priorité
       case gratitude  // Gratitude
       case presence   // Présence (breathing 60s tracking)
       case sleep      // Sommeil (HealthKit)
   }
   ```

   Supprime les anciens cas `body`, `relationships`, `work`, `intention`. Adapte les call sites.

2. **Modifie** `Apple/lumen/Domain/Entities/DashboardSnapshot.swift` pour exposer 6 valeurs :

   ```swift
   struct DashboardSnapshot: Sendable {
       let date: Date
       let mood: MoodLevel?
       let energy: EnergyLevel?
       let priority: Priority?
       let gratitude: String?       // texte court Q4
       let presence: PresenceState  // .completed | .partial | .skipped | .notStarted
       let sleep: SleepSummary?     // nil si HealthKit non autorisé / indispo
   }
   ```

3. **Modifie** `Apple/lumen/Domain/UseCases/BuildDashboardSnapshot.swift` :
   - Lit le ritual du jour via `RitualRepository`
   - Pour `mood`, `energy`, `priority`, `gratitude` : extraction directe des champs `QuestionnaireAnswer`
   - Pour `presence` : lit le nouveau champ `Ritual.presence` (voir Bloc 3)
   - Pour `sleep` : appelle `SleepHealthService.fetchLastNight()` async, **enveloppé dans un do/catch** qui retourne `nil` sans throw si erreur (HealthKit indispo, autorisation refusée, pas de données)
   - Ajoute le service via DI (param `sleepService: SleepHealthService` du init)

4. **Modifie** `Apple/lumen/Features/Dashboard/DashboardHomeView.swift` :
   - Grille 2 colonnes, ordre : Humeur · Énergie · Priorité · Gratitude · Présence · Sommeil
   - Card vide pour Sleep si `snapshot.sleep == nil` → CTA « Active Apple Santé » avec icône `heart.fill`, tap → trigger l'auth flow (voir Bloc 5)
   - Pas de placeholder « — » ailleurs : si `snapshot.mood == nil` (cas Empty state premier lancement), garde l'Empty state existant
   - **Footer card** : keep `Ask Lumen` FAB en place, inchangé

5. **Modifie** `Apple/lumen/Features/Dashboard/CategoryDetailView.swift` :
   - Switch sur les 6 nouveaux cas
   - Detail Sommeil affiche : durée totale, qualité (low/medium/high), répartition asleep/deep/REM si dispo, bouton « Voir dans Apple Santé » qui ouvre `x-apple-health://`
   - Detail Présence : « Tu t'es offert 60 secondes ce matin » / « Pas de présence ce matin, demain peut-être » selon `presence`

**Validation Bloc 2** : après un rituel complet (Mood + Energy + Priority + Gratitude), les 6 cards sont remplies (ou Sommeil affiche le CTA Apple Santé si non autorisé). Plus aucun `—`.

---

### Bloc 3 — Présence tracking depuis le timer 60s (~30 min)

1. **Crée** `Apple/lumen/Domain/Entities/PresenceState.swift` :

   ```swift
   enum PresenceState: String, Sendable, Codable {
       case completed     // 60s atteintes
       case partial       // entre 30s et 60s, puis skip
       case skipped       // skip avant 30s
       case notStarted    // l'utilisateur n'a pas encore fait le rituel
   }
   ```

2. **Modifie** `Apple/lumen/Domain/Entities/Ritual.swift` (et `Apple/lumen/Data/Models/RitualEntity.swift`) :
   - Ajoute `presence: PresenceState` (default `.notStarted`)
   - Migration SwiftData : si l'on évite une migration explicite, ajoute `presence: PresenceState = .notStarted` avec valeur par défaut côté entity

3. **Modifie** `Apple/lumen/Features/Timer/PresenceTimerViewModel.swift` :
   - Track `elapsed: TimeInterval` (déjà présent)
   - Quand le timer atteint 0s naturellement → set `presence = .completed`
   - Quand l'utilisateur tape « Passer » → si `elapsed >= 30s` set `.partial`, sinon `.skipped`
   - Persiste via `RitualRepository.updatePresence(ritualId:state:)` (ajoute la méthode)

4. **Modifie** `Apple/lumen/Domain/Protocols/RitualRepository.swift` + `Apple/lumen/Data/Repositories/SwiftDataRitualRepository.swift` :
   - Ajoute `func updatePresence(ritualId: UUID, state: PresenceState) async throws`

5. **Modifie** la synthèse IA — `Apple/lumen/Data/AI/PromptBuilder.swift` :
   - Inclus le state Présence dans le prompt système
   - Si `.completed` → prompt include « L'utilisateur a pris 60 secondes de présence — souligne brièvement »
   - Si `.skipped` → « L'utilisateur a sauté la présence — invite-le doucement à essayer 30 secondes demain, sans pression »
   - Si `.partial` → ne mentionne pas
   - **Pas de jugement, pas de score** — formulation chaleureuse

**Validation Bloc 3** : tu lances un rituel, tu laisses tourner les 60s → state = `.completed`, card Dashboard affiche « Présence prise ce matin ». Tu re-lance, skip immédiat → state = `.skipped`, card affiche « Pas de présence ce matin ».

---

### Bloc 4 — HealthKit Sleep service (~2h, scope défensif strict)

⚠️ **Règle dure** : ce bloc doit pouvoir être **débranché en 5 minutes** si tout part en sucette. Le reste de l'app doit continuer à marcher avec `snapshot.sleep == nil`.

1. **Entitlement** : ajoute `com.apple.developer.healthkit` à `Apple/lumen/lumen.entitlements`. Si le fichier n'existe pas, créé-le et lie-le dans le `.pbxproj`.

2. **Info.plist** : ajoute `NSHealthShareUsageDescription` :
   > « Lumen lit tes données de sommeil pour enrichir ta synthèse matinale. Aucune donnée n'est transmise. »
   
   **Pas** de `NSHealthUpdateUsageDescription` — on ne fait que lire.

3. **Crée** `Apple/lumen/Domain/Entities/SleepSummary.swift` :

   ```swift
   struct SleepSummary: Sendable, Codable {
       let bedtime: Date
       let wakeTime: Date
       let totalAsleep: TimeInterval
       let deep: TimeInterval        // .asleepDeep
       let rem: TimeInterval         // .asleepREM
       let core: TimeInterval        // .asleepCore
       let awake: TimeInterval       // brief awakenings
       
       var quality: SleepQuality {
           // Heuristique simple, pas de modèle scientifique
           switch totalAsleep {
           case ..<5*3600:  return .low
           case ..<7*3600:  return .medium
           default:         return .high
           }
       }
   }
   
   enum SleepQuality: String, Sendable, Codable { case low, medium, high }
   ```

4. **Crée** `Apple/lumen/Domain/Protocols/SleepHealthProviding.swift` :

   ```swift
   protocol SleepHealthProviding: Sendable {
       /// Returns nil if HealthKit unavailable, not authorized, or no data for last night.
       /// MUST NOT throw under normal conditions — return nil instead.
       func fetchLastNight() async -> SleepSummary?
       
       /// Triggers the system permission dialog. Caller must handle UI feedback.
       /// Returns true if granted, false otherwise.
       func requestAuthorization() async -> Bool
       
       var isAuthorized: Bool { get async }
   }
   ```

5. **Crée** `Apple/lumen/Infrastructure/Health/SleepHealthService.swift` :

   ```swift
   import Foundation
   #if canImport(HealthKit)
   import HealthKit
   #endif
   
   final class SleepHealthService: SleepHealthProviding {
   #if canImport(HealthKit)
       private let store = HKHealthStore()
   #endif
       
       var isAuthorized: Bool {
           get async {
   #if canImport(HealthKit)
               guard HKHealthStore.isHealthDataAvailable() else { return false }
               let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
               return store.authorizationStatus(for: type) == .sharingAuthorized
   #else
               return false
   #endif
           }
       }
       
       func requestAuthorization() async -> Bool {
   #if canImport(HealthKit)
           guard HKHealthStore.isHealthDataAvailable() else { return false }
           let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
           do {
               try await store.requestAuthorization(toShare: [], read: [type])
               return await isAuthorized
           } catch {
               return false
           }
   #else
           return false
   #endif
       }
       
       func fetchLastNight() async -> SleepSummary? {
   #if canImport(HealthKit)
           guard await isAuthorized else { return nil }
           // Query: last 24h, group by stage, compute durations
           // ... implémentation classique HKSampleQuery / HKCategoryValueSleepAnalysisAsleep*
           // Si l'utilisateur dort avec son iPhone seul (pas Watch), il n'aura que .inBed et .asleepUnspecified
           // Dans ce cas : map .asleepUnspecified → core, set deep/rem à 0
           // Si aucune sample sur les dernières 24h → return nil
           // ...
   #else
           return nil
   #endif
       }
   }
   ```

   Implémente la query complètement. Documente avec des commentaires pourquoi chaque choix (en particulier le mapping `.asleepUnspecified` → core).

6. **Modifie** `Apple/lumen/App/CompositionRoot.swift` :
   - Ajoute `let sleepService: any SleepHealthProviding`
   - Init : `self.sleepService = SleepHealthService()`
   - Passe à `BuildDashboardSnapshot`

7. **Privacy Manifest** : si `Apple/lumen/PrivacyInfo.xcprivacy` existe, ajoute la déclaration HealthKit. Sinon ne le crée pas — c'est App Store Connect qui te demandera plus tard, hors scope V1.

8. **UI dans `DashboardHomeView`** : si la card Sommeil est tappée et `!isAuthorized` :
   - Show alert ou half-sheet : « Lumen peut lire ton sommeil depuis Apple Santé pour enrichir ta synthèse. Tes données restent sur ton téléphone. »
   - CTA « Autoriser » → `await sleepService.requestAuthorization()`
   - Si granted → trigger `BuildDashboardSnapshot.refresh()`
   - Si refusé → ferme la modale, card reste sur CTA

**Validation Bloc 4** :
- Sur simulator : `HKHealthStore.isHealthDataAvailable()` retourne `true` mais aucune donnée → `fetchLastNight()` retourne `nil`. Card Sommeil affiche le CTA. **L'app ne crash pas, le rituel marche normalement.**
- Sur device réel iPhone (Apple Watch ou tracking iPhone) : tu fais une nuit, puis tu lances l'app, tap sur la card Sommeil, autorises, et la card se remplit avec les données du shape `7h 12m · qualité moyenne`.

**Si Bloc 4 dérape** : tu commentes les 3 lignes dans `CompositionRoot` qui injectent `sleepService`, tu hardcodes `snapshot.sleep = nil`, et tu commit ce que tu as. La card affiche le CTA en permanence — c'est dégradé mais ça ne casse rien d'autre.

---

### Bloc 5 — Mise à jour Maestro flow + tests Domain (~30 min)

1. **Modifie** `Apple/.maestro/flows/smoke/04-ritual-happy-path.yaml` :
   - Q1 Mood : inchangé
   - Q2 Energy (NEW) : ajoute le bloc :
     ```yaml
     - assertVisible: "Quelle énergie"
     - tapOn:
         id: "energy-3"
     - tapOn: "Suivant"
     ```
   - Q3 Priority : inchangé (était Q2)
   - Q4 Gratitude : inchangé (était Q3) — c'est maintenant la dernière étape, le bouton après devient « Voir ma synthèse »
   - **Supprime** le bloc Q4 Intention (lignes 42-48 de la version actuelle)

2. **Tests Domain à ajouter** dans `Apple/lumenTests/Domain/` :
   - `BuildDashboardSnapshotTests.swift` : 4 cas — full ritual / no ritual / sleep authorized / sleep not authorized
   - `PresenceStateTests.swift` : 3 cas — completed / partial / skipped logic from elapsed time
   - `SleepHealthServiceMockTests.swift` : utilise un mock `SleepHealthProviding` qui retourne nil ou un `SleepSummary` fixé

3. **Update doc** :
   - `Project/02_product/user_stories/dashboard.md` : réécris US-D2 avec le mapping V2 (mood, energy, priority, gratitude, presence, sleep)
   - `Project/02_product/user_stories/questionnaire.md` : update l'ordre des Q (Mood → Energy → Priority → Gratitude), retire toute mention de Q4 Intention
   - `Design/palo-docs/ARCHITECTURE.md` : update le schéma de flow rituel
   - **Aucune** mention de V1.1, post-PALO, ou roadmap dans ces docs

---

### Bloc 6 — Polish Audio Player + Ask Lumen Sheet (~30 min)

Aligne 2 composants existants sur les nouveaux mockups V2. Pas de logique métier touchée — uniquement visuel.

#### 6.1 — `ListenPlayer.swift` (audio player de la synthèse IA)

1. **Lis** `Apple/lumen/Shared/DesignSystem/Components/ListenPlayer.swift` pour comprendre la structure actuelle (props, états, layout)
2. **Lis** la section correspondante dans le mockup V2 (`03-mockups.html` § Synthèse IA, ou screens.jsx composant `ListenPlayer` / équivalent)
3. **Identifie le diff visuel** : forme de la barre de progression, position des boutons play/pause, treatment des timestamps, état idle vs playing vs paused, couleurs accent
4. **Applique le diff** en modifiant le SwiftUI sans toucher :
   - Les bindings `@State`, `@Binding`, ViewModel callbacks
   - Les `accessibilityIdentifier` (`synthesis-listen-button`, `synthesis-progress-bar`, etc. — utilisés par les flows Maestro)
   - La logique de play/pause/seek
5. **Validation** : screenshot le ListenPlayer dans le simulator, compare visuellement au mockup. Si tu vois une divergence, c'est un bug.

#### 6.2 — `AskLumenView.swift` + `AskLumenViewModel.swift` (sheet Ask Lumen)

1. **Lis** `Apple/lumen/Features/AskLumen/AskLumenView.swift` et `AskLumenViewModel.swift`
2. **Lis** la section correspondante dans le mockup V2 (`03-mockups.html` § Ask Lumen, ou composant `AskLumen` dans screens.jsx)
3. **Identifie le diff visuel** : layout input + send button, présentation de la réponse IA, scroll behavior, hierarchy texte
4. **Applique le diff** en gardant intacts :
   - L'intégration avec le waterfall AI (`AskLumenViewModel` reste connecté au même use case)
   - Les `accessibilityIdentifier` `ask-lumen-fab`, `ask-lumen-input`, `ask-lumen-send`, `ask-lumen-response`
   - Le rate limiting et les bindings au `RateLimiter`
5. **Validation** : trigger le flow Ask Lumen depuis le Dashboard (FAB) en simulator, compare au mockup.

**Notes pour les 2 polishes** :
- Si le diff visuel touche un composant partagé (ex : tu remplaces `PrimaryCTA` par autre chose), **stoppe et signale** — un changement de composant partagé impacte d'autres écrans, hors scope.
- Si le mockup V2 utilise des nouveaux tokens (couleur, espacement, radius) qui n'existent pas dans `Apple/lumen/Shared/DesignSystem/`, ajoute-les dans le fichier approprié (`Spacing.swift`, `Typography.swift`, etc.) avec un nom cohérent.

**Validation Bloc 6** : `ListenPlayer` et `AskLumenView` rendent à l'identique du mockup V2 sur simulator. Aucun test cassé. Maestro flows `08-synthesis-listen-tts.yaml` et `10-ask-lumen-modal.yaml` continuent à passer.

---

## Ce qu'il NE faut PAS faire

- **Ne pas** ajouter de nouvelle feature au-delà de cette tâche (pas d'historique sommeil 7 jours, pas de chart, pas de comparaison hier/aujourd'hui — c'est V1.5+)
- **Ne pas** ajouter d'intégration HealthKit *write* (Mindful Sessions, etc.) — read-only sleep uniquement
- **Ne pas** demander la permission HealthKit au lancement de l'app — uniquement quand l'utilisateur tape la card Sommeil
- **Ne pas** bloquer le rituel sur HealthKit — la fetch sleep est asynchrone et non-bloquante au build du dashboard
- **Ne pas** mentionner V1.1, roadmap, post-PALO dans le code, les commentaires, ou la doc
- **Ne pas** renommer les fichiers View existants — juste réordonner dans le ViewModel
- **Ne pas** committer ; laisse en working tree, je commit après revue

## Validation finale

```bash
# Build
xcodebuild -workspace Lumen.xcworkspace -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20

# Tests
xcodebuild test -workspace Lumen.xcworkspace -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30

# Maestro
./scripts/test_maestro.sh smoke
```

Les 5 flows smoke doivent passer. Les nouveaux tests Domain doivent passer. Build clean.

## Output attendu

Rapport ≤ 250 mots :
- Status par bloc (✅ / ⚠️ partiel avec raison / ❌ non livré)
- Liste fichiers créés / modifiés
- Pass count tests (avant / après)
- **Si Bloc 4 HealthKit a dérapé** : dis-le franchement, dis ce qui marche et ce qui est commenté/débranché. Pas de honte à débrancher — l'app doit shipper le 11 mai même sans HealthKit.
- Une note honnête : ce qui t'inquiète encore, ou ce que tu n'as pas su trancher.
