# ADR-008 — UI testing avec Maestro

## Statut
Accepté (2 mai 2026)

## Contexte

Le brief PALO mentionne :
- Tests Domain ≥ 60 % couverture (unit XCTest)
- "1-2 XCUITest pour parcours critiques (optionnel V1)"

On veut élever la rigueur de testing UI sans tomber dans le piège du test brittle XCUITest. Maestro émerge comme standard 2026 pour les UI tests cross-platform mobile, avec une syntaxe déclarative YAML beaucoup plus maintenable que XCUITest.

## Options évaluées

### Option A — XCUITest seul
- ✅ Apple-natif, intégration Xcode profonde
- ✅ Tests sur device réel (utile pour alarme background)
- ❌ Verbosité Swift, fragile sur les changements UI
- ❌ Apprentissage long
- ❌ Pas cross-platform (Android future blocked)

### Option B — Maestro seul
- ✅ Syntaxe YAML déclarative, lisible et maintenable
- ✅ Cross-platform (Android future ready)
- ✅ Zero-wait automatique (gère animations + network)
- ❌ **iOS simulators only** (en mai 2026) — pas de tests sur device réel
- ❌ Limites pour tester micro réel + alarme background

### Option C — Maestro + XCUITest minimal
- ✅ Maestro pour 90 % des flows UI (lisible, rapide à écrire)
- ✅ XCUITest pour les 2-3 cas qui nécessitent device réel (alarme background, micro)
- ⚖️ Double stack à maintenir mais usage clairement compartimenté

## Décision

**Option C — Maestro + XCUITest minimal.**

| Layer | Tool | Coverage |
|---|---|---|
| Domain logic (use cases, services, rate limiter, waterfall AI) | **XCTest** | ≥ 60 % (contrainte brief) |
| UI flows (rituel, navigation, settings, Q3/Q4 typing fallback) | **Maestro** | ~15-20 flows YAML |
| Hardware-dependent (alarme background, micro réel, AVAudioSession real-device) | **XCUITest** | 2-3 tests max, device réel |

## Rationale

**Pourquoi Maestro plutôt que XCUITest seul ?**
1. **Lisibilité** : un flow YAML de 20 lignes vs ~150 lignes Swift XCUITest pour le même test.
2. **Maintenance** : changement UI = ajustement YAML (1 ligne) vs refactor du test Swift entier.
3. **Cross-platform** : si V2 Android, on ré-utilise les flows.
4. **Zero-wait** : Maestro gère automatiquement les animations + délais network, on n'a pas à `sleep`.
5. **Studio visual** : prototype visuel de tests, accélère l'écriture.

**Pourquoi compléter avec XCUITest ?**
- Alarme background : nécessite UNUserNotificationCenter sur device réel pour valider la fiabilité (impossible en simulator).
- Micro permission + recognition : comportement différent simulator vs device réel.
- AVAudioSession : ducking et route changes ne se testent réalistement qu'en condition réelle.

## Setup

### Local dev

```bash
brew tap mobile-dev-inc/tap && brew install mobile-dev-inc/tap/maestro
# Verify Java 17+ : java -version
```

### CI integration

**Xcode Cloud** : pas de support natif Maestro à ce jour. Workaround :
1. Ajouter un script `ci_post_xcodebuild.sh` qui télécharge Maestro et lance les flows post-build.
2. Coût : +5-10 min par build CI, marginal.

**Alternative** : déclencher Maestro Cloud (managed infra) sur push, en parallèle du build Xcode Cloud. Plus cher (~$100/mois) mais parallel + résultats centralisés.

V1 : on commence avec **Maestro local** (pas de CI), Sprint 3 on ajoute le hook CI si temps.

## Scope V1 PALO

### Flows à implémenter (priorité)

**Smoke (5 flows, run sur chaque PR)** — voir `Project/04_tech/testing/maestro-scenarios.md` :
1. `app-launch` — splash + landing screen detection
2. `onboarding-complete` — happy path onboarding
3. `create-alarm` — création d'une alarme
4. `ritual-happy-path` — rituel complet (sans vraie alarme — démarrage manuel via deep link)
5. `settings-export-json` — export monitoring éthique

**Regression (10 flows, run weekly sur main)** :
6. `snooze-flow`
7. `voice-q3-typing-fallback` (le voice réel via XCUITest)
8. `synthesis-listen-tts`
9. `synthesis-offline-queued`
10. `ask-lumen-modal`
11. `settings-byo-key`
12. `settings-voice-toggle`
13. `settings-sound-picker`
14. `rate-limit-message`
15. `dark-light-mode-toggle`

**Edge cases (5 flows)** :
16. `permissions-mic-refused`
17. `permissions-notif-refused`
18. `reduce-motion-on`
19. `app-background-resume`
20. `byo-key-invalid`

### XCUITest minimal (3 tests) :
- `BackgroundAlarmTest` — programmer alarme +5 s, mettre app en background, attendre notification, valider le tap-Snooze.
- `MicPermissionTest` — flow Q3 voice avec micro réel + reconnaissance vocale on-device.
- `AudioSessionConflictTest` — démarrer Spotify, déclencher alarme, valider que `.duckOthers` fonctionne.

## Effort estimé

| Tâche | Effort |
|---|---|
| Setup Maestro CLI + first flow | 0.25 j |
| 5 flows smoke (priorité Sprint 1-2) | 1 j |
| 10 flows regression (Sprint 3 si temps, sinon V1.1) | 1.5 j |
| 5 flows edge cases (V1.1) | 1 j |
| 3 XCUITest hardware-deps (Sprint 3) | 0.75 j |
| CI integration Xcode Cloud (Sprint 3) | 0.5 j |
| **Total V1 PALO (smoke + 3 XCUITest + setup)** | **~2 j** |
| **Total full coverage V1.1** | **~5 j** |

V1 PALO scope : **smoke 5 flows Maestro + 3 XCUITest hardware**, démontre la rigueur de testing sans déraper la deadline. Le reste en V1.1.

## Conséquences

### Positives
- Couverture UI beaucoup plus rapide à atteindre que XCUITest seul
- Maintenance 5x plus simple (YAML vs Swift)
- Préparation Android future quasi-gratuite
- Démontre une stack de testing moderne en soutenance Sami

### Négatives
- Double stack à maintenir (XCTest + Maestro + XCUITest minimal)
- Dépendance Java 17 pour run Maestro (overhead env)
- iOS simulator only = certains tests pas couvrables par Maestro

### Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Maestro change syntaxe entre versions | Pin la version dans CI : `maestro@1.x.y` |
| Java 17 non installé chez Sami pour reviewer | Documenter le setup dans README, fournir un `Makefile` avec `make test-ui` qui setup tout |
| Maestro ne peut pas tester micro réel | XCUITest dédié, plus quelques mocks dans le code Domain |
| CI Xcode Cloud lent à intégrer Maestro | Repousser CI integration en V1.1, run local en V1 |

## Références

- [Maestro Documentation](https://docs.maestro.dev/)
- [Maestro Studio](https://docs.maestro.dev/getting-started/maestro-studio)
- `Project/04_tech/testing/maestro-scenarios.md` — flows YAML détaillés
- `Apple/.maestro/flows/` — fichiers YAML exécutables
