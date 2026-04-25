# ADR-006 — CI/CD via Xcode Cloud

## Statut
Accepté (24 avr 2026, révisé : dev local Xcode 26.4 + CI Xcode 16 pour forward compatibility check)

## Contexte

Le brief PALO IT impose :
- **Xcode 16+** pour build direct
- Repo GitHub privé partagé avec Sami
- TestFlight ou Loom comme livrable démo

Setup Haithem :
- **Dev local : Xcode 26.4** (donne accès aux APIs iOS 26 dont Foundation Models / Apple Intelligence)
- Compte Apple Developer Program actif
- Volonté d'automatiser tests et builds
- **Décision stratégique :** ne pas downgrade le local — utiliser la CI pour vérifier la compatibilité Xcode 16 (forward compatibility verification)

Cette stratégie garantit que :
- Haithem peut développer avec les APIs récentes (Foundation Models pour Apple Intelligence)
- Sami peut effectivement build le projet sur Xcode 16 sans surprise
- Le projet est rétro-compatible et démontrable sur l'environnement spécifié au brief

## Options évaluées

### Option A — Xcode Cloud
- **Free tier : 25 compute hours/mois** (inclus dans Apple Developer Program 99 €/an)
- Native Apple, intégration TestFlight directe
- Provisioning, signing, certificats gérés automatiquement
- Workflow YAML simple via Xcode UI ou config file
- Secrets via Environment Variables protégées
- Build numbers auto-incrémentés
- Limitations : nombre limité de workflows en free tier

### Option B — GitHub Actions (macOS runners)
- Free tier : 2000 min/mois Linux **mais multiplicateur 10x sur macOS** = **5 h macOS effectives/mois**
- Au-delà : $0.048/min (pricing Jan 2026)
- Build iOS typique : 10-15 min × 0.048 = $0.48-0.72 par run
- Plus flexible (lint, scripts custom, multi-platform)
- Setup signing/provisioning manuel (fastlane)
- Secrets via GitHub Secrets

### Option C — Self-hosted Mac mini
- Coût matériel élevé (~600-1500 €)
- Maintenance lourde
- Hors scope timeline

## Décision

**Xcode Cloud** comme CI/CD principal.

Raisons :
1. **Free tier 5x plus généreux** que GitHub Actions pour macOS (25 h vs 5 h effectives)
2. **Intégration TestFlight native** — le brief Sami demande TestFlight comme option démo, c'est un gain de ~1 jour
3. **Provisioning géré automatiquement** — moins de friction signing/certificates pour un solo dev
4. **Secrets natifs sécurisés** — pas besoin de gérer les `.xcconfig` manuellement en CI
5. **Apple Developer Program déjà payé** — coût marginal nul

## Workflows Xcode Cloud — Stratégie dual version

Xcode Cloud permet de spécifier la version d'Xcode par workflow. Voir [List All Xcode Versions Available in Xcode Cloud](https://developer.apple.com/documentation/appstoreconnectapi/list_all_xcode_versions_available_in_xcode_cloud).

### Workflow 1 — Tests Xcode 16 (compatibility check, primaire)
- **Xcode version** : 16.x (la plus récente stable disponible Xcode Cloud)
- **Trigger** : push sur n'importe quelle branche
- **Actions** : run unit tests sur scheme principal
- **Objectif** : garantir que le code est buildable et testable sur Xcode 16, comme demandé par Sami
- **Post-action** : email/Slack si fail
- **Estimation durée** : 6-10 min par run
- **Volume** : ~3-5 push/jour × 22 jours = ~80 runs × 8 min = **~10 h/mois**

### Workflow 2 — Tests Xcode 26 (Apple Intelligence + nouvelles APIs)
- **Xcode version** : 26.x (matching dev local)
- **Trigger** : push sur branche `main`
- **Actions** : run unit tests + tests spécifiques Apple Intelligence (gated par `@available(iOS 26.0, *)`)
- **Objectif** : valider que les chemins iOS 26+ (Foundation Models) compilent et passent
- **Estimation durée** : 6-10 min
- **Volume** : ~1-2 push/jour main × 22 = ~30 runs × 8 min = **~4 h/mois**

