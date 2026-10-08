# Journal des décisions

L'état du projet, les questions ouvertes et, en bref, l'historique des
décisions d'Eglantine. Les règles qui en résultent sont toutes décrites dans
[`regles.md`](regles.md), qui fait foi.

Le détail de chaque décision (chiffres, essais, variantes écartées) est dans
l'historique Git : journal complet, brief initial et comptes rendus des étapes
1 et 2 au commit `cdcb229` (avant le tri du 8 octobre).

## État du projet

| Étape | État |
|---|---|
| 0. Informations et accès | Faite (5 – 6 oct.) |
| 1. Découverte des données | Faite et validée (6 oct.) |
| 2. Calcul dans BigQuery | Fait (7 oct.) : fonction `elsee_funnel.agregats`, mise à jour le 8 oct. |
| 3. Page Apps Script | En ligne, publiée par Eglantine ; dernière mise à jour le 8 oct. |
| 4. Alertes | Écrites et testées hors ligne ; installation du déclencheur à confirmer (section 6 de [`deploiement_apps_script.md`](deploiement_apps_script.md)) |
| 5. Documentation | Faite (8 oct.) : [`README`](../README.md), [`regles.md`](regles.md), tri du dépôt |
| Recette | À faire (voir ci-dessous) |

## Questions ouvertes

- **Recette** : comparer les arrivées du schéma aux explorations GA4 sur une
  période d'au moins 7 jours couverte par l'export (au plus tôt du 5 au 11
  oct.). Il faut pour cela :
  - l'export des quatre explorations (long form, compléments, offre directe,
    bloc compléments) sur cette période ;
  - leur définition : entonnoir ouvert ou fermé, « suivie directement de » ou
    « suivie de », pages de l'étape « Entrée ».

  L'ancien export (8 sept. – 5 oct.) est antérieur à l'export BigQuery,
  il ne peut pas servir.
- **Réglages GA4**, pour expliquer les écarts à la recette : mode de
  consentement, identité utilisée pour les rapports.
