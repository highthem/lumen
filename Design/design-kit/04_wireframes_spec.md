# Spec des écrans V1

Description texte des 10 écrans pour Claude Design. Pas de maquette ASCII : Claude Design produira les hautes fidélités.

## 1. Onboarding (4 écrans)

### 1.1 Welcome
- Fond : `bg-primary` avec léger dégradé chaud centre-haut
- Hero : typo serif display "Lumen" en bas à gauche
- Sous-titre : "Un rituel matinal pour commencer avec intention."
- CTA bas : "Commencer"

### 1.2 Pitch
- Illustration (optionnel V1) ou typo centrée
- Texte : "5 minutes. Pas plus. Pour cadrer ta journée avant qu'elle ne te cadre."
- CTA : "Suivant"

### 1.3 Permissions
- Titre : "On a besoin de deux choses."
- Liste :
  - "📍 Te notifier à l'heure choisie" (avec CTA "Activer")
  - "🔔 Jouer un son doux quand c'est l'heure"
- Sous-texte : "On ne t'envoie rien d'autre. Promis."
- CTA principal : "Continuer"

### 1.4 Première alarme
- Titre : "À quelle heure veux-tu qu'on commence ?"
- Picker : time selector (iOS native), défaut 07:00
- Sous-texte : "Tu pourras changer plus tard."
- CTA : "Programmer"

## 2. Dashboard home (idle / post-rituel / empty)

### États

**Empty state (premier lancement) :**
- Titre : "Ton premier matin t'attend."
- Sous-texte : "Programme une alarme. On s'occupe du reste."
- CTA : "Programmer mon réveil"
- Illustration discrète ou typographie hero

