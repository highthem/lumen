# User stories — Dashboard

## Epic
En tant qu'utilisateur, je veux un dashboard qui reflète mon identité du jour et me permet d'y revenir tout au long de la journée.

## Les 6 catégories (décision candidat D5)

1. **Énergie** — niveau perçu, évolution journalière
2. **Intention** — intention du jour (issue Q4)
3. **Corps** — check-in physique (hydratation, mouvement, sommeil ressenti)
4. **Relations** — une personne à qui penser/contacter aujourd'hui
5. **Travail** — priorité n°1 (tirée de Q2 si `travail` taggé)
6. **Gratitude** — gratitude du jour (issue Q3)

Rationale : miroir d'identité, pas métriques cliniques. Différenciation vs Rise (chiffres) et Fabulous (tâches).

## US-D1 — Vue d'ensemble
**En tant qu'** utilisateur
**Je veux** voir les 6 catégories d'un coup d'œil
**Afin de** avoir ma journée en tête

**Critères d'acceptation :**
- 6 cards en grille 2 colonnes.
- Chaque card : icône, titre, 1-2 lignes de contenu ou placeholder.
- Accès au détail au tap.
- Accès "Ask Lumen" (US-AI6) en bouton flottant global.

## US-D2 — Alimentation automatique post-rituel
**En tant qu'** utilisateur
**Je veux** que le dashboard soit rempli automatiquement après mon rituel
**Afin de** ne pas avoir à re-saisir des infos

**Critères d'acceptation :**
- Énergie : dérivée du Ressenti (Q1) via mapping humeur → énergie.
- Intention : directement issue de Q4.
- Corps : hydratation/sommeil laissés en placeholder utilisateur, check-in manuel.
- Relations : placeholder "Qui veux-tu soutenir aujourd'hui ?" avec 1 tap pour remplir.
- Travail : issue de Q2 si pertinent, sinon placeholder.
- Gratitude : directement issue de Q3.

## US-D3 — Détail par catégorie
**En tant qu'** utilisateur
**Je veux** pouvoir approfondir une catégorie
**Afin de** noter plus, voir un peu d'historique, demander à l'IA

**Critères d'acceptation :**
- Écran détail par catégorie : contenu du jour + 7 derniers jours (si existant).
- Possibilité d'éditer le contenu du jour.
- Bouton "Ask Lumen" contextuel (pré-prompt par catégorie).
- Pas de graphiques (pas quantified-self) — listes courtes et texte.

## US-D4 — État vide (premier jour)
**En tant qu'** utilisateur au premier lancement
**Je veux** comprendre à quoi sert le dashboard sans avoir encore fait de rituel
**Afin de** ne pas être perdu

**Critères d'acceptation :**
- Empty state avec brève explication et CTA "Programme ta première alarme".
- Pas de fake data.
- Animation subtile qui fait sentir que c'est vivant.

## US-D5 — Accessible à tout moment
**En tant qu'** utilisateur en cours de journée
**Je veux** pouvoir revenir au dashboard
**Afin de** me reconnecter à mon intention

**Critères d'acceptation :**
- Dashboard = home screen de l'app hors rituel.
- Ouverture directe du dashboard si rituel déjà fait ce jour.
- Si rituel pas encore fait : prompt doux "Tu veux démarrer ton rituel ?"

## US-D6 — Reset quotidien
**En tant qu'** utilisateur
**Je veux** que le dashboard soit "neuf" chaque jour
**Afin de** ne pas voir l'ancien quand je me lève

**Critères d'acceptation :**
- À 3h du matin (heure locale), le dashboard bascule sur le nouveau jour (J+1).
- L'état J-1 reste consultable via l'historique.
- Pas d'alerte, pas de popup, juste un switch silencieux.

## Out of scope V1
- Graphiques / charts
- Customisation des 6 catégories
- Partage social
- Widget iOS home screen (V1.1)
