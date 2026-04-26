# ADR-007 — Voice integration (input + output)

## Statut
Accepté (25 avr 2026, sur insight produit Haithem)

## Contexte

Le brief PALO IT impose un questionnaire matinal en 4 étapes avec persistance locale, mais ne précise pas la modalité d'input. Notre spec initiale (US-Q3, US-Q4) demandait du typing pour la Gratitude (≤140 chars) et l'Intention (≤30 chars). Au réveil, taper sur un clavier iOS est une friction majeure :
- Yeux fatigués, doigts maladroits
- Le clavier iOS prend 50% de l'écran → casse la posture "espace, calme"
- L'utilisateur sort de l'expérience contemplative pour entrer dans une expérience "task"

Symétriquement, lire la synthèse IA à l'écran force l'utilisateur à rester scotché au téléphone — contre-productif au moment où il devrait être en train de se préparer pour la journée (café, brossage de dents, etc.).

## Décision

**Ajouter l'input vocal (dictation) pour Q3/Q4 et l'output vocal (TTS) pour la synthèse IA — en V1.**

| Capacité | Framework Apple | Coût | Privacy |
|---|---|---|---|
| Input vocal | `Speech` (`SFSpeechRecognizer`) | 0 | On-device requis (`requiresOnDeviceRecognition = true`) |
| Output vocal | `AVFoundation` (`AVSpeechSynthesizer`) | 0 | 100 % on-device, voix neural iOS 17+ |

### Permissions Info.plist

- `NSMicrophoneUsageDescription`: *"Lumen utilise le micro pour transcrire ta réponse au questionnaire matinal. L'audio reste sur ton téléphone."*
- `NSSpeechRecognitionUsageDescription`: *"La reconnaissance vocale fonctionne directement sur ton téléphone. Aucun audio n'est envoyé à Apple."*

### Stratégie privacy stricte

`SFSpeechRecognitionRequest.requiresOnDeviceRecognition = true` (iOS 13+). Si la reconnaissance on-device n'est pas supportée pour la langue de l'utilisateur (varie selon device + langue, à check via `SFSpeechRecognizer.supportsOnDeviceRecognition`), on **bascule sur typing** plutôt que d'envoyer l'audio à Apple. Conforme à notre posture privacy-first.

### UX

#### Input vocal (Q3 Gratitude + Q4 Intention)

- Bouton micro central, large (taille pouce), animation pulse subtile pendant l'écoute (cohérent avec le cercle respiration timer — voir style_guide.md, motion niveau 2 "signature")
- Auto-stop après 2 s de silence
- Texte transcrit affiché en typo serif large dans la zone réponse
- Bouton "Modifier" discret (passe au keyboard pour correction manuelle)
- Bouton "Recommencer" si transcription ratée
- Skip toujours possible (cohérent avec US-Q3/Q4 actuelles)
- VoiceOver-friendly : label clair sur le micro, annonce de l'état (écoute / transcription terminée)

#### Output vocal (synthèse IA)

- Bouton "Écouter" (icône `speaker.wave.2`) à côté du texte de la synthèse
- Lit avec voix neural iOS 17+ (qualité Eloquence ou autre)
- Vitesse normale, pas de drama narratif
- Compatible Bluetooth / AirPods (route audio par défaut iOS)
- Pause / Resume possible
- Auto-pause si l'utilisateur quitte l'écran

#### Settings

- Toggle "Mode vocal par défaut" (true par défaut)
- Choix de la voix TTS (parmi voix iOS natives FR + EN)
- Vitesse de lecture (0.8x / 1.0x / 1.2x)

## Justification

1. **Différenciateur produit fort.** Aucun des 4 concurrents (Fabulous, Alarmy, Opal, Rise) n'a d'input ou output vocal sur le rituel matinal. Vide marché net.
2. **Cohérent avec la posture "respect du moment"** documentée dans `Project/01_vision/proposition_valeur.md`.
3. **Cohérent avec la posture "ethical AI"** : audio jamais hors device, renforce la promesse privacy.
4. **Effort raisonnable** : ~1.5 jour total (0.75 input + 0.5 output + 0.25 tests). Rentre dans Sprint 2.
5. **Contraintes brief respectées** : zéro lib tierce, frameworks Apple natifs, iOS 17+.

