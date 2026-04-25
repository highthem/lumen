# User stories — Questionnaire matinal

## Epic
En tant qu'utilisateur, je veux répondre à 4 questions courtes pour cadrer ma journée sans effort.

## Les 4 étapes (hypothèse candidat, à challenger)

1. **Ressenti** : "Comment tu te sens ce matin ?" — échelle 5 emojis + tag émotionnel optionnel
2. **Priorité** : "Qu'est-ce qui compte vraiment aujourd'hui ?" — 1 tag choisi parmi les 6 catégories + texte libre (optionnel)
3. **Gratitude** : "Une chose pour laquelle tu es reconnaissant ?" — texte libre court (≤ 140 caractères)
4. **Intention** : "En un mot, ton intention pour la journée ?" — texte libre ultra-court (≤ 30 caractères)

Rationale : 3 réponses sur 4 sont 1-tap ou ultra-courtes. Un seul texte libre plus long (gratitude). Fit avec une complétion en < 90 secondes.

## US-Q1 — Flow séquentiel 4 étapes
**En tant qu'** utilisateur
**Je veux** répondre aux 4 questions en flow continu
**Afin de** ne pas avoir de friction

**Critères d'acceptation :**
- Une question par écran, transition smooth (swipe ou animation).
- Progression visible (1 / 4, 2 / 4…).
- Retour arrière possible pour corriger.
- Skip de question possible (sauf Q1 Ressenti — obligatoire pour la synthèse IA).

## US-Q2 — Persistance locale
**En tant qu'** utilisateur
**Je veux** que mes réponses soient sauvegardées localement
**Afin de** pouvoir les revoir et que l'IA les synthétise

**Critères d'acceptation :**
- Sauvegarde via SwiftData après chaque étape (pas à la fin).
- Pas de perte de données si l'utilisateur ferme l'app entre 2 étapes.
- Reprise du questionnaire à la dernière étape non complétée si relance dans la journée.

## US-Q3 — Validation minimaliste
**En tant qu'** utilisateur
**Je veux** des inputs simples et tolérants
**Afin de** ne pas être bloqué

**Critères d'acceptation :**
- Pas de validation stricte (pas d'erreur "champ obligatoire").
- Texte libre : trim whitespaces, max-length visible.
- Q1 Ressenti : un tap obligatoire, pas de validation multi-champ.
- Bouton "Suivant" actif dès que l'input minimum est rempli.

## US-Q4 — Historique (V1.1)
**En tant qu'** utilisateur
**Je veux** voir mes réponses des derniers jours
**Afin de** observer mes patterns

**Critères d'acceptation :**
- Vue historique accessible depuis le dashboard.
- Par jour : les 4 réponses + la synthèse IA générée.
- Lecture seule en V1.1.

**Note :** repoussé en V1.1 pour ne pas alourdir la V1.

## US-Q5 — Complétion partielle
**En tant qu'** utilisateur
**Je veux** pouvoir sortir au milieu et continuer plus tard
**Afin de** ne pas être frustré

**Critères d'acceptation :**
- Si sortie avant Q4 : reprise à l'étape non complétée.
- Si l'utilisateur ne revient pas dans la journée : les réponses partielles sont persistées avec un flag `isPartial: true`.
- La synthèse IA n'est générée que si Q1 + Q4 sont remplis minimum.

## Out of scope V1
- Questions adaptatives (IA qui change la question suivante selon la précédente)
- Questionnaires thématiques (semaine / mois)
- Input vocal (dictation native OS = OK mais pas de traitement spécifique)
