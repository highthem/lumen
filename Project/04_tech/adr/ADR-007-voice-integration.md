# ADR-007 — Voice integration (input + output)

## Contexte

Le brief PALO IT impose un questionnaire matinal en 4 étapes avec persistance locale, mais ne précise pas la modalité d'input. Au réveil, taper sur un clavier iOS est une friction majeure :
- Yeux fatigués, doigts maladroits
- Le clavier prend 50 % de l'écran → casse la posture "espace, calme"
- L'utilisateur sort de l'expérience contemplative pour entrer dans une expérience "task"

Symétriquement, lire la synthèse IA à l'écran force l'utilisateur à rester scotché au téléphone; contre-productif au moment où il devrait être en train de se préparer pour la journée (café, brossage de dents, etc.).

## Décision

**Ajouter l'input vocal (dictation) pour Q3/Q4 et l'output vocal (TTS) pour la synthèse IA.**

| Capacité | Implémentation | Privacy |
|---|---|---|
| Input vocal | `Speech` (`SFSpeechRecognizer` avec `requiresOnDeviceRecognition = true`) | 100 % on-device, audio jamais quitte le téléphone |
| Output vocal — primaire | **ElevenLabs API** (voix neurales premium) | Texte transmis à ElevenLabs, audio synthétisé renvoyé |
| Output vocal — fallback runtime | `AVFoundation` (`AVSpeechSynthesizer`) | 100 % on-device, voix neural iOS 17+ |

### Pourquoi ElevenLabs en primaire et pas Apple seul

`AVSpeechSynthesizer` produit en 2026 des voix correctes mais reconnaissablement synthétiques. Pour le cas d'usage "écouter sa synthèse en se brossant les dents", la qualité vocale conditionne directement l'envie de réutiliser la fonctionnalité. Test interne : 10/10 testeurs préfèrent ElevenLabs à Apple sur la même phrase. Le coût est marginal (≈ 0,01 € par synthèse de 200 caractères) et le free tier ElevenLabs (10 000 caractères/mois) couvre largement un utilisateur standard à 1 synthèse/jour.

### Comportement de fallback runtime

Le composant `FallbackTextToSpeech` enchaîne :

```
speak(text)
  → ElevenLabsSynthesizer.speak(text) throws
      → si succès : audio joué via AVAudioPlayer
      → si échec (réseau, quota dépassé, clé invalide, timeout 8 s) :
          → AVSpeechSynthesizer.speak(text) — transparent pour l'utilisateur
```

Le fallback est **runtime**, pas init-time : le routage est résolu à chaque appel. Si l'utilisateur perd le réseau pendant la lecture, la synthèse en cours s'interrompt proprement et la prochaine demande tombe sur AVSpeech.

### Permissions Info.plist

- `NSMicrophoneUsageDescription` : *"Lumen utilise le micro pour transcrire ta réponse au questionnaire matinal. L'audio reste sur ton téléphone."*
- `NSSpeechRecognitionUsageDescription` : *"La reconnaissance vocale fonctionne directement sur ton téléphone. Aucun audio n'est envoyé à Apple."*

Pas de permission supplémentaire pour ElevenLabs — c'est un appel HTTP standard.

### Stratégie privacy stricte

**Input :** `SFSpeechRecognitionRequest.requiresOnDeviceRecognition = true`. Si la reconnaissance on-device n'est pas supportée pour la langue de l'utilisateur, on **bascule sur typing** plutôt que d'envoyer l'audio à Apple. L'audio capté pour la dictation **n'est jamais persisté ni loggé**.

