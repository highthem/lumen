# Demande Apple Critical Alerts — dossier post-V1

> **Statut** : préparé pour soumission post-PALO. **Ne PAS soumettre avant V1.1**.
> **Angle stratégique** : repositionnement health & wellness avec HealthKit + sleep stages.
> **Probabilité réaliste d'approbation** : faible (15-25 %). Plan B obligatoire.

## 1. Pourquoi on attend la V1.1 pour soumettre

L'entitlement Critical Alerts est accordé sur dossier par Apple, **pas via les capabilities Xcode standard**. Soumettre une app de réveil nue = rejet quasi certain (Sleep Cycle, Alarmy n'ont jamais obtenu l'approbation).

L'unique angle qui peut marcher : **positionnement health/safety crédible**, supporté par du code et une intégration HealthKit qui montre qu'on n'est pas juste une alarme.

Donc la séquence est :
1. **V1 PALO (mai 2026)** : ship sans Critical Alerts, alarme `UNNotificationCenter` standard, doc onboarding sur la limite "désactive le silencieux"
2. **V1.1 (juin-août 2026)** : intégration HealthKit (lecture sleep stages, écriture mindfulness sessions), repositionnement marketing, ajout cas d'usage shift workers / parents nouveau-né
3. **Soumission Critical Alerts (août-septembre 2026)** : avec dossier complet et build live qui démontre l'usage health
4. **Si approuvé** : push update V1.2 qui active Critical Alerts derrière toggle Settings opt-in
5. **Si rejeté** : Plan B (voir § 7)

## 2. Pré-requis V1.1 avant soumission

Sans ces éléments dans le code et le marketing, la demande sera rejetée. À traiter pendant Sprint post-PALO :

- [ ] **HealthKit integration** : lecture `HKCategoryValueSleepAnalysis` (sleep stages iOS 17+), affichage dashboard "qualité de sommeil" → corrélation avec qualité du rituel matinal
- [ ] **Écriture HealthKit Mindful Sessions** pendant le timer présence 60 s + breathing
- [ ] **Onboarding question "ton profil"** : shift worker / parent nouveau-né / sleep disorder diagnostiqué / utilisateur standard → segmentation des cas d'usage critique
- [ ] **Settings toggle "Critical Alerts"** : opt-in explicite, désactivé par défaut, copy mentionnant la justification health
- [ ] **Privacy Manifest update** : déclaration usage HealthKit avec API reasons
- [ ] **App Store description** : ajouter section "For shift workers, new parents, and users with sleep disorders" — sans mentir, mais en mettant ce segment en avant
- [ ] **Landing page** : page dédiée "Why Critical Alerts" expliquant le cas d'usage
- [ ] **Témoignages utilisateurs** (3-5 minimum) : parents nouveau-né + shift workers documentés via emails/canal direct, attestant que rater le réveil = conséquence sécurité réelle (transport, garde enfant)

## 3. Le formulaire Apple — réponses préparées

La demande se fait via **développeur.apple.com → Account → Certificates → Provisioning Profiles → demande spéciale**, ou par email à **product-security@apple.com / app-review@apple.com** selon la procédure 2026.

Apple demande typiquement :

### 3.1 App description (max ~500 chars)

> Lumen Morning is a mindful wake-up and sleep wellness application for iOS. It supports users with documented sleep needs — including shift workers, new parents, and individuals with diagnosed sleep disorders — by providing a structured 5-minute morning ritual integrated with HealthKit sleep tracking. The app reads Apple Health sleep stages to recommend optimal wake times and writes mindfulness session data back to HealthKit.

### 3.2 Why are Critical Alerts necessary? (max ~1000 chars)

> A subset of our user base relies on Lumen Morning for safety-critical wake-ups: night-shift hospital staff who must wake to begin a shift, parents of newborns coordinating feeding schedules during sleep-deprived periods, and users with circadian rhythm disorders or hypersomnia diagnoses. For these users, missing a wake-up due to Silent Mode or Focus is not an inconvenience — it has direct safety, occupational, or caregiving consequences.
>
> We currently document this limitation prominently in onboarding and Settings, but a non-trivial number of users have reported missed shifts or missed feeding windows after enabling Focus or Silent Mode by mistake. Critical Alerts would solve this for users who explicitly opt in via a Settings toggle, and only for the alarm trigger event (not for any marketing or non-essential notification).
>
> All other notifications in Lumen Morning use standard `UNNotificationSound` and respect Silent / Focus / DND. Critical Alerts would be reserved exclusively for the user's primary alarm.

### 3.3 What categories of users? (max ~500 chars)

> Three documented segments :
> - Healthcare and emergency-service shift workers (rotating shifts, irregular sleep)
> - New parents (first 12 months post-partum, frequent night feedings)
> - Users with diagnosed sleep disorders (hypersomnia, narcolepsy, circadian rhythm disorders)
>
> These segments are surfaced in the onboarding flow and tracked anonymously to provide Apple with usage statistics on Critical Alerts opt-in if requested.

### 3.4 Frequency and conditions of Critical Alert usage

> Critical Alerts are triggered only by the user's primary alarm, scheduled by the user themselves. Maximum frequency : once per day per active alarm. Snooze re-notifications are NOT sent as Critical Alerts (only the initial wake-up trigger). The toggle is opt-in, off by default, and disabled automatically if the user has not used the app for 14 consecutive days.

## 4. Technical implementation plan (V1.2)

