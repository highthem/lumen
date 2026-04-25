# Critères d'acceptation V1

Pour qu'une feature soit considérée "DONE" et entre en démo de soutenance, elle doit passer les critères suivants.

## Critères transverses (toutes features)

- [ ] Code compile sans warnings sur Xcode 16+
- [ ] Unit tests écrits pour la logique métier (Domain layer)
- [ ] Pas de force unwrap hors tests
- [ ] Pas de `print` en prod (logger dédié)
- [ ] VoiceOver fonctionne sur les écrans clés
- [ ] Dark mode support (par défaut SwiftUI + validation visuelle)
- [ ] Pas de fuite mémoire sur 5 min d'usage (Xcode Instruments check rapide)

## F1 — Alarme

- [ ] Une alarme sonne à l'heure prévue même app fermée, device verrouillé
- [ ] Les actions Snooze et Silence fonctionnent depuis la notification, le lock screen et l'app
- [ ] Snooze replanifie pour +5 min, max 3 fois
- [ ] AVAudioSession `.playback` + `.duckOthers` testé avec un podcast en cours
- [ ] Après appel entrant, l'app propose de reprendre manuellement
- [ ] Permissions refusées → parcours dégradé sans crash
- [ ] Limites documentées dans ADR-001 (Critical Alerts absents, modes silent/DND)

## F2 — Timer

- [ ] Démarre automatiquement après Silence de l'alarme
- [ ] Durée réglable 30/60/120s, par défaut 60s
- [ ] Citation aléatoire depuis JSON local, pas de répétition sous 7 jours
- [ ] Skip possible, loggé
- [ ] Animation circulaire fluide, VoiceOver annonce début et fin

## F3 — Questionnaire

- [ ] Les 4 étapes dans l'ordre, transition fluide
- [ ] Persistance SwiftData à chaque étape (pas de perte si crash app)
- [ ] Reprise à l'étape non complétée
- [ ] Skip possible sauf Q1 (Ressenti)
- [ ] Q1 Ressenti : 5 emojis + tag émotionnel optionnel
- [ ] Q3 et Q4 respectent les limites de caractères (140 et 30)

## F4 — Synthèse IA

- [ ] Appel OpenAI en primaire (clé via xcconfig)
- [ ] Fallback Anthropic si OpenAI fail (timeout, 5xx, rate limit)
- [ ] Fallback offline template si les deux fail ou si `NWPathMonitor` détecte offline
- [ ] Temps génération < 4s cloud, < 1s offline
- [ ] Streaming supporté côté OpenAI si possible
- [ ] Format synthèse : intention + focus + rappel (3 sections visibles)
- [ ] Badge "Hors-ligne" visible si mode offline

## F5 — Rate limiting + monitoring éthique

- [ ] 1 synthèse auto + 3 régénérations manuelles par jour max
- [ ] Compteur reset à minuit local
- [ ] Chaque appel loggé avec tous les champs spec (US-AI5)
- [ ] Pas de PII dans les logs
- [ ] Export JSON complet accessible depuis Settings
- [ ] Prompt hashé, pas stocké en clair

## F6 — Dashboard

- [ ] 6 cards en grille 2 colonnes
- [ ] Pré-remplissage automatique depuis réponses questionnaire
- [ ] Détail par catégorie avec édition possible du jour
- [ ] Pas de graphiques
- [ ] Reset silencieux à 3h du matin local
- [ ] Empty state au premier lancement, CTA alarme

## F7 — Ask Lumen

- [ ] Bouton global accessible depuis dashboard
- [ ] Rate limit partagé avec F5
- [ ] Réponse en modal, bouton Fermer
- [ ] Log monitoring éthique

## Qualité technique

- [ ] Architecture MVVM + Clean respectée : couche Domain sans import UIKit / SwiftUI
- [ ] Couverture tests ≥ 60% sur Domain
- [ ] Swift Concurrency utilisée (async/await, actors), justifiée ADR-003
- [ ] SwiftData, justifiée ADR-002
- [ ] Zero lib tierce pour persistance (cf H2 en attente validation Sami)

## Livrables

- [ ] Repo GitHub privé partagé avec shenchiri@palo-it.com
- [ ] Xcode 16+, build direct sans config additionnelle hors xcconfig keys
- [ ] 5 documents .md (README, ARCHITECTURE, TECHNICAL_DECISIONS, ETHICAL_MONITORING, ARTIFACTS)
- [ ] Loom ≤ 5 min OU TestFlight link fonctionnel
- [ ] Présentation 10-15 slides
- [ ] Export JSON monitoring éthique joint à l'email récap

## Soutenance

- [ ] Démo live de l'alarme en background reproductible
- [ ] Plan B si la démo live échoue (vidéo Loom de secours)
- [ ] 10 min archi + alarme prêts
- [ ] 15 min revue de code : mettre en avant Domain layer, ADR, rate limiting, monitoring
- [ ] Anticiper les Q&R probables (cf 06_roadmap/risks.md)
