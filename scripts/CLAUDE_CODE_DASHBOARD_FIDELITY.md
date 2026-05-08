# Claude Code task — Dashboard 3 états · haute fidélité visuelle · wired to data

> **Pour l'utilisateur** : ouvre ce dossier dans Claude Code et passe ce fichier comme prompt initial.
> **Scope strict** : refondre **uniquement le Dashboard** pour qu'il matche les mockups V2 à 100 %, dans ses 3 états, avec wiring data correct. **Aucun autre écran n'est touché.** Aucun fichier n'est créé hors de ceux listés.

---

## Étape 0 — La source de vérité visuelle

**Avant d'écrire la moindre ligne de SwiftUI, lis intégralement ces fichiers** :

### Mockups Claude Design (canoniques)

- **URL Claude Design (référence visuelle)** : https://api.anthropic.com/v1/design/h/tZ9OZLgGaP6cjdLtzuXeeg?open_file=03-mockups.html
- **Fichiers locaux à lire** (synchronisés le 8 mai 2026 par Haithem depuis Claude Design — sync complet vérifié) :
  - `Design/designs/03-mockups.html` — fichier mockup principal (198 LOC). Section « Dashboard · 3 états » à lire en priorité.
  - **`Design/designs/screens/screens-shell.jsx`** — **CONTIENT LE DASHBOARD** : `DashboardEmpty`, `DashboardIdle`, `DashboardPost`, `PresenceCard`, `SleepCard`, `SleepPermissionSheet`, ainsi que `OnboardingWelcome/Pitch/Permissions/Alarm`, `AlarmEdit`, `AlarmRinging`, `PresenceTimer`, `CategoryDetail`, `AskLumen`. **C'est ICI que tu lis la spec Dashboard pixel par pixel** (53 KB, ~1000 LOC).
  - `Design/designs/screens/screens-flow.jsx` — composants questionnaire (Q1-Q4) + Synthesis + Settings (809 LOC). **PAS le Dashboard**, mais utile pour comprendre le pattern de composition.
  - `Design/designs/screens/_chrome.jsx` — chrome partagé (StatusBar, HomeIndicator, KineticTitle, MoodGlyph) utilisé par tous les écrans (182 LOC).
  - `Design/designs/screens/styles.css` — feuille de style globale (987 LOC) — toutes les classes CSS utilisées par les composants JSX. Utile pour les traduire en SwiftUI modifiers.
  - `Design/designs/02-design-system.html` — design system (couleurs, typo, spacing)
  - `Design/designs/handoff/tokens.json` — design tokens à respecter strictement
  - `Design/designs/handoff/sections/screens.html` — handoff section spec écrans
  - `Design/designs/handoff/sections/components.html` — handoff section composants design system
  - `Design/designs/handoff/sections/tokens.html` — handoff section tokens
  - `Design/designs/handoff/CLAUDE.md` — instructions handoff dédiées (lis-le, peut contenir des contraintes additionnelles)
  - `Design/design-kit/19_workflow_v2.md` — brief design qui a guidé la production

**Note sur `IdleHeroCard`** : il n'existe pas comme composant standalone — son JSX est inliné directement dans `function DashboardIdle()` autour de la ligne 176 de `screens-shell.jsx`. Reproduis la même approche en SwiftUI (sous-vue interne ou `@ViewBuilder`).

**Si les fichiers locaux divergent de l'URL Claude Design, signale-le et stoppe. Ne pas inventer.**

### Règle d'or

Toute divergence visuelle entre ton implémentation Swift et le mockup HTML est un bug à corriger. Tu n'inventes ni hiérarchie, ni typo, ni spacing — tout est dans le mockup. Tu reproduis fidèlement avec les composants design system existants.

---

## Contexte produit

Le Dashboard a 3 états mutuellement exclusifs :

