# Landing page strategy

## Pour PALO V1 — pas de landing

Le brief Sami n'en demande pas. Le repo PALO se suffit à lui-même (README + démo Loom/TestFlight).

## Pour Studio V1.1+ — landing minimaliste statique

### Objectif unique
Convertir un visiteur en téléchargement App Store.

Pas de blog, pas de docs, pas de pricing détaillé. Une seule page, une seule action.

### Stack technique

**Hosting : Vercel ou Cloudflare Pages (gratuit)**
- Pattern déjà utilisé pour Skoul landing
- HTTPS automatique
- Build statique Astro ou Next.js (mode SSG)
- 0 € jusqu'à 100k visites/mois

**Framework recommandé : Astro**
- Zero JS par défaut → page < 50 KB
- Très rapide (Lighthouse 100)
- Markdown content si évolution
- Pas besoin de SSR pour une landing

**Alternative : HTML pur** (si on veut aller encore plus simple)
- 1 fichier HTML + 1 fichier CSS
- Hébergé sur Cloudflare Pages
- Effort : 0,5 j vs 1 j Astro

### Domaine

- **Hypothèse :** `lumen.app` (à vérifier disponibilité)
- Backups : `getlumen.app`, `lumen.morning`, `lumenritual.com`
- Coût : 30-50 €/an selon TLD
- Registrar : Cloudflare ou Porkbun (cheap)

### Structure de la page (single-page, scroll vertical)

#### Section 1 — Hero
- Titre serif XXL : "Wake up to intention."
- Sous-titre : "Lumen — Le rituel matinal qui prend le relais de ton alarme."
- Mockup iPhone hero (single image, 16:9)
- CTA primaire : "Télécharger sur l'App Store" (Apple badge SVG)
- CTA secondaire : "How it works ↓" (scroll anchor)

#### Section 2 — Le problème
- 1 phrase : "Tes 5 premières minutes sont devenues 5 doomscrolls."
- 3 mockups en ligne montrant le doomscroll typique
- Transition vers la solution

#### Section 3 — La solution (le flow)
- 5 cards horizontales montrant les 5 étapes du rituel :
  1. Réveil doux
  2. 60 secondes de présence
  3. 4 questions courtes
  4. Synthèse IA éthique
  5. Dashboard du jour
- Chaque card : icon + 1 ligne de description + screenshot

#### Section 4 — Pourquoi pas les autres
- Tableau comparatif léger (issu de `01_vision/competitive_analysis.md`)
- Colonnes : Feature, Fabulous, Alarmy, Opal, Rise, Lumen
- Highlight : Lumen est la seule à couvrir toute la chaîne + IA + privacy

#### Section 5 — Privacy & éthique
- "Tes données restent sur ton téléphone."
- 3 bullets : prompt haché, export JSON, no streak shaming
- Lien vers Privacy Policy (page dédiée)

#### Section 6 — Pricing simple
- Free : "Tout l'essentiel chaque matin."
- Premium 4,99 €/mois ou 29,99 €/an : "Historique illimité, alarmes multiples, Ask Lumen."
- "No trial trap. Cancel any time."

#### Section 7 — Final CTA
- Titre : "Demain matin commence ce soir."
- App Store badge XL
- Footer minimal : Highthem © 2026, Privacy, Terms, Contact

### Pages annexes (1 page chacune)

1. **/privacy** — Privacy Policy (obligatoire App Store)
2. **/terms** — Terms of Service
3. **/support** — FAQ + email support

Pas de blog, pas de "About us", pas de careers page. Discipline.

### Performance & SEO

- Lighthouse score 100 sur les 4 axes obligatoire
- Open Graph tags pour partage social
- Schema.org Application markup
- No tracking, no cookies (banner inutile)
- Hébergement EU si possible (Cloudflare EU edge ou Hetzner)

### Mots-clés SEO

Voir `05_business/go_to_market.md` section ASO.

Pour le SEO web (pas ASO) :
- "morning ritual app no streaks"
- "ethical AI morning routine"
- "alarm clock with reflection"
- "5 minute morning routine app"

### Capture email

Optionnel mais recommandé : un formulaire discret en pied de page :
- "Stay updated, no spam." → email field
- Stockage : Resend audiences ou Buttondown
- Pas de popup intrusive

### Effort estimé

- Design landing (Claude Design ou copy adapté de la maquette app) : **1 j**
- Développement (Astro ou HTML) : **1 j**
- Setup domaine + DNS + Vercel : **0,5 j**
- Privacy/Terms (générés via TermsFeed ou ChatGPT puis revus) : **0,5 j**
- QA cross-device + Lighthouse : **0,5 j**

**Total : ~3,5 j post-PALO** — compatible avec un lancement V1.1 fin mai / début juin.

## Anti-patterns à éviter

- ❌ Landing avec animations heavy (contredit la posture calme)
- ❌ Popup email immédiat
- ❌ Cookie banner gigantesque (on n'utilise pas de cookies)
- ❌ Vidéo autoplay
- ❌ Testimonials inventés
- ❌ "As seen on TechCrunch" sans le screenshot réel
- ❌ Pricing comparé qui dénigre les concurrents (battlecard, oui ; trash talk, non)

## Maintenance

Une landing minimaliste = 1-2 updates/an :
- Refresh des screenshots après nouvelle version app
- Update pricing si changement
- Ajout 1-2 testimonials si vrais

Pas de A/B testing en V1.1. À considérer si trafic > 1k visites/jour.
