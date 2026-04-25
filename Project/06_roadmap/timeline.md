# Timeline — livrable PALO IT + post-PALO

## Dates clés

| Date | Événement | Statut |
|------|-----------|--------|
| 14 avr 2026 | Interview Sami (premier contact) | ✅ Fait |
| 21 avr 2026 | Sami envoie le brief Lumen | ✅ Reçu |
| 22 avr 2026 | Confirmation réception | ✅ Fait |
| 24 avr 2026 | Email questions de périmètre envoyé | 🟡 À envoyer |
| 27 avr-3 mai | **Semaine solo Haithem (famille partie)** — sprint 1 | 🔵 À venir |
| 4-9 mai | Sprint 2 — rituel + IA + dashboard | 🔵 |
| 10 mai 2026 | **Deadline interne (buffer 1j seulement)** | 🎯 Cible |
| 10-11 mai | Polish final, tests, démo, présentation | 🔵 |
| 11 mai 2026 | **Rendu Sami** (date envoyée par email) | 🔴 Deadline DURE |
| 12-19 mai | Soutenance 30 min (à caler avec Sami) | 🔵 |
| 12 mai+ | Fork Studio, angle monétisation, préparation V1.1 | ⚪ Optionnel |
| Fin mai 2026 | Décision PALO IT (go/no-go pour embauche ou freelance) | ⚪ |
| Juin 2026 | Publication App Store V1.1 (si go décidé) | ⚪ |

## Capacité

### Budget heures Lumen par semaine

| Semaine | Dispo Lumen | Total cumulé |
|---------|-------------|--------------|
| 27 avr - 3 mai (semaine solo) | ~40-50 h | 40-50 h |
| 4 - 10 mai | ~20 h (soirs + weekend) | 60-70 h |
| 11 mai (jour J) | ~5-8 h (rendu) | 65-78 h |
| **Total** | **~65-78 h** |

⚠️ **Buffer ultra-réduit (1 jour) avec deadline 11 mai.** Toute dérive sprint 1 = sacrifice scope sprint 2.

### Budget effort V1 (rappel features.md)

- Dev core P0 : 10-13 j-h = ~80-100 h
- Dev polish P1 : 2,4 j-h = ~20 h
- Docs + tests + démo : 6 j-h = ~50 h
- Buffer aléas : 2 j-h = ~16 h
- **Total estimé : ~165 h**

⚠️ **Gap capacité : ~75-90 h dispo vs ~165 h estimées = déficit 75-90 h.**

### Actions pour fermer le gap

