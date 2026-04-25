# Risk register

## Méthode
Probabilité (faible / moyen / élevé) × Impact (faible / moyen / élevé) = Priorité.

Stratégie par priorité :
- **Critique** : mitigation obligatoire, check hebdo
- **Majeur** : plan de mitigation documenté
- **Modéré** : surveiller
- **Mineur** : accepter

## Risques techniques

| # | Risque | Prob | Impact | Prio | Mitigation |
|---|--------|------|--------|------|------------|
| T0 | ~~Xcode 16 pas installé localement~~ | ✅ Résolu | — | — | Stratégie : dev local Xcode 26.4 + CI Xcode 16 pour compatibility check. Voir ADR-006. |
| T0b | Code Xcode 26 qui ne compile pas en CI Xcode 16 (APIs iOS 26 oubliées sans `@available`) | Moy | Moy | Majeur | Discipline `#if canImport`, `@available`, deployment target iOS 17.0 forcé. Workflow 1 CI Xcode 16 visible à chaque push pour catch tôt. |
| T1 | Alarme en background ne sonne pas fiablement | Moy | Élevé | Critique | ADR-001 assume best-effort hors silent mode. Onboarding explicite. Tests bas-level sur device réel. |
| T2 | Critical Alerts demandés in extremis par Sami | Faible | Élevé | Majeur | Question posée dans l'email. Plan B : implémenter code avec entitlement, demander Apple vet en parallèle, livrer feature fonctionnelle en sim. |
| T3 | SwiftData bug bloquant (relations, performance) | Faible | Moy | Modéré | Fallback Core Data documenté ADR-002, surface d'impact limitée aux repos. |
| T4 | OpenAI / Anthropic rate limit hit en démo | Moy | Moy | Majeur | Fallback Apple Intelligence on-device si dispo, sinon queue offline. Démo backup Loom. |
| T4b | Apple Intelligence framework changes (jeune, iOS 26 récent) | Moy | Moy | Modéré | Wrap dans `AppleIntelligenceProvider`, compilation conditionnelle `@available(iOS 26.0, *)`, fallback queue garanti. Voir ADR-004. |
| T4c | Xcode Cloud build fail (env vars manquantes, signing) | Moy | Moy | Majeur | Test setup en J1 sprint 1. `ci_post_clone.sh` testable localement. Voir ADR-006. |
| T5 | Strict concurrency Swift 6 : compile errors surprise | Moy | Moy | Majeur | Migration progressive, Complete en fin de dev si besoin. |
| T6 | Xcode 16 breaks dépendance imprévue | Faible | Faible | Mineur | Pas de deps tierces = pas de surface. |
| T7 | SwiftUI Questionnaire flow : navigation complexe multi-étapes | Moy | Faible | Mineur | Coordinator pattern simple, pas NavigationStack complexe. |
| T8 | AVAudioSession ne duck pas correctement en prod | Moy | Faible | Mineur | Test manuel simulateur + device au sprint 1. |
| T9 | Clés API committées accidentellement | Faible | Élevé | Majeur | `.xcconfig` dans `.gitignore`, `.xcconfig.sample` template. Pré-commit hook à setup. |
| T10 | Tests couverture < 60% | Moy | Moy | Majeur | Focus Domain uniquement, pattern AAA strict, TDD sur alarme. |

## Risques timeline

| # | Risque | Prob | Impact | Prio | Mitigation |
|---|--------|------|--------|------|------------|
| S1 | Sprint 1 dérape (>50% retard alarme) | Moy | Élevé | Critique | Checkpoint 1 mai. Si retard : simplifier flow alarme à minimum viable, garder snooze/silence strict. |
| S2 | Sprint 2 dérape sur IA (fallback complexe) | Moy | Moy | Majeur | Offline template prêt dès J1 sprint 2, cloud ajouté après. |
| S3 | Capacité WBD/FTV explose (imprévu client) | Faible | Élevé | Majeur | Communiquer tôt, ne pas sacrifier sleep/famille. Sami plutôt que WBD si conflit. |
| S4 | Sami ne répond pas à l'email questions | Faible | Moy | Modéré | Relance douce à J+4. Avancer sur hypothèses en attendant. |
| S5 | Haithem malade / indisponible | Faible | Élevé | Majeur | Pas de backup humain. Repousser date Sami si critique. |
| S6 | Semaine solo moins productive qu'espéré | Moy | Moy | Majeur | 40h est ambitieux. 30h réaliste. Prévoir dès le départ. |