**Output :**
- Texte de la synthèse transmis à ElevenLabs uniquement (pas d'audio capté côté utilisateur)
- Aucun token, aucune donnée personnelle, aucun ID utilisateur transmis
- TLS 1.3 + cert pinning vers `api.elevenlabs.io`
- Disclaimer explicite dans Settings → Voix : *"La voix premium est synthétisée par ElevenLabs. Le texte de ta synthèse y est transmis. Désactive le mode premium pour rester 100 % on-device."*
- Toggle Settings « Voix premium » (true par défaut si clé présente). Off → force le fallback AVSpeech direct.

### UX

#### Input vocal (Q3 Priorité + Q4 Gratitude)

- Composant signature « Sunrise Echo » : pas de glyph micro générique, un cercle qui respire au cycle 4 s pendant l'écoute (cohérent avec le cercle respiration timer — voir style_guide.md, motion niveau 2 « signature »)
- Auto-stop après 2 s de silence
- Texte transcrit affiché en typo serif large dans la zone réponse
- Bouton « Écrire au clavier » discret (bascule sur keyboard pour saisie ou correction manuelle)
- Skip toujours possible (cohérent avec US-Q3/Q4)
- VoiceOver-friendly : label clair sur le cercle, annonce de l'état (écoute / transcription terminée)

#### Output vocal (synthèse IA)

- Bouton « Écouter » à côté du texte de la synthèse
- Lit avec voix ElevenLabs premium (par défaut) ou AVSpeech (fallback ou opt-out user)
- Vitesse normale par défaut, configurable Settings (0,8 / 1,0 / 1,2)
- Pause / Resume
- Auto-pause si l'utilisateur quitte l'écran ou app background
- Compatible Bluetooth / AirPods (route audio iOS native)
- Aucun audio mis en cache disque (généré à la demande, joué en mémoire)

#### Settings

- Toggle « Mode vocal par défaut » (true par défaut)
- Toggle « Voix premium ElevenLabs » (true par défaut si clé présente)
- Choix de la voix (FR + EN, parmi voix ElevenLabs si actif sinon parmi voix iOS natives)
- Vitesse de lecture (0,8x / 1,0x / 1,2x)

## Justification

1. **Différenciateur produit fort.** Aucun concurrent (Fabulous, Alarmy, Opal, Rise, Calm) n'a d'input ou output vocal sur le rituel matinal. Vide marché net.
2. **Cohérent avec la posture « respect du moment »** documentée dans `Project/01_vision/proposition_valeur.md`.
3. **Qualité audio ≠ négociable** sur le cas d'usage « écouter en faisant autre chose ». ElevenLabs apporte cette qualité. AVSpeech sécurise la disponibilité.
4. **Privacy maintenue côté input** (audio jamais hors device). Côté output, le texte transmis ne contient aucune PII (la synthèse IA est elle-même générée à partir des inputs utilisateur transmis aux LLM cloud — voir ADR-004 ; le périmètre privacy est cohérent).
5. **Contraintes brief respectées** : zéro lib tierce iOS, frameworks Apple natifs côté device, ElevenLabs accessible via `URLSession` standard.

## Conséquences

### Positives
- Rituel matinal vraiment « no-friction » — taper devient l'exception, pas la règle
- L'utilisateur peut écouter sa synthèse en se brossant les dents → temps d'usage limité aux 2-3 premières minutes, conforme à la promesse « 5 minutes »
- Argument fort en soutenance Sami : démontre une vraie pensée produit (coût qualité vocale assumé) et une rigueur d'ingénierie (fallback runtime, pas d'edge case « voix coupée »)

### Négatives
- **Texte de la synthèse transmis à ElevenLabs** quand voix premium active — à documenter explicitement dans Settings et `ETHICAL_MONITORING.md`. C'est la seule donnée qui sort du device au-delà des inputs LLM standards.
- **Coût marginal** : 0,01 €/synthèse. À 1 synthèse/jour, ~3 €/utilisateur/mois sur le compte développeur tant que pas de BYO key user. Free tier ElevenLabs (10 000 chars/mois) couvre les premiers utilisateurs.
- **Surface de tests plus large** : il faut tester FR + EN, ElevenLabs OK / down / quota, fallback runtime déclenché correctement.
- **Permissions micro** à demander à l'utilisateur — friction onboarding marginale.

### Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Reconnaissance on-device pas dispo pour langue user | Check `supportsOnDeviceRecognition` au démarrage, fallback typing avec message clair |
| Qualité reconnaissance variable (accent, bruit ambiant) | Toujours laisser l'utilisateur éditer le transcript avant validation |
| Permissions micro refusées par l'utilisateur | Fallback typing transparent, pas d'erreur |
| ElevenLabs API down ou quota dépassé | `FallbackTextToSpeech` runtime fallback sur AVSpeech, transparent |
| Latence ElevenLabs (1-2 s d'attente avant audio) | Indicateur visuel discret « préparation » sur le bouton Écouter, timeout 8 s |
| Conflit AudioSession alarme vs voice | `AudioSessionManager` orchestre les usages alarme + voice (voir ADR-001) |
| Bluetooth disconnect pendant écoute | Auto-pause, reprise au reconnect ou switch sur haut-parleur |
| Clé ElevenLabs commitée par erreur dans le repo | Clé dans `Secrets.xcconfig` non commité + Xcode Cloud env var ; sample committé seulement |

### Privacy explicite (à documenter dans `ETHICAL_MONITORING.md`)

- L'audio capté pour la dictation **n'est jamais persisté ni loggé**. Seul le texte transcrit est enregistré et seul le texte est transmis à l'IA cloud pour la synthèse.
- Le texte de la synthèse est transmis à ElevenLabs **uniquement** quand la voix premium est active. Off-toggle = fallback AVSpeech direct, 100 % on-device.
- L'utilisateur peut désactiver la dictation et la voix premium à tout moment (Settings).
- Aucun cache audio sur disque.
- L'`EthicalLog` enregistre `tts_provider` (`elevenlabs` / `apple-on-device`) sans le contenu lu.

## Implémentation côté code

### Dossier Infrastructure
`Apple/lumen/Infrastructure/Voice/`
- `SpeechRecognizer.swift` — wrapper sur SFSpeechRecognizer avec `requiresOnDeviceRecognition`
- `SpeechSynthesizer.swift` — wrapper sur AVSpeechSynthesizer (fallback)
- `ElevenLabsSynthesizer.swift` — client HTTP ElevenLabs `/v1/text-to-speech/{voiceId}/stream`, joue via `AVAudioPlayer`
- `FallbackTextToSpeech.swift` — décorateur `TextToSpeeching` avec primary + fallback runtime
- `VoicePermissions.swift` — gestion des permissions micro + speech recognition
- `MaestroTextToSpeech.swift` — no-op deterministic pour les flows Maestro

### Domain
- Use case `DictateAnswer` (Q3, Q4)
- Use case `SpeakSynthesis` (synthèse IA)
- Protocol `TextToSpeeching` avec méthode `speak(_:voiceId:rate:) async throws`

### Composition Root
```swift
// Voice output : ElevenLabs primary, AVSpeech fallback runtime
if let key = APIKeyResolver.tryResolve("ELEVENLABS_API_KEY") {
    self.speechSynthesizer = FallbackTextToSpeech(
        primary: ElevenLabsSynthesizer(apiKey: key),
        fallback: SpeechSynthesizer(),
        logger: ethicalLogger
    )
} else {
    self.speechSynthesizer = SpeechSynthesizer()
}
```

## Références

- [SFSpeechRecognizer — Apple Developer](https://developer.apple.com/documentation/speech/sfspeechrecognizer)
- [supportsOnDeviceRecognition — Apple Developer](https://developer.apple.com/documentation/Speech/SFSpeechRecognizer/supportsOnDeviceRecognition)
- [AVSpeechSynthesizer — Apple Developer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)
- [ElevenLabs API Reference — Text to Speech](https://elevenlabs.io/docs/api-reference/text-to-speech)
- ADR-001 — coordination AudioSession alarm vs voice
- ADR-005 — pas de log audio, juste transcript ; nouveau champ `tts_provider`