**Idle (rituel pas fait aujourd'hui) :**
- Titre top : "Bonjour [prenom si connu, sinon rien]"
- Bandeau : "Tu n'as pas encore fait ton rituel. Prêt ?" avec CTA "Démarrer"
- 6 cards grisées en dessous (placeholder)

**Post-rituel :**
- Titre top : "Aujourd'hui" + date (format "Lundi 11 mai")
- Synthèse du jour (intention + focus court) en card hero
- 6 cards remplies en grille 2 colonnes

### 6 cards
1. **Énergie** : emoji humeur + label textuel ("posé", "fragile", "en forme")
2. **Intention** : 1-3 mots en serif display
3. **Corps** : 2 lignes de check-in (sommeil, hydratation)
4. **Relations** : 1 nom ou prompt "Qui soutenir ?"
5. **Travail** : priorité en 1 ligne
6. **Gratitude** : la phrase du matin en serif

### Footer
- Bouton flottant "Ask Lumen" (circulaire, accent, bottom right)

## 3. Création / édition alarme

- Titre : "Nouvelle alarme" (ou "Modifier alarme")
- Time picker wheel (iOS native)
- Segmented : récurrence (Jamais / Jours de semaine / Tous les jours / Personnalisé)
- Liste 3 sons doux sélectionnables (preview au tap)
- Toggle : "Activer"
- CTA : "Enregistrer"
- Si édition : bouton Supprimer en bas discret

## 4. Écran "alarme sonne" (app foreground)

- Fond plein écran `bg-primary`, cercle animé lent au centre
- Heure en serif display XXL
- 2 CTAs :
  - Haut : "Snooze 5 min" (secondary)
  - Bas : "Silence" (primary, plein-largeur)
- Icône subtile de vibration haut-droite si son actif

## 5. Timer de présence

- Fond `bg-primary`
- Citation en serif display centrée (3-4 lignes max)
- Cercle qui se remplit progressivement en dessous (barre de progression radiale)
- Pas de chiffres par défaut (option dans settings pour les afficher)
- Bouton discret "Passer" en bas-droite
- Animation respiration (scale 1.0 → 1.05 → 1.0, cycle 4s) sur le cercle

## 6. Questionnaire (4 écrans)

### Q1 — Ressenti
- Titre : "Comment tu te sens ?"
- Ligne de 5 emojis tap-able (😔 😐 😊 ☺️ 🌟 — à affiner par design)
- Sous-ligne optionnelle : tag émotionnel ("fatigué", "serein", "anxieux"...)
- CTA : "Suivant" (activé après tap emoji)

### Q2 — Priorité
- Titre : "Qu'est-ce qui compte aujourd'hui ?"
- Grille 6 catégories (chips)
- Zone texte libre sous les chips : "Précise si tu veux (optionnel)"
- CTA : "Suivant" (activé si chip sélectionnée)

### Q3 — Gratitude
- Titre : "Une gratitude ?"
- **Input vocal par défaut** : gros bouton micro central (taille pouce, ~80pt), animation pulse subtile pendant l'écoute
- Auto-stop après 2s de silence
- Texte transcrit affiché en serif large dans la zone réponse
- Bouton "Modifier" discret (passe au keyboard typing pour correction) + bouton "Recommencer"
- Fallback typing : si permissions micro refusées ou langue non on-device → textarea 3 lignes (max 140 caractères, compteur discret)
- Placeholder vocal : "Parle, je t'écoute..."
- Placeholder typing fallback : "Un moment, une personne, une chose..."
- CTA : "Suivant" (activé si > 0 caractère ou bouton Skip)

### Q4 — Intention
- Titre : "Ton intention en un mot."
- **Input vocal par défaut** : même UI que Q3 (micro central + transcription)
- Auto-stop court (1s de silence — un mot suffit)
- Texte transcrit affiché en typo display
- Fallback typing : input single-line grande typo (max 30 caractères, compteur)
- Placeholder vocal : "Dis-le..."
- Placeholder typing fallback : "focus", "patience", "présence"...
- CTA : "Voir ma synthèse" (activé si > 0 caractère)

### Transitions
- Swipe horizontal + fade (pas de sauts).
- Progress bar fine en haut (4 segments).

## 7. Synthèse IA

- Fond `bg-primary`, gradient léger vers `accent-muted` en haut
- Titre en haut : "Ton matin"
- 3 blocs empilés en scroll :
  1. **Intention** (serif display)
  2. **Focus** (body, 1-2 actions suggérées)
  3. **Rappel** (italic, ton présence)
- Badge discret "Hors-ligne" si fallback offline
- **Bouton "Écouter"** (icône `speaker.wave.2`) à côté du titre — joue la synthèse à voix haute via TTS Apple natif, voix neural iOS 17+
- Bouton "Régénérer" en bas (secondary, avec compteur 2/3 restantes)
- Bouton "Continuer vers le dashboard" (primary)

## 8. Dashboard détail catégorie

- Navigation bar retour
- Titre : nom de la catégorie + icône
- Contenu du jour éditable
- Section "7 derniers jours" (liste compacte, lecture seule)
- Bouton "Ask Lumen" contextuel en bas

## 9. Ask Lumen modal

- Présentée en modal half-sheet
- Titre : "Ask Lumen"
- Message utilisateur (si contextuel) en chip top
- Zone réponse IA en body (texte streaming si dispo)
- Bouton "Fermer"
- Compteur rate limit en bas ("2 questions restantes aujourd'hui")

## 10. Settings

- Sections :
  - **Rituel** : heure alarme par défaut, son, durée timer
  - **Voice** (NEW, ADR-007) : toggle "Mode vocal par défaut" (true), choix voix TTS, vitesse lecture (0.8x/1x/1.2x), info "audio reste sur ton téléphone"
  - **IA** : rate limit info (read-only), provider status
  - **Monitoring éthique** : bouton "Exporter en JSON"
  - **Apparence** : dark / light / system
  - **À propos** : version, licenses, privacy

## Écrans out of scope V1

- Historique des synthèses
- Vue calendrier mensuel
- Paramétrage avancé alarme (multiple alarms par jour, vibration patterns)

## Palette d'états clés à designer

- Loading (pendant appel IA) — skeleton ou animation subtile
- Offline — badge
- Permissions refusées — notice douce dans dashboard
- Rate limit atteint — toast ou card info
