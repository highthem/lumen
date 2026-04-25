# User stories — Synthèse IA

## Epic
En tant qu'utilisateur, je veux recevoir une synthèse courte et pertinente de mes réponses pour cadrer ma journée.

## Contexte technique

Pattern **waterfall IA** (réutilisé du projet Skoul) :
1. **Cloud primaire** : OpenAI (GPT-4o-mini ou équivalent)
2. **Cloud secondaire** : Anthropic Claude (Haiku 4.5) en fallback
3. **On-device** : Apple Intelligence (iOS 18+ si dispo) — note : impact sur cible iOS 17 à documenter
4. **Offline final** : template pré-écrit contextualisé par les réponses (pas d'IA)

## US-AI1 — Générer la synthèse
**En tant qu'** utilisateur
**Je veux** recevoir une synthèse de mes réponses du matin
**Afin de** avoir un cadrage clair pour ma journée

**Critères d'acceptation :**
- Synthèse déclenchée automatiquement à la fin du questionnaire.
- Format : 3 éléments concis
  - **Intention du jour** (1-2 phrases, reprend l'input utilisateur enrichi du contexte)
  - **Focus suggéré** (1-2 actions concrètes alignées sur la Priorité et le Ressenti)
  - **Rappel doux** (une phrase de présence, ancrée sur la Gratitude ou l'émotion du jour)
- Temps de génération cible : < 4 secondes en cloud, < 1 seconde en offline.
- Streaming du texte si supporté (UX plus vivante).

## US-AI2 — Fallback hors-ligne
**En tant qu'** utilisateur sans réseau
**Je veux** quand même avoir une synthèse
**Afin de** ne pas être bloqué

**Critères d'acceptation :**
- Détection offline via `NWPathMonitor`.
- Si offline : mode template avec 12 variantes pré-écrites par humeur (Q1), interpolant les inputs Q2/Q3/Q4.
- UI indique visuellement que la synthèse est "mode hors-ligne" (badge discret, pas de popup).
- Logged dans monitoring éthique comme `mode: offline`.

## US-AI3 — Rate limiting local
**En tant qu'** éditeur de l'app
**Je veux** limiter les appels IA par utilisateur
**Afin de** contrôler les coûts et éviter les abus

**Critères d'acceptation :**
- Max 1 synthèse automatique par jour par device (celle du rituel).
- Max 3 régénérations manuelles par jour (si l'utilisateur appuie sur "Régénérer").
- Après dépassement : message clair "Limite atteinte pour aujourd'hui", pas d'erreur technique.
- Compteur reset à minuit local.

## US-AI4 — Régénération manuelle
**En tant qu'** utilisateur insatisfait de la synthèse
**Je veux** pouvoir demander une autre version
**Afin de** trouver celle qui me parle

**Critères d'acceptation :**
- Bouton "Régénérer" discret sur l'écran synthèse.
- Soumis au rate limiting (US-AI3).
- Nouvelle synthèse remplace l'ancienne (pas d'historique de régénération V1).
- Log dans monitoring éthique.

## US-AI5 — Monitoring éthique
**En tant qu'** éditeur de l'app
**Je veux** tracker la qualité, la privacy et l'impact des appels IA
**Afin de** garantir un usage responsable

**Critères d'acceptation :**
- Chaque appel IA logue (localement et exportable en JSON) :
  - `id` (UUID local, pas d'ID user)
  - `timestamp`
  - `provider` (openai / anthropic / apple / offline)
  - `mode` (auto / manual-regen / fallback)
  - `latency_ms`
  - `token_in`, `token_out` (si dispo via API)
  - `prompt_hash` (hash du prompt, pas le prompt en clair)
  - `content_safety_flags` (détection mots-clés sensibles pré-envoi)
  - `user_feedback` (thumbs up/down optionnel)
  - `privacy_scope` (`user_input_only` — on ne transmet pas de PII au-delà des réponses user)
- Export JSON accessible depuis Settings.
- Pas d'envoi remote, tout est local.

## US-AI6 — Accès rapide à l'IA depuis le dashboard
**En tant qu'** utilisateur
**Je veux** pouvoir solliciter l'IA depuis le dashboard
**Afin de** approfondir sur une catégorie

**Critères d'acceptation :**
- Bouton "Ask Lumen" visible sur le dashboard.
- Prompt prédéfini type : "Donne-moi un focus de 5 minutes pour la catégorie X, basé sur mes réponses du matin."
- Soumis au rate limiting.
- Output en modal avec option "Fermer" uniquement (pas de conversation V1).

## Out of scope V1
- Conversation multi-tour avec l'IA
- Personnalisation du ton (formel / chaleureux / direct)
- Export de l'historique de synthèses
- Apprentissage des préférences via feedback explicite
