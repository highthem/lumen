# Découpage sprints

3 sprints alignés sur timeline.md.

## Sprint 1 — "Alarme qui marche" (27 avr - 3 mai)

**Objectif de sprint :** une alarme iOS fiable en background, avec Snooze et Silence fonctionnels, architecture propre, tests Domain à 60%.

### Critère de succès
Je peux programmer une alarme pour dans 5 min, verrouiller le device, poser le téléphone, elle sonne à l'heure, Snooze fonctionne, Silence fonctionne, et j'ai des tests unitaires pour la logique métier.

### User stories
- US-A1 Créer alarme
- US-A2 Sonner en background
- US-A3 Snooze
- US-A4 Silence
- US-A5 Son concurrent (edge case)
- US-A6 Lister et modifier

### Tâches techniques (découpage par demi-journée ~4h)

| # | Tâche | Durée | Jour cible |
|---|-------|-------|------------|
| 0a | **Pré-requis : install Xcode 16 + check macOS** | 0.25j | 26 avr (avant sprint) |
| 0b | **Setup Xcode Cloud workflow tests + secrets env vars** | 0.25j | 27 avr |
| 1 | Setup Xcode project (iOS 17+, Swift 6 strict, modules) | 0.5j | 27 avr |
| 2 | Setup SwiftData `ModelContainer` + `AlarmEntity` | 0.5j | 27 avr |
| 3 | Domain `Alarm` entity + `AlarmRepository` protocol | 0.5j | 28 avr |
| 4 | `SwiftDataAlarmRepository` + tests | 0.5j | 28 avr |
| 5 | Use cases : `ScheduleAlarm`, `SnoozeAlarm`, `CancelAlarm` | 1j | 29 avr |
| 6 | `NotificationScheduler` (UN schedulizer + category) | 1j | 30 avr |
| 7 | `AudioPlayer` + `AudioSessionManager` (AVFoundation) | 1j | 1 mai |
| 8 | Feature AlarmList UI + ViewModel | 0.5j | 2 mai |
| 9 | Feature AlarmEdit UI + ViewModel | 0.5j | 2 mai |
| 10 | Feature AlarmRinging UI (app foreground) | 0.5j | 3 mai |
| 11 | Tests Domain alarme (>= 60%) | 1j | 3 mai |
| 12 | Démo self-test : alarme background + snooze + silence | 0.25j | 3 mai |

**Total ~8-9 jours-homme** dans 7 jours calendaires (sémaine solo = ~50h disponible).

### Risques sprint 1
- AVAudioSession config tricky en background (voir ADR-001)
- SwiftData `@ModelActor` learning curve
- Tests async/await Domain

### Livrables fin sprint 1
- Code commité (repo privé)
- README initial
- Une vidéo screen capture 1 min de l'alarme fonctionnelle

---

## Sprint 2 — "Rituel complet" (4-10 mai)

**Objectif de sprint :** flow complet opérationnel — timer → questionnaire → synthèse IA → dashboard.

### Critère de succès
Je peux silencer une alarme et vivre le rituel complet sur simulateur ou device, avec une synthèse IA générée (cloud ou offline), et les données reflétées dans le dashboard.

### User stories
- US-T1 à T5 Timer
- US-Q1 à Q3 Questionnaire
- US-AI1 à AI6 Synthèse IA + Ask Lumen
- US-D1 à D6 Dashboard

### Tâches techniques

