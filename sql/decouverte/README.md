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

## Lancer une requête

Les dates se règlent en tête de fichier (`DECLARE date_debut` / `date_fin`, au
format `AAAAMMJJ`). Par défaut : du 5 octobre 2026 à hier.

- **Console BigQuery** : coller le fichier dans un onglet de requête, puis
  Exécuter. Le fichier est un script : le résultat est celui de la dernière
  instruction.
- **Ligne de commande** :
  ```sh
  bq query --project_id=ga4-chemin-form --use_legacy_sql=false < sql/decouverte/04_domaines_et_chemins.sql
  ```

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
l'export. Si ces champs n'existent pas dans le schéma de la table, les retirer
des clauses `ORDER BY`.
