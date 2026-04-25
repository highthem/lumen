# Backend strategy

## Pour PALO V1 — ZÉRO backend

**Décision ferme :** la V1 livrée à Sami n'a **aucun backend custom**.

Justifications :
1. **Brief Sami est explicite :** "SwiftData/Core Data pour la persistance" + "OpenAI ou Anthropic" appelés directement. Aucune mention de serveur.
2. **Hors scope :** ajouter un backend serait une dérive de scope, signal négatif en revue.
3. **Privacy-first :** la V1 vante "tout local" — un backend casse cette promesse.
4. **Effort :** ~5-10 jours de dev pour un backend même minimal. Inviable dans la timeline.

**Stack V1 entièrement client-side :**
- Persistance : SwiftData
- IA : appels REST directs OpenAI/Anthropic depuis l'app
- Logs : SwiftData local + export JSON manuel
- Notifications : UNUserNotificationCenter (locales uniquement)

## Pour Studio V1.1+ — décisions par besoin

À chaque feature qui réclame un backend, appliquer cette décision tree :

```
Feature requires shared state across devices ?
├── No → No backend needed
└── Yes
    ├── Shared with Apple ecosystem only ?
    │   ├── Yes → CloudKit (zero backend, free, native Apple)
    │   └── No → Custom backend required
    └── Custom backend triggers minimal MVP setup
```

## Cas d'usage analysés

### Sync multi-device (iPhone ↔ iPad ↔ Mac futur)

**Recommandation : CloudKit.**

- Apple-natif, zero backend custom
- Storage gratuit pour user (1 Go inclus iCloud, payant au-delà mais c'est l'user qui paie)
- Latence acceptable (sync background)
- Conflict resolution automatique (Last Write Wins par défaut, custom si besoin)
- Compatible SwiftData via `@Model` + `cloudKitDatabase: .private`

**Setup minimal :**
```swift
let configuration = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .private("iCloud.com.highthem.lumen")
)
let container = try ModelContainer(for: schema, configurations: configuration)
```

**Impact :** 0,5 jour de setup en V1.1, gros gain UX.

### Validation subscription (StoreKit 2)

**Recommandation V1.1 : client-side validation suffit.**

StoreKit 2 (iOS 15+) permet une validation locale signée par Apple :
```swift
let result = await product.purchase()
switch result {
case .success(.verified(let transaction)):
    // Premium activé, transaction signée Apple
    await transaction.finish()
case .success(.unverified(_, let error)):
    // Signal de fraude potentielle
default: break
}
```

**Quand passer server-side :**
- Si on détecte des abus (>2% des transactions unverified)
- Si on offre des features cross-device avec rights server-side (pas en V1.1)
- Si on veut un dashboard analytics fin (Stripe/Paddle plus tard)

**Outils si besoin un jour :**
- RevenueCat (managed, ~$2 pour 1000 MTR free, 1% revenue après)
- Backend custom léger (Vercel + Supabase)

### Push notifications custom

**Recommandation V1.1 : pas nécessaire.**

Toutes les notifications de Lumen sont **locales** :
- Alarme matinale (UNCalendarNotificationTrigger)
- Notif "ta synthèse est prête" (UNTimeIntervalNotificationTrigger)
- Reminder doux paywall (UNTimeIntervalNotificationTrigger)

Les notifs custom (depuis serveur) ne sont nécessaires que pour :
- Annonces produit (newsletter mieux adaptée)
- Re-engagement users churned (newsletter ou rien — fidèle à la posture anti-pression)
- Real-time multi-user (pas notre cas)

**Conclusion :** APNs serveur **inutile** pour Lumen.

### Analytics

**Recommandation V1.1 : Apple App Analytics (App Store Connect) suffit.**

Disponible gratuitement sur App Store Connect :
- Impressions, downloads
- Sessions, crashes
- Conversions in-app
- Retention (D1, D7, D30)
- Funnels basiques

**Pas de Mixpanel / Amplitude / Firebase en V1.1.** Privacy-first, et ces outils dépassent le besoin réel.

Si besoin custom plus tard : TelemetryDeck (privacy-friendly, EU-based, $30/mois).

### Backend pour landing page

**Recommandation : statique, pas de backend.**

Voir `landing.md` pour détail.

## Si un backend devient nécessaire un jour (V2+)

**Stack recommandée pour Highthem :**
- **Vercel** (hosting frontend + edge functions) — déjà utilisé pour Skoul landing
- **Supabase** (Postgres + Auth + Storage) — déjà utilisé pour Skoul backend
- **Resend** (transactional emails) — alternative légère à SendGrid
- **Stripe** (paiements one-shot ou abos non-Apple) — si distribution hors App Store un jour

Coût estimé : ~30-50 €/mois pour <10k users.

## Anti-patterns à éviter

- ❌ "On va faire le backend en parallèle" en V1 (dérive scope, certaine)
- ❌ Backend custom pour le simple sync iCloud (CloudKit existe)
- ❌ Push serveur pour des notifs locales (UN suffit)
- ❌ Mixpanel pour mesurer 100 users
- ❌ Subscription proxy server avant d'avoir 1000 abonnés

## Décisions résumées

| Besoin | V1 (PALO) | V1.1 (post-PALO) | V2+ (si traction) |
|--------|-----------|------------------|-------------------|
| Persistance | SwiftData local | SwiftData + CloudKit private | + Supabase si analytics fin |
| IA | OpenAI + Anthropic direct | + Apple Intelligence on-device | RevenueCat metering |
| Subscriptions | N/A | StoreKit 2 client-side | Server-side validation if abuse |
| Push notifs | UN locales | UN locales | APNs custom si re-engagement |
| Analytics | aucune | App Store Connect | TelemetryDeck si besoin |
| Email | aucune | Resend pour pre-renewal | Resend séquences |
| Landing | aucune | Vercel statique | + edge functions si forms complexes |
