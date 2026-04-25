# Unit economics (V1.1 post-monétisation)

## Hypothèses de coût

### Coût par user actif (DAU)

**IA cloud (OpenAI GPT-4o-mini) :**
- Tokens par synthèse : ~300 in + ~150 out
- Prix 2026 approximatif (à vérifier pricing courant) : ~0,15 $/1M tokens in, ~0,60 $/1M tokens out
- Coût par synthèse : ~0,045 $ + 0,09 $ = **~0,13 $ par synthèse** — à vérifier.
- Synthèse / jour / user : 1 auto (gratuit utilise toujours cet appel ou le fallback offline)

⚠️ **À vérifier au moment de builder :** les prix OpenAI bougent. Je ne commite pas sur ces chiffres avant de checker l'endpoint pricing officiel.

**Fallback Anthropic :**
- Déclenché seulement si OpenAI down — ~1-2% des appels attendus
- Coût négligeable en agrégé

**Apple Intelligence** (V1.1+ sur iOS 18+) :
- 0 $ par appel (on-device)
- Réduit le coût IA d'un pourcentage à mesurer

### Free user

- 1 synthèse auto / jour : ~0,13 $ / jour cloud, sauf si offline template (0 $).
- Si on mixe : ~70% cloud, 30% offline (hypothèse conservative) = **~0,09 $/jour**
- Par mois : **~2,75 $**
- Par an : **~33 $**

⚠️ Le coût par user free dépasse **100% du prix annuel du Premium**. **Cela ne tient pas économiquement** si 100% des free users utilisent 1 synthèse/jour.

### Levers pour rendre viable

1. **Most free users aren't daily.** Hypothèse : rétention D30 ~20-30% (standard wellness apps). Le coût réel moyen par free user est 2-3× moindre que le worst case.
2. **Push agressif vers offline template.** Si 70% des appels free passent en offline (template pré-écrit, 0 coût), le coût moyen tombe.
3. **Apple Intelligence** sur iOS 18+ (majorité devices en 2027) : bascule massive sur on-device.
4. **Gate la synthèse IA après J7** pour le free tier : "Tu as utilisé tes 7 premières synthèses. Tu veux continuer ?" → paywall ou basculer en offline.

### Décision V1.1

Gate **light** : synthèse IA cloud limitée à **J0-J7**, puis **100% offline template** pour free. Premium = 100% cloud + Apple Intelligence si dispo.

- Coût free user moyen : ~0,09 × 7 = **~0,65 $** sur la première semaine, puis **0 $/mois**.
- Coût premium user moyen : ~0,13 × 30 = **~4 $/mois** worst case → **~2 $/mois** avec mix Apple Intelligence.

### Marge Premium

- Prix : 4,99 €/mois ou 29,99 €/an = **2,50 €/mois moyen** (après mix mensuel/annuel hypothétique 30/70).
- Apple Store fee : 30% (ou 15% après 1 an d'abonnement — App Store Small Business Program si < 1M$/an : 15% flat).
- Revenu net/user Premium : ~2,13 €/mois (2,50 × 0,85).
- Coût IA worst case : ~2 €/mois.
- **Marge nette par user Premium : ~0,13 €/mois si on est en worst case Apple Intelligence off.**

**Conclusion :** **la marge est tendue sans Apple Intelligence.** Actions :

1. Activer Apple Intelligence dès V1.1 (iOS 18+).
2. Rate limiter plus agressif si usage anormal (un user Premium ne fait pas 30 Ask Lumen/jour).
3. Augmenter le prix si conversion > 5% (signal produit fort).

## Autres coûts

- Apple Developer : 99 €/an (coût fixe Highthem)
- Xcode Cloud ou Fastlane + GitHub Actions : 0 €/mois (free tier) à 15 €/mois si build volume
- Domain lumen.app ou équivalent : ~30 €/an
- Mailchimp/Resend pour newsletters : 0 €/mois au début
- Crash reporting : 0 € (on-device logs only V1)

Total overhead annuel : ~200-400 €.

## Seuil de rentabilité

Pour couvrir 400 €/an d'overhead :
- Il faut ~15 Premium/an à 30 € net après Apple = ~450 € de revenus
- + couvrir les coûts IA des free users (7 jours × 0,09 $ × N utilisateurs).

**Avec 500 free users actifs sur 30 jours et 15 premium annuels** → break-even réaliste.

## KPIs à suivre en V1.1

| KPI | Cible J30 | Cible M3 | Cible M12 |
|-----|-----------|----------|-----------|
| Downloads cumulés | 500 | 3 000 | 15 000 |
| DAU/MAU | 20% | 25% | 30% |
| Free → Premium conversion | 1% | 3% | 5% |
| Churn Premium mensuel | 15% | 10% | <8% |
| CAC | ~0 € | ~0 € | ~5 € si ads |
| LTV Premium | ~30 € (un an abo) | ~60 € | ~100 € |
| LTV/CAC | inf | inf | >10 |

## Risques unit economics

1. **Coûts IA montent** si OpenAI/Anthropic augmentent leurs prix. Mitigation : Apple Intelligence, caching intelligent.
2. **Usage supérieur aux hypothèses** (Ask Lumen abusé par Premium). Mitigation : rate limit hard cap.
3. **Conversion free → premium < 2%**. Mitigation : revoir paywall triggers, retry pricing.
4. **Churn > 15%/mois**. Mitigation : retention emails (monthly "your month in Lumen" sans métriques cliniques).

## Sources à vérifier avant commit chiffres

- OpenAI pricing GPT-4o-mini (à la date de V1.1 launch)
- Anthropic Haiku 4.5 pricing
- Apple App Store Small Business Program eligibility 2026
