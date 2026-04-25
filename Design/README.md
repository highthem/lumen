# Design — Préparation et livrables

Tout ce qui touche au design produit pour Lumen, dans le repo (versionné).

## Structure

```
Design/
├── README.md           ← ce fichier
├── design-kit/         ← input pour Claude Design (Anthropic Labs)
│   ├── 00_PROMPT_TO_PASTE.md     (le prompt initial)
│   ├── 01_design_brief.md
│   ├── 02_mood_inspiration.md
│   ├── 03_style_guide.md
│   ├── 04_wireframes_spec.md
│   ├── 05_personas.md
│   ├── 06_pitch.md
│   ├── 07_flows.md
│   ├── 08_web_capture_targets.md ← URLs concurrents et inspirations
│   └── 09_handoff_to_claude_code.md ← workflow design → SwiftUI
└── palo-docs/          ← 5 docs PALO finalisées (R/ARCH/TECH/ETHICAL/ARTIFACTS)
    ├── README.md
    ├── ARCHITECTURE.md
    ├── TECHNICAL_DECISIONS.md
    ├── ETHICAL_MONITORING.md
    └── ARTIFACTS.md
```

## `design-kit/` — Input pour Claude Design (Anthropic Labs)

À utiliser dans **Claude Design** (Anthropic Labs, Claude Opus 4.7) — **pas un chat Claude classique**. Voir [annonce officielle](https://www.anthropic.com/news/claude-design-anthropic-labs).

**Pré-requis :**
- Abonnement Claude Pro / Max / Team / Enterprise
- Si Enterprise : activer Claude Design dans Organization settings
- Le repo `highthem/lumen` poussé sur GitHub (Claude Design peut le référencer comme codebase)

**Comment :**
1. Aller sur claude.ai → bouton "Claude Design" ou onglet Anthropic Labs
2. Nouvelle conversation
3. Coller le contenu de `design-kit/00_PROMPT_TO_PASTE.md` dans le premier message
4. Drag & drop les 9 autres fichiers (`01_*.md` à `09_*.md`) en pièces jointes
5. (Optionnel) Activer le **codebase reference** vers `highthem/lumen`
6. (Optionnel) Activer le **web capture tool** — voir `08_web_capture_targets.md`
7. Send → Claude Design répond avec calibration (Étape 1)

**Outputs Claude Design attendus :**
- Prototypes interactifs HTML (cliquables)
- Maquettes haute fidélité PNG/SVG (10+ écrans, dark + light)
- Design tokens JSON (colors, typo, spacing, motion)
- Composants spec (Markdown ou JSON)
- Code-powered prototypes (HTML/SwiftUI snippets)

**Itérations recommandées :** 4-6 sessions, 2-3h total, roadmap détaillée dans `00_PROMPT_TO_PASTE.md` (étapes 1-6).

**Handoff vers Claude Code :** voir `09_handoff_to_claude_code.md` — workflow détaillé pour passer du livrable design à l'implémentation SwiftUI.

## `palo-docs/` — 5 docs PALO finalisées

Les 5 documents Markdown qui doivent être **à la racine du repo iOS-only** au moment du partage à Sami (sprint 3, 10 mai 2026).

Pour l'instant, ils vivent ici (dans `Design/palo-docs/`) en attendant la restructuration. Le script `scripts/restructure-for-palo.sh` les déplacera automatiquement à la racine au bon moment.

| Fichier | Contenu | Source |
|---|---|---|
| `README.md` | Quick start, requirements, structure repo | nouveau |
| `ARCHITECTURE.md` | MVVM + Clean, layers, DI, state machine | extrait de `Project/04_tech/architecture.md` |
| `TECHNICAL_DECISIONS.md` | 6 ADR consolidés inline | aggrégé de `Project/04_tech/adr/` |
| `ETHICAL_MONITORING.md` | Logging, content safety, rate limit, JSON export | extrait de `Project/04_tech/adr/ADR-005-monitoring-ethique.md` |
| `ARTIFACTS.md` | AI tools utilisés, diagrammes, screenshots, **honest acknowledgements** | nouveau |

## Quand utiliser quoi

| Quand | Quoi |
|---|---|
| Maintenant | `design-kit/` → lancer Claude Design |
| Sprint 1 (27 avr - 3 mai) | Récupérer maquettes "Alarme ringing" + "Onboarding" depuis Claude Design |
| Sprint 2 (4-9 mai) | Récupérer maquettes restantes (timer, questionnaire, synthèse, dashboard) |
| Sprint 3 J-1 (10 mai) | `palo-docs/` → consommé par `scripts/restructure-for-palo.sh` |
| Sprint 3 J-0 (11 mai) | Tagger `v1.0.0` + ajouter `shenchiri@palo-it.com` en collaborateur GitHub |

## ⚠️ Décision à prendre : commit ou gitignore Design/ ?

`Design/` est actuellement **tracked dans le repo Git**. Avant le partage à Sami (sprint 3), trois options :

| Option | Pour | Contre |
|---|---|---|
| **A — Garder tracked** | Versionne l'évolution du design. Sami voit qu'on a un process design. | Sami voit le prompt Claude Design + URLs concurrents (info pas confidentielle mais pas pure code). |
| **B — Gitignore avant push final** | Repo iOS pur pour Sami. | Perte de l'historique design. |
| **C — Migrer dans `lumen-docs` repo séparé** | Sépare clairement code vs design. | Restructuration plus lourde. |

**Recommandation :** Option B ou C. Le script `scripts/restructure-for-palo.sh` peut s'en charger automatiquement. Décision à figer avant le 10 mai.
