# Design brief Lumen — Input Claude Design

## Contexte
App iOS de rituel matinal. Flow : réveil doux → timer de présence → questionnaire 4 étapes → synthèse IA → dashboard 6 catégories. Cible : cadres 28-42 ans fatigués par le numérique. Anti-thèse de Fabulous/Opal/Alarmy.

## Principes directeurs (non-négociables)

1. **Calme avant tout.** Zéro animation aggressive, zéro couleur saturée, pas de bruit visuel.
2. **Respect du moment.** On vient d'ouvrir les yeux. Pas de surcharge cognitive, pas de texte dense, pas de bouton à choisir avec précision.
3. **Voice as primary input/output.** Au réveil, taper et lire un écran = friction. La dictation vocale est l'input par défaut pour Q3/Q4, et la synthèse IA est lisible à voix haute (TTS). Voir ADR-007.
4. **Identité, pas métriques.** Pas de graphiques, pas de chiffres mis en avant. Le produit est un miroir, pas un coach.
5. **Typographie > iconographie.** Laisser respirer le texte, icônes minimalistes uniquement quand nécessaire.
6. **Dark mode first.** L'utilisateur lance l'app dans une chambre sombre. Noir chaud par défaut, light mode en option.
7. **Un geste, une décision.** Chaque écran propose 1 action principale. Les secondaires sont visibles mais discrètes.

## Voice & tone

- **Posture :** compagnon silencieux, pas coach motivant.
- **Personne :** tu (FR) / you (EN).
- **Vocabulaire :** simple, concret, non-prescriptif. Éviter : "tu dois", "parfait !", "bravo", "tu as raté".
- **Emoji :** zéro, sauf dans le questionnaire Q1 (5 émojis de ressenti).
- **Ponctuation :** phrases courtes, pas d'exclamation.

**Exemples de copy :**
- ✅ "Quelques minutes à toi"
- ❌ "Bravo ! Tu as complété ton rituel !"
- ✅ "Une chose qui te tient à cœur aujourd'hui ?"
- ❌ "Allez, définis ta priorité du jour !!!"
- ✅ "Reviens demain"
- ❌ "Oh non, tu as atteint ta limite quotidienne !"

## Direction visuelle

### Palette (proposée, à affiner)

**Dark mode (primaire) :**
- Background : `#0F0D0B` (noir chaud, presque marron très foncé)
- Surface : `#1A1714`
- Accent : `#E8C39E` (sable chaud)
- Texte primaire : `#F5EFE6` (blanc cassé chaud)
- Texte secondaire : `#9A8D7D`
- Erreur/Alert : `#C85A54` (rouge atténué, jamais cramoisi)

**Light mode :**
- Background : `#FAF6EF` (crème)
- Surface : `#FFFFFF`
- Accent : `#A67C52` (terracotta)
- Texte primaire : `#1F1A14`
- Texte secondaire : `#6B5F50`

### Typographie

- **Primaire :** New York ou Charter (serif, iOS system)
- **Secondaire :** SF Pro (sans-serif, pour micro-copy)
- **Usage :** serif pour les titres et citations, sans-serif pour labels/UI
- **Tailles :** échelle iOS Dynamic Type, support accessibilité complet

### Iconographie

- SF Symbols uniquement, weight light ou regular.
- Pas d'illustrations complexes en V1 (trop coûteuses + risque incohérence).
- Optionnel : une illustration signature pour l'empty state et l'onboarding (pas plus).

### Motion

Voir `style_guide.md` section "Motion design — 3 niveaux" pour le détail complet.

**Résumé :**
- **Niveau 1 — Functional** : transitions, button press, input focus, loading. Invisible mais essentiel. Durée 100-300ms, easing iOS natif.
- **Niveau 2 — Signature** : cercle respiration du timer, reveal séquentiel de la synthèse IA, transitions questionnaire. Identité produit reconnaissable.
- **Niveau 3 — Decorative** : interdit par défaut (confettis, bounces, mascottes animées). Une seule exception : empty state pulse subtil.

**Règles :**
- Reduce Motion respecté → fallback crossfade
- Pas de spring iOS standard (trop rebondissant) → `.easeInOut`
- Haptic feedback parcimonieux : tap Silence alarme (`.medium`), fin timer (`.soft`), synthèse prête (`.success`)
- Performance 60 FPS minimum, sinon supprimer
- Animation = décision, pas un défaut

## Layout patterns

- **Gap généreux** entre éléments (24-32pt minimum).
- **Alignement à gauche** pour les titres (plus lisible), centré uniquement pour le timer.
- **Marges** : 20pt horizontal iPhone.
- **Boutons** : full-width sur mobile, corners arrondis 14-16pt.
- **Cards dashboard** : arrondies 20pt, shadow douce en light mode, aucune shadow en dark mode (juste surface).

## Écrans clés à designer (input détaillé dans wireframes_spec.md)

1. Onboarding (4 écrans)
2. Home dashboard (idle / post-rituel / empty state)
3. Création/édition d'alarme
4. Écran "alarme sonne" (app foreground)
5. Timer de présence
6. Questionnaire (4 écrans : Q1, Q2, Q3, Q4)
7. Écran synthèse IA
8. Dashboard détail catégorie
9. Ask Lumen modal
10. Settings (rate limit info, export JSON, à propos)

## Inspirations (voir mood_inspiration.md)

- Calm (motion + tons)
- Oak Meditation (simplicité extrême)
- Reflectly (onboarding doux)
- Mubert (écran sonore minimal)
- Applications Apple first-party (Journal, Mindfulness)

## Anti-inspirations

- Fabulous : trop coloré, trop "app de coach"
- Headspace : trop illustré, trop mascotte
- Tout ce qui ressemble à Duolingo

## Contraintes techniques à respecter côté design

- iOS 17+ only : peut utiliser les dernières APIs SwiftUI (MeshGradient iOS 18 : **non**, cible 17+).
- Pas de custom font embedded en V1 (utiliser les system fonts).
- Accessibilité : contraste WCAG AA minimum, Dynamic Type complet, VoiceOver.
- Performance : pas d'images lourdes, pas de vidéo embeddée.

## Livrables attendus du pôle design (Claude Design)

1. Moodboard final (5-10 images de référence)
2. Système de design minimal : palette figée, échelles typo, spacing scale, composants
3. Maquettes hautes fidélité des 10 écrans
4. Prototype Figma cliquable du flow principal (rituel complet)
5. Spec de motion (keyframes, durées, easing)
6. Export assets (icons, illustrations si V1)
7. Variantes dark / light mode

## Points d'arbitrage à trancher avec design

- Question 1 : **Illustration custom pour onboarding ou typographie seule ?** Impact effort +2j si illustration.
- Question 2 : **Widget iOS dashboard** pour V1 ou V1.1 ? Design inclus ou non ?
- Question 3 : **Son de démarrage** du rituel (soft chime) ou silence total ?
