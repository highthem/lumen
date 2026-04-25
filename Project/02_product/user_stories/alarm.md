# User stories — Alarme

## Epic
En tant qu'utilisateur, je veux être réveillé de manière fiable et douce pour que mon rituel matinal démarre sans friction.

## US-A1 — Créer une alarme
**En tant qu'** utilisateur
**Je veux** définir une heure de réveil avec un son doux
**Afin de** déclencher mon rituel matinal

**Critères d'acceptation :**
- L'utilisateur choisit une heure (HH:mm), une récurrence (none / weekdays / custom days), un son (liste de 3 sons doux embarqués).
- L'alarme est persistée localement via SwiftData.
- Une notification UN est programmée via UNUserNotificationCenter.
- Permission notifications demandée à la première création avec message explicite.

## US-A2 — Sonner en background / device verrouillé
**En tant qu'** utilisateur
**Je veux** que l'alarme sonne même si l'app est fermée ou le device verrouillé
**Afin de** ne pas rater mon réveil

**Critères d'acceptation :**
- Le son est programmé dans `UNNotificationSound` embarqué (fichier ≤ 30s connu comme limite plateforme, à vérifier).
- Si l'utilisateur interagit avec la notification, un mécanisme AVAudioSession + AVAudioPlayer étend le son au-delà de la durée native si l'app est foreground.
- Catégorie de notification avec actions : **Snooze** (5 min par défaut), **Silence** (arrêt complet).
- Limitations connues documentées dans ADR-001 : sans Critical Alerts entitlement, l'alarme peut être muted en mode Silent/Focus/DND.

## US-A3 — Snooze
**En tant qu'** utilisateur
**Je veux** pouvoir reporter l'alarme de 5 minutes
**Afin de** prendre quelques minutes supplémentaires

**Critères d'acceptation :**
- Action "Snooze" dispo depuis la notification, depuis le lock screen et depuis l'app.
- Nombre max de snooze : **3** (configurable en hypothèse, à valider).
- Après 3 snooze, le bouton Snooze est désactivé et remplacé par "Silence" uniquement.
- Chaque snooze est loggé (pour monitoring éthique et debug).

## US-A4 — Silence
**En tant qu'** utilisateur
**Je veux** arrêter l'alarme définitivement
**Afin de** passer au rituel ou reprendre ma journée

**Critères d'acceptation :**
- Action "Silence" dispo depuis la notification et depuis l'app.
- Si l'utilisateur ouvre l'app après Silence, l'onboarding du rituel démarre (US-T1).
- Si l'utilisateur ne réagit pas dans les 2 min après la dernière notif, l'alarme se met en silence automatiquement (auto-stop documenté).

## US-A5 — Son concurrent (édge case)
**En tant qu'** utilisateur écoutant un podcast ou ayant un appel en cours
**Je veux** que l'alarme se comporte de manière prévisible
**Afin de** ne pas avoir une expérience cassée

**Critères d'acceptation :**
- AVAudioSession category `.playback` avec option `.duckOthers` : le son concurrent est atténué pendant l'alarme.
- Après snooze/silence, le son reprend son niveau normal.
- Si appel entrant : l'alarme s'interrompt (comportement système natif), le user ré-ouvre l'app post-appel pour continuer le rituel.
- Documenté en ADR.

## US-A6 — Lister et modifier les alarmes
**En tant qu'** utilisateur
**Je veux** voir mes alarmes actives et les modifier
**Afin de** adapter mon rituel selon mes rythmes

**Critères d'acceptation :**
- Liste simple des alarmes (heure, récurrence, actif/inactif).
- Toggle rapide actif/inactif sans ouvrir le détail.
- Édition = mêmes champs qu'en création.
- Suppression avec confirmation.

## US-A7 — Réveil doux progressif (nice-to-have V1)
**En tant qu'** utilisateur
**Je veux** que le son monte progressivement de 0 à 100% sur 30s
**Afin de** ne pas être brutalement réveillé

**Critères d'acceptation :**
- AVAudioPlayer avec `setVolume(_, fadeDuration:)` si l'app est foreground.
- Si l'app est background uniquement, la notif joue le son normalement (pas de fade possible nativement).
- Documenté : le fade complet n'est garanti que si l'app est pré-lancée le matin.

## Out of scope V1
- Alarme vocale IA (réveil personnalisé par synthèse vocale)
- Réveil basé sur le cycle de sommeil (smart alarm)
- Sync Apple Watch
