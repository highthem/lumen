# Modèle de monétisation

> **Note stratégique :** la monétisation est explicitement **en second plan** (décision Haithem, avril 2026). La V1 livrée à Sami IT est **gratuite et sans abonnement**. Ce document pose les fondations pour une V1.1 monétisée post-PALO, à activer à partir de mi-mai 2026 si l'opportunité PALO est sécurisée ou abandonnée.

## Thèse de monétisation

**Freemium avec paywall doux et transparent.**

L'usage gratuit doit être réellement utilisable quotidiennement. Le paywall ne bloque pas le rituel de base — il débloque profondeur, historique et personnalisation. Positionnement anti-dark-pattern volontaire (cf analyse compétitive : Fabulous, Opal, Rise ont tous des notes 1★ sur le billing).

## Plan tarifaire proposé

### Free tier
- 1 alarme active
- Rituel complet (timer, questionnaire, synthèse IA — 1/jour)
- Dashboard du jour (6 catégories)
- Pas d'historique au-delà de 7 jours
- Pas d'Ask Lumen supplémentaire (limite 0 manuel, 1 auto)
- 2 sons de réveil
- Pas d'export JSON

### Premium — "Lumen+"
- Alarmes multiples
- Historique illimité + vue calendrier
- Ask Lumen (3 interactions / jour)
- 10 sons de réveil et 3 durées timer
- Import / export des logs éthiques
- Thèmes visuels (light/dark/sepia/high-contrast)
- Widget iOS home screen (V1.1)

### Hypothèses de prix (à valider par test AB)

| Plan | Prix cible FR | Prix cible US | Rationale |
|------|---------------|---------------|-----------|
| Mensuel | 4,99 € | 4,99 $ | Entry point, test pricing |
| Annuel | 29,99 € | 29,99 $ | -50% vs mensuel annualisé, marge confortable |
| Lifetime | 79,99 € | 79,99 $ | Ancre psychologique, fidélise les premiers fans |

Benchmark concurrents :
- Fabulous : 40-60 $/an
- Alarmy : 59 $/an
- Opal : 60-100 $/an
- Rise : 36-70 $/an

Lumen se positionne **en dessous** pour amorcer, avec promesse "no BS billing" comme différenciation.

## Principes anti-dark-pattern

1. **Pas de trial gratuit 7 jours** qui se convertit automatiquement. Le free tier EST le trial.
2. **Un bouton "Annuler" visible** dans Settings, pas caché dans un menu 4 niveaux.
3. **Pre-renewal reminder** email 48h avant le renouvellement annuel (obligation légale UE + bonne pratique).
4. **Prix affichés TTC** en Europe, clairement.
5. **Full refund** possible dans les 14 jours sans question.
6. **Pas de `upsell` aggressive** pendant le rituel. Le paywall apparaît dans Settings et sur des features gated uniquement.

## Trigger de conversion identifiés

- **Jour 3** : après 3 rituels, une notification douce ("Tu es en route. Tu veux garder l'historique ?") → lien Settings.
- **Paywall sur Ask Lumen** : après 1 question sur le dashboard, "Tu as posé 1 question aujourd'hui. Plus avec Lumen+." Pas de popup, juste un message calme.
- **Paywall sur historique** : en scrollant l'historique au-delà de 7 jours, "Voir plus avec Lumen+".
- **Pas de paywall sur le rituel du matin lui-même.** Jamais.

## Channels de conversion

- In-app uniquement en V1.1
- Pas de paid ads au lancement (budget nul, positionnement organic/content)
- Featured App Store possible si qualité éditoriale reconnue (design, accessibilité)

## Objectifs KPIs premiers 12 mois post-monétisation

| Métrique | Target soft | Target ambitieux |
|----------|-------------|------------------|
| Téléchargements | 5 000 | 30 000 |
| % Free → Premium | 2% | 5% |
| MRR fin année 1 | 400 € | 6 000 € |
| Churn mensuel Premium | < 10% | < 5% |
| Rating App Store | > 4,5 | > 4,7 |

Rationale : Lumen est un side project, pas un bet startup. L'objectif est la **qualité produit** et la **validation marché**, pas de scaler à tout prix.

## Scénarios de monétisation alternatifs étudiés

| Modèle | Pourquoi non |
|--------|--------------|
| One-shot (IAP unique) | Pas de récurrence, mal aligné avec le SaaS moderne |
| Publicitaire | Contradictoire avec la promesse anti-dopamine |
| B2B bien-être d'équipe | Complexe sales cycle, pas solo-friendly |
| Donation-based | Fragile, pas aligné avec la qualité IA qui coûte (cf API OpenAI) |
| IA à la carte (pay-per-query) | Friction cognitive, rejette un utilisateur déjà anxieux |

## Points ouverts

- **Apple Family Sharing** : à activer par défaut sur Premium (bonne pratique 2026).
- **Student pricing** : à tester en mois 6 (-50%).
- **Yearly discount** s'active automatiquement après 1 mois premium pour limiter le churn.
- **Abonnement + IA usage** : si volume bcp plus élevé que prévu, reconsidérer inclusion Ask Lumen (économie sur cost API).
