# Maestro UI Test Scenarios — Lumen Morning

> Source de vérité pour les flows YAML Maestro.
> Implémentation : `Apple/.maestro/flows/`.
> Stratégie testing globale : voir `Project/04_tech/adr/ADR-008-maestro-ui-testing.md`.

## Setup

```bash
# Install
brew tap mobile-dev-inc/tap && brew install mobile-dev-inc/tap/maestro

# Verify Java 17+
java -version

# Run a single flow
maestro test Apple/.maestro/flows/smoke/01-app-launch.yaml

# Run a folder
maestro test Apple/.maestro/flows/smoke/

# Run all flows
maestro test Apple/.maestro/flows/

# Maestro Studio (visual debugger)
maestro studio
```

## Convention

- Chaque flow ouvre l'app avec `launchApp` (sauf si héritage via `runFlow`)
- Flows partagés (login, navigation) → `Apple/.maestro/flows/_shared/`
- Préférer `id:` (accessibility identifier) à `text:` quand possible — moins fragile aux changements de copy
- Tags : `tags: [smoke]`, `[regression]`, `[edge]` pour filter `maestro test --include-tags=smoke`
- AppId fixe : `com.highthem.lumen`
- Reset state entre tests : `clearState: true` au launch quand isolation requise

---

## Flows Smoke (5 critiques — run sur chaque PR)

### 01 — `app-launch.yaml`

```yaml
appId: com.highthem.lumen
tags: [smoke, launch]
---
- launchApp:
    clearState: true
- assertVisible:
    text: "Quelques minutes à toi."
    timeout: 3000
- assertVisible: "Commencer"
```

### 02 — `onboarding-complete.yaml`

```yaml
appId: com.highthem.lumen
tags: [smoke, onboarding]
---
- launchApp:
    clearState: true

# Welcome
- assertVisible: "Quelques minutes à toi."
- tapOn: "Commencer"

# Pitch
- assertVisible: "Cinq minutes."
- tapOn: "Suivant"

# Permissions
- assertVisible: "On a besoin"
- tapOn: "Continuer"
- runFlow: ../_shared/dismiss-system-permission.yaml

# Première alarme
- assertVisible: "À quelle heure"
- tapOn:
    id: "alarm-time-picker"
- tapOn: "Programmer"

# Land on Dashboard
- assertVisible: "Bonjour"
- assertVisible:
    id: "ritual-cta"
```

### 03 — `create-alarm.yaml`

```yaml
appId: com.highthem.lumen
tags: [smoke, alarm]
---
- launchApp:
    clearState: false   # garde l'onboarding fait

# Depuis dashboard, ouvre alarmes
- tapOn:
    id: "settings-button"
- tapOn: "Heure d'alarme"

# Form
- tapOn:
    id: "alarm-time-picker"
- inputText: "0700"
- tapOn: "Tous les jours de semaine"
- tapOn: "Aube"   # son
- tapOn: "Enregistrer"

# Verify
- assertVisible: "07:00"
- assertVisible: "Lun-Ven"
```

### 04 — `ritual-happy-path.yaml`

```yaml
appId: com.highthem.lumen
tags: [smoke, ritual]
env:
  RITUAL_DEEPLINK: "lumen://ritual/start"
---
- launchApp:
    clearState: false

# Trigger ritual via deep link (skip the real alarm)
- openLink: ${RITUAL_DEEPLINK}

# Timer présence (60s par défaut, on skip pour le test)
- assertVisible: "Présence"
- tapOn: "Passer"

# Q1 Mood — sélectionner "posé"
- assertVisible: "Comment tu te sens"
- tapOn:
    id: "mood-3"   # 3rd dot = posé
- tapOn: "Suivant"

# Q2 Priority — sélectionner Énergie
- assertVisible: "Qu'est-ce qui compte"
- tapOn: "Énergie"
- tapOn: "Suivant"

# Q3 Gratitude — fallback typing (Maestro can't mic)
- assertVisible: "Une gratitude"
- tapOn: "Écrire au clavier"
- inputText: "Le silence avant que les enfants se lèvent."
- hideKeyboard
- tapOn: "Suivant"

# Q4 Intention — typing fallback
- assertVisible: "Ton intention"
- tapOn: "Écrire au clavier"
- inputText: "présence"
- hideKeyboard
- tapOn: "Voir ma synthèse"

# Synthesis screen
- assertVisible:
    text: "Ton matin"
    timeout: 8000   # cloud AI call
- assertVisible:
    id: "synthesis-listen-button"
- tapOn: "Continuer vers le dashboard"

# Dashboard post-rituel
- assertVisible: "Aujourd'hui"
- assertVisible: "Intention"
```

### 05 — `settings-export-json.yaml`

