# ADR-001 — Stratégie alarme en background

## Statut
Accepté (sous réserve de confirmation Sami sur la question fiabilité Silent/DND)

## Contexte

Le brief PALO IT impose :
- iOS 17+
- Alarme avec Snooze/Silence fonctionnelle en background
- `UserNotifications + AVFoundation` imposés
- Pas de lib tierce sur persistance

Contraintes plateforme iOS 17+ vérifiées :
- **AlarmKit** n'est disponible qu'à partir d'**iOS 26** (WWDC 2025, Apple docs). Hors cible.
- **Critical Alerts** (qui outrepassent Silent, Focus, DND) nécessitent un **entitlement Apple approuvé manuellement**, réservé aux cas santé/sécurité. Délai d'approbation non compatible avec notre deadline 11 mai (vérifié Apple Developer docs).
- `UNNotificationSound` : la durée réellement jouée via la notification est contrainte par iOS (durée souvent rapportée à ~30 s — à confirmer en test).

## Décision

### 1. Approche choisie
Alarme basée sur :
- `UNUserNotificationCenter` + `UNCalendarNotificationTrigger` pour le scheduling
- `UNNotificationCategory` avec actions `Snooze` et `Silence`
- `UNNotificationSound` pointant sur un fichier `.caf` embedded pour le déclenchement en background pur (app fermée)
- `AVAudioSession` catégorie `.playback` + option `.duckOthers` et `AVAudioPlayer` pour étendre le son **uniquement** quand l'app passe en foreground

### 2. Fiabilité

**Sans entitlement Critical Alerts, l'alarme n'est PAS garantie en :**
- Mode silencieux physique (switch latéral ou Control Center)
- Focus / Do Not Disturb
- Low Power Mode (peut retarder les notifications)

**Ce choix est assumé** : on livre une alarme fiable **hors modes silencieux**, documentée clairement côté UX (message d'information dans Settings).

Alternative envisagée et rejetée : demander Critical Alerts. Rejeté car (a) le produit n'est pas santé/sécurité, (b) délai Apple vet incompatible avec deadline.

### 3. Gestion des interruptions

- **Appel entrant** : l'alarme est interrompue par le système. L'app propose de reprendre le rituel manuellement à la réouverture.
- **Son concurrent** (Spotify, podcast) : `.duckOthers` atténue le son concurrent pendant l'alarme. Reprise normale après Snooze/Silence.
- **AirPods** : par défaut, le son sort sur la route audio active. Pas de route override en V1 (impact fiabilité).

### 4. Snooze et Silence

- Actions accessibles depuis : notification (lock screen, banner), app foreground.
- Snooze : replanifie UNE nouvelle notification à +5 min. Max 3 snooze successifs (compteur persisté SwiftData, reset à 4h AM).
- Silence : annule la chaîne, bascule sur l'écran timer si l'utilisateur ouvre l'app, sinon rien.
- Auto-stop : si l'utilisateur ne réagit pas dans les 2 min après la dernière notif, l'alarme est considérée "silenced" pour éviter les replannifications infinies.

### 5. Notifications multiples et récurrence

iOS limite à **64 notifications programmées en avance** par app. Stratégie :
- Une alarme récurrente = replanification à chaque trigger (snooze compris), pas de pré-programmation en masse.
- Cette stratégie est robuste au changement d'heure et aux modifications utilisateur.

## Conséquences

### Positives
- Respect intégral de la contrainte brief (UN + AVFoundation, pas d'AlarmKit, pas de lib tierce).
- Fiabilité explicite et testable hors modes silencieux.
- Déterminisme : 0 dépendance externe, 0 service cloud.
- Transparence utilisateur : on documente les limites dans Settings plutôt que de les cacher.

### Négatives
- **Un utilisateur qui laisse son iPhone en mode silencieux toute la nuit ratera son alarme.** C'est la limite plateforme sans Critical Alerts. À documenter dans l'onboarding et dans Settings ("Pour être réveillé à coup sûr, désactive le mode silencieux").
- La durée du son embarqué est contrainte plateforme si l'app est backgroundée au moment du trigger.
- Pas de réveil "progressive fade-in" complet si l'app est cold-launched par la notification (le fade ne peut commencer qu'après wake-up de l'app).

### Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Son de notification trop court pour réveiller | `.caf` soigneusement designé (progression dense dans les premières secondes) + fallback AVAudioPlayer si app foreground |
| Utilisateur en DND rate le rituel | Message d'onboarding explicite + notice Settings |
| Snooze en boucle | Cap à 3 snooze, puis auto-stop |
| iOS limite de 64 notifs atteinte | Replanification au trigger, pas en avance |

## À clarifier avec Sami (question 1 dans l'email envoyé)

> Fiabilité attendue de l'alarme vs modes Silence / Focus / DND. Best-effort acceptable, ou Critical Alerts envisagés ?

Cette décision est révisée si Sami répond "Critical Alerts envisagés". Dans ce cas : on documente demande entitlement, on code comme si on l'avait, on explique en soutenance que la live demo est en mode sans entitlement et qu'un passage prod nécessiterait la validation Apple.

## Références

- [AlarmKit — Apple Developer Documentation](https://developer.apple.com/documentation/AlarmKit)
- [Critical Alerts — Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.critical-alerts)
- [AVAudioSession — Apple Developer Documentation](https://developer.apple.com/documentation/AVFAudio/AVAudioSession)
- [User Notifications framework](https://developer.apple.com/documentation/usernotifications)
