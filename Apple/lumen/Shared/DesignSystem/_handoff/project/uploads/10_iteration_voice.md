# Itération Claude Design — Ajout du voice (input + output)

> À envoyer à Claude Design en suivi de la session précédente, OU à inclure dès la 1ère itération si tu n'as pas encore lancé.

---

## Le prompt à coller

J'ajoute une décision produit majeure : **input + output vocal** pour Lumen Morning. Voir le nouvel ADR-007 dans la documentation tech.

**Pourquoi :** au réveil, taper sur un clavier iOS = friction maximale (yeux fatigués, doigts maladroits, le clavier prend 50% de l'écran et casse la posture calme). Lire la synthèse à l'écran force aussi l'utilisateur à rester scotché — contre-productif.

**Décision :**
- **Q3 (Gratitude) et Q4 (Intention)** → input vocal par défaut, fallback typing
- **Synthèse IA** → bouton "Écouter" (TTS Apple natif neural)
- **Settings** → nouvelle section Voice (toggle, choix voix, vitesse)

**Tech utilisée (déjà décidé) :**
- `Speech` framework (`SFSpeechRecognizer`) avec `requiresOnDeviceRecognition = true` — l'audio ne quitte jamais le device
- `AVFoundation` (`AVSpeechSynthesizer`) avec voix neural iOS 17+
- 0 lib tierce, 0 cloud, 100% privacy on-device

## Ce que je te demande de refaire ou ajouter

### 1. Refaire les écrans Q3 (Gratitude) et Q4 (Intention)

Spec mise à jour :
- **Hero** : gros bouton micro central (taille pouce, ~80pt diamètre), couleur `--lumen-accent`, animation pulse subtile pendant l'écoute (cohérent avec le cercle respiration timer — niveau 2 "signature" du motion design)
- Auto-stop après 2s de silence détecté
- Texte transcrit s'affiche **au-dessus** du bouton micro, en typo serif large (display ou title1)
- Sous le bouton micro :
  - Bouton "Modifier" discret (passe au keyboard pour correction)
  - Bouton "Recommencer" (reset transcription)
- Placeholder vocal : "Parle, je t'écoute..." (Q3) / "Dis-le..." (Q4)
- Skip toujours possible

Variantes à designer :
- Default (avant tap)
- Listening (pendant l'enregistrement, avec pulse + waveform si possible)
- Transcribed (après l'auto-stop)
- Editing fallback (keyboard ouvert)

### 2. Refaire l'écran Synthèse IA

Ajouter :
- **Bouton "Écouter"** à côté du titre "Ton matin" (icône `speaker.wave.2` SF Symbol, 22pt, couleur `--lumen-accent`)
- États du bouton : default / playing (icône `speaker.wave.2.fill` + waveform animé) / paused (icône `speaker.wave.2.fill`)
- Tap = play/pause toggle
- Auto-pause si l'utilisateur scroll out

### 3. Nouvel écran : Settings → Voice

Section dédiée dans Settings :
- **Toggle** : "Mode vocal par défaut" (true par défaut)
- **Choix voix TTS** : liste déroulante des voix iOS natives FR + EN (preview au tap)
- **Vitesse de lecture** : segmented control 0.8x / 1.0x / 1.2x
- **Notice privacy** : "L'audio reste sur ton téléphone. Aucun envoi à Apple ou ailleurs."
- **Lien** "Vérifier les permissions" → ouvre Settings.app iOS si besoin

### 4. Mise à jour du design system

Composants à ajouter au design system :
- `MicrophoneButton` (3 états : idle, listening, transcribed)
- `SpeakerButton` (2 états : idle, playing)
- `VoiceWaveform` (optionnel, animation pendant l'écoute)
- `VoiceSettingsRow` (toggle + speed selector + voice picker)

Tokens à ajouter (si pas déjà couverts) :
- Animation pulse durée pour bouton micro (cycle 1.5s, scale 1.0 → 1.06)
- Couleur "écoute active" : variante de `--lumen-accent` plus vive (mais toujours calme)

### 5. Mise à jour du flow rituel matinal (prototype interactif)

Ajouter dans le prototype HTML cliquable :
- Q3 : tap micro → animation pulse → transcription apparaît
- Q4 : idem
- Synthèse : tap "Écouter" → simulation de lecture avec waveform

## Ce que je veux en retour

- 4 nouvelles maquettes hautes fidélité (dark + light) pour : Q3 (4 états), Q4 (4 états), Synthèse mise à jour, Settings/Voice
- Specs des nouveaux composants au format Markdown
- Update des tokens si nouveaux ajoutés
- Update du prototype HTML avec les écrans modifiés

## Délai

Idéalement avant Sprint 2 (4 mai), pour que je puisse implémenter dans le bon ordre. Sprint 1 attaque l'alarme + onboarding (pas de voice nécessaire pour ça).
