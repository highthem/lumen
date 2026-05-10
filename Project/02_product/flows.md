# Flows

## Flow principal — Rituel matinal (happy path)

```
[Alarme sonne en background]
       ↓
[User tape "Silence" depuis la notification]
       ↓
[App ouvre sur écran Timer de présence (60s par défaut)]
       ↓ (après durée ou skip)
[Q1 — Humeur]
       ↓
[Q2 — Energie]
       ↓
[Q3 — Priorité]
       ↓
[Q4 — Gratitude]
       ↓
[Appel IA waterfall : OpenAI → Anthropic → offline]
       ↓
[Écran Synthèse IA : intention + focus + rappel]
       ↓ (après lecture)
[Dashboard 6 catégories pré-remplies]
       ↓
[User ferme l'app ou explore une catégorie]
```

## Flow — Snooze

```
[Alarme sonne]
       ↓
[User tape "Snooze" depuis la notification]
       ↓
[Alarme replanifiée +5 min] ← (max 3 fois)
       ↓
[Retour à "Alarme sonne"]
```

## Flow — Sortie en cours de rituel

```
[Questionnaire en cours : par exemple Q2]
       ↓
[User ferme l'app]
       ↓ ou [Plus tard dans la journée]
[User rouvre Lumen]
       ↓
[App détecte : rituel incomplet, dernière étape Q2]
       ↓
[Prompt : "Reprendre ton rituel de ce matin ?"]
  └── Oui → reprise à Q3
  └── Non → Dashboard en mode "rituel partiel"
```

## Flow — Appel entrant pendant l'alarme

```
[Alarme sonne]
       ↓
[Appel entrant (système prend la main)]
       ↓
[Alarme interrompue par iOS]
       ↓ [User raccroche]
[Alarme ne reprend pas automatiquement]
       ↓
[User ouvre Lumen manuellement]
       ↓
[App propose : "L'alarme a été interrompue. Démarrer le rituel maintenant ?"]
```

## Flow — Mode hors-ligne

```
[Fin du questionnaire]
       ↓
[Tentative appel OpenAI]
       ↓ [Échec réseau]
[Tentative appel Anthropic]
       ↓ [Échec réseau]
[Fallback offline : template par humeur Q1]
       ↓
[Affichage synthèse avec badge "Hors-ligne"]
       ↓
[Log monitoring éthique : mode=offline]
```

## Flow — Ask Lumen depuis dashboard

```
[Dashboard]
       ↓
[User tape bouton "Ask Lumen"]
       ↓
[Vérification rate limit (3/jour)]
  └── Limite atteinte → Toast "Reviens demain pour une nouvelle question"
  └── OK → continuer
       ↓
[Appel IA avec prompt contextualisé sur la catégorie si détail, sinon prompt général]
       ↓
[Modal avec réponse]
       ↓
[Bouton Fermer]
       ↓
[Log monitoring éthique : mode=manual-regen]
```

## Flow — Premier lancement (onboarding)

```
[Ouverture app]
       ↓
[Écran 1 — Bienvenue / pitch en 1 phrase]
       ↓
[Écran 2 — "Donne-toi 5 minutes chaque matin"]
       ↓
[Écran 3 — Permissions (notifications, optionnel)]
       ↓
[Écran 4 — Première alarme à programmer]
       ↓
[Dashboard en empty state]
```

## États globaux à gérer

| État | Déclencheur | UI |
|------|-------------|-----|
| `idle` | App ouverte sans alarme en cours | Dashboard |
| `alarm_ringing` | Heure alarme atteinte | Notification + (si app ouverte) modal |
| `ritual_active` | User a silencé l'alarme et démarré | Timer → Questionnaire → Synthèse |
| `ritual_partial` | Rituel commencé et abandonné, pas encore la fin de journée | Dashboard avec bandeau "Reprendre" |
| `ritual_done` | Rituel complété pour la journée | Dashboard complet |
| `offline` | Pas de réseau | Badge, fallback IA |