| # | Tâche | Durée | Jour cible |
|---|-------|-------|------------|
| 1 | Feature Timer UI + ViewModel + `QuoteProvider` + JSON quotes | 0.5j | 4 mai |
| 2 | Feature Questionnaire flow (4 écrans + state) | 1j | 4-5 mai |
| 3 | SwiftData `QuestionnaireAnswer` + repo | 0.5j | 5 mai |
| 4 | `PromptBuilder` + system prompts | 0.25j | 6 mai |
| 5 | `OpenAIClient` (URLSession, async/await, streaming optionnel) | 0.75j | 6 mai |
| 6 | `AnthropicClient` | 0.5j | 7 mai |
| 7 | `AppleIntelligenceProvider` (Foundation Models, conditionnal compile iOS 26+) + `SynthesisQueue` (queue offline persistée) | 0.75j | 7 mai |
| 8 | `WaterfallAISynthesisService` (cloud → Apple Intelligence → queue) | 0.5j | 7 mai |
| 9 | `RateLimiter` (actor) + tests | 0.5j | 8 mai |
| 10 | `EthicalLogger` + `SwiftDataEthicalLogRepository` + export JSON | 0.75j | 8 mai |
| 11 | Feature Synthesis UI + VM | 0.5j | 9 mai |
| 12 | Feature Dashboard UI (home + 6 cards + détail) | 1j | 9-10 mai |
| 13 | Feature Ask Lumen modal | 0.25j | 10 mai |
| 14 | Onboarding 4 écrans | 0.25j | 10 mai |
| 15 | Tests Domain IA + RateLimiter | 0.75j | 10 mai |

**Total ~7,5 j-h** dans 7 jours calendaires (WBD + FTV la semaine → ~25h dispo soirs+weekend) = tendu.

### Risques sprint 2
- IA waterfall testing complexe (mocks providers)
- JSON parsing OpenAI si API change format
- Rate limiter edge cases (reset à minuit)

### Livrables fin sprint 2
- Flow complet end-to-end testé
- Export JSON d'exemple généré

---

## Sprint 3 — "Finition + docs + démo" (10-11 mai)

**Objectif de sprint :** livrable propre prêt pour Sami.

### Critère de succès
Le repo privé est partagé avec Sami, les 5 docs sont complètes, une démo Loom 5 min est enregistrée, une présentation 10-15 slides est prête, et j'ai fait une répétition soutenance 30 min.

### Tâches

| # | Tâche | Durée | Jour cible |
|---|-------|-------|------------|
| 1 | Polish UI final (spacing, Dark/Light, VoiceOver) | 1j | 11 mai |
| 2 | Couverture tests finale (≥ 60% Domain) | 0.5j | 11 mai |
| 3 | README.md exhaustif | 0.5j | 12 mai |
| 4 | ARCHITECTURE.md (schémas, flows) | 0.5j | 12 mai |
| 5 | TECHNICAL_DECISIONS.md (copier les 5 ADR du pack + 1 ou 2 ADR supplémentaires si besoin) | 0.5j | 12 mai |
| 6 | ETHICAL_MONITORING.md | 0.5j | 13 mai |
| 7 | ARTIFACTS.md (captures, prompts IA utilisés, diagrammes) | 0.5j | 13 mai |
| 8 | Loom vidéo 5 min (script + enregistrement + montage) | 0.75j | 13 mai |
| 9 | Présentation 10-15 slides | 0.5j | 11 mai |
| 10 | Submit TestFlight si demande Sami | 0.25j | 11 mai |
| 11 | Répétition soutenance 30 min (timing + Q&R) | 0.5j | 11 mai |
| 12 | Email récap + partage repo | 0.1j | 11 mai |

**Total ~6 j-h** dans 4 jours = tight mais faisable en focus.

### Livrables fin sprint 3 = livrables Sami
- Repo GitHub privé partagé avec shenchiri@palo-it.com
- Loom vidéo 5 min ou TestFlight link
- Export JSON monitoring éthique
- Présentation 10-15 slides
- Email récap

---

## Rituels de suivi

### Daily stand-up solo (5 min le matin)
- Qu'est-ce que j'ai fini hier ?
- Qu'est-ce que je fais aujourd'hui ?
- Quelle est la priorité n°1 ?
- Quel risque pour la deadline ?

### Revue sprint (30 min fin de sprint)
- Qu'est-ce qui a dérapé ?
- Qu'est-ce qui est dans la poche ?
- Ajustement plan pour le sprint suivant

### Checkpoint J-3 (8 mai)
Si plus de 30% du scope restant → coupe P1 supplémentaire + focus P0 strict.

### Checkpoint J-1 (10 mai)
Freeze code à midi. L'après-midi : que de la doc, polish visuel, démo Loom.
