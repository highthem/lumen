# Sanity check Lumen Morning — prompt pour Claude Code

> **Pour l'utilisateur** : ouvre ce dossier dans Claude Code et passe ce fichier comme prompt initial, ou copie-colle directement dans Claude Code.
> Date contexte : 7 mai 2026. Deadline PALO : **11 mai 2026 (J-4)**.

---

## Contexte projet (à charger en mémoire avant tout)

Tu es dans le repo monorepo `highthem/lumen`. Cible : livrer un MVP iOS "Lumen Morning" pour PALO IT (Sami Henchiri, CTO PALO Labs) **le 11 mai 2026**. Aujourd'hui = 7 mai. Il reste **4 jours**.

Le pack projet (specs, ADR, sprints) vit sous `Project/`. Le code iOS sous `Apple/`. La doc PALO finale sous `Design/palo-docs/`. Les tests UI sous `Apple/.maestro/`.

**Préférences de communication du founder Haithem :** pas de fluff, ton de coach, critique honnête, jamais d'affirmation technique sans source vérifiée. Pas de validation complaisante. Si quelque chose dérape, dis-le.

---

## Mission

Faire un audit franc de l'état d'avancement Lumen Morning vs plan initial, et mettre à jour le board Notion "Lumen" avec le résultat.

Le board Notion :
- URL : https://www.notion.so/highthem-ai/3a747d60f32d43c9ae7e6e26a1e1e5d1?v=3597e4b5122980bd9f26000cd0b6d899
- Data source ID : `3a747d60f32d43c9ae7e6e26a1e1e5d1`
- Workspace : highthem-ai

Tu as (probablement) accès à un MCP Notion. Vérifie d'abord avec `notion-fetch` ou équivalent. Si pas dispo, demande à Haithem d'activer Notion MCP, et en attendant produis un rapport markdown qu'il pourra coller manuellement.

---

## Étape 1 — Charger le plan initial

Lis ces fichiers dans cet ordre, sans rien sauter :

1. `Project/02_product/features.md` → liste F1-F22 avec priorités P0/P1 et efforts
2. `Project/06_roadmap/timeline.md` → dates, capacité, phases
3. `Project/06_roadmap/sprints.md` → 3 sprints, tâches par demi-journée, US couvertes
4. `Project/02_product/user_stories/` → tous les fichiers (alarm, timer, questionnaire, ai_synthesis, dashboard, etc.) pour avoir la liste US-A1 → US-D6, US-AI1 → US-AI8, US-Q1 → US-Q6, US-T1 → US-T6
5. `Project/04_tech/adr/` → tous les ADR (ADR-001 à ADR-008) pour comprendre les décisions techniques
6. `Project/06_roadmap/risks.md` et `test_plan_v1.md`

**Construis mentalement (ou dans un scratch markdown) la liste exhaustive des items planifiés** : features F1 à F22, US par sprint, ADR par décision, livrables docs.

---

## Étape 2 — Cartographier ce qui est codé

Sans modifier le code, fais l'inventaire :

### 2.1 Code applicatif

```bash
# Compte par couche
find Apple/lumen/Domain -name '*.swift' | wc -l
find Apple/lumen/Data -name '*.swift' | wc -l
find Apple/lumen/Infrastructure -name '*.swift' | wc -l
find Apple/lumen/Features -name '*.swift' | wc -l
find Apple/lumen/Shared -name '*.swift' | wc -l
```

Pour chaque feature attendue (Alarm, Timer, Questionnaire, Synthesis, Dashboard, AskLumen, Onboarding, Splash, Settings) :
- vérifier la présence de `*View.swift` + `*ViewModel.swift`
- noter ce qui est manquant

Pour chaque User Story (US-A1 → US-D6, etc.), tente de la mapper à un fichier ou une fonction. Quand le mapping est ambigu, le marquer `?`.

### 2.2 Tests

```bash
find Apple/lumenTests -name '*.swift' | sort
find Apple/lumenUITests -name '*.swift' | sort
find Apple/.maestro/flows -name '*.yaml' | sort
```

Calcule le ratio approximatif tests/features. Cible brief PALO : **Domain ≥ 60 %**.

Si possible, lance la suite de tests :
```bash
xcodebuild test -workspace Lumen.xcworkspace -scheme lumen -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -50
```
Note le pass/fail count. Si build échoue, capture l'erreur en haut du rapport — c'est critique.

### 2.3 CI/CD et infrastructure

Vérifie présence et état :
- `Lumen.xcworkspace/contents.xcworkspacedata`
- `ci_scripts/ci_post_clone.sh`
- `Apple/lumen/Config/Secrets.xcconfig` (référencé, pas commité)
- `Apple/.maestro/` complet
- `scripts/test_maestro.sh`, `scripts/qa_install.sh`, `scripts/lint.sh`
- workflows Xcode Cloud configurés (regarde `scripts/xcode-cloud/workflows.json`)

### 2.4 Doc PALO finale

```bash
ls -la Design/palo-docs/
```
Pour chaque fichier (README, ARCHITECTURE, TECHNICAL_DECISIONS, ETHICAL_MONITORING, ARTIFACTS) : vérifie qu'il existe ET qu'il a du contenu réel (≥ 50 lignes), pas un placeholder.

