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
  - `repli` (facultatif, `true`) : étape de repli de sa page. Une page vue sans
    parcours connu (règle 2.4 de `docs/etape2_calcul.md`) y est rattachée. Une
    seule par page (le chemin MAIL pour `/mon-offre`, `/mon-panier` et
    `/bienvenue-chez-elsee`) ;
  - `fleche_entree` (facultatif, `true`) : dessine une flèche venant de la
    gauche, avec le nombre de personnes arrivées directement sur l'étape (début
    de session) ;
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
- `pages_vues` : tableau « Pages vues par personne », à côté du schéma.
  - `formulaire` : domaine du formulaire. Les personnes qui n'y ont vu aucune
    page sont données à part ;
  - `debut` : `id` des étapes par lesquelles on commence le formulaire. Seules
    les personnes qui en ont vu une sur la période sont comptées ; les autres
    personnes du formulaire sont données à part (arrivées en cours de route) ;
  - `offre` : `id` des étapes qui montrent son offre à la personne (colonne
    « dont ont vu leur offre ») ;
  - `position` : coin supérieur gauche du tableau dans le dessin (`colonne`,
    `ligne`), dans un espace laissé libre par les étapes.
- `paiement` : case de fin « paiement ok ».
  - `libelle` : nom affiché ;
  - `page` : page (domaine + chemin) qui porte les étapes de fin ;
  - `pages` : pages regroupées sous ce nom, chacune avec ses conditions
    facultatives : `apres` (page vue juste avant dans la session) et
    `provenance` (domaine d'où l'on vient). Une page avec conditions ne compte
    que si l'une est remplie ; sinon elle est ignorée. Sans condition, elle
    compte toujours ;
  - `reprise_si_provenance` : domaines (Stripe) depuis lesquels une page de
    paiement reprend le parcours de la session précédente (le paiement ouvre
    souvent une nouvelle session).
- `leads` : encadré « Nombre leads » (personnes qui ont donné leurs
  coordonnées ; règle 10 de [`docs/etape2_calcul.md`](../docs/etape2_calcul.md)).
  Les étapes citées doivent porter seules leur page.
  - `provenance_interne` : domaine du formulaire. Une page ouverte depuis ce
    domaine (navigation dans le formulaire) ne change pas l'entrée de la
    session ;
  - `entrees` : pages d'entrée, dans l'ordre (la première qui convient
    s'applique). `etape` ; `provenance` (facultatif) : domaine de la page d'où
    l'on vient ; `coordonnees` : `a_l_entree` (coordonnées données avant le
    questionnaire) ou `plus_tard` ;
  - `moments` : moments où un lead est compté. `id`, `libelle` et `detail`
    (affichés dans la bulle d'aide) ; `page` : étape dont l'arrivée compte ;
    `apres` (facultatif) : étape qui doit la précéder juste avant dans la
    session ; `entree` (facultatif) : `a_l_entree` ou `plus_tard`, l'entrée que
    doit avoir la session.

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
