# Handoff Claude Design → Claude Code

Comment passer proprement du livrable Claude Design (prototype + design system) à l'implémentation SwiftUI dans Claude Code.

## Pré-requis avant le handoff

Claude Design doit avoir produit :
- [ ] Design tokens au format JSON (colors, typography, spacing, radius, motion)
- [ ] Composants spec (en Markdown ou JSON, avec props, états, behavior)
- [ ] Maquettes des 10+ écrans en PNG haute résolution (dark + light)
- [ ] Prototype HTML cliquable du flow rituel
- [ ] Spec motion (durées, easings, keyframes)
- [ ] Notes accessibilité (Dynamic Type, VoiceOver labels critiques)

## Structure du livrable Claude Design à intégrer

Crée un dossier `Apple/lumen/Shared/DesignSystem/_handoff/` (gitignored ou committed selon ta préférence) :

```
Apple/lumen/Shared/DesignSystem/_handoff/
├── tokens.json                    # exporté depuis Claude Design
├── components/
│   ├── Button.spec.md
│   ├── DashboardCard.spec.md
│   ├── MoodSelector.spec.md
│   ├── BreathingCircle.spec.md
│   └── QuoteContainer.spec.md
├── screens/
│   ├── 01_onboarding_welcome_dark.png
│   ├── 01_onboarding_welcome_light.png
│   ├── 02_alarm_ringing_dark.png
│   ├── ... (toutes les variantes)
├── prototype.html                 # prototype interactif Claude Design
└── motion.json                    # spec animations
```

Si tu préfères ne pas commit ces gros fichiers, mets-les dans `Design/output/` et ajoute la ligne `Design/output/` au `.gitignore` (et garde seulement les tokens JSON dans le repo).

## Conversion tokens → SwiftUI

Les tokens JSON Claude Design doivent être convertis en code Swift. Crée :

```
Apple/lumen/Shared/DesignSystem/
├── Colors.swift               # SwiftUI Color extensions
├── Typography.swift           # Font tokens + Dynamic Type
├── Spacing.swift              # CGFloat constants
├── Corners.swift              # corner radius constants
├── Motion.swift               # Animation tokens
└── Components/
    ├── PrimaryButton.swift
    ├── DashboardCard.swift
    ├── MoodSelector.swift
    ├── BreathingCircle.swift
    └── QuoteContainer.swift
```

## Prompt à donner à Claude Code

Quand tu lances Claude Code dans le repo Lumen pour démarrer Sprint 1 ou pour intégrer le design :

```
Tu es développeur iOS senior, expert SwiftUI 6 + iOS 17+ + Swift Concurrency.

Contexte projet : voir Project/ (en particulier 04_tech/architecture.md, 04_tech/stack.md, 04_tech/adr/).

Ta mission immédiate : intégrer le design system livré par Claude Design dans le code SwiftUI.

Sources :
- tokens : Apple/lumen/Shared/DesignSystem/_handoff/tokens.json
- composants spec : Apple/lumen/Shared/DesignSystem/_handoff/components/
- maquettes : Apple/lumen/Shared/DesignSystem/_handoff/screens/

Étape 1 : convertir les tokens JSON en fichiers Swift (Colors.swift, Typography.swift, Spacing.swift, Corners.swift, Motion.swift) dans Apple/lumen/Shared/DesignSystem/.
Étape 2 : implémenter les composants SwiftUI un par un, en respectant les states documentés dans .spec.md.
Étape 3 : pour chaque composant, créer un fichier de preview SwiftUI qui montre tous les states (dark + light + Dynamic Type max).
Étape 4 : tests unitaires sur la logique des composants si non-trivial (sinon tests visuels via preview).

Contraintes (non-négociables) :
- iOS 17+ deployment target
- Swift 6 strict concurrency (pas de data races)
- Pas de dépendance tierce
- Reduce Motion respecté (fallback crossfade)
- Dynamic Type complet
- VoiceOver labels sur tous les composants interactifs

Démarre par tokens → Colors.swift uniquement, montre-moi le résultat avant de continuer.
```

## Workflow recommandé pour les itérations

1. **Sprint 1 (alarme + structure)** :
   - Claude Design génère onboarding + alarm screens UNIQUEMENT
   - Tu integres ces 2 sets de maquettes dans le code Sprint 1
   - Pas besoin du design system complet — juste les composants utilisés (Button, time picker)

2. **Sprint 2 (rituel + IA + dashboard)** :
   - Claude Design produit le RESTE des écrans (timer, questionnaire, synthèse, dashboard, ask lumen)
   - Tu intègres en parallèle du dev IA + dashboard
   - Le design system est désormais complet

3. **Sprint 3 (polish)** :
   - Comparaison écran par écran avec les maquettes Claude Design
   - Ajustements pixel-perfect
   - Optimisation motion

## Points de friction probables

| Problème | Solution |
|---|---|
| Claude Design produit du code React/HTML, je veux du SwiftUI | Demander explicitement "donne-moi l'équivalent SwiftUI" — le modèle Opus 4.7 sait porter |
| Les maquettes ne respectent pas Dynamic Type | Re-itérer en demandant "refais en supposant que la taille de police peut x1.5 sans casser la mise en page" |
| Les couleurs proposées ont un mauvais contraste WCAG | Demander "vérifie le ratio de contraste de chaque combinaison texte/background, doit être ≥ 4.5:1 pour le texte normal" |
| Le motion proposé est trop snappy / bouncy | Rappeler le principe "calme avant tout, ease-in-out, pas de spring" du design_brief.md |
| Le prototype HTML utilise des fonts non-iOS | Demander "remplace par les fonts iOS natives : New York (serif), SF Pro (sans-serif)" |

## Validation finale

Avant de considérer le handoff Claude Design → Claude Code complet, valider que :
- [ ] Tous les composants ont une variante dark + light fonctionnelle
- [ ] Tous les composants ont une preview SwiftUI qui compile et affiche correctement
- [ ] Le prototype HTML est fidèle aux maquettes (pas de divergence)
- [ ] Les tokens JSON sont parsables et complets (aucune valeur "TBD" ou placeholder)
- [ ] La motion spec couvre les 3 niveaux (functional, signature, decorative — voir style_guide.md)
- [ ] Les maquettes couvrent tous les écrans du wireframes_spec.md (pas d'oubli)