- **Alertes** : le déclencheur `verifierChaqueJour` est-il installé ?
- **À signaler à la personne qui gère GTM** (nous n'y touchons pas) :
  - GA4 perd la personne entre www.elsee.care et app.elsee.care ;
  - l'événement `order_paid` n'est envoyé que sur `/bienvenue-chez-elsee`, pas
    sur `/success`.

## Historique des décisions

Le plus récent en haut.

### 8 octobre 2026

- **Calcul accéléré** (demande d'Eglantine : plus rapide, sans perte de
  qualité ni approximation) : de 20 – 40 s à environ 4 s. Aucune règle ne
  change : les blocs intermédiaires du calcul ne sont plus lus qu'une fois
  (BigQuery les recalculait à chaque lecture : 1 518 étapes d'exécution, 121
  maintenant). Résultats identiques, ligne à ligne, à ceux de la fonction en
  place sur cinq périodes (5 – 7 oct., 5 oct., 6 oct., 7 – 12 oct., une période
  sans données) ; contrôle de cohérence sans écart négatif. Fonction BigQuery
  remplacée avec l'accord d'Eglantine (3 s sur les 5 – 7 oct., mêmes
  résultats).
- **Textes de la page allégés** (même demande) : bulles des 4 pages de
  `/obtenir-mon-offre` réduites à « page N sur 4 » ; texte des pages sans
  parcours connu remis à jour ; messages « indisponible » prévus pour une
  ancienne fonction BigQuery retirés. `Page.html` à remplacer dans Apps Script.
- **Les 4 pages de `/obtenir-mon-offre`** (demande d'Eglantine, développée sur
  la branche `etapes-obtenir-mon-offre`, fusionnée dans `main` puis supprimée) :
  - le formulaire, à adresse unique, est suivi par l'événement GA4
    `step_form` (balise GTM d'Eglantine : envoyé à chaque nouvelle page
    affichée, avec `form_derniere_page`) ;
  - il est dessiné en 4 étapes au-dessus de `/signup` : page 1 (arrivées
    d'après les pages vues), pages 2 à 4 (d'après l'événement) ;
  - page 4 → `/signup` non mesurable, sans taux d'abandon sur la page 4 : une
    partie des personnes de la page 4 est passée sur `/signup` (remarque
    d'Eglantine).

  Précision d'Eglantine : atteindre une page, c'est avoir vu toutes celles
  d'avant. Les personnes arrivées à la page 2 sans que GA4 ait vu leur page 1
  (12, sans doute des cookies acceptés en cours de formulaire) comptent donc
  aussi à la page 1 et dans le passage page 1 → page 2.

  Les 5 – 7 oct. : page 1 134 (abandon 48 %), page 2 67 (abandon 7 %), page 3
  62 (0 %), page 4 62. Le reste du calcul est identique ; contrôle de cohérence sans
  écart négatif sur les 61 étapes. Fonction BigQuery remplacée avec l'accord
  d'Eglantine (résultats identiques au test). Reste à faire par Eglantine :
  remplacer `Page.html` et `Graphe.gs` dans Apps Script et publier une nouvelle
  version.
- **Encadré « Clients »** à côté du nombre de leads : personnes arrivées sur
  « paiement ok » sur la période, tous chemins (somme des cases de fin ;
  identique au nombre de personnes distinctes sur les 5 – 7 oct. : 7, 3 et 4).
  Calculé dans la page : la fonction BigQuery ne change pas. Bulle d'aide par
  chemin, courbe par jour, repris dans l'export PNG. Reste à faire par
  Eglantine : remplacer `Page.html` dans Apps Script et publier une nouvelle
  version.
- **Tri du dépôt** (demande d'Eglantine) :
  - règles regroupées dans [`regles.md`](regles.md) ;
  - README complet ;
  - journal résumé ;
  - supprimés car dépassés : brief initial, comptes rendus des étapes 1 et 2,
    requêtes de découverte et résultats du 5 oct., PDF de référence (schéma du
    6 oct., explorations GA4 du 8 sept. – 5 oct.).
- **Carte cadeau** : une branche `/pricing/cartecadeau` → `/mon-panier` →
  paiement ok après chaque `/mon-offre` (offre directe, long form, MAIL),
  plutôt qu'une branche commune. Pas d'entrée www.elsee.care/carte-cadeau. La
  règle du détour par la carte cadeau est gardée sur les trois branches.
- **Retours** : une personne qui revient (e-mail, plus tard) sur `/mon-offre`
  et les pages suivantes ne compte que dans le chemin MAIL, plus dans son
  ancien chemin. But : distinguer les personnes qui arrivent après avoir
  répondu au formulaire. Exception : le paiement en revenant de Stripe garde
  son chemin. Cela remplace la règle du 7 oct.
- **Paiement ok** remplace `/bienvenue-chez-elsee` en fin de chaque chemin :
  `/bienvenue-chez-elsee` ou `/success`, juste après `/mon-panier` ou en
  revenant de Stripe. Ventes réelles données par Eglantine : 6, 4 et 3 les 5,
  6 et 7 oct. Cette règle, la plus proche, donne 7, 3 et 4.
- **Tableau « Pages vues par personne »** : seulement les personnes qui
  commencent le formulaire par `/signup`, `/social_signup` ou `/signup-corpo` ;
  sans les entrées de www.elsee.care (GA4 y perd la plupart des personnes).
  Créé le même jour, avec la colonne « dont ont vu leur offre ».
- **Chemin MAIL** : `/mon-bilan-elsee` → `/mon-offre` → `/mon-panier` → paiement
  ok, avec des flèches d'entrée pour les personnes arrivées directement. Il
  remplace la liste des pages « sans parcours connu ». Flèche www → app en
  pointillés. Pas de flèche `/obtenir-mon-offre` → `/mon-bilan-elsee` (ce lien
  n'existe pas).
- **Nombre leads** : trois moments de recueil des coordonnées ; la pop-up avant
  `bilan` est obligatoire ; l'offre directe n'est pas comptée ; un lead au plus
  par personne ; une personne revenue en cours de formulaire n'est pas
  comptée.
- **Premier essai de la page** : « Hier » sans données d'hier, périodes vides,
  période libre corrigés ; message d'arrivée des données « dans le courant du
  lendemain ».

### 7 octobre 2026

- **Alertes** : à hello@elsee.care, seulement en cas de gros problème (export
  arrêté depuis plus de 2 jours, calcul en échec, tunnel à zéro), vérification
  entre 15 h et 16 h, rappel tous les 3 jours.
- **Affichage des taux** : tous les taux d'abandon dans les étapes, jamais sur
  les flèches. La répartition en % des sorties fait toujours 100 %.
- **Page Apps Script** :
  - propriétaire et exécution : hello@elsee.care ;
  - accès : comptes @elsee.care ;
  - mise en ligne par Eglantine, par copier-coller.

  L'étape 2 est validée.
- **BigQuery** : dataset `elsee_funnel` (EU) et fonction de table
  `agregats(date_debut, date_fin)` créés. Ils remplacent les vues et la
  requête programmée prévues, impossibles ou inutiles en bac à sable.
- Rattachement des personnes qui reviennent à leur ancien parcours, sur 60
  jours (remplacé le 8 oct. par le chemin MAIL).

### 6 octobre 2026

- **Correspondance schéma ↔ données validée** :
  - seuls app.elsee.care et www.elsee.care comptent ;
  - raccourci NON de `depenses_complements` vers `sante_mentale_seances` ;
  - `en_savoir_plus_sur_vous` n'est montrée qu'aux personnes sans coordonnées ;
  - entrées vers `/signup` (et `/social_signup` vers `depenses_complements`) ;
  - seuls les raccourcis du schéma sont dessinés ;
  - pages hors schéma ignorées ;
  - aucun chiffre sur les flèches www → app.
- **Carte cadeau** : un aller-retour vers `/pricing/cartecadeau` avant
  `/mon-panier` compte comme un passage direct.
- **Affichage** : page web Apps Script plutôt qu'un module Odoo.
- **Bac à sable BigQuery gardé** : pas de DML ni de requête programmée,
  expiration à 60 jours.
- **Page** :
  - période éditable ;
  - libellé du seuil compléments retiré ;
  - les arrivées sans page précédente ne sont pas affichées (remplacé le 8 oct.
    par le chemin MAIL).
- **Branche Git principale** : `main`. Chaque session y fusionne son travail.

### 5 octobre 2026

- **Étape 0** : liste des informations et accès manquants (accès BigQuery,
  fichier de référence, choix d'affichage).
