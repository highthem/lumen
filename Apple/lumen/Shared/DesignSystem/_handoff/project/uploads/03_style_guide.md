# Style guide — Design tokens V1

## Couleurs

### Dark mode (primaire)

```
--lumen-bg-primary:     #0F0D0B   (noir chaud)
--lumen-bg-secondary:   #1A1714   (surface élevée)
--lumen-bg-tertiary:    #2A241F   (hover / pressed)
--lumen-text-primary:   #F5EFE6   (blanc cassé chaud)
--lumen-text-secondary: #9A8D7D
--lumen-text-tertiary:  #6A5E51
--lumen-accent:         #E8C39E   (sable chaud)
--lumen-accent-muted:   #A68566
--lumen-success:        #7FA58A
--lumen-warning:        #D4A853
--lumen-error:          #C85A54
--lumen-divider:        #2E2822
```

### Light mode

```
--lumen-bg-primary:     #FAF6EF   (crème)
--lumen-bg-secondary:   #FFFFFF
--lumen-bg-tertiary:    #F2ECDE
--lumen-text-primary:   #1F1A14
--lumen-text-secondary: #6B5F50
--lumen-text-tertiary:  #A89A88
--lumen-accent:         #A67C52   (terracotta)
--lumen-accent-muted:   #C9A882
--lumen-success:        #5A7A65
--lumen-warning:        #B08040
--lumen-error:          #A04540
--lumen-divider:        #E5DDC9
```

## Typographie

### Familles
- **Serif (hero / quote / titre)** : New York (système iOS 17+)
- **Sans-serif (body / label / UI)** : SF Pro

### Échelle (points)

| Token | Taille | Weight | Usage |
|-------|--------|--------|-------|
| `display` | 48 | Regular | Citation hero, quote timer |
| `title1` | 32 | Semibold | Titre écran principal |
| `title2` | 24 | Semibold | Sous-titre |
| `title3` | 20 | Medium | Card header |
| `body` | 17 | Regular | Texte courant |
| `bodyBold` | 17 | Semibold | Emphasis dans texte |
| `callout` | 15 | Regular | Secondary text |
| `footnote` | 13 | Regular | Metadata |
| `caption` | 11 | Regular | Tiny label |

**Line-height :** 1.3 (titres), 1.5 (body).
**Support Dynamic Type :** oui, toutes les tailles scalables.

## Espacement

Grid 4pt. Scale :

```
--spacing-xs:   4pt
--spacing-s:    8pt
--spacing-m:    16pt
--spacing-l:    24pt
--spacing-xl:   32pt
--spacing-xxl:  48pt
--spacing-huge: 64pt
```

**Règle :** gap minimum 16pt entre éléments, 24pt entre sections.

## Corners

```
--radius-s:    8pt   (chips, tags)
--radius-m:    14pt  (boutons, inputs)
--radius-l:    20pt  (cards dashboard, modals)
--radius-xl:   28pt  (hero cards, quote container)
```

## Ombres (light mode uniquement)

```
--shadow-soft: 0px 2px 8px rgba(0, 0, 0, 0.04)
--shadow-card: 0px 4px 16px rgba(0, 0, 0, 0.06)
```

Aucune ombre en dark mode (on utilise la surface élévée à la place).

## Composants signature

### Boutons

- **Primary** : full-width, height 52pt, radius 14pt, fond `--accent`, texte `--bg-primary`.
- **Secondary** : full-width, height 52pt, radius 14pt, border `--accent`, texte `--accent`.
- **Ghost** : inline, padding 16×8, texte `--text-secondary`.

### Cards dashboard

- Fond `--bg-secondary`, radius 20pt, padding 20pt.
- Icône en haut-gauche (22pt), titre en dessous (title3), contenu (body) puis footnote.

### Inputs

- Texte : fond `--bg-secondary`, border 1pt `--divider`, radius 14pt, padding 14×16.
- Focused : border 1.5pt `--accent`.

### Chips / tags

- Fond `--bg-tertiary`, texte `--text-secondary`, radius 8pt, padding 6×12.
- Selected : fond `--accent`, texte `--bg-primary`.

## Motion tokens

```
--duration-instant: 100ms
--duration-quick:   200ms
--duration-smooth:  300ms
--duration-slow:    500ms
--duration-breath:  4000ms   (pour la respiration du timer)

--easing-standard:    ease-in-out
--easing-decelerate:  cubic-bezier(0.0, 0.0, 0.2, 1)  (iOS natif, pour les entrées)
--easing-accelerate:  cubic-bezier(0.4, 0.0, 1.0, 1.0)  (pour les sorties)
--easing-breath:      ease-in-out  (cycle respiration)
```

## Motion design — 3 niveaux

### Niveau 1 — Functional motion (essentiel, invisible)

Toutes les transitions et feedbacks qui rendent l'app vivante sans être décoratifs.

| Pattern | Implémentation | Durée | Usage |
|---------|---------------|-------|-------|
| Push view | `NavigationStack` natif iOS | system | Toute navigation hiérarchique |
| Modal sheet | `.sheet()` natif | system | Ask Lumen, Settings |
| Tab switch (V1.1) | crossfade subtil | 200ms | Si tab bar ajoutée |
| Button press | `.scaleEffect(isPressed ? 0.97 : 1.0)` + opacity | 100ms | Tous les CTA primaires |
| Input focus | border color transition | 200ms | TextField, TextArea |
| Toast / snackbar | slide-up + fade | 300ms in / 250ms out | Rate limit info, erreurs douces |
| Loading state | dot pulse subtil (3 dots) | 1200ms loop | Pendant appel IA |