## Risques soutenance

| # | Risque | Prob | Impact | Prio | Mitigation |
|---|--------|------|--------|------|------------|
| P1 | Démo live alarme ne marche pas (device en silent, permissions) | Moy | Élevé | Critique | Vidéo Loom backup + check device avant call. |
| P2 | Démo IA cloud échoue (rate limit, réseau PALO) | Moy | Moy | Majeur | Démo en mode offline volontairement pour montrer fallback. |
| P3 | Questions techniques surprenantes (ex: memory leak, perf) | Moy | Moy | Majeur | Préparer réponses anticipées (cf liste ci-dessous). |
| P4 | Soutenance ne fit pas dans 30 min | Moy | Faible | Mineur | Répét timed avec chrono. Coupe pré-planifiée si dérape. |
| P5 | Questions sur choix produits (pourquoi cette feature) | Élevée | Faible | Mineur | ADR prêts, angle différenciant maîtrisé. |

## Risques business / stratégiques

| # | Risque | Prob | Impact | Prio | Mitigation |
|---|--------|------|--------|------|------------|
| B1 | PALO IT refuse quand même (candidat suivant préféré) | Moy | Moy | Majeur | L'effort produit Lumen reste valorisable (V1.1 publication, portfolio). |
| B2 | PALO considère que la monétisation du concept est conflit d'intérêt | Faible | Élevé | Majeur | Décision : PALO first, fork Studio après + changement de nom produit si nécessaire. |
| B3 | Nom "Lumen" indisponible sur App Store | Faible | Faible | Mineur | Vérifier ASC availability. Backup names : Dawn, Morning, Wake, Aubade. |
| B4 | Apple rejette le submit (métadonnées, guidelines) | Moy | Moy | Modéré | Lire Guidelines, submit early. |
| B5 | Compétiteur lance IA matinale avant nous | Faible | Moy | Modéré | Timing agressif, lancement sous 3 mois post-PALO. |

## Questions probables en soutenance (prep mentale)

Anticipées pour les 15 min de revue de code + 5 min Q&R :

1. **Pourquoi Swift Concurrency et pas Combine ?** → ADR-003 résumé.
2. **Pourquoi SwiftData ?** → ADR-002, en restant honnête sur les bugs jeunesse et le fallback CoreData.
3. **Comment fonctionne le waterfall IA ?** → ADR-004 + démo offline.
4. **Qu'est-ce que le monitoring éthique exactement ?** → ADR-005, export JSON live.
5. **Comment tu gères l'alarme en mode silencieux ?** → ADR-001 : best-effort documenté, discussed explicitly avec l'user.
6. **Tests Domain à 60%, comment tu as fait les choix ?** → Use cases avec logique pure prioritaires (rate limit, waterfall, snooze logic).
7. **Si tu devais scale l'app à 100k users, qu'est-ce qui change ?** → Analytics observability, Apple Intelligence on-device pour réduire coût IA, sync multi-device.
8. **Qu'est-ce qui est mal fait dans le code ?** → Préparer 2-3 dettes tech honnêtes (sans tomber dans l'auto-flagellation).
9. **Qu'est-ce que tu ferais différemment en V1.1 ?** → Widget, Apple Intelligence, historique calendrier.
10. **Question sur la synthèse IA : comment tu gères les hallucinations ?** → Content safety flags + format JSON strict + fallback template.

## Points d'attention continus

- **Privacy** : toute décision qui touche aux données user doit passer par le filtre "est-ce qu'on envoie quelque chose hors du device ?". Si oui, justifier.
- **Accessibility** : VoiceOver, Dynamic Type, contrast — à checker chaque sprint.
- **Performance** : pas d'Instruments profound en V1 mais pas de gros "laggy spinner" non plus.
- **Respect du ton** : copy relue passage par passage pour éviter la dérive "motivant toxique".
