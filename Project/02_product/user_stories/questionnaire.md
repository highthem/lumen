# User stories — Questionnaire matinal

## Epic
En tant qu'utilisateur, je veux répondre à 4 questions courtes pour cadrer ma journée sans effort.

## Les 4 étapes

1. **Humeur** : "Aujourd'hui je me sens…" — `ChromaticSlider` plein écran, drag vertical continu (0→1, 5 paliers : enfoui / fragile / posé / vif / rayonnant)
2. **Énergie** : "Quelle énergie ce matin ?" — 5 chips (À plat / Faiblard / Moyen / Bien chargé / Au top)
3. **Priorité** : "Sur quoi tu veux poser l'attention ?" — **vocal par défaut** (4 états : default / listening / transcribed / editing) + fallback typing libre
4. **Gratitude** : "Une gratitude ?" — **vocal par défaut** (mêmes 4 états) + fallback typing (≤ 140 caractères)

Rationale : Q1 = drag continu (zéro tap). Q2 = 1 tap chip. Q3 + Q4 = dictation vocale on-device, typing en fallback. Complétion en < 90 secondes sans clavier prolongé. Le bouton final passe à "Voir ma synthèse" sur Q4.

Voir `Project/04_tech/adr/ADR-007-voice-integration.md` pour le détail technique (Speech framework + TTS).

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

## US-Q6 — Input vocal pour Q3 Priorité + Q4 Gratitude (voir ADR-007)
**En tant qu'** utilisateur qui vient d'ouvrir les yeux
**Je veux** dicter ma priorité et ma gratitude au lieu de taper
**Afin de** ne pas avoir à manipuler le clavier au réveil

**Critères d'acceptation (s'appliquent à Q3 et Q4) :**
- Q3 et Q4 partagent le composant `VoiceCaptureField` — 4 états visibles : default / listening / transcribed / editing.
- État `default` : bouton micro central large (taille pouce) + invitation textuelle ("Appuie pour parler" ou équivalent).
- État `listening` : animation pulse subtile pendant l'écoute (cohérent avec cercle respiration timer).
- État `transcribed` : texte transcrit affiché en typo serif large dans la zone réponse.
- État `editing` : bouton "Écrire au clavier" discret pour passer en saisie textuelle (id `priority-keyboard-toggle` / `gratitude-keyboard-toggle` pour Maestro).
- Auto-stop après 2 s de silence détecté.
- Bouton "Recommencer" si transcription ratée.
- Reconnaissance vocale en mode `requiresOnDeviceRecognition = true` — l'audio ne quitte jamais le device.
- Si la langue de l'utilisateur n'est pas supportée on-device, fallback transparent vers typing (jamais cloud Apple).
- Si permissions micro refusées : fallback typing, pas d'erreur, pas de relance.
- VoiceOver : label "Bouton micro, double-tape pour parler" + annonce d'état (écoute / transcription terminée).

## Out of scope V1
- Questions adaptatives (IA qui change la question suivante selon la précédente)
- Questionnaires thématiques (semaine / mois)
- Multi-langues simultanées (langue de la dictation suit celle du device)
- Personnalisation du language model (iOS 17+ permet via SFSpeechLanguageModel — repoussé V1.1)
