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

## US-T6 — Audio ambient pendant le timer (NOUVEAU)
**En tant qu'** utilisateur en moment de présence
**Je veux** un son d'ambiance discret qui soutient ma respiration
**Afin de** ne pas être seul·e dans le silence si je préfère un soutien sonore

**Critères d'acceptation :**
- 3 ambiances disponibles : `breath-aube` (default, 4 s breath cycle synchronisé avec le cercle visuel), `breath-bois` (field recording forêt), `breath-silence` (quasi-silence avec marqueurs début/fin)
- Choix dans Settings → Rituel → "Ambiance du timer"
- Toggle "Activer l'ambiance" — par défaut OFF (silence) pour ne pas surprendre l'utilisateur au 1er lancement
- Quand l'utilisateur active : preview de 5 s avant validation
- Audio joue à -20 LUFS (background), respecte `AVAudioSession .ambient` (cohabitation avec autres apps audio)
- Reduce Motion ne désactive PAS l'audio (le son ne crée pas de mouvement visuel)
- Skip du timer = stop immédiat de l'audio
- Voir `Design/sound-kit/01_brief.md` pour les spec audio détaillées

## Out of scope V1
- Guidance respiratoire vocale (inspire/expire dictée)
- Timer variable selon l'heure du réveil
- Sons custom uploadés par l'utilisateur (V1.1 si demandé)
