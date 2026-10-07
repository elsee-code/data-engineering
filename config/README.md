# Configuration du graphe : `graphe.json`

Seule description du tunnel. Le calcul (requêtes de `sql/calcul/`) et la page
(`apps-script/Graphe.gs`) en sont générés. Ajouter une page au formulaire = modifier ce fichier,
puis régénérer les requêtes.

## Contenu

- `domaines` : domaines pris en compte (les autres sont ignorés).
- `parcours` : parcours du schéma, avec libellé et couleur.
- `etapes` : une entrée par étape.
  - `id` : identifiant unique (minuscules, chiffres, `_`) ;
  - `chemin` : chemin de la page, en minuscules, sans paramètres ni « / » final ;
  - `domaine` : domaine de la page ;
  - `parcours` : clé d'un des `parcours` ;
  - `position` : place dans le dessin (`colonne` : 0 = colonne principale,
    négatif = à gauche ; `ligne` : de haut en bas) ;
  - `libelle` (facultatif) : titre affiché au-dessus du chemin (ex. « SOCIAL ») ;
  - `effacer_si_retour` (facultatif) : une visite suivie d'un retour à la page
    précédente, puis d'une flèche partant de cette page, compte comme si la
    personne n'avait pas vu l'étape (utilisé pour `/pricing/cartecadeau`).
- `fleches` : une entrée par flèche.
  - `de`, `vers` : `id` des étapes ;
  - `type` : `normale`, `oui` ou `non` (raccourci NON). Une page à question a
    exactement une flèche `oui` et une flèche `non` ;
  - `mesurable` (facultatif, `false`) : passage impossible à mesurer, laissé
    vide par le calcul, avec la `raison` ;
  - `note` (facultatif) : explication affichée avec la flèche.

Une même page peut porter plusieurs étapes, une par parcours (`/mon-offre`,
`/mon-panier`, `/bienvenue-chez-elsee`) : l'étape est déduite de la page
précédente. Une page précédente ne doit donc mener qu'à une seule de ces étapes.

## Ajouter une étape

1. Ajouter l'étape dans `etapes`, et ses flèches dans `fleches` (en remplaçant
   la flèche qu'elle coupe, s'il y en a une).
2. Régénérer les requêtes : `node scripts/generer_sql.mjs`. Le script vérifie
   la configuration (identifiants, flèches, pages à question, boucles, taille
   de la fonction : 32 Ko au plus) et
   s'arrête en cas d'erreur.
3. Vérifier avec `sql/calcul/controle_coherence.sql` (aucun écart négatif).
4. Recréer la fonction dans BigQuery :
   `env -u CLOUDSDK_AUTH_ACCESS_TOKEN bq query --project_id=ga4-chemin-form --use_legacy_sql=false < sql/calcul/creer_fonction.sql`
   (après `scripts/activer_cle_gcp.sh` dans une session cloud).
5. Mettre à jour la page : remplacer le contenu de `Graphe.gs` dans le projet
   Apps Script par `apps-script/Graphe.gs` (régénéré à l'étape 2), puis publier
   une nouvelle version (voir [`docs/deploiement_apps_script.md`](../docs/deploiement_apps_script.md)).
