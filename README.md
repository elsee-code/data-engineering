# Schéma du tunnel d'inscription Elsee

Page web privée (comptes @elsee.care) qui redessine le tunnel d'inscription
d'Elsee sous forme de diagramme de flux. Pour la période choisie, elle montre :
- les arrivées sur chaque étape, les passages sur chaque flèche et le taux
  d'abandon de chaque étape ;
- le nombre de leads ;
- un tableau « Pages vues par personne ».

Les chiffres sont recalculés à partir de l'export quotidien de GA4 dans
BigQuery.

- **Règles de calcul et d'affichage** : [`docs/regles.md`](docs/regles.md)
- **État du projet, questions ouvertes, historique des décisions** :
  [`docs/decisions.md`](docs/decisions.md)
- **Mettre la page en ligne ou la mettre à jour** (pas à pas, pour
  hello@elsee.care) :
  [`docs/deploiement_apps_script.md`](docs/deploiement_apps_script.md)
- **Modifier le schéma** (ajouter une page, une flèche) :
  [`config/README.md`](config/README.md)

## Comment ça marche

1. **GA4 → BigQuery** : GA4 exporte chaque jour les pages vues dans le dataset
   `ga4-chemin-form.analytics_383563328` (région EU, lecture seule pour nous).
2. **Calcul dans BigQuery** : la fonction de table
   `ga4-chemin-form.elsee_funnel.agregats(date_debut, date_fin)` calcule tous
   les chiffres d'une période. Elle ne renvoie que des totaux, jamais
   d'identifiant de personne. Elle est générée à partir du fichier de
   configuration et n'expire pas.
3. **Page Apps Script** : application web du compte hello@elsee.care. Elle
   appelle la fonction, garde les résultats en cache 6 heures et dessine le
   schéma en SVG. Une vérification quotidienne envoie un e-mail en cas de gros
   problème.

La seule description du tunnel est [`config/graphe.json`](config/graphe.json)
(étapes, flèches, chemins, positions dans le dessin, règles des leads et du
paiement). Le calcul et la page en sont générés.

## Les fichiers

| Fichier | Rôle |
|---|---|
| [`config/graphe.json`](config/graphe.json) | Description du tunnel ; mode d'emploi : [`config/README.md`](config/README.md) |
| [`scripts/generer_sql.mjs`](scripts/generer_sql.mjs) | Vérifie la configuration et génère `sql/calcul/` et `apps-script/Graphe.gs` : `node scripts/generer_sql.mjs` |
| [`sql/calcul/creer_fonction.sql`](sql/calcul/creer_fonction.sql) | Crée ou remplace la fonction `elsee_funnel.agregats` (généré) |
| [`sql/calcul/agregats.sql`](sql/calcul/agregats.sql) | Le même calcul en script autonome, dates en tête du fichier : chaque chiffre affiché se retrouve ici (généré) |
| [`sql/calcul/controle_coherence.sql`](sql/calcul/controle_coherence.sql) | Contrôle « sorties + abandons ≈ arrivées » par étape : aucun écart négatif attendu (généré) |
| [`apps-script/`](apps-script/) | Code de la page : `Code.gs` (serveur, cache, alertes), `Page.html` (dessin), `Graphe.gs` (configuration, générée), `appsscript.json` |
| [`scripts/apercu_page.mjs`](scripts/apercu_page.mjs) | Aperçu local de la page, sans Apps Script, à partir d'agrégats en CSV |
| [`scripts/activer_cle_gcp.sh`](scripts/activer_cle_gcp.sh) | Active la clé du compte de service dans une session cloud |

## Tâches courantes

**Modifier le schéma** : suivre [`config/README.md`](config/README.md).
1. Modifier `config/graphe.json`.
2. Lancer `node scripts/generer_sql.mjs`.
3. Vérifier avec `controle_coherence.sql`.
4. Recréer la fonction avec `creer_fonction.sql`, avec l'accord d'Eglantine.
5. Remplacer `Graphe.gs` (et `Page.html` s'il a changé) dans Apps Script, puis
   publier une nouvelle version.

**Lancer une requête dans une session cloud** :

```sh
scripts/activer_cle_gcp.sh   # une fois par session ; la clé n'est jamais affichée
env -u CLOUDSDK_AUTH_ACCESS_TOKEN bq query --project_id=ga4-chemin-form --use_legacy_sql=false < sql/calcul/agregats.sql
```

- **La clé** : la variable d'environnement `GCP_SA_KEY_JSON` de la session
  contient la clé JSON du compte de service
  `funnel-dev@ga4-chemin-form.iam.gserviceaccount.com` (brute ou en base64).
- **Les droits du compte de service** : lecture seule (« Lecteur de données
  BigQuery ») sur `analytics_383563328`, écriture dans `elsee_funnel`.
- **Le jeton factice** : la session cloud définit un jeton
  `CLOUDSDK_AUTH_ACCESS_TOKEN` qui fait échouer `bq`, d'où le `env -u`.

**Voir la page sans Apps Script** : exporter les agrégats d'une période en
CSV, puis ouvrir le fichier HTML produit dans un navigateur.

```sh
env -u CLOUDSDK_AUTH_ACCESS_TOKEN bq query --project_id=ga4-chemin-form --use_legacy_sql=false --format=csv --max_rows=100000 \
  'SELECT genre, de, vers, jour, utilisateurs FROM `ga4-chemin-form.elsee_funnel.agregats`(DATE "2026-10-05", DATE "2026-10-07")' > agregats.csv
node scripts/apercu_page.mjs agregats.csv 2026-10-05 2026-10-07 apercu.html
```

**En cas de problème** : voir la rubrique « Dépannage » de
[`docs/deploiement_apps_script.md`](docs/deploiement_apps_script.md).

## Contraintes

- Projet `ga4-chemin-form` en **bac à sable BigQuery** : pas de DML ni de requête
  programmée ; tables et vues expirent 60 jours après leur création (la
  fonction de table, elle, n'expire pas).
- Lecture seule sur `analytics_383563328` ; écritures seulement dans
  `elsee_funnel`.
- Aucun identifiant de personne (`user_pseudo_id`, `ga_session_id`) ne sort de
  BigQuery.
- Aucun secret dans le dépôt.
- On ne modifie ni GTM ni GA4.