1. **Coupe agressive P1** : ne garder que F8 (onboarding) et F13 (reprise rituel). Gain ~15 h.
2. **Tests à 60% minimum** (pas plus), focus Domain uniquement. Gain ~15 h.
3. **Présentation en parallèle du code** : slide building pendant que les builds tournent. Gain ~8 h.
4. **Utiliser heavily l'IA** (Opus pour ADR et archi, Sonnet pour code) : gain potentiel 30-40%, soit ~30-50 h.
5. **Focus uniquement iOS** (pas d'iPad, pas de Watch) : évite distractions.

**Si ces leviers jouent : ~75 h dispo × 1,35 (coef IA) = ~100 h effectives** → reste tendu mais jouable avec P0 strict + docs.

## Phases détaillées

### Phase 1 — Préparation (24-26 avr, 0,5 jour)
- [x] Analyse brief Sami
- [x] Brief compétitif (agent)
- [x] Prep docs projet (ce pack)
- [x] Email questions à Sami (envoyé 24 avr, deadline 11 mai DURE)
- [x] Repo GitHub `highthem/lumen` créé + 1er commit
- [x] App "Lumen Morning" créée dans App Store Connect (bundle `com.highthem.lumen`)
- [x] Lumen.xcworkspace racine créé (workaround monorepo)
- [x] Kit Claude Design préparé (`/sessions/lucid-youthful-darwin/lumen-design-kit/`)
- [x] 5 docs PALO préparées (`/sessions/lucid-youthful-darwin/lumen-palo-docs/`)
- [ ] **EN COURS** Push workspace + scheme shared
- [ ] **EN COURS** Setup Xcode Cloud workflows (1 = Xcode 16, 2 = Xcode 26)
- [ ] **EN COURS** Configurer Secrets.xcconfig comme Base Configuration dans Xcode
- [ ] **EN COURS** Lancer Claude Design (kit prêt)

### Phase 2 — Sprint 1 Archi + Alarme (27 avr - 3 mai, 40-50 h)

**Objectif :** archi propre, alarme fonctionnelle en background, tests Domain alarme à 60%.

- [ ] Setup Xcode projet (Xcode 16, iOS 17+, Swift 6 strict)
- [ ] Structure dossiers MVVM + Clean
- [ ] Domain entities + use cases alarme (US-A1 à A6)
- [ ] Infra : NotificationScheduler + AudioPlayer + AudioSessionManager
- [ ] Data : SwiftData repo alarme
- [ ] Feature Alarm UI : list + edit + ringing
- [ ] Tests unitaires Domain alarme (≥ 60%)
- [ ] Démo interne : alarme qui sonne en background + snooze + silence

### Phase 3 — Sprint 2 Rituel + IA + Dashboard (4-10 mai, 25-30 h)

**Objectif :** flow complet rituel → synthèse IA → dashboard.

- [ ] Feature Timer (US-T1 à T5)
- [ ] Feature Questionnaire (US-Q1 à Q3)
- [ ] Data AI : OpenAI + Anthropic clients + PromptBuilder
- [ ] Data AI : WaterfallAISynthesisService + OfflineTemplateSynthesis
- [ ] Domain : RateLimiter + EthicalLogger
- [ ] Feature Synthesis UI
- [ ] Feature Dashboard UI (6 cards + détail)
- [ ] Feature Ask Lumen modal
- [ ] Onboarding 4 écrans
- [ ] Reset quotidien 3h AM

### Phase 4 — Sprint 3 Finition + Docs + Démo (10-11 mai, 8-10 h)

**Objectif :** livrable propre, docs complètes, démo convaincante.

- [ ] Tests Domain IA + Rate limiter
- [ ] Code review personnel (pass général)
- [ ] Écrire README.md, ARCHITECTURE.md, TECHNICAL_DECISIONS.md, ETHICAL_MONITORING.md, ARTIFACTS.md
- [ ] Export JSON monitoring éthique testé
- [ ] Loom vidéo 5 min (script + enregistrement)
- [ ] Présentation 10-15 slides
- [ ] Email récap + repo partagé à shenchiri@palo-it.com
- [ ] TestFlight upload si demande d'accès

### Phase 5 — Soutenance (12-19 mai)

- [ ] Répet soutenance 30 min (timing)
- [ ] Anticiper 10 questions probables
- [ ] Démo live backup (vidéo) en cas de bug
- [ ] Soutenance réelle

## Buffers et jalons de fallback

### Checkpoint J-3 (8 mai)
- Si alarme background pas fonctionnelle → alerter Sami, prioriser ce point sur tout le reste.
- Si IA waterfall bogué → basculer Premium live sur 1 seul provider + offline.
- Si docs pas commencées → les commencer immédiatement en parallèle.

### Checkpoint J-1 (10 mai)
- Tout doit être figé sauf polish + présentation.
- Pas de nouveau code après J-1 midi.
- Focus relecture + démo prep.

## Stratégie de partage repo Sami (décision 25 avr)

**Décision :** garder le monorepo `highthem/lumen` pour le dev, **restructurer en iOS-only juste avant le rendu** (sprint 3, J-1 = 10 mai).

- Pendant dev : monorepo `highthem/lumen` avec Project/ + Apple/ + Android/ + Lumen.xcworkspace racine
- J-1 (10 mai après-midi) : exécuter `scripts/restructure-for-palo.sh` qui :
  1. Crée nouveau repo `highthem/lumen-docs` (privé) et y migre `Project/`
  2. Restructure `highthem/lumen` en iOS-only (Apple/* à racine, supprime Project + Android + workspace)
  3. Force push sur main (historique reset)
  4. Copie les 5 docs PALO préparées à la racine
- J-0 (11 mai) : ajouter shenchiri@palo-it.com en collaborateur GitHub `highthem/lumen`

⚠️ **Risque assumé** : force push perd l'historique mais protège la confidentialité business (`monetization.md`, `go_to_market.md`, etc.) qui ne doivent pas être visibles à Sami.

## Dépendances externes (bloquantes potentielles)

- Réponse Sami aux 5 questions (envoyé 24 avr, idéal retour avant 28 avr)
- Clés API OpenAI + Anthropic actives sur compte Haithem (à mettre dans Xcode Cloud Env Vars)
- Compte Apple Developer en règle (✅ confirmé via création app Lumen Morning)
- Mac avec Xcode 26.4 installé (✅ confirmé) + CI Xcode Cloud sur Xcode 16/26 (en cours)
