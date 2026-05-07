# ADR-008 — UI testing avec Maestro

## Statut
Accepté (2 mai 2026) · Révisé le 7 mai 2026 (suppression de la couche XCUITest, Maestro seul + test plan manuel device).

## Contexte

Le brief PALO mentionne :
- Tests Domain ≥ 60 % couverture (unit XCTest)
- "1-2 XCUITest pour parcours critiques (optionnel V1)"

On veut élever la rigueur de testing UI sans tomber dans le piège du test brittle XCUITest. Maestro est devenu le standard 2026 pour les UI tests cross-platform mobile, avec une syntaxe déclarative YAML beaucoup plus maintenable que XCUITest.

## Options évaluées

### Option A — XCUITest seul
- ✅ Apple-natif, intégration Xcode profonde
- ✅ Tests sur device réel (utile pour alarme background)
- ❌ Verbosité Swift, fragile sur les changements UI
- ❌ Apprentissage long
- ❌ Pas cross-platform

### Option B — Maestro seul
- ✅ Syntaxe YAML déclarative, lisible et maintenable
- ✅ Cross-platform (Android future ready)
- ✅ Zero-wait automatique (gère animations + network)
- ❌ iOS simulators only (en mai 2026) — pas de tests automatisés sur device réel
- ❌ Limites pour tester micro réel + alarme background sans hooks DEBUG

### Option C — Maestro + XCUITest minimal
- ✅ Maestro pour 90 % des flows UI
- ✅ XCUITest pour les 2-3 cas qui nécessitent device réel
- ❌ Double stack à maintenir, effort 0,75 j supplémentaire pour 3 tests
- ❌ Coordination Xcode Cloud + Maestro Cloud non triviale

## Décision

**Option B — Maestro seul, complété par un test plan manuel device réel.**

| Layer | Tool | Coverage |
|---|---|---|
| Domain logic (use cases, services, rate limiter, waterfall AI) | **Swift Testing** (XCTest moderne) | ≥ 60 % (contrainte brief) |
| UI flows (rituel, navigation, settings, Q3/Q4 typing fallback) | **Maestro** | 20 flows YAML (5 smoke + 10 regression + 5 edge) |
| Hardware-dépendant (alarme background, micro réel, AVAudioSession real device) | **Test plan manuel** | `Project/06_roadmap/test_plan_v1.md` + capture dans `test_report_latest.md` |

## Rationale

**Pourquoi Maestro plutôt que XCUITest seul ?**
1. **Lisibilité** : un flow YAML de 20 lignes vs ~150 lignes Swift XCUITest pour le même test.
2. **Maintenance** : changement UI = ajustement YAML (1 ligne) vs refactor du test Swift entier.
3. **Cross-platform** : si V2 Android, on ré-utilise les flows.
4. **Zero-wait** : Maestro gère automatiquement les animations + délais network, on n'a pas à `sleep`.
5. **Studio visuel** : prototype visuel de tests, accélère l'écriture.

**Pourquoi pas XCUITest pour le hardware-dépendant ?**
La rédaction de 3 XCUITest demande ~0,75 j de travail pour valider 3 scénarios (alarme background, micro réel, AudioSession). À ce coût, on couvre les mêmes scénarios par un **test plan manuel discipliné**, exécuté sur device réel à chaque release candidate, avec capture d'écrans et journal écrit dans `test_report_latest.md`. La discipline manuelle a été choisie parce que (a) l'effort dev est mieux investi sur les fixes des FAILs identifiés, (b) certains comportements (par ex. `.duckOthers` avec Spotify en arrière-plan) sont plus robustement validés à l'œil nu qu'avec une assertion XCUITest fragile.

## Setup

### Local dev

```bash
brew tap mobile-dev-inc/tap && brew install mobile-dev-inc/tap/maestro
java -version  # Maestro requires Java 17+
```

Lancer la suite : `./scripts/test_maestro.sh` (qui appelle `qa_install.sh` pour build + install + boot sim, puis `maestro test Apple/.maestro/flows/`).

### CI integration

`scripts/test_maestro.sh` peut être appelé depuis Xcode Cloud via `ci_post_xcodebuild.sh`. Coût : +5-10 min par build.

## Scope V1 PALO

### Flows implémentés (20 YAML)

**Smoke (5 flows, run sur chaque PR)** — voir `Project/04_tech/testing/maestro-scenarios.md` :
1. `01-app-launch` — splash + landing screen detection
2. `02-onboarding-complete` — happy path onboarding
3. `03-create-alarm` — création d'une alarme
4. `04-ritual-happy-path` — rituel complet (sans vraie alarme — démarrage manuel via deep link)
5. `05-settings-export-json` — export monitoring éthique

**Regression (10 flows)** : snooze, voice fallback typing, TTS listen, offline queued, ask lumen, BYO key, voice toggle, sound picker, rate limit, dark/light mode toggle.

**Edge cases (5 flows)** : permissions mic refused, permissions notif refused, reduce motion, app background resume, BYO key invalid.

### Test plan manuel hardware-dépendant

Trois scénarios documentés dans `Project/06_roadmap/test_plan_v1.md`, exécutés sur iPhone réel à chaque release candidate :

- **Alarme background** : programmer alarme +5 s, mettre app en background + lock device, attendre notification, valider tap-Snooze depuis lock screen.
- **Micro permission + reconnaissance** : flow Q3 voice avec micro réel + reconnaissance vocale on-device sur device.
- **AVAudioSession `.duckOthers`** : démarrer Spotify, déclencher alarme, valider que la musique ducke pendant l'alarme et reprend après Silence.

Chaque scénario est documenté avec capture d'écran ou screencast court dans `test_report_latest.md`.

## Effort

| Tâche | Effort |
|---|---|
| Setup Maestro CLI + first flow | 0.25 j |
| 5 flows smoke | 1 j |
| 10 flows regression | 1.5 j |
| 5 flows edge cases | 1 j |
| Test plan manuel hardware (3 scénarios documentés) | 0.25 j |
| **Total** | **~4 j** |

## Conséquences

### Positives
- Couverture UI rapide à atteindre, lisible, maintenable
- Zéro double stack à maintenir
- Préparation Android quasi-gratuite (mêmes flows YAML)
- Démontre une stack de testing moderne en soutenance

### Négatives
- Hardware-dépendant testé manuellement, pas de garantie CI
- iOS simulator only = certains comportements (real mic, route audio Bluetooth) non automatisés
- Dépendance Java 17 pour run Maestro

### Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Maestro change syntaxe entre versions | Pin la version dans CI : `maestro@1.x.y` |
| Régression hardware-dépendante non détectée | Discipline test plan manuel à chaque release, journal écrit |
| Java 17 non installé chez Sami | Documenté dans `Apple/.maestro/README.md`, `Makefile` avec `make test-ui` setup |

## Références

- [Maestro Documentation](https://docs.maestro.dev/)
- [Maestro Studio](https://docs.maestro.dev/getting-started/maestro-studio)
- `Project/04_tech/testing/maestro-scenarios.md` — flows YAML détaillés
- `Apple/.maestro/flows/` — fichiers YAML exécutables
- `Project/06_roadmap/test_plan_v1.md` — test plan manuel hardware