```yaml
appId: com.highthem.lumen
tags: [smoke, settings, ethics]
---
- launchApp:
    clearState: false

- tapOn:
    id: "settings-button"

# Scroll to ethical monitoring section
- scrollUntilVisible:
    element: "Exporter mes données"

- tapOn: "Exporter mes données"

# ShareSheet expected
- assertVisible:
    text: "Lumen-ethical-export"
    timeout: 5000

# Dismiss share sheet
- tapOn: "Cancel"
```

---

## Flows Regression (10 — run weekly sur main)

### 06 — `snooze-flow.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, alarm]
env:
  ALARM_DEEPLINK: "lumen://alarm/test-ringing"
---
- launchApp:
    clearState: false

# Trigger alarm ringing UI via deep link
- openLink: ${ALARM_DEEPLINK}

- assertVisible: "07:00"
- tapOn: "Snooze 5 min"

# After snooze, expect normal app (alarm rescheduled)
- assertVisible: "Aujourd'hui"
- assertNotVisible: "07:00"
```

### 07 — `voice-q3-typing-fallback.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, voice, fallback]
env:
  RITUAL_DEEPLINK: "lumen://ritual/q3"
---
- launchApp:
    clearState: false

- openLink: ${RITUAL_DEEPLINK}

# Q3 voice par défaut → tap "Écrire au clavier"
- assertVisible: "Une gratitude"
- assertVisible:
    id: "mic-button"
- tapOn: "Écrire au clavier"
- assertVisible:
    id: "gratitude-textarea"

# Verify retour à la voix
- tapOn: "Tu peux aussi reparler"
- assertVisible:
    id: "mic-button"
```

### 08 — `synthesis-listen-tts.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, tts, voice]
env:
  SYNTHESIS_DEEPLINK: "lumen://ritual/synthesis-mock"
---
- launchApp:
    clearState: false

- openLink: ${SYNTHESIS_DEEPLINK}

# Synthesis ready, tap Listen
- assertVisible: "Ton matin"
- tapOn: "Écouter"

# Reading focus active : paragraphe 1 visible, autres dimmed
- assertVisible:
    id: "synthesis-block-0"
- assertVisible:
    id: "synthesis-progress-bar"

# Pause
- tapOn: "Pause"
- assertVisible: "Écouter"   # button revient à idle
```

### 09 — `synthesis-offline-queued.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, offline, queue]
---
# Set device airplane mode (Maestro hook iOS Settings)
- runScript:
    file: ../../scripts/enable-airplane-mode.sh

- launchApp:
    clearState: true

# Quick onboarding + ritual via deep links
- runFlow: ../_shared/quick-onboard.yaml
- openLink: "lumen://ritual/q4-direct"
- inputText: "présence"
- hideKeyboard
- tapOn: "Voir ma synthèse"

# Expect Queued state (no Apple Intelligence on simulator)
- assertVisible: "Ta synthèse arrive."
- assertVisible: "On te notifie au retour réseau"
- tapOn: "Aller au dashboard"

# Cleanup
- runScript:
    file: ../../scripts/disable-airplane-mode.sh
```

### 10 — `ask-lumen-modal.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, ai, ask-lumen]
---
- launchApp:
    clearState: false

- assertVisible: "Aujourd'hui"
- tapOn:
    id: "ask-lumen-fab"

- assertVisible: "Ask Lumen"
- inputText: "Comment garder l'énergie ?"
- tapOn:
    id: "ask-lumen-send"

- assertVisible:
    id: "ask-lumen-response"
    timeout: 8000

- tapOn: "Fermer"
- assertVisible: "Aujourd'hui"
```

### 11 — `settings-byo-key.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, settings, byo]
---
- launchApp:
    clearState: false

- tapOn:
    id: "settings-button"
- scrollUntilVisible:
    element: "Mode avancé"
- tapOn: "Mode avancé"

# BYO API key flow
- tapOn:
    id: "provider-anthropic"
- tapOn:
    id: "api-key-input"
- inputText: "sk-ant-fake-test-key-not-real"
- tapOn: "Tester la clé"

# Test should fail (fake key)
- assertVisible:
    text: "Clé invalide"
    timeout: 8000

# Test with valid placeholder (env-injected during test)
- tapOn:
    id: "api-key-input"
- eraseText: 50
- inputText: ${MAESTRO_TEST_ANTHROPIC_KEY}
- tapOn: "Tester la clé"
- assertVisible:
    text: "Clé valide"
    timeout: 8000

- tapOn: "Enregistrer"
- assertVisible: "Clé personnelle"
```

### 12 — `settings-voice-toggle.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, settings, voice]
---
- launchApp:
    clearState: false

- tapOn:
    id: "settings-button"
- scrollUntilVisible:
    element: "Mode vocal par défaut"
- tapOn:
    id: "voice-default-toggle"