### Workflow 3 — Build TestFlight sur tag
- **Xcode version** : 16.x (cohérent avec ce que Sami va build, sauf si Sami nous dit qu'il a aussi Xcode 26)
- **Trigger** : tag git `v*` sur branche `main`
- **Actions** : archive + upload TestFlight
- **Post-action** : email à shenchiri@palo-it.com avec lien
- **Estimation durée** : 12-15 min par run
- **Volume** : ~3-5 builds total = **<1 h/mois**

**Total estimé budget Xcode Cloud :** ~15-20 h/mois sur 25 h disponibles. Marge confortable mais à surveiller.

## Discipline de code à maintenir (dev Xcode 26)

Pour que la CI Xcode 16 reste verte malgré le dev sur Xcode 26 :

### 1. Deployment target figé à iOS 17.0
- Xcode 26 par défaut peut proposer iOS 26 comme target. Forcer iOS 17.0 dans Build Settings.
- Vérifier dans `project.pbxproj` : `IPHONEOS_DEPLOYMENT_TARGET = 17.0`.

### 2. Compilation conditionnelle stricte pour iOS 26+ APIs
```swift
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
final class AppleIntelligenceProvider {
    // ...
}
#endif
```

### 3. Vérifier les nouveaux APIs SwiftUI iOS 18+/26+
- `MeshGradient` (iOS 18+) : ne pas utiliser
- `@Entry` macros, nouveaux modifiers : `@available` annotation obligatoire
- Animations spring iOS 17+ : OK
- Liquid Glass APIs (iOS 26+) : éviter ou conditionner

### 4. Concurrency
- Strict concurrency Swift 6 : compatible Xcode 16+ (Swift 6 introduit dans Xcode 16). OK.
- Pas de feature Swift 6.1+ exclusive

### 5. Tests croisés
- Avant de pusher main, mental check : "est-ce que ce code compile sur Xcode 16 ?"
- Si doute : pusher sur branche feature, vérifier le workflow 1 avant merge

### 6. Régler avec Apple Intelligence
- Le code Apple Intelligence ne s'exécute pas en CI Xcode 16 (manque le SDK)
- Tests Apple Intelligence : taggés `@available(iOS 26.0, *)`, exécutés uniquement par workflow 2
- Mocks pour les tests qui ne dépendent pas de Foundation Models en eux-mêmes

## Gestion des secrets

### `.xcconfig` local (jamais commité)

```
// Lumen/Config/Secrets.xcconfig (gitignored)
OPENAI_API_KEY = sk-proj-...
ANTHROPIC_API_KEY = sk-ant-...
```

### `.xcconfig.sample` (committé)

```
// Lumen/Config/Secrets.xcconfig.sample (committed)
OPENAI_API_KEY = REPLACE_ME
ANTHROPIC_API_KEY = REPLACE_ME
```

### Xcode Cloud Environment Variables

Configurées via Apple Developer / App Store Connect → Xcode Cloud → Workflow → Environment :
- `OPENAI_API_KEY` (Secret = checked)
- `ANTHROPIC_API_KEY` (Secret = checked)

Le build script Xcode Cloud (`ci_scripts/ci_post_clone.sh`) génère le fichier `Secrets.xcconfig` à partir des variables d'environnement.

```bash
#!/bin/sh
# ci_scripts/ci_post_clone.sh
cat > Lumen/Config/Secrets.xcconfig <<EOF
OPENAI_API_KEY = ${OPENAI_API_KEY}
ANTHROPIC_API_KEY = ${ANTHROPIC_API_KEY}
EOF
```

Pour le dev local : Haithem copie `Secrets.xcconfig.sample` en `Secrets.xcconfig` et remplit ses propres clés.

## Setup pas-à-pas

1. App Store Connect → Apps → Lumen → Xcode Cloud → "Get Started"
2. Connect GitHub repo (privé)
3. Create workflow "Tests on push"
4. Add Environment Variables (secrets)
5. Push initial commit avec `ci_scripts/ci_post_clone.sh`
6. Vérifier premier run vert
7. Ajouter workflow "TestFlight on tag"

## Implications structurelles repo

```
Lumen/
├── ci_scripts/                  # Xcode Cloud convention
│   ├── ci_pre_xcodebuild.sh
│   ├── ci_post_clone.sh
│   └── ci_post_xcodebuild.sh
├── Lumen/
│   └── Config/
│       ├── Secrets.xcconfig          # gitignored
│       └── Secrets.xcconfig.sample   # committed
├── .gitignore                    # contient Secrets.xcconfig
└── README.md                     # explique setup local
```

## Conséquences

### Positives
- **Zéro setup signing** côté dev (Xcode Cloud signe automatiquement)
- **TestFlight upload automatisé** — gain de temps, mieux que upload manuel
- **Coût zéro** dans nos volumes
- **Conventions Apple** — moins de doc à expliquer à Sami
- **Tests automatisés à chaque push** — discipline de qualité

### Négatives
- **Vendor lock-in léger** — config workflow spécifique à Xcode Cloud
- **Moins flexible que GitHub Actions** pour des scripts custom complexes
- **Logs UI seulement** (pas de stream temps réel comme GitHub Actions)
- **Pas de matrice OS** (mais inutile pour iOS-only)

### Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Xcode Cloud free tier dépassé | Surveillance dashboard, tagging plus discipliné si proche limite |
| Build qui marche local mais fail Xcode Cloud (env diff) | Tester `ci_post_clone.sh` localement avec env vars temp |
| Secret leak dans logs Xcode Cloud | Variables marquées "Secret" → masquées dans logs |
| Switch vers GitHub Actions plus tard | Workflows portables (xcodebuild commands), `.xcconfig` pattern réutilisable |

## Setup pré-Sprint 1 — checklist

À faire avant le 27 avril (sprint 1) :

1. **Xcode Cloud workflows configurés :**
   - Workflow 1 : tests Xcode 16 sur push toutes branches
   - Workflow 2 : tests Xcode 26 sur push main
   - Workflow 3 : build TestFlight sur tag (à activer plus tard, sprint 3)

2. **Environment Variables ajoutées (App Store Connect → Xcode Cloud) :**
   - `OPENAI_API_KEY` (Secret = checked)
   - `ANTHROPIC_API_KEY` (Secret = checked)

3. **Repo GitHub initialisé :**
   - `.gitignore` avec `Lumen/Config/Secrets.xcconfig`
   - `Lumen/Config/Secrets.xcconfig.sample` versionné
   - `ci_scripts/ci_post_clone.sh` exécutable

4. **Test du setup CI :**
   - Push initial avec un test minimal qui passe
   - Vérifier workflow 1 (Xcode 16) vert
   - Vérifier workflow 2 (Xcode 26) vert
   - Vérifier secrets injectés

5. **Project settings :**
   - `IPHONEOS_DEPLOYMENT_TARGET = 17.0`
   - Swift Language Version : 6
   - Strict Concurrency Checking : Complete

**Effort total setup : ~0.5 jour** (conservatif).

## Références

- [Xcode Cloud — Apple Developer](https://developer.apple.com/xcode-cloud/)
- [Xcode Cloud workflow syntax](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow)
- [Yakov Manshin — Xcode Cloud Stays Free Forever](https://yakovmanshin.com/2024/01/xcode-cloud/)
- [GitHub Actions 2026 pricing changes](https://resources.github.com/actions/2026-pricing-changes-for-github-actions/)
