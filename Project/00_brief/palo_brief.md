# Brief PALO IT — Lūmen (Morning Ritual)

**Source :** email de Sami Henchiri (CTO PALO Labs), 21 avril 2026
**Destinataire :** Haithem Ben Hamouda (candidat AI – Mobile Natif iOS & Android)
**Rôle :** exercice technique pour le rôle AI - Mobile Natif chez PALO Labs

## Pitch du produit

> "Lūmen - Morning Ritual" : une app iOS qui guide les premières minutes de la journée, du réveil à un tableau de bord, avec un questionnaire et une synthèse IA.

## Flux attendu

1. **Réveil doux** avec Snooze/Silence, fonctionnel en background
2. **Timer de présence** avec citation inspirante
3. **Questionnaire matinal** en 4 étapes, persistance locale
4. **Synthèse IA** avec fallback hors-ligne et monitoring éthique
5. **Dashboard** avec au moins 6 catégories et accès rapide à l'IA

## Livrables attendus

- Repo GitHub **privé** (Xcode 16+, build direct), partagé avec `shenchiri@palo-it.com`
- Documents :
  - `README.md`
  - `ARCHITECTURE.md`
  - `TECHNICAL_DECISIONS.md` (≥ 5 ADR)
  - `ETHICAL_MONITORING.md`
  - `ARTIFACTS.md`
- Tests : couverture minimale **60%** sur la couche Domain (logique alarme/snooze prioritaire)
- Démo : vidéo Loom ≤ 5 min **ou** lien TestFlight
- Export JSON des logs de monitoring éthique
- Présentation 10-15 slides (architecture, choix clés, démos, limites connues)

## Contraintes techniques

- **iOS 17+**, **SwiftUI** (pas d'UIKit pur), **MVVM + Clean**
- **Combine ou Swift Concurrency** (à justifier)
- **SwiftData / Core Data** pour la persistance (pas de lib tierce)
- **UserNotifications + AVFoundation** pour l'alarme en background
- **IA via OpenAI ou Anthropic**, avec journalisation et rate limiting local

## Modalités de restitution

- Partage du repo privé avec `shenchiri@palo-it.com`
- Email récapitulatif : lien repo + lien Loom/TestFlight + export JSON
- Soutenance technique 30 min : 10' archi + alarme/background, 15' revue de code, 5' Q/R

## Règle IA

> "L'usage d'outils d'IA pour accélérer est recommandé si tu es en mesure d'expliquer et défendre chaque choix."

## Chronologie

- **21 avr 2026** : Sami envoie le brief
- **22 avr 2026** : Haithem confirme réception
- **24 avr 2026** : en attente de la réponse de Sami aux 5 questions de périmètre
- **10 mai 2026** : deadline interne cible (buffer 4 jours avant Sami)
- **11 mai 2026** : deadline DURE proposée à Sami (email envoyé 24 avr)
- **Post-11 mai** : soutenance 30 min (date à caler)

## Questions posées à Sami (en attente de réponse)

1. Fiabilité alarme vs modes Silence/Focus/DND — Critical Alerts envisagés ou best-effort acceptable ?
2. Portée "pas de lib tierce" — persistance uniquement, ou projet entier ?
3. Synthèse IA — synthétise quoi (questionnaire / dashboard / les deux) et quel format de sortie ?
4. Clés API IA — fournies par PALO ou à provisionner par le candidat ?
5. `ARTIFACTS.md` — que contient ce document (captures, prompts, diagrammes, décisions) ?