## Conséquences

### Positives
- Rituel matinal vraiment "no-friction" — taper devient l'exception, pas la règle.
- L'utilisateur peut écouter sa synthèse en se brossant les dents → temps d'usage de l'app vraiment limité aux 2-3 premières minutes, conforme à la promesse "5 minutes pour cadrer ta journée".
- Argument fort en soutenance Sami : démontre une vraie pensée produit, pas juste une exécution technique.
- Privacy boost démontrable (audio on-device, à montrer dans Settings).

### Négatives
- **Surface de tests plus large** : il faut tester FR + EN, sur device A17+ et device plus ancien, avec et sans Bluetooth.
- **Permissions supplémentaires** à demander à l'utilisateur — friction onboarding marginale.
- **Si on-device pas supporté** pour la langue (cas rare en FR/EN mais possible), fallback typing → l'expérience dégradée doit être documentée clairement.

### Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Reconnaissance on-device pas dispo pour langue user | Check `supportsOnDeviceRecognition` au démarrage, fallback typing avec message clair |
| Qualité reconnaissance variable (accent, bruit ambiant) | Toujours laisser l'utilisateur éditer le transcript avant validation |
| Permissions micro refusées par l'utilisateur | Fallback typing transparent, pas d'erreur |
| TTS interrompu par notification système | `AVAudioSession` configuré pour reprendre |
| Bluetooth disconnect pendant écoute | Auto-pause, reprise au reconnect ou switch sur haut-parleur |
| Conflit avec le module alarme (audio session category) | Voir ADR-001 — audio session unique gérée par `AudioSessionManager`, qui orchestre les usages alarme + voice |

### Privacy explicite (à documenter dans ETHICAL_MONITORING.md)

- L'audio capté pour la dictation **n'est jamais persisté ni loggé**. Seul le texte transcrit est enregistré (et seul le texte est transmis à l'IA cloud pour la synthèse).
- L'utilisateur peut désactiver la dictation à tout moment (Settings).
- La synthèse vocale (TTS) est purement output, ne capte pas d'audio.

## Implémentation côté code

### Nouveau dossier
`Apple/lumen/Infrastructure/Voice/`
- `SpeechRecognizer.swift` — wrapper sur SFSpeechRecognizer avec `requiresOnDeviceRecognition`
- `SpeechSynthesizer.swift` — wrapper sur AVSpeechSynthesizer avec choix de voix
- `VoicePermissions.swift` — gestion des permissions micro + speech recognition

### Domain
- Nouveau use case `DictateAnswer` (Q3, Q4)
- Nouveau use case `SpeakSynthesis` (synthèse IA)

### Features
- `Questionnaire/Q3GratitudeView.swift` et `Q4IntentionView.swift` ajoutent le bouton micro central
- `Synthesis/SynthesisView.swift` ajoute le bouton "Écouter"
- `Settings/VoiceSettingsView.swift` (nouveau) — toggle + choix voix + vitesse

## Effort estimé

| Tâche | Effort |
|---|---|
| `SpeechRecognizer` wrapper + permissions | 0.4 j |
| `SpeechSynthesizer` wrapper + choix voix | 0.3 j |
| UI Q3/Q4 avec bouton micro + animation | 0.3 j |
| UI synthèse avec bouton speaker | 0.2 j |
| Settings vocal | 0.2 j |
| Tests (Speech mocks, AudioSession, fallbacks) | 0.3 j |
| **Total** | **~1.7 j** |

À intégrer en Sprint 2 (4-9 mai), tâches dans `Project/06_roadmap/sprints.md`.

## Références

- [SFSpeechRecognizer — Apple Developer](https://developer.apple.com/documentation/speech/sfspeechrecognizer)
- [supportsOnDeviceRecognition — Apple Developer](https://developer.apple.com/documentation/Speech/SFSpeechRecognizer/supportsOnDeviceRecognition)
- [AVSpeechSynthesizer — Apple Developer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)
- [Customize on-device speech recognition — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10101/)
- [Project/04_tech/adr/ADR-001-alarme-background.md](./ADR-001-alarme-background.md) — coordination AudioSession alarm vs voice
- [Project/04_tech/adr/ADR-005-monitoring-ethique.md](./ADR-005-monitoring-ethique.md) — pas de log audio, juste transcript