### 2.5 Sound + Design kits

```bash
ls Design/sound-kit/ 2>/dev/null
ls Design/design-kit/ 2>/dev/null
ls Apple/lumen/Resources/Sounds/ 2>/dev/null
```
Note quels sons (5 alarmes + 3 breathings) sont effectivement embedded en `.caf`.

---

## Étape 3 — Synthèse en trois colonnes

Produis un tableau markdown avec 3 sections :

### 3.1 ✅ Done (planifié + livré)

| ID | Item | Priorité | Statut | Fichiers / preuves |
|---|---|---|---|---|

Ne mets ici que ce que tu peux justifier par un fichier existant + (si possible) un test passant.

### 3.2 ➕ Added (livré mais pas dans le plan initial)

| Item | Justification probable | Fichiers | Risque |
|---|---|---|---|

Exemples potentiels à creuser :
- `ElevenLabsSynthesizer.swift` (planifié = AVSpeechSynthesizer seul ?)
- `ContentSafetyDetector` + `SupportResourcesProvider` (safety stuff added pour wellness ?)
- `KineticText`, `AlarmSunrise`, `LiveTranscript` (composants Sunrise Echo)
- Composants design system non listés dans features.md

Pour chaque ajout, tranche : **est-ce que ça vaut son coût à 4 jours du rendu, ou c'est du scope creep qui aurait dû être V1.1 ?**

### 3.3 ❌ Missing (planifié mais non livré)

| ID | Item | Priorité | Bloquant ? | Effort restant estimé |
|---|---|---|---|---|

Distingue clairement P0 manquant (= bloquant rendu) vs P1 manquant (= acceptable à couper). Pour chaque P0 manquant à J-4, propose un arbitrage : couper, descoper, ou mode dégradé.

---

## Étape 4 — Verdict coach

À la fin du rapport, écris une section **Verdict** en 6-8 phrases max, pas plus. Réponds franchement à :

1. Est-ce que le rendu 11 mai est tenable au scope P0 actuel ? (oui/non/risqué — justifie en 1 phrase)
2. Quels sont les **3 vrais risques** restants (pas tout lister, les 3 qui peuvent faire foirer le rendu) ?
3. **Quoi couper maintenant** (si applicable) pour sécuriser le P0 ?
4. **Quoi prioriser absolument** dans les 4 jours restants, dans l'ordre ?

Pas de phrase d'encouragement vide ("good job", "you're on track"). Pas de hedging mou ("ça pourrait peut-être"). Si tu vois un truc qui pue, tu le dis.

---

## Étape 5 — Mise à jour Notion

Une fois le rapport produit :

1. Vérifie que tu as accès au MCP Notion (`notion-fetch` ou équivalent). Si pas dispo, **stop et signale** — produis le rapport markdown seul.
2. Récupère la structure du board Lumen (data source `3a747d60f32d43c9ae7e6e26a1e1e5d1`) : colonnes statuts, propriétés (priorité, sprint, deadline, tags…).
3. Lis les pages existantes du board pour ne pas créer de doublons.
4. Pour chaque ligne de **Done** non encore présente : crée la page avec statut `Done`.
5. Pour chaque ligne de **Added** : crée la page avec un tag `Off-plan` ou équivalent + statut `Done`.
6. Pour chaque ligne de **Missing** : crée la page avec statut `Todo` ou `In progress`, priorité ad hoc, deadline 11 mai pour P0.
7. Pour les pages déjà présentes : mets à jour le statut sans toucher aux notes éventuelles que Haithem aurait écrites manuellement (préserve les commentaires libres).
8. Ajoute une page épinglée "📋 Sanity check 7 mai" qui contient le rapport markdown complet en bloc, pour traçabilité.

**Ne supprime rien sur Notion.** Les pages ajoutées par Haithem qui ne matchent pas la roadmap doivent rester telles quelles.

---

## Format du rapport final

Sortie attendue à la fin de ton run, dans cet ordre :

1. **Une-ligne météo** : `🟢 / 🟡 / 🔴 — Rendu 11 mai = [tenable / risqué / compromis]`
2. **Tableaux Done / Added / Missing** comme spécifié § 3
3. **Verdict coach** § 4
4. **Récap Notion** : nombre de pages créées / mises à jour, lien vers la nouvelle page de rapport épinglée
5. **Prochaines actions concrètes pour Haithem** (5 max, ordre de priorité)

---

## Sanity check de toi-même

Avant de claim "done" sur cette tâche :
- Tu as effectivement lu les `.md` du § Étape 1 ? (sinon tu inventes)
- Tu as effectivement listé les fichiers Swift du § Étape 2 ? (sinon tu hallucines)
- Tu as essayé `xcodebuild test` ? (sinon le verdict est sans tests = faible confiance)
- Tu as accédé à Notion via MCP, ou tu as explicitement signalé que ce n'était pas possible ?
- Tu n'as pas inventé d'items "Added" sans pointer un fichier précis ?
- Le verdict est honnête, pas une réassurance polie ?

Si non à n'importe lequel de ces points, refais la passe avant de rendre.