À implémenter une fois l'entitlement obtenu :

### 4.1 Entitlement file
```xml
<!-- Apple/lumen/lumen.entitlements -->
<key>com.apple.developer.usernotifications.critical-alerts</key>
<true/>
```

### 4.2 Notification authorization
```swift
// Apple/lumen/Sources/Domain/Services/NotificationService.swift
let options: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
try await UNUserNotificationCenter.current().requestAuthorization(options: options)
```

### 4.3 Sound critique
```swift
// Apple/lumen/Sources/Domain/UseCases/ScheduleAlarmUseCase.swift
content.sound = UNNotificationSound.criticalSoundNamed(
    UNNotificationSoundName(rawValue: "aube.caf"),
    withAudioVolume: 1.0
)
```

### 4.4 Settings toggle
```swift
// Toggle dans SettingsView
Toggle("Critical Alerts (opt-in)", isOn: $criticalAlertsEnabled)
    .help("L'alarme te réveille même en mode silencieux. Réservé aux usages critiques.")
```

### 4.5 Tests à ajouter
- Maestro flow `21-critical-alerts-toggle.yaml` (V1.2 regression)
- XCUITest hardware-dep : alarme avec switch silencieux ON, vérifier déclenchement
- Domain test : `criticalSoundNamed` n'est pas utilisé hors flow alarme

## 5. Artefacts à joindre à la demande

- [ ] Build TestFlight de Lumen Morning V1.1 avec HealthKit complet
- [ ] Démo vidéo 2-3 min : onboarding "shift worker" → setup alarme → simulation Silent Mode rate l'alarme → toggle Critical Alerts → alarme passe
- [ ] Capture d'écran Settings showing opt-in toggle
- [ ] Privacy Policy URL avec section dédiée Critical Alerts
- [ ] Métriques V1.1 : nb users actifs, % qui ont enable HealthKit, % qui s'identifient comme shift worker / parent / sleep disorder
- [ ] Témoignages utilisateurs anonymisés (3-5 minimum) avec consentement écrit

## 6. Timeline

| Étape | Date cible | Responsable |
|---|---|---|
| Ship V1 PALO sans Critical Alerts | 11 mai 2026 | Haithem (dev) |
| Sprint V1.1 health repositioning | juin-juil 2026 | Haithem |
| Collecte témoignages utilisateurs | juil-août 2026 | Haithem (manuel via email) |
| Préparation dossier complet | mi-août 2026 | Haithem + ce doc |
| Soumission Apple | fin août 2026 | Haithem via portal dev |
| Réponse Apple attendue | sept-nov 2026 (variable) | — |
| Si approuvé : ship V1.2 | dans les 2 semaines post-réponse | Haithem |

## 7. Plan B si rejet

Apple rejette ~75-85 % des demandes Critical Alerts hors santé/sécurité physique pure. Si rejet :

1. **Ne pas resoumettre tout de suite.** Apple flagge les apps qui bombardent le système.
2. **Renforcer le cas health pendant 6 mois** : partenariat avec une appli de monitoring sleep disorder (par ex. SleepWatch, AutoSleep), publication d'un white paper sur l'usage Lumen en pop shift workers.
3. **Resoumettre avec dossier renforcé** au plus tôt 6 mois après le rejet.
4. **Alternative produit** : pousser l'angle "alarme fiable hors silencieux" via UX education :
   - Shortcut iOS pour désactiver silencieux la nuit auto via Focus mode
   - Tutoriel "configuration nuit" avec Sleep Focus + Lumen exception
   - Apple Watch alarm complication pour redondance (vibreur poignet contourne le silencieux iPhone)

## 8. Risques de soumission

| Risque | Mitigation |
|---|---|
| Soumission perçue comme abusive (alarme banale) | Repositionnement V1.1 health + témoignages utilisateurs documentés AVANT soumission |
| Apple impose des contraintes tracking strictes | Privacy Manifest impeccable, pas de SDK tiers analytics |
| Approbation conditionnelle (ex : audit annuel usage) | Accepter, prévoir process annuel de renouvellement |
| Délai 3-6 mois sans réponse | Patience, ne pas relancer avant 60 jours |
| Si approuvé puis abus détecté → révocation | Discipline stricte : Critical Alerts uniquement pour le trigger alarme principal, jamais pour autre chose |

## 9. Cohérence avec ADR-001

Cette demande **ne contredit pas ADR-001**. ADR-001 acte que pour V1 PALO on ne demande PAS Critical Alerts — décision toujours valide. Ce doc prépare la **suite** une fois la base produit stabilisée et repositionnée.

À la soumission Critical Alerts, mettre à jour ADR-001 avec un addendum daté.

## 10. Coût

- Développement V1.1 health repositioning : ~5-7 j-h (déjà prévu dans roadmap commerciale post-PALO)
- Préparation dossier + témoignages : ~2-3 j-h
- Implémentation V1.2 si entitlement obtenu : ~1 j-h
- **Total marginal Critical Alerts (hors V1.1 qui se fait de toute façon)** : ~3-4 j-h

## Références

- [Critical Alerts entitlement — Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.critical-alerts)
- [Requesting Critical Alerts — Apple Developer Forums historical thread](https://developer.apple.com/forums/thread/97001)
- ADR-001 — Stratégie alarme en background (ce repo)
- HealthKit Sleep Analysis — `HKCategoryValueSleepAnalysis` (iOS 17+)
