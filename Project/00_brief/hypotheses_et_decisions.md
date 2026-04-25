# Hypothèses et décisions initiales

Document vivant. Toute hypothèse assumée (faute de réponse de Sami, ou choix candidat) est consignée ici avec justification, et doit finir dans un ADR si elle a un impact architectural.

## Hypothèses en attente de validation Sami

| # | Sujet | Hypothèse par défaut | Impact si Sami répond différemment |
|---|-------|---------------------|-----------------------------------|
| H1 | Fiabilité alarme en Silent/Focus/DND | Best-effort hors modes silencieux, Critical Alerts non demandés (délai Apple vet incompatible avec deadline). ADR-001 documenté. | Si Sami exige Critical Alerts → blocage technique, à renégocier ou lever contrainte. |
| H2 | Lib tierce | "Pas de lib tierce" limité à la persistance. Reste du projet : libs minimales et justifiées OK (ex: swift-log pour monitoring, si besoin). | Si Sami impose zero-dep global → refonte tests et DI manuelles. |
| H3 | Synthèse IA | Synthétise le questionnaire matinal (4 étapes) → produit une intention du jour + 3 recommandations par catégorie concernée. Format JSON structuré parseable. | Si Sami veut synthèse sur dashboard → repenser le data flow. |
| H4 | Clés API IA | Candidat provisionne ses propres clés (OpenAI + Anthropic), stockées via `Lumen/Config/Secrets.xcconfig` non commité + Xcode Cloud Environment Variables, sample committé. | Si PALO fournit → simplifie la démo live. |
| H5 | ARTIFACTS.md | Inventaire des artefacts non-code (diagrammes, prompts IA utilisés pour générer le code, captures, données de test). | À ajuster selon clarification Sami. |

## Pré-requis technique

| # | Sujet | Statut | Action |
|---|-------|--------|--------|
| P1 | ~~Xcode 16 local~~ | ✅ Résolu : dev sur Xcode 26.4 + CI Xcode 16 pour compatibility check | Voir ADR-006 |
| P2 | Apple Developer Program actif | À confirmer | Indispensable pour Xcode Cloud, TestFlight, signing |
| P3 | Compte OpenAI avec budget API | À confirmer | Sinon attendre réponse Sami sur clés fournies |
| P4 | Compte Anthropic avec budget API | À confirmer | Idem |
| P5 | Xcode Cloud workflows setup (16 + 26) | À faire avant 27 avr | Voir ADR-006 checklist |

## Décisions candidat (non dépendantes de Sami)

| # | Sujet | Décision | Justification courte |
|---|-------|----------|---------------------|
| D1 | Positioning produit | "Le seul rituel matinal avec IA éthique qui démarre à l'alarme" | Gap marché confirmé : aucun concurrent ne couvre la chaîne réveil→rituel→IA→dashboard. |
| D2 | Concurrency | Swift Concurrency (async/await, Task, actors) — pas Combine | Swift 6 + iOS 17 = natif, plus testable, aligné avec les attentes 2026. ADR-003. |
| D3 | Persistance | SwiftData | iOS 17+ disponible, API moderne, moins de boilerplate que Core Data, interop CoreData possible. ADR-002. |
| D4 | Stratégie IA | Waterfall : OpenAI cloud → Anthropic cloud → Apple Intelligence on-device → queue offline | Pattern Skoul amélioré. Pas de templates pauvres : toujours du LLM (cloud ou on-device) ou queue jusqu'au retour réseau. ADR-004. |
| D5 | 6 catégories dashboard | Energie, Intention, Corps, Relations, Travail, Gratitude | Miroir d'identité vs métriques cliniques (gap marché Rise/Fabulous). |
| D6 | Questions questionnaire | 4 étapes : "Comment tu te sens ?" / "Qu'est-ce qui compte aujourd'hui ?" / "Une gratitude" / "Une intention" | Cadre minimaliste, format court, maximise complétion. |
| D7 | Design direction | Calme, neutre, monochrome chaud, typographie serif → voir 03_design | Anti-dopamine, cohérent avec angle C du brief compétitif. |
| D8 | Langue | Bilingue FR/EN via localization strings, UI en anglais par défaut pour démo Sami | Présentation plus universelle, démo internationale. |
| D9 | Cible device | iPhone uniquement pour V1 | Réduire surface test ; iPad et Watch en post-V1. |
| D10 | Timer de présence | 60 secondes par défaut, configurable 30s/60s/120s, citation pré-chargée depuis JSON local | Simple, offline-first, pas de dépendance externe. |
| D11 | CI/CD | Xcode Cloud (free tier 25h/mois, intégration TestFlight native) | Apple Dev Program déjà payé, 5x plus généreux que GitHub Actions macOS. ADR-006. |
| D12 | Motion design | 3 niveaux : Functional (essentiel invisible) / Signature (cercle timer + reveal IA) / Decorative (interdit) | Cohérence avec posture calm. Voir style_guide.md. |
| D13 | Backend V1 | ZÉRO backend, tout client-side | Brief Sami explicite, scope respecté. CloudKit envisagé en V1.1 si sync multi-device. Voir 07_ecosystem/backend.md. |
| D14 | Landing V1 | Aucune | PALO V1 = repo + démo seulement. Landing prévue V1.1 (Astro statique, Vercel). Voir 07_ecosystem/landing.md. |
| D15 | Apple Intelligence offline | Foundation Models si dispo (iOS 26+ A17 Pro+), sinon queue + génération différée | Suppression des templates pré-écrits — qualité IA constante ou pas de synthèse immédiate. Validé Haithem 24 avr. |

## Principe directeur

> **Ne rien ajouter qui n'est pas dans le brief Sami tant que le livrable PALO n'est pas figé.** Les idées produit pour la monétisation sont documentées dans `05_business/` mais n'entrent pas dans le code V1.