| État | Condition de bascule | Contenu |
|---|---|---|
| **Empty** | `!hasAnyAlarm` (jamais d'alarme programmée — premier lancement après onboarding skippé, ou alarmes toutes supprimées) | Hero illustratif + copy d'invitation + PrimaryCTA « Programmer mon premier réveil » |
| **Idle** | `hasAnyAlarm && !hasRitualToday` (alarme existante, mais rituel pas encore fait aujourd'hui) | Hero card « Démarre ton rituel » + 6 cards en preview désaturées + AskLumen FAB |
| **Post-rituel** | `hasRitualToday` (rituel complété aujourd'hui) | 6 cards remplies (Humeur, Énergie, Priorité, Gratitude, Présence, Sommeil) + AskLumen FAB |

Le ViewModel `DashboardHomeViewModel` calcule `hasAnyAlarm` (depuis `AlarmRepository.fetchAll`) et `hasRitualToday` (depuis `RitualRepository.fetchToday` → snapshot non-nil). C'est déjà câblé, ne le casse pas.

---

## Mission

### Bloc unique — Refonte du Dashboard à haute fidélité

**Fichiers que tu peux modifier (et seulement ceux-là)** :

- `Apple/lumen/Features/Dashboard/DashboardHomeView.swift` (258 LOC actuels)
- `Apple/lumen/Features/Dashboard/DashboardHomeViewModel.swift` (82 LOC) — uniquement si nécessaire pour exposer une nouvelle propriété computed (ex : `displayState: DashboardState` enum)
- `Apple/lumen/Features/Dashboard/IdleHeroCard.swift` (105 LOC) — pour aligner le hero card sur le mockup
- `Apple/lumen/Shared/DesignSystem/Components/DashboardCard.swift` (125 LOC) — uniquement si le DashboardCard component doit gagner des variantes (ex : `state: .filled | .preview`) pour l'état Idle désaturé

**Fichiers à NE PAS toucher** :

- `Apple/lumen/Domain/...` — entités et use cases inchangés
- `Apple/lumen/Data/...` — repositories inchangés
- `Apple/lumen/Infrastructure/...` — services inchangés (HealthKit, Notifications, Audio, Voice)
- `Apple/lumen/Features/Dashboard/CategoryDetailView.swift` — détail catégorie inchangé
- `Apple/lumen/Features/Dashboard/SleepPermissionSheet.swift` — half-sheet permission HealthKit déjà alignée, ne pas toucher
- Tous les autres fichiers de `Features/`, `Shared/`, `App/`

**Aucun nouveau fichier ne doit être créé sauf si absolument indispensable.** Si tu penses devoir créer un fichier, signale-le avec justification avant.

---

## État Empty — détails

Quand `viewModel.hasAnyAlarm == false`, l'écran affiche :

- **Header** : eyebrow caption uppercase « PREMIER MATIN » (ou ce que dit le mockup), pas de titre « Aujourd'hui. »
- **Hero** : illustration / typo serif display 48pt « Ton premier matin t'attend. » (texte exact selon mockup)
- **Sous-titre** : body 17pt text-secondary, copy d'invitation depuis le mockup
- **PrimaryCTA full-width** : « Programmer mon premier réveil » (texte exact mockup) — tap déclenche navigation vers `AlarmEditView` en mode création
- **Pas de cards 6 catégories** dans cet état
- **Pas de FAB Ask Lumen** dans cet état (rien à demander, pas de contexte)
- **Tab bar bas** présente, inchangée

Accessibility :
- Container : `accessibilityIdentifier("dashboard-screen")` + `accessibilityLabel("Dashboard premier lancement")`
- CTA : `accessibilityIdentifier("dashboard-empty-cta")`

---

## État Idle — détails

Quand `viewModel.hasAnyAlarm && !viewModel.hasRitualToday` :

- **Header** : eyebrow uppercase de la date « VENDREDI 8 MAI » + serif display « Aujourd'hui. »
- **IdleHeroCard** (composant existant) : background distinctif, copy « Tu n'as pas encore fait ton rituel ce matin », bouton GhostCTA « Démarrer le rituel » (tap → trigger navigation rituel via `RootView.RitualFlowState = .timer` ou équivalent)
- **6 cards en preview** : grille 2×3, mêmes cards que post-rituel mais **désaturées** (opacity 0.4 ou variante visuelle dédiée — voir mockup pour le treatment exact). Caption visible (HUMEUR, ÉNERGIE, etc.) mais value remplacée par un dash subtle ou un placeholder inerte.
- **Hauteur de card uniforme** : ~140pt comme en post-rituel
- **AskLumen FAB** : visible (le user peut demander des conseils même sans rituel)
- **Tab bar** : inchangée

Accessibility :
- Container : `accessibilityIdentifier("dashboard-screen")`
- IdleHeroCard CTA : `accessibilityIdentifier("ritual-cta")`
- Chaque card preview : `accessibilityIdentifier("dashboard-card-{mood,energy,priority,gratitude,presence,sleep}")` + flag `.preview`

---

## État Post-rituel — détails

Quand `viewModel.hasRitualToday` :

- **Header** : eyebrow uppercase date + serif display « Aujourd'hui. »
- **Pas de IdleHeroCard**
- **Grille 2×3 de 6 cards remplies**, dans l'ordre exact :

| Pos | Card | Caption | Value (depuis `snapshot`) |
|---|---|---|---|
| 1,1 | Humeur | `HUMEUR` | `snapshot.mood?.displayName` (ex « Posé ») en serif italic |
| 1,2 | Énergie | `ÉNERGIE` | `snapshot.energy?.displayName` (ex « Bien chargé ») en serif italic |
| 2,1 | Priorité | `PRIORITÉ` | `snapshot.priority?.displayName` (ex « Énergie ») en serif italic |
| 2,2 | Gratitude | `GRATITUDE` | `snapshot.gratitude` truncate 2 lignes max, serif italic |
| 3,1 | Présence | `PRÉSENCE` | selon `snapshot.presence` : completed → « 60 secondes prises », partial → « Quelques secondes », skipped → « Pas de présence ce matin » (italic, text-secondary) |
| 3,2 | Sommeil | `SOMMEIL` | si `snapshot.sleep != nil` → durée + qualité (« 7 h 12 min · qualité moyenne ») ; sinon → CTA « Active Apple Santé » avec icône heart, qui ouvre `SleepPermissionSheet` au tap |

- **AskLumen FAB** visible
- **Tab bar** inchangée
- **Pas de placeholder « — »** : si une valeur est `nil` dans le snapshot post-rituel, c'est un bug en amont du Dashboard. Le Dashboard ne masque pas le bug — affiche un état dégradé minimal (italic text-tertiary « non renseigné ») et logger un warning console.

Accessibility :
- Container : `accessibilityIdentifier("dashboard-screen")`
- Cards : `accessibilityIdentifier("dashboard-card-{mood,energy,priority,gratitude,presence,sleep}")`
- AskLumen FAB : `accessibilityIdentifier("ask-lumen-fab")` (existe déjà, inchangé)

---

## Wiring data (déjà câblé, à vérifier)

`DashboardHomeViewModel.load()` doit :

1. Lire `alarms = await alarmRepository.fetchAll()` → `hasAnyAlarm = !alarms.isEmpty`
2. Lire `hasRitualToday` :
   - Soit via `ritualRepository.fetchToday() != nil`
   - Soit via le UserDefault `lumen.hasAnyRitual` si la repo est plus simple — utilise ce qui est déjà en place dans le ViewModel actuel
3. Si `hasRitualToday`, appeler `buildDashboardSnapshot.execute()` qui retourne un `DashboardSnapshot` avec mood, energy, priority, gratitude, presence, sleep — **garde le call existant intact**
4. Exposer un `displayState: DashboardState` computed sur le ViewModel :
   ```swift
   enum DashboardState { case empty, idle, postRitual }
   var displayState: DashboardState {
       if hasRitualToday { return .postRitual }
       if hasAnyAlarm { return .idle }
       return .empty
   }
   ```
5. La View switch sur `viewModel.displayState` pour rendre la bonne hierarchy.

**Ne casse pas** la logique de chargement async existante (`task { await viewModel.load() }`).

---

## Composants design system à utiliser

Tous existent déjà dans `Apple/lumen/Shared/DesignSystem/Components/`. Réutilise sans modifier (sauf `DashboardCard` qui peut gagner une variante `.preview`) :

- `DashboardCard` — la card de base, avec caption + value + optional icon. Si tu lui ajoutes une variante preview, fais-le proprement avec un enum `state: { filled, preview, empty }`
- `IdleHeroCard` — déjà existant, à aligner sur le mockup mais pas le réécrire from scratch
- `PrimaryCTA` — bouton plein full-width
- `GhostCTA` — bouton inline secondaire
- `AskLumenFAB` — bouton flottant en bas-droite
- `Eyebrow` — caption uppercase letter-spaced
- `KineticText` — pour l'animation typo si le hero Empty l'utilise (selon mockup)
- Tokens : `Spacing.m`, `Spacing.l`, `Spacing.xl` etc. ; `Typography.display`, `.title1`, `.body` ; `Sizes.cornerRadiusM` etc.

**Ne crée pas de nouveau composant.** Si le mockup contient un visuel non couvert par les composants existants, signale-le dans ton rapport.

---

## Validation

Avant de claim done :

1. **Build** : `xcodebuild -workspace Lumen.xcworkspace -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build` doit passer sans warning ni error
2. **Tests existants** : `xcodebuild test ...` continue à passer (pas de régression)
3. **Maestro smoke** : `./scripts/test_maestro.sh smoke` — les 5 flows passent. Le flow `04-ritual-happy-path.yaml` valide notamment les `accessibilityIdentifier` `dashboard-screen` + `dashboard-card-{mood,energy,priority,gratitude,presence,sleep}`.
4. **Validation visuelle** : tu lances l'app dans le simulator et tu reproduis les 3 états :
   - Empty : `clearState: true`, skip onboarding, atterris directement (ou ouvre via deep link `lumen://test/dashboard?state=empty`)
   - Idle : programme une alarme, n'effectue pas de rituel
   - Post-rituel : effectue le rituel complet (ou deep link `lumen://test/dashboard?state=ritual`)
   
   Pour chaque état, screenshot le simulator et compare visuellement au mockup correspondant. **Toute divergence visible à l'œil = bug à fixer.**
5. **Aucun fichier hors-scope modifié** : `git status` doit lister uniquement les fichiers listés en début de brief.

---

## Ce qu'il NE faut PAS faire

- **Ne pas** créer de nouveau composant design system (pas de `EmptyHeroCard`, `PreviewCard`, etc. — réutilise l'existant ou ajoute une variante au composant existant)
- **Ne pas** introduire de nouveau token (couleur, espacement, radius)
- **Ne pas** toucher aux Domain entities, Data repositories, Infrastructure services
- **Ne pas** réécrire le ViewModel from scratch — adapte si nécessaire, garde la logique métier intacte
- **Ne pas** changer les `accessibilityIdentifier` existants (les flows Maestro en dépendent)
- **Ne pas** ajouter de feature non prévue (animations décoratives, charts, comparaisons jours)
- **Ne pas** committer ; laisse en working tree
- **Ne pas** mentionner V1.1, post-PALO, roadmap dans le code ou les commentaires

---

## Output attendu

Rapport ≤ 200 mots :

- Liste des fichiers modifiés (chemins absolus depuis racine repo)
- Pour chaque état (Empty / Idle / Post-rituel) : 1 ligne « ✅ matche le mockup » ou « ⚠️ divergence sur X » (sois précis)
- Build status : ✅ / ❌ avec extrait erreur si ❌
- Tests count : `X tests, Y passed, Z failed`
- Maestro smoke : `5 / 5 passed` ou `X / 5 with failure on flow Y`
- **Si tu as dû créer un fichier ou ajouter un composant non listé** : explique pourquoi, en 1 phrase

Si tu détectes un bug non causé par cette tâche (ex : un crash existant, un mauvais wiring qui n'est pas dans le scope), **signale-le sans le fixer**. Hors scope.
