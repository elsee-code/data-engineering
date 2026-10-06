# Schéma du tunnel d'inscription Elsee (GA4 → BigQuery → Apps Script)

Avant toute action, lire [`docs/decisions.md`](docs/decisions.md) (état du
projet, décisions, questions ouvertes), puis [`docs/brief.md`](docs/brief.md).

## Règles

- Tout en français : interface, documentation, messages de commit.
- Faire valider par Eglantine à la fin de chaque étape, et avant toute action
  irréversible (création de dataset, de vue, de déclencheur, déploiement).
- Le projet `ga4-chemin-form` est en **bac à sable BigQuery** : pas de DML, pas
  de requête programmée ; tables et vues expirent 60 jours après leur création.
- Lecture seule sur `analytics_383563328` ; écritures uniquement dans
  `elsee_funnel`.
- Aucun `user_pseudo_id` ni `ga_session_id` ne sort de BigQuery : ne renvoyer
  que des agrégats, y compris dans le terminal pendant le développement.
- Aucun secret dans le dépôt. La clé du compte de service est fournie par une
  variable d'environnement de la session cloud : l'écrire dans un fichier hors
  du dépôt (droits 600) pour `gcloud auth activate-service-account`, ne jamais
  l'afficher.
- Ne modifier ni GTM ni GA4.
- Ne rien deviner : si une information manque, la demander.
- Tenir `docs/decisions.md` à jour à chaque décision.
