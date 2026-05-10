# Lumen — Morning Ritual

> Exercice technique PALO IT (mai 2026) + projet iOS destiné à publication publique (V1.1 post-PALO).

**Statut :** app iOS fonctionnelle en phase de polish/livraison PALO. Le pack produit/design/tech/business est conservé dans `Project/`, et le code source iOS vit dans `Apple/lumen/`.

## Quick start

### Pré-requis
- macOS Sequoia 15.2+ (ou Sonoma 14.5+ si Xcode 16.0-16.2)
- Xcode 16+ (dev sur Xcode 26.4 recommandé pour Apple Intelligence)
- Compte Apple Developer Program actif
- Clé API OpenAI ([platform.openai.com](https://platform.openai.com/api-keys))
- Clé API Anthropic ([console.anthropic.com](https://console.anthropic.com/settings/keys))
- Clé API ElevenLabs optionnelle pour le TTS haute qualité ([elevenlabs.io](https://elevenlabs.io/app/api/api-keys))

### Setup local
```bash
git clone git@github.com:highthem/lumen.git
cd lumen
cp Apple/lumen/Config/Secrets.xcconfig.sample Apple/lumen/Config/Secrets.xcconfig
# Éditer Secrets.xcconfig avec tes vraies clés
open Lumen.xcworkspace
```

Dans Xcode, vérifier que `Secrets.xcconfig` est défini comme **Base Configuration** :
- Project → Info → Configurations → Debug & Release : pointer sur `Secrets.xcconfig`

### CI/CD
- Xcode Cloud (cf `Project/04_tech/adr/ADR-006-cicd-xcode-cloud.md`)
- Secrets gérés via Environment Variables dans App Store Connect → Xcode Cloud → Workflow
- `ci_scripts/ci_post_clone.sh` génère `Apple/lumen/Config/Secrets.xcconfig` en CI
- Secrets attendus : `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `ELEVENLABS_API_KEY`

### Documentation
Voir `Project/` pour la documentation complète (vision, product, design, tech, business, roadmap, ecosystem).

## Positionnement

> Lumen est la seule app iOS qui relie ton alarme du matin à un rituel réflexif de 5 minutes guidé par une IA éthique — pour démarrer la journée avec intention, pas en doomscrollant.

## Contexte dual

1. **Livrable PALO IT** : exercice technique briefé par Sami Henchiri (CTO PALO Labs) le 21 avril 2026. Deadline DURE 11 mai 2026 (envoyée à Sami), interne 10 mai.
2. **Projet public** : V1.1 envisagée post-PALO pour publication App Store (Highthem Studio).

Décision stratégique : **PALO first**, fork Studio à partir du 12 mai. La V1 livrée à Sami est gratuite et sans logique de monétisation ; la V1.1 ajoutera le paywall doux.

## Organisation rapide

```
Apple/                     # Xcode project + iOS source
  lumen.xcodeproj
  lumen/
    App/                   # App root, CompositionRoot, app state, test support
    Features/              # SwiftUI screens/view models by workflow
    Domain/                # Entities, protocols, use cases, domain services
    Data/                  # SwiftData models/repositories and AI clients
    Infrastructure/        # Notifications, audio, voice, network, logging
    Shared/                # Design system, resources, small utilities
  lumenTests/              # Unit tests mirroring Data/Domain/Features/Infrastructure
Project/                   # Product, architecture, ADR, roadmap docs
Design/                    # Local design kit and handoff assets
ci_scripts/                # Xcode Cloud hooks
scripts/                   # Local QA and utility scripts
```

## Documentation pack

```
Project/
├── 00_brief/
│   ├── palo_brief.md                  # Brief Sami original figé
│   └── hypotheses_et_decisions.md     # Hypothèses assumées + décisions candidat
├── 01_vision/
│   ├── pitch.md                       # One-liner, elevator pitch, value prop
│   ├── personas.md                    # Personas primaire, secondaire, anti-persona
│   ├── proposition_valeur.md          # Value prop canvas, USP
│   └── competitive_analysis.md        # Synthèse du brief compétitif
├── 02_product/
│   ├── user_stories/
│   │   ├── alarm.md                   # US-A1 à US-A7 (alarme + snooze + silence)
│   │   ├── timer.md                   # US-T1 à US-T5 (timer de présence)
│   │   ├── questionnaire.md           # US-Q1 à US-Q5 (4 étapes + persistance)
│   │   ├── ai_synthesis.md            # US-AI1 à US-AI6 (waterfall IA + monitoring)
│   │   └── dashboard.md               # US-D1 à US-D6 (6 catégories + Ask Lumen)
│   ├── flows.md                       # Flows : rituel, snooze, edge cases
│   ├── features.md                    # Features V1 avec estimation effort
│   └── acceptance_criteria.md         # Critères DONE par feature
├── 03_design/                         # INPUT CLAUDE DESIGN
│   ├── design_brief.md                # Principes, voice/tone, direction visuelle
│   ├── mood_inspiration.md            # Inspirations, keywords mood, contre-ex
│   ├── style_guide.md                 # Design tokens (couleurs, typo, spacing)
│   └── wireframes_spec.md             # Spec des 10 écrans V1
├── 04_tech/                           # INPUT CLAUDE CODE
│   ├── stack.md                       # Frameworks, lib, CI/CD, contraintes
│   ├── architecture.md                # MVVM + Clean, structure Xcode, DI
│   ├── data_model.md                  # Entités Domain + SwiftData @Model
│   ├── api_contracts.md               # Apple Intelligence, OpenAI, Anthropic, secrets
│   └── adr/
│       ├── ADR-001-alarme-background.md
│       ├── ADR-002-persistance-swiftdata.md
│       ├── ADR-003-swift-concurrency.md
│       ├── ADR-004-waterfall-ia.md         # Cloud + Apple Intelligence + queue offline
│       ├── ADR-005-monitoring-ethique.md
│       └── ADR-006-cicd-xcode-cloud.md     # CI/CD strategy
├── 05_business/                       # POST-PALO / V1.1
│   ├── monetization.md                # Modèle freemium anti-dark-pattern
│   ├── unit_economics.md              # CAC, LTV, marge par user
│   └── go_to_market.md                # ASO, channels, launch plan
├── 06_roadmap/
│   ├── timeline.md                    # Dates clés, capacité, gap analysis
│   ├── sprints.md                     # 3 sprints détaillés par demi-journée
│   └── risks.md                       # Risk register technique + timeline + biz
└── 07_ecosystem/                      # POST-PALO / Studio
    ├── backend.md                     # Stratégie backend (zero V1, CloudKit V1.1)
    └── landing.md                     # Landing page Astro, GTM web
```

## Comment utiliser ce pack

### Pour Claude Design (étape 1)
Entrée :
- `01_vision/` (comprendre positionnement et personas)
- `03_design/design_brief.md` (principes non-négociables)
- `03_design/mood_inspiration.md` (direction visuelle)
- `03_design/style_guide.md` (tokens)
- `03_design/wireframes_spec.md` (spec écrans)
- `02_product/flows.md` (comprendre les transitions)

Sortie attendue :
- Moodboard final
- Design system figé (palette, typo, spacing, composants)
- Maquettes hautes fidélité des 10 écrans
- Prototype Figma cliquable du flow rituel
- Spec de motion
- Export assets

### Pour Claude Code (étape 2)
Entrée :
- `00_brief/` (contraintes brief PALO)
- `02_product/` (user stories, acceptance criteria)
- `04_tech/` (stack, architecture, data model, API, 5 ADR)
- `06_roadmap/sprints.md` (découpage des tâches)

Sortie attendue :
- Code iOS Swift 6 / SwiftUI / iOS 17+ conforme au pack
- Tests Domain ≥ 60%
- Les 5 livrables docs du brief Sami (README, ARCHITECTURE, TECHNICAL_DECISIONS, ETHICAL_MONITORING, ARTIFACTS) dans le repo
- Export JSON monitoring éthique fonctionnel

### Pour la suite business (étape 3, post-PALO)
Entrée :
- `05_business/` (modèle, pricing, GTM)
- `01_vision/competitive_analysis.md` (positionnement)

## Points d'attention à jour

### ⚠️ Pré-requis technique
- La compatibilité Xcode 16 est validée par Xcode Cloud ; le poste local peut rester sur Xcode 26.4 pour les chemins Apple Intelligence.

### Questions en attente de réponse Sami (bloquant partiellement démarrage dev)
1. Fiabilité alarme vs modes Silence/Focus/DND
2. Portée "pas de lib tierce" (persistance only ou global)
3. Contenu et format de la synthèse IA
4. Clés API IA (fournies ou à provisionner)
5. Définition de `ARTIFACTS.md`

### Hypothèses assumées si pas de réponse d'ici 28 avril
Voir `00_brief/hypotheses_et_decisions.md`. Ne pas attendre la réponse pour démarrer Sprint 1 — l'alarme peut être construite sur l'hypothèse best-effort sans Critical Alerts.

### Gap capacité identifié
Estimation effort V1 : ~165 h. Capacité dispo : ~75-90 h. Gap fermé par :
- Coupe agressive P1
- Utilisation IA Opus/Sonnet sur ADR, code, tests
- Parallélisation docs pendant dev

Voir `06_roadmap/timeline.md` pour le détail.

### Ce qui change vs version initiale du pack (24 avr 2026)
- **ADR-004 mis à jour** : suppression des templates pré-écrits offline. Stratégie remplacée par Apple Intelligence (iOS 26+ A17 Pro+) ou queue + génération différée au retour réseau.
- **ADR-006 ajouté** : CI/CD via Xcode Cloud (free tier 25h/mois inclus dans Apple Dev Program).
- **style_guide.md enrichi** : section motion design 3 niveaux (functional / signature / decorative).
- **07_ecosystem/ ajouté** : décisions sur backend (zero V1, CloudKit V1.1) et landing page (Astro statique post-PALO).

## Prochaines étapes immédiates

1. ✉️ Envoyer l'email questions à Sami (prêt dans la conversation parent)
2. 🎨 Démarrer Claude Design sur le design_brief (en parallèle de l'attente Sami)
3. 💻 Démarrer Sprint 1 (27 avril) : scaffold Xcode + alarme + tests Domain
4. 🔁 Revue pack avec Haithem : valider/ajuster avant de coder ou designer

## Principes directeurs à garder en tête

- **Calme avant tout.** Zéro dark pattern, zéro streak, zéro culpabilisation.
- **Identité, pas métriques.** Le dashboard est un miroir, pas un coach.
- **Privacy first.** Tout en local, prompt haché, export JSON.
- **Éthique IA concrète.** Monitoring lisible, rate limit visible, fallback offline réel.
- **Challenge candidat.** Chaque ADR défendable, chaque décision justifiable en soutenance.

---

*Pack préparé le 24 avril 2026 par Claude (Cowork mode) sur instruction Haithem. Inputs : brief Sami du 21 avril + analyse compétitive dédiée + conventions Highthem/StockTrack.*