# Verify Q3 default = typing (after toggle off)
- runFlow: ../_shared/back-to-dashboard.yaml
- openLink: "lumen://ritual/q3"
- assertVisible:
    id: "gratitude-textarea"   # typing par défaut maintenant
- assertNotVisible:
    id: "mic-button"   # micro masqué
```

### 13 — `settings-sound-picker.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, settings, audio]
---
- launchApp:
    clearState: false

- tapOn:
    id: "settings-button"
- tapOn: "Son"

# 5 alarmes disponibles
- assertVisible: "Aube"
- assertVisible: "Bois"
- assertVisible: "Marée"
- assertVisible: "Cloche"
- assertVisible: "Souffle"

# Preview au tap
- tapOn: "Bois"
- assertVisible:
    id: "sound-preview-playing"
    timeout: 2000
- tapOn: "Bois"   # 2nd tap = stop preview

# Save selection
- tapOn: "Choisir"
- assertVisible:
    text: "Bois"
```

### 14 — `rate-limit-message.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, rate-limit]
env:
  # State seed: 3 synthèses déjà faites today
  SEED_RATE_LIMIT_HIT: "true"
---
- launchApp:
    clearState: false

# Trigger ritual
- openLink: "lumen://ritual/q4-direct"
- inputText: "patience"
- hideKeyboard
- tapOn: "Voir ma synthèse"

# Expected rate limit
- assertVisible: "Reviens demain"
- tapOn: "Aller au dashboard"
- assertVisible: "Aujourd'hui"
```

### 15 — `dark-light-mode-toggle.yaml`

```yaml
appId: com.highthem.lumen
tags: [regression, settings, appearance]
---
- launchApp:
    clearState: false

- tapOn:
    id: "settings-button"
- tapOn: "Thème"

# Test all 3 modes
- tapOn: "Sombre"
- runFlow: ../_shared/back-to-dashboard.yaml
- takeScreenshot: theme-dark
- assertVisible:
    id: "dashboard-screen"

- tapOn:
    id: "settings-button"
- tapOn: "Thème"
- tapOn: "Clair"
- runFlow: ../_shared/back-to-dashboard.yaml
- takeScreenshot: theme-light

- tapOn:
    id: "settings-button"
- tapOn: "Thème"
- tapOn: "Système"
- assertVisible: "Système"
```

---

## Flows Edge cases (5 — run weekly sur main)

### 16 — `permissions-mic-refused.yaml`

```yaml
appId: com.highthem.lumen
tags: [edge, permissions, voice]
---
- launchApp:
    clearState: true
- runFlow: ../_shared/quick-onboard.yaml

- openLink: "lumen://ritual/q3"

- tapOn:
    id: "mic-button"

# System permission alert appears
- assertVisible:
    text: "would like to access the Microphone"
    timeout: 3000
- tapOn: "Don't Allow"

# Lumen falls back to typing without error
- assertNotVisible:
    text: "Erreur"
- assertVisible:
    id: "gratitude-textarea"
```

### 17 — `permissions-notif-refused.yaml`

```yaml
appId: com.highthem.lumen
tags: [edge, permissions, notif]
---
- launchApp:
    clearState: true

# Onboarding jusqu'à permissions
- tapOn: "Commencer"
- tapOn: "Suivant"
- assertVisible: "On a besoin"
- tapOn: "Continuer"

# System permission alert
- assertVisible:
    text: "Send You Notifications"
    timeout: 3000
- tapOn: "Don't Allow"

# Onboarding continue, message dégradé doux
- assertVisible: "Tu pourras activer plus tard"
- tapOn: "Suivant"
```

### 18 — `reduce-motion-on.yaml`

```yaml
appId: com.highthem.lumen
tags: [edge, a11y, motion]
---
- runScript:
    file: ../../scripts/enable-reduce-motion.sh

- launchApp:
    clearState: false
- openLink: "lumen://ritual/timer"

# Cercle respiration doit être statique
- assertVisible:
    id: "presence-circle"
- assertNotVisible:
    id: "presence-circle-animated"

# Cleanup
- runScript:
    file: ../../scripts/disable-reduce-motion.sh
```

### 19 — `app-background-resume.yaml`

```yaml
appId: com.highthem.lumen
tags: [edge, lifecycle]
---
- launchApp:
    clearState: false
- openLink: "lumen://ritual/q2"

- tapOn: "Énergie"

# Background l'app
- pressKey: Home

- waitForAnimationToEnd:
    timeout: 2000

# Reopen
- launchApp:
    clearState: false

# Should resume on Q2 (or offer reprise)
- assertVisible:
    text: "Reprendre ton rituel"
    timeout: 3000
