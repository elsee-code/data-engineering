# Étape 1 — Requêtes de découverte

Toutes en **lecture seule** sur `ga4-chemin-form.analytics_383563328`. Elles ne
renvoient que des agrégats : aucun `user_pseudo_id` ni `ga_session_id` ne sort
de BigQuery.

| Fichier | Question |
|---|---|
| `01_inventaire_tables.sql` | Quelles tables quotidiennes existent, quand sont-elles arrivées, quand expirent-elles ? |
| `02_volumes_par_jour.sql` | Volumes par jour ; part des événements sans identifiant (refus de cookies) ; user_id envoyés ? ; fuseau horaire de la propriété |
| `03_evenements.sql` | Le formulaire envoie-t-il un page_view par étape, ou des événements personnalisés ? |
| `04_domaines_et_chemins.sql` | Domaines et vrais chemins du tunnel, avec volumes |
| `05_continuite_inter_domaines.sql` | Une session continue-t-elle d'elsee.care à app.elsee.care ? |
| `06_transitions_tunnel.sql` | Transitions réellement observées entre pages du tunnel (flèches, raccourcis NON, transitions hors schéma) |
| `07_pages_intercalees.sql` | Pages hors motif vues juste après une page du tunnel (étapes oubliées par le motif ?) |
| `08_ruptures_de_session.sql` | Pages du tunnel sur lesquelles une session démarre (rupture inter-domaines, retour de paiement, inactivité) |
| `09_identite_www_vers_app.sql` | Sessions ouvertes sur app.elsee.care depuis www.elsee.care : la personne garde-t-elle son identifiant GA4 ? |
| `10_evenements_formulaire_paiement.sql` | Pages et paramètres des événements `step_form`, `form_start`, `click_form`, `add_to_cart`, `order_paid` ; pages `/success` et `/bienvenue-chez-elsee` |
| `11_identite_retour_vers_www.sql` | Retour vers www.elsee.care (depuis app ou Stripe) : même identifiant, même session ? |
| `12_nouvelle_etape_par_heure.sql` | Après `/signup/medecine_douce_step`, heure par heure : `en_savoir_plus_sur_vous` ou `depenses_sports` ? |
| `13_provenance_entrees_app.sql` | Arrivées sur le formulaire selon la page de www.elsee.care d'origine (réponse : la provenance est réduite au domaine) |
| `14_parcours_sessions_precedentes.sql` | Sessions qui commencent sur `/mon-offre`, `/mon-panier` ou `/bienvenue-chez-elsee` : parcours suivi dans une session précédente ? |
| `15_en_savoir_plus_selon_entree.sql` | Qui voit `/signup/en_savoir_plus_sur_vous`, selon la première page de la session |

Les requêtes 09 à 13 ont été ajoutées après une première lecture des résultats, 14 et 15 pendant l'étape 2.
Résultats du 5 octobre 2026 (agrégats seulement) :
[`resultats/20261005/`](resultats/20261005/). Analyse :
[`docs/etape1_decouverte.md`](../../docs/etape1_decouverte.md).

Attention : le motif `motif_tunnel` des requêtes 04 à 08 attrape aussi
`/remboursements`, une page de l'espace membre (préfixe « remboursement ») ;
l'ignorer dans les résultats.

## Lancer une requête

Les dates se règlent en tête de fichier (`DECLARE date_debut` / `date_fin`, au
format `AAAAMMJJ`). Par défaut : du 5 octobre 2026 à hier.

Dans une session cloud, activer d'abord la clé du compte de service (variable
`GCP_SA_KEY_JSON`, jamais affichée) :

```sh
scripts/activer_cle_gcp.sh
```

- **Console BigQuery** : coller le fichier dans un onglet de requête, puis
  Exécuter. Le fichier est un script : le résultat est celui de la dernière
  instruction.
- **Ligne de commande** :
  ```sh
  env -u CLOUDSDK_AUTH_ACCESS_TOKEN bq query --project_id=ga4-chemin-form --use_legacy_sql=false < sql/decouverte/04_domaines_et_chemins.sql
  ```
  (`env -u` retire le jeton factice que la session cloud définit et qui ferait
  échouer `bq`.)

Région et expiration par défaut du dataset d'export :

```sh
bq show --format=prettyjson ga4-chemin-form:analytics_383563328
```

## Ce qu'on en tire

Un **tableau de correspondance schéma ↔ données réelles** à valider avec
Eglantine avant l'étape 2 :

1. pour chaque étape du schéma : chemin réel (domaine + chemin), utilisateurs,
   statut (trouvée, chemin différent, introuvable) ;
2. les pages réelles du tunnel absentes du schéma ;
3. pour chaque raccourci NON : destination prévue au schéma et destination
   réelle ;
4. les transitions observées absentes du schéma ;
5. l'état du suivi inter-domaines et des ruptures de session.

Note : les requêtes trient les pages d'une session avec `event_timestamp` puis
les champs `batch_ordering_id`, `batch_page_id` et `batch_event_index` de
l'export (présents dans les tables, vérifié le 6 oct.).
