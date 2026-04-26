# Liste des features V1

Référence : brief PALO + user stories.

## Features Core (brief PALO, obligatoires)

| ID | Feature | Priorité | User stories | Effort (j) |
|----|---------|----------|--------------|------------|
| F1 | Alarme avec Snooze / Silence en background | P0 | US-A1 à US-A6 | 3-4 |
| F2 | Timer de présence 60s configurable + citation | P0 | US-T1 à US-T5 | 1 |
| F3 | Questionnaire 4 étapes avec persistance | P0 | US-Q1 à US-Q3 | 1 |
| F4 | Synthèse IA avec waterfall (OpenAI → Anthropic → offline) | P0 | US-AI1 à US-AI2 | 2-3 |
| F5 | Rate limiting local + monitoring éthique + export JSON | P0 | US-AI3, US-AI5 | 1-2 |
| F6 | Dashboard 6 catégories | P0 | US-D1 à US-D3, US-D5 | 2 |
| F7 | Ask Lumen (accès rapide IA depuis dashboard) | P0 | US-AI6 | 0,5 |
| F7b | Voice input (dictation Q3/Q4, on-device) | P0 | US-Q6, ADR-007 | 0,75 |
| F7c | Voice output (TTS synthèse IA, on-device) | P0 | US-AI7, ADR-007 | 0,5 |

**Sous-total P0 :** ~11-15 jours de dev.

## Features Polish (importants pour la soutenance)

| ID | Feature | Priorité | User stories | Effort (j) |
|----|---------|----------|--------------|------------|
| F8 | Onboarding 4 écrans | P1 | Flows | 0,5 |
| F9 | Empty state dashboard premier lancement | P1 | US-D4 | 0,3 |
| F10 | Reset quotidien dashboard à 3h | P1 | US-D6 | 0,3 |
| F11 | Fade-in progressif du son alarme si foreground | P1 | US-A7 | 0,5 |
| F12 | Régénération manuelle IA | P1 | US-AI4 | 0,3 |
| F13 | Reprise rituel partiel | P1 | US-Q5, Flows | 0,5 |

**Sous-total P1 :** ~2,4 jours.

## Features Documentation (obligatoires brief)

| ID | Livrable | Priorité | Effort (j) |
|----|----------|----------|------------|
| F14 | README.md | P0 | 0,3 |
| F15 | ARCHITECTURE.md | P0 | 0,5 |
| F16 | TECHNICAL_DECISIONS.md (≥ 5 ADR) | P0 | 1 |
| F17 | ETHICAL_MONITORING.md | P0 | 0,5 |
| F18 | ARTIFACTS.md | P0 | 0,3 |
| F19 | Tests ≥ 60% couverture Domain | P0 | 2 |
| F20 | Démo Loom 5 min | P0 | 0,5 |
| F21 | Export JSON monitoring éthique | P0 | inclus F5 |
| F22 | Présentation 10-15 slides | P0 | 1 |

**Sous-total docs :** ~6 jours.

## Récapitulatif effort V1

- Dev core P0 : ~10-13 j
- Dev polish P1 : ~2,4 j
- Docs + tests + démo : ~6 j
- Buffer aléas (alarme background, debug) : ~2 j

**Total estimé : 20-24 jours-homme**
**Deadline interne : 10 mai 2026 (16 jours calendaires, capacité ~85h cumulée = ~10-11 j-h effectifs)**

⚠️ **Alerte capacité** : l'estimation dépasse la capacité. Actions :
- Découper P1 agressivement : ne garder que F8 (onboarding) et F13 (reprise).
- Parallélisation : docs rédigés pendant que les features cuisent (tests + docs en // du dev).
- Deadline DURE 11 mai (envoyée à Sami), interne 10 mai (buffer 1j seulement).
- Si retard : sacrifier F11 et F12 en premier, pas les docs.

## Out of scope V1 (post-PALO / V1.1 / monétisation)

- Historique questionnaire (US-Q4)
- Apple Watch complication
- Widget iOS home screen
- Conversation multi-tour avec IA
- Réveil progressif complet (avec musique / guidance)
- Partage social
- Intégration calendrier
- Export data (CSV / Apple Health)