- tapOn: "Reprendre"
- assertVisible: "Qu'est-ce qui compte"
```

### 20 — `byo-key-invalid.yaml`

```yaml
appId: com.highthem.lumen
tags: [edge, byo, error]
---
- launchApp:
    clearState: false

- tapOn:
    id: "settings-button"
- scrollUntilVisible:
    element: "Mode avancé"
- tapOn: "Mode avancé"

- tapOn:
    id: "provider-openai"
- tapOn:
    id: "api-key-input"
- inputText: "definitely-not-a-valid-key"
- tapOn: "Tester la clé"

# Error state
- assertVisible:
    text: "Clé invalide"
    timeout: 8000

# Save button disabled
- assertVisible:
    id: "save-button-disabled"
```

---

## Flows partagés (`_shared/`)

### `_shared/quick-onboard.yaml`

```yaml
appId: com.highthem.lumen
---
- tapOn: "Commencer"
- tapOn: "Suivant"
- tapOn: "Continuer"
- runFlow: ./dismiss-system-permission.yaml
- tapOn: "Programmer"
```

### `_shared/back-to-dashboard.yaml`

```yaml
appId: com.highthem.lumen
---
- pressKey: Back
- assertVisible: "Aujourd'hui"
```

### `_shared/dismiss-system-permission.yaml`

```yaml
appId: com.highthem.lumen
---
# Tries to allow if dialog appears, otherwise no-op
- runFlow:
    when:
      visible: "Allow"
    commands:
      - tapOn: "Allow"
```

---

## Scripts auxiliaires (`Apple/.maestro/scripts/`)

Les 4 scripts existent comme fichiers exécutables (chmod +x) dans `Apple/.maestro/scripts/` :

| Script | Contenu | Usage |
|---|---|---|
| `enable-airplane-mode.sh` | `xcrun simctl status_bar booted override --dataNetwork hide --wifiBars 0` | Avant flow `09-synthesis-offline-queued` |
| `disable-airplane-mode.sh` | `xcrun simctl status_bar booted clear` | Cleanup post-flow offline |
| `enable-reduce-motion.sh` | `xcrun simctl spawn booted defaults write com.apple.Accessibility ReduceMotionEnabled 1` (+ fallback `simctl ui ... --reduce-motion on`) | Avant flow `18-reduce-motion-on` |
| `disable-reduce-motion.sh` | `xcrun simctl spawn booted defaults write com.apple.Accessibility ReduceMotionEnabled 0` | Cleanup post-flow a11y |

Le path resolution Maestro est relatif au YAML qui appelle, donc depuis `flows/regression/*.yaml` ou `flows/edge-cases/*.yaml` les scripts sont référencés en `../../scripts/foo.sh`.

---

## Deep links pour les tests

L'app doit exposer ces deep links **uniquement dans la build Debug** (pas en prod) :

| Deep link | Effet |
|---|---|
| `lumen://ritual/start` | Démarre le timer présence (skip alarm) |
| `lumen://ritual/timer` | Saute directement au timer |
| `lumen://ritual/q3` | Saute directement à Q3 (avec Q1, Q2 mockées posé/Énergie) |
| `lumen://ritual/q4-direct` | Saute directement à Q4 (mock complet) |
| `lumen://ritual/synthesis-mock` | Affiche un écran synthèse avec contenu fictif (skip cloud call) |
| `lumen://alarm/test-ringing` | Affiche l'écran AlarmRinging |

À implémenter dans `Apple/lumen/App/AppDelegate.swift` ou `lumenApp.swift` avec un `#if DEBUG` strict.

---

## CI integration (V1.1)

### Option A — Xcode Cloud post-script
```bash
# ci_scripts/ci_post_xcodebuild.sh
if [ "$CI_XCODEBUILD_ACTION" = "test-without-building" ]; then
  brew install mobile-dev-inc/tap/maestro
  maestro test Apple/.maestro/flows/smoke/
fi
```

### Option B — GitHub Actions parallel
```yaml
# .github/workflows/maestro.yml
on: [push, pull_request]
jobs:
  maestro-smoke:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: mobile-dev-inc/action-maestro-cloud@v1
        with:
          api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
          app-file: build/lumen.app
          flows: Apple/.maestro/flows/smoke/
```

V1 : on commence local. V1.1 : on ajoute Option A pour intégrer aux runs Xcode Cloud.

---

## Notes pour la soutenance Sami

- Les tests Maestro = signal de modernité testing 2026 (rare en iOS où XCUITest reste dominant)
- Combo Maestro + XCUITest + XCTest = 3 layers couvrant tout (UI lisible, hardware, Domain)
- 5 smoke + 3 XCUITest = scope V1, le reste documenté pour V1.1
- Mention dans `Design/palo-docs/ARTIFACTS.md` que les tests UI sont déclaratifs YAML, accessibles aux non-Swift devs
