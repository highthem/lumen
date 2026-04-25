# Prompt initial à coller dans Claude Design (Anthropic Labs)

> Tu utilises **Claude Design** (Anthropic Labs, Claude Opus 4.7) — pas un chat Claude classique.
> Capacités : text + image + DOCX/PPTX/XLSX + **codebase ref** + **web capture** + outputs **prototypes interactifs** (HTML, Canva, PPTX, PDF).

---

## Le prompt à coller

Tu es designer produit senior, spécialisé en iOS et apps wellness/lifestyle. Je travaille sur **Lumen Morning**, une app iOS de rituel matinal, et j'utilise Claude Design pour passer rapidement de la spec à un prototype interactif que je pourrai handoff à Claude Code.

**Contexte produit (1 phrase)**
Lumen est la seule app iOS qui relie l'alarme du matin à un rituel réflexif de 5 minutes guidé par une IA éthique. Cible : cadres 28-42 ans fatigués par le numérique.

**Sources que je vais te donner :**
1. **Codebase reference** : repo GitHub `highthem/lumen` (privé — je vais te partager l'accès). Le projet Xcode est dans `Apple/lumen.xcodeproj`. Pour l'instant c'est un template SwiftUI vide — pas de design system existant à reverse-engineer.
2. **Documents joints** (à drag & drop dans cette conversation) :
   - `01_design_brief.md` — principes, voice, direction visuelle
   - `02_mood_inspiration.md` — mood, keywords, références
   - `03_style_guide.md` — palette, typo, spacing, composants, motion 3 niveaux
   - `04_wireframes_spec.md` — spec textuelle des 10 écrans
   - `05_personas.md` — persona primaire/secondaire/anti
   - `06_pitch.md` — pitch + value prop
   - `07_flows.md` — flows produit
   - `08_web_capture_targets.md` — URLs à capturer (concurrents + inspirations)
3. **Web capture (si tu peux)** : voir `08_web_capture_targets.md` pour des URLs spécifiques d'inspirations visuelles (Apple Journal, Oak, Things 3, etc.) et de contre-inspirations à éviter (Fabulous, Headspace, Duolingo).

**Principes directeurs (non-négociables) :**
1. Calme avant tout. Zéro animation aggressive, zéro saturation, zéro bruit visuel.
2. Respect du moment. On vient d'ouvrir les yeux. Pas de surcharge cognitive.
3. Identité, pas métriques. Le produit est un miroir, pas un coach.
4. Typographie > iconographie. Laisser respirer le texte.
5. Dark mode first. L'utilisateur lance dans une chambre sombre.
6. Un geste, une décision.

**Contre-inspirations explicites (à éviter) :**
Fabulous (violet vif, mascotte), Headspace (rond orange, illustrations kids), Duolingo (gamification néon), apps "Gen Z" (gradients pastel, emojis partout).

**Inspirations souhaitées :**
Apple Journal (dark mode chaud, beige), Oak Meditation (simplicité extrême), Kinfolk magazine (palette papier crémeux), Things 3 (espace, légèreté), Bear app (typographie hero serif), Stoic (calme, simple).

---

## Ce que j'attends de toi (par étapes)

### Étape 1 — Calibration (avant de produire)
1. Lis l'ensemble des 8 documents joints.
2. Confirme en 5 lignes que tu as bien capté la posture produit.
3. Propose une **palette finalisée** : 4-6 nuanciers dark + 4-6 light, en respectant `03_style_guide.md`. 2 variantes : "fidèle au brief" et "alternative légèrement plus audacieuse".
4. Recommande 2-3 références visuelles sourcées que tu juges les plus alignées avec l'esprit Lumen.

**Stop. Je valide ces 3 éléments avant de continuer.**

### Étape 2 — Design system minimal
- Composants : Button (primary/secondary/ghost), Card dashboard, TextField, Chip, Modal, Toast, Mood emoji selector, Progress bar (4 steps questionnaire), Breathing circle (timer), Quote container.
- Tokens : colors, typography (display/title1-3/body/callout/footnote), spacing (4pt grid), radius, shadows, motion durations + easings.
- Documenter chaque composant avec ses états (default, hover, pressed, disabled, focused).

### Étape 3 — Maquettes haute fidélité (10+ écrans)
Pour chaque écran : version dark + light, en suivant `04_wireframes_spec.md`. Liste :
1. Onboarding — Welcome
2. Onboarding — Pitch
3. Onboarding — Permissions
4. Onboarding — Première alarme
5. Dashboard home (états : empty / idle / post-rituel)
6. Création / édition alarme
7. Écran "alarme sonne" (foreground)
8. Timer de présence (signature animation)
9. Questionnaire 4 étapes (Q1 ressenti, Q2 priorité, Q3 gratitude, Q4 intention)
10. Synthèse IA (résultat cloud + variant offline-queued)
11. Dashboard détail catégorie
12. Ask Lumen modal
13. Settings

### Étape 4 — Prototype interactif
Construis un **prototype HTML/code-powered** du flow rituel matinal complet (de l'alarme au dashboard). Je veux pouvoir cliquer à travers les écrans. Inclure les transitions signatures (cercle respiration timer, reveal séquentiel synthèse).

### Étape 5 — Handoff vers Claude Code
Package final pour que je le passe à Claude Code :
- Design tokens au format JSON (colors, typo, spacing — réutilisables en SwiftUI)
- Liste des composants avec leur spec (props, états, behavior)
- Maquettes en PNG haute résolution + version code (HTML/SwiftUI snippets si tu peux)
- Spec de motion sous forme de keyframes / Bezier
- Notes d'accessibilité (Dynamic Type, VoiceOver labels critiques)

### Étape 6 — Bonus si temps
- Génère 5 propositions d'icône d'app iOS (1024×1024) en respectant l'esprit calme/serif/dark
- Génère 3 captures App Store style (iPhone 6.7" portrait, 1290×2796) pour les futures screenshots store

---

## Format de livraison

Préfère :
- **HTML standalone** pour le prototype interactif (je peux l'ouvrir localement)
- **PNG/SVG export** pour les maquettes (high-res)
- **JSON** pour les tokens (colors, typo, spacing)
- **Markdown** pour la spec composants et le handoff Claude Code
- **PDF** pour la version "présentation" si tu juges utile (pas obligatoire)

Évite :
- Les exports Canva uniquement (je ne suis pas dans la team Canva)
- Les liens shareable Anthropic uniquement (je veux pouvoir versionner les assets dans le repo `lumen` et les partager à Claude Code en local)

---

## Ne commence pas l'étape 2 avant que je valide l'étape 1.

On itère.