**Règle :** functional motion n'est jamais perçu consciemment. Si l'utilisateur le remarque, c'est qu'il est trop visible.

### Niveau 2 — Signature motion (identité produit)

Animations qui définissent la personnalité Lumen. À utiliser parcimonieusement, doivent rester reconnaissables.

#### Le cercle de présence (timer)
- Cercle qui se remplit progressivement sur la durée du timer (60s par défaut)
- En parallèle : respiration subtile (`scaleEffect` 1.0 → 1.04 → 1.0, cycle 4s, ease-in-out)
- Couleur : `--accent` qui s'intensifie légèrement à mesure que le timer avance
- Pas de chiffres : la progression est purement visuelle
- À la fin : pulse final + fade vers questionnaire (transition 500ms)

#### Reveal de la synthèse IA
- Apparition séquentielle des 3 blocs (intention → focus → reminder)
- Chaque bloc : fade + slide-up subtil (translation 12pt → 0)
- Délai entre blocs : 250ms
- Total : ~1s
- Effet : impression que la synthèse s'écrit/se révèle, pas qu'elle pop d'un coup

#### Transitions du questionnaire
- Entre Q1, Q2, Q3, Q4 : slide horizontal subtil + crossfade
- Durée : 350ms
- Easing : ease-in-out
- Pas de spring rebondissant
- Progress bar en haut s'incrémente en parallèle

#### Réveil — l'écran "alarme sonne" (app foreground)
- Cercle central qui pulse lent (cycle 2s, scale 1.0 → 1.08 → 1.0)
- Background : très léger gradient qui ondule (mouvement à peine perceptible)
- Effet : sensation d'être "appelé doucement", pas alarmé

### Niveau 3 — Decorative motion (interdit par défaut)

À éviter strictement, sauf cas exceptionnel justifié :
- ❌ Confettis, explosions
- ❌ Bounces, springs aggressifs
- ❌ Rotations gratuites
- ❌ Parallaxe sur scroll
- ❌ Mascottes animées
- ❌ Loading spinners pleins de personnalité

Un seul cas autorisé : empty state du dashboard premier lancement → une illustration discrète qui pulse très lentement (pour signifier que l'app est "en attente").

## Règles transverses motion

1. **Reduce Motion respecté** : si l'utilisateur l'active, tous les motion deviennent crossfade simple. Tester via Settings → Accessibility → Motion.
2. **Pas de spring** par défaut (iOS standard `.spring()` est trop rebondissant pour notre voice). Utiliser `.easeInOut(duration:)`.
3. **Motion implique discoverability** : le cercle de présence doit donner envie d'attendre 60s, pas de skipper.
4. **Performance 60 FPS minimum**. Si une animation ramise (Instruments) : la simplifier ou la supprimer.
5. **Haptic feedback léger** sur les interactions critiques :
   - Tap sur "Silence" alarme : `.medium`
   - Fin du timer : `.soft`
   - Synthèse IA prête : `.success`
   - Pas de haptic sur les transitions courantes (pollue)
6. **Animation = decision**, pas de défaut.

## Implémentation SwiftUI recommandée

```swift
// Functional
Button(action: {}) {
    Text("Silence")
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
}

// Signature : cercle de présence
Circle()
    .scaleEffect(isBreathing ? 1.04 : 1.0)
    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true),
               value: isBreathing)
    .onAppear { isBreathing = true }

// Reveal séquentiel synthèse
VStack(spacing: 24) {
    ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
        BlockView(block: block)
            .opacity(visibleBlocks.contains(index) ? 1 : 0)
            .offset(y: visibleBlocks.contains(index) ? 0 : 12)
            .animation(
                .easeOut(duration: 0.4).delay(Double(index) * 0.25),
                value: visibleBlocks
            )
    }
}
```

## Anti-patterns motion à bannir

- `.spring(response: 0.3, dampingFraction: 0.6)` aggressif → utiliser `.easeInOut`
- Animation sur `.foregroundColor` qui clignote (perçu comme bug)
- Auto-play vidéo dans onboarding
- Transitions entre `NavigationStack` customs qui surchargent le natif iOS

## Iconographie

- SF Symbols uniquement, weight **light** par défaut.
- Taille par défaut : 22pt (UI), 28pt (hero).
- Couleur : `--text-secondary` (inactive), `--accent` (active).

## Accessibility

- Contraste minimum WCAG AA (4.5:1 pour le texte < 18pt, 3:1 au-dessus).
- Dynamic Type : toutes les tailles doivent scale jusqu'à AccessibilityXXXL.
- VoiceOver labels : tous les boutons, toutes les cards dashboard.
- Reduce Motion : fallback en cross-fade, pas de motion parallaxe.
- Reduce Transparency : surfaces deviennent opaques (pas de glass effect).

## Ce qu'on n'utilise PAS

- Gradients (sauf exception signature sur l'écran synthèse)
- Glass effect / materials translucides (pollue le dark mode chaud)
- Emojis (sauf Q1 Ressenti)
- Illustrations custom V1 (tauche cost/time)
- Animations décoratives en dehors du timer
