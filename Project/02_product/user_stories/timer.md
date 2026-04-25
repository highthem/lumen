# User stories — Timer de présence

## Epic
En tant qu'utilisateur, je veux un court moment de pause avant la réflexion pour ancrer ma présence.

## US-T1 — Démarrage automatique après alarme
**En tant qu'** utilisateur qui vient d'arrêter son alarme
**Je veux** être guidé immédiatement vers un moment de présence
**Afin de** ne pas aller sur Instagram par réflexe

**Critères d'acceptation :**
- Après Silence (US-A4), l'app s'ouvre directement sur l'écran du timer.
- Aucun tap intermédiaire nécessaire.
- Écran minimaliste : durée, citation, bouton "Commencer".

## US-T2 — Timer configurable
**En tant qu'** utilisateur
**Je veux** pouvoir choisir la durée du timer (30s / 60s / 120s)
**Afin de** adapter selon mon temps dispo

**Critères d'acceptation :**
- Réglage accessible depuis l'écran timer (segmented control).
- Durée par défaut : **60s**.
- Changement persisté pour les prochains démarrages.

## US-T3 — Citation inspirante
**En tant qu'** utilisateur
**Je veux** une citation pendant le timer
**Afin de** avoir un ancrage mental pendant la présence

**Critères d'acceptation :**
- Citations chargées depuis un fichier JSON embarqué (pas de dépendance réseau).
- Sélection aléatoire parmi ~50 citations bilingues FR/EN.
- Catégories : gratitude, intention, présence, acceptation.
- Pas de citations religieuses ni politiques.
- Pas de répétition d'une même citation avant 7 jours (tracking léger via SwiftData).

## US-T4 — Progression visuelle
**En tant qu'** utilisateur
**Je veux** voir le temps qui passe sans anxiété
**Afin de** rester dans le moment

**Critères d'acceptation :**
- Cercle qui se remplit progressivement.
- Pas de chiffres qui défilent (évite le "compte à rebours anxiogène").
- Animation fluide 60 FPS.
- Accessible VoiceOver : annonce en début et fin.

## US-T5 — Skip et reprise
**En tant qu'** utilisateur pressé
**Je veux** pouvoir passer le timer
**Afin de** aller directement au questionnaire

**Critères d'acceptation :**
- Bouton "Passer" discret mais accessible.
- Skip loggé (pour monitoring comportemental, pas pour culpabiliser).
- Si skip > 3 fois consécutives, proposer de réduire la durée par défaut (nudge UX, pas une alerte).

## Out of scope V1
- Son / musique pendant le timer
- Guidance respiratoire (inspire/expire)
- Timer variable selon l'heure du réveil
