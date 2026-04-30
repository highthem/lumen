# ADR-005 — Monitoring éthique

## Statut
Accepté

## Contexte

Le brief demande :
- "Synthèse IA avec fallback hors-ligne et **monitoring éthique**"
- "Intégration IA avec **journalisation et rate limiting local**"
- Un livrable : **`ETHICAL_MONITORING.md`** (document)
- Un livrable : **export JSON des logs de monitoring éthique**

Le terme "monitoring éthique" est peu cadré par Sami. Interprétation assumée par le candidat : il s'agit de rendre visibles, auditables et limités les usages de l'IA dans le produit, pour :
- Contrôler les coûts (rate limit)
- Détecter les dérives (hallucinations, contenu inapproprié)
- Respecter la vie privée (pas de PII, tout local)
- Donner à l'utilisateur un droit de regard (export JSON)

## Décision

Implémenter un système de monitoring éthique à 4 piliers.

### Pilier 1 — Journalisation locale

Chaque interaction IA (réussie ou non) produit un `EthicalLog` persisté en SwiftData :

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant log local, pas d'ID user |
| `timestamp` | Date | UTC ISO 8601 |
| `provider` | String | `openai` / `anthropic` / `apple` / `offlineTemplate` |
| `mode` | String | `auto` / `manualRegenerate` / `fallbackOffline` |
| `latency_ms` | Int | Durée totale de l'appel |
| `token_in` | Int? | Tokens d'entrée (si l'API les renvoie) |
| `token_out` | Int? | Tokens de sortie |
| `prompt_hash` | String | SHA256 du prompt concaténé (system + user) |
| `content_safety_flags` | [String] | Flags de content safety pré-envoi |
| `user_feedback` | String? | `positive` / `negative` / nil |
| `privacy_scope` | String | `user_input_only` fixe en V1 |

**PRINCIPE :** aucune PII. Pas d'email user, pas d'ID remote, pas de géoloc, pas de prompt en clair.

### Pilier 2 — Content safety pré-envoi

Avant chaque appel cloud, détection basique côté device :

```swift
enum ContentSafetyFlag: String {
    case violentLanguage
    case selfHarmCue
    case medicalAdviceRequest
    case legalAdviceRequest
}

func detectFlags(in text: String) -> [ContentSafetyFlag] {
    // regex + mots-clés, pas d'IA remote
}
```

Si un flag `selfHarmCue` est détecté : l'appel IA est **remplacé** par un template de redirection vers une ressource de soutien (numéros d'urgence localisés), pas de cloud, pas de risque de réponse inappropriée.

### Pilier 3 — Rate limiting local (conditionnel selon BYO API key)

**Mode standard (Lumen AI, clés Highthem) — limites :**
- 1 synthèse auto / jour
- 3 interactions manuelles / jour (régénération + Ask Lumen, budget partagé)
- Reset à minuit local

Dépassement → UI claire ("Reviens demain pour une nouvelle question"), pas d'erreur technique.

**Mode BYO API key (clé personnelle utilisateur) :**
- **Rate limit levé** (l'utilisateur paie son usage directement à OpenAI ou Anthropic).
- Le compteur s'affiche en Settings sous la forme *"Quotas — Illimité (clé personnelle)"* pour la transparence.
- L'`EthicalLog` enregistre `usingPersonalKey: true` (champ ajouté) pour distinguer les sessions où la clé Highthem n'est pas consommée.
- La clé personnelle n'est jamais loggée elle-même, ni en clear ni en hash — elle vit uniquement dans Keychain iOS.

Voir US-AI8 (Project/02_product/user_stories/ai_synthesis.md) pour le détail des critères d'acceptation et US-AI8 dans le BYO flow.

### Pilier 4 — Export JSON et transparence utilisateur

- Settings → "Exporter mes logs" → génère un JSON complet (`exported_at`, `app_version`, array de logs) et propose un `ShareSheet`.
- Pas d'upload, pas de cloud : l'utilisateur choisit la destination.
- Settings → "Effacer mes logs" : purge complète disponible à tout moment.
- Schema JSON documenté dans `data_model.md` + `api_contracts.md`.

## Pourquoi ce design

### Privacy by design
- Tout est local. Aucun log ne quitte le device sans action explicite.
- Prompt haché, pas stocké en clair (impossible de reconstituer les réponses matinales d'un utilisateur à partir des logs).
- `privacy_scope` comme champ explicite : si demain on ajoute des features qui élargissent le scope, c'est visible.

### Voice integration (ADR-007) — engagements privacy supplémentaires
- **L'audio capté pour la dictation N'EST JAMAIS persisté ni loggé.** Seul le texte transcrit est stocké (et seul le texte est transmis à l'IA cloud pour la synthèse).
- **Reconnaissance vocale 100 % on-device** (`requiresOnDeviceRecognition = true`). Si la langue de l'utilisateur n'est pas supportée on-device → fallback typing, jamais cloud Apple speech.
- **TTS (lecture synthèse) est on-device** via `AVSpeechSynthesizer` avec voix neural natives. Aucun audio généré n'est envoyé en cloud.
- L'utilisateur peut désactiver input vocal et output vocal à tout moment dans Settings → Voice.

### Cost control
- Rate limit côté client (pas de dépendance serveur pour le plafond).
- Logs des tokens par provider pour analyser les coûts par session.

### Auditabilité
- Un utilisateur sceptique peut exporter son JSON, lire ce qui a été stocké, vérifier qu'il n'y a rien de sensible.
- Format lisible humainement, pas binaire.

### Non-jugement
- Pas de "score de qualité" de rituel, pas de classement, pas de streaks dans le log.
- Le feedback user (thumbs up/down) est optionnel et n'impacte aucune métrique produit visible.

## Conséquences

### Positives
- Alignement avec la promesse "éthique" du positionnement marketing.
- Différenciateur vs concurrents (Fabulous, Opal billing prédateurs).
- Soutenable réglementairement (GDPR : data portability via export JSON ; right to be forgotten via purge).
- Facile à démontrer en soutenance : un simple screenshot du JSON exporté suffit.

### Négatives
- Surface de code à maintenir (logger, store, export, content safety).
- Content safety basique regex est faible (peut passer à côté de cas non-anglais). À iterer.
- Pas d'analyse agrégée (pas de dashboard personnel pour l'utilisateur). V1.1 si jugé utile.

### Risques et mitigations

| Risque | Mitigation |
|--------|------------|
| Taille des logs grandit (100 synthèses = ~100 logs/an = négligeable) | Purge manuelle + auto-purge >1 an |
| Content safety laisse passer un cas sensible | Fail-safe : en cas de doute sur le flag, utiliser le template de redirection plutôt que le cloud |
| Utilisateur croit que tout est envoyé à OpenAI | Copy explicite dans Settings : "Ton questionnaire est envoyé à OpenAI/Anthropic pour la synthèse. Rien d'autre. Pas d'ID, pas d'email." |

## Document `ETHICAL_MONITORING.md` (livrable brief)

Le document final à livrer à Sami reprendra :
- Ce ADR-005 en version prose
- Un extrait JSON d'exemple anonymisé
- Les principes privacy
- Les limitations connues
- Les évolutions prévues V1.1

## Références

- [GDPR — Right of access](https://gdpr-info.eu/art-15-gdpr/)
- [Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/)
- Principes d'IA responsable (Anthropic, OpenAI — referenced publicly)
