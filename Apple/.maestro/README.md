# Maestro UI Tests — Lumen Morning

## Setup

```bash
# Install Maestro
brew tap mobile-dev-inc/tap && brew install mobile-dev-inc/tap/maestro

# Verify Java 17+
java -version

# Build and install Lumen, then run Maestro
TAGS=smoke ./scripts/test_maestro.sh
```

## Run

```bash
# All configured flows
./scripts/test_maestro.sh

# Smoke flows only
TAGS=smoke ./scripts/test_maestro.sh

# Single flow
FLOW=Apple/.maestro/flows/smoke/01-app-launch.yaml ./scripts/test_maestro.sh

# Regression and edge flows by tag
TAGS=regression ./scripts/test_maestro.sh
TAGS=edge ./scripts/test_maestro.sh

# Maestro directly, after the app is already installed
maestro test Apple/.maestro
maestro test --include-tags=smoke Apple/.maestro

# Visual debugger
maestro studio
```

## Structure

```
.maestro/
├── README.md                ← this file
├── config.yaml              ← recursive flow discovery, skips _shared helpers
├── flows/
│   ├── smoke/               ← 5 critical flows, run on every PR
│   │   ├── 01-app-launch.yaml
│   │   ├── 02-onboarding-complete.yaml
│   │   ├── 03-create-alarm.yaml
│   │   ├── 04-ritual-happy-path.yaml
│   │   └── 05-settings-export-json.yaml
│   ├── regression/          ← 10 flows, run weekly on main
│   │   ├── 06-snooze-flow.yaml
│   │   ├── 07-voice-q3-typing-fallback.yaml
│   │   ├── 08-synthesis-listen-tts.yaml
│   │   ├── 09-synthesis-offline-queued.yaml
│   │   ├── 10-ask-lumen-modal.yaml
│   │   ├── 11-settings-byo-key.yaml
│   │   ├── 12-settings-voice-toggle.yaml
│   │   ├── 13-settings-sound-picker.yaml
│   │   ├── 14-rate-limit-message.yaml
│   │   └── 15-dark-light-mode-toggle.yaml
│   ├── edge-cases/          ← 5 flows, run weekly
│   │   ├── 16-permissions-mic-refused.yaml
│   │   ├── 17-permissions-notif-refused.yaml
│   │   ├── 18-reduce-motion-on.yaml
│   │   ├── 19-app-background-resume.yaml
│   │   └── 20-byo-key-invalid.yaml
│   └── _shared/             ← composable sub-flows (referenced via runFlow)
│       ├── quick-onboard.yaml
│       ├── back-to-dashboard.yaml
│       └── dismiss-system-permission.yaml
└── scripts/                 ← bash scripts for simctl manipulation
    ├── enable-airplane-mode.sh
    ├── disable-airplane-mode.sh
    ├── enable-reduce-motion.sh
    └── disable-reduce-motion.sh
```

## Runner output

`scripts/test_maestro.sh` writes generated reports and artifacts under ignored `build/` paths:

- `build/maestro/maestro-report.xml`
- `build/maestro/results/`
- `build/maestro/debug/`

The runner uses `scripts/qa_install.sh`, so `SIM_NAME`, `CONFIG`, and `REPORT_DIR` can be overridden through the environment.

## Path resolution conventions

Maestro resolves `runFlow:` relative to the **calling YAML file**.

- A flow in `flows/smoke/` referencing `_shared/` → `runFlow: ../_shared/foo.yaml`
- Flows in `_shared/` calling sibling sub-flows → `runFlow: ./bar.yaml`

If you move a flow between folders, double-check these relative paths.

## Required prereqs (debug build only)

Some flows assume the **Debug build of Lumen exposes test-only deep links**. Those app-side hooks are intentionally separate from the Maestro runner infrastructure.
See `Project/04_tech/testing/maestro-scenarios.md` for the planned list.

The BYO key flows run against DEBUG-only deterministic validation when launched with `isMaestro: "true"`, so they do not require real provider keys.

## Strategy

See `Project/04_tech/adr/ADR-008-maestro-ui-testing.md` for the full rationale (3-layer testing: XCTest Domain ≥60 % + Maestro UI + XCUITest hardware-dependent) and `Project/04_tech/testing/maestro-scenarios.md` for the source of truth (all flows YAML inline, kept in sync with the files in `flows/`).

## Limitations to know

- iOS = simulators only (no real device support). Hardware-dependent tests (background alarm, real mic, AVAudioSession real device) use **XCUITest** instead.
- Voice input (`SFSpeechRecognizer` real call) cannot be tested in Maestro — flows use the typing fallback.
- Apple Intelligence path is not testable on simulator (no A17 Pro hardware) — use real-device manual test.
- `runScript` executes JavaScript in current Maestro versions, so shell-based simulator setup is kept out of YAML flows.
