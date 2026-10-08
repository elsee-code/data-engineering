# Étape 2 — Calcul : configuration du graphe et requêtes

> **Terminée, à valider par Eglantine.** Le calcul est en place dans BigQuery
> depuis le 7 octobre 2026 : fonction `elsee_funnel.agregats(date_debut,
> date_fin)`, testée sur la journée du 5 octobre (section 5).

## 1. Les fichiers

| Fichier | Rôle |
|---|---|
| [`config/graphe.json`](../config/graphe.json) | **Seule description du tunnel** : étapes (page, domaine, parcours, position dans le dessin) et flèches (normale, OUI, NON). Le calcul et, à l'étape 3, la page s'en servent. Voir [`config/README.md`](../config/README.md). |
| [`scripts/generer_sql.mjs`](../scripts/generer_sql.mjs) | Vérifie la configuration, puis écrit les requêtes de `sql/calcul/`. À relancer après chaque modification de la configuration : `node scripts/generer_sql.mjs`. |
| [`sql/calcul/agregats.sql`](../sql/calcul/agregats.sql) | Calcul complet sur une période (dates en tête du fichier). Ne renvoie que des agrégats. |
| [`sql/calcul/controle_coherence.sql`](../sql/calcul/controle_coherence.sql) | Contrôle « sorties + abandons ≈ arrivées » pour chaque étape. |
| [`sql/calcul/creer_fonction.sql`](../sql/calcul/creer_fonction.sql) | Crée (ou remplace) la fonction `elsee_funnel.agregats(date_debut, date_fin)`, que la page interrogera. Lancé le 7 oct. ; à relancer après chaque modification de la configuration. |

## 2. Le graphe (schéma du 6 oct. et réponses d'Eglantine)

- 42 pages, 52 étapes : `/mon-offre`, `/mon-panier` et `/bienvenue-chez-elsee`
  existent une fois par parcours (offre directe, long form, compléments, carte
  cadeau, mail), comme sur le schéma.
- Chemin **MAIL** (ajouté le 8 oct., croquis d'Eglantine) : `/mon-bilan-elsee`
  (www.elsee.care, lien des e-mails) → `/mon-offre` → `/mon-panier` →
  `/bienvenue-chez-elsee`. La flèche `/mon-bilan-elsee → /mon-offre` passe de
  www à app : non mesurable, en pointillés. Les pages vues sans parcours connu
  y sont rattachées (règle 2.4) ; une flèche venant de la gauche montre, sur
  chacune de ses trois dernières pages, les personnes arrivées directement
  (genre `entrees_directes`).
- Seuls les domaines app.elsee.care et www.elsee.care comptent.
- Entrées : `/signup-corpo`, `/remboursement-complements-alimentaires`,
  `/offres-remboursement-elsee` et `/obtenir-mon-offre` mènent à `/signup` ;
  `/social_signup` mène à `/signup/depenses_complements`.
- Raccourci NON de `depenses_complements` → `sante_mentale_seances`.
- `medecine_douce_step` a deux sorties : vers `en_savoir_plus_sur_vous` (quand
  les coordonnées n'ont pas encore été recueillies : entrée par `/social_signup`
  ou directement par `/signup`) et directement vers `depenses_sports`. Les
  données du 5 oct. le confirment : aucune des 82 personnes arrivées sur
  `/signup` depuis www ne voit `en_savoir_plus_sur_vous`, 19 des 20 arrivées par
  `/social_signup` la voient
  ([requête 15](../sql/decouverte/15_en_savoir_plus_selon_entree.sql)).
- Flèches **non mesurables** : `/obtenir-mon-offre`,
  `/offres-remboursement-elsee` et `/remboursement-complements-alimentaires` →
  `/signup` (GA4 perd la personne entre www et app). Le calcul les laisse vides,
  ainsi que le taux d'abandon de ces trois pages : **aucun chiffre faux**.
- Hors périmètre, comme prévu : sous-étapes 1 à 4 de `/obtenir-mon-offre`,
  pop-ups (dont le recueil des coordonnées entre `bonus-abonnement` et `bilan`,
  sans changement d'adresse), marqueurs LEAD. Le nombre de leads est compté
  depuis le 8 oct. (règle 10), sans rien ajouter au dessin.

## 3. Règles de calcul

Unité : utilisateurs distincts (`user_pseudo_id`) sur la période choisie, plus
une série jour par jour.

1. **Pages retenues** : page vue (`page_view`) dont le domaine et le chemin
   (sans paramètres, en minuscules, sans « / » final) sont dans le graphe. Les
   autres pages sont ignorées.
2. **Étape d'une page à plusieurs parcours** (`/mon-offre`, `/mon-panier`,
   `/bienvenue-chez-elsee`), dans l'ordre (règle validée le 7 oct.) :
   1. d'après la page du graphe vue juste avant dans la session (par exemple
      `/mon-panier` après `/offres` = parcours compléments) ;
   2. sinon (retour en arrière), le même parcours que la dernière fois que cette
      page a été vue dans la session ;
   3. sinon (personne qui revient par un lien, un e-mail, le paiement), d'après
      la dernière étape qu'elle a vue, dans cette session ou une précédente,
      sur 60 jours au plus : l'étape de la page la plus proche en suivant les
      flèches (après `/offres`, `/mon-panier` du parcours compléments ; après
      `/signup`, l'offre directe), à défaut celle du même parcours ;
   4. sinon (aucun parcours connu), la page va dans l'étape de repli de sa
      page, celle du chemin MAIL (décision du 8 oct., qui remplace celle du
      6 oct. : ces pages étaient comptées à part, sans être affichées). Ce
      rattachement se fait après toutes les autres règles : il ne change le
      parcours d'aucune autre page. Une page sans étape de repli resterait
      comptée à part (genre `non_rattache`) ; il n'y en a plus.
3. **Rechargements** : la même étape vue plusieurs fois de suite compte une
   fois.
4. **Carte cadeau** : une personne qui va de `/mon-offre` à
   `/pricing/cartecadeau`, revient sur `/mon-offre`, puis va sur `/mon-panier`,
   compte comme passée directement de `/mon-offre` à `/mon-panier`, sans avoir
   vu `/pricing/cartecadeau`. Si elle revient sur `/mon-offre` puis s'arrête, la
   visite de `/pricing/cartecadeau` est gardée.
5. **Arrivées sur une étape** : utilisateurs ayant vu l'étape sur la période,
   tous chemins confondus.
6. **Passage A → B** : dans une même session, B est l'étape du graphe vue juste
   après A, et une flèche A → B existe. Un utilisateur compte une fois par
   flèche sur la période. Le passage est daté du jour où la personne était sur
   A.
7. **Taux d'abandon de A** : 1 − (utilisateurs ayant au moins une sortie vers
   l'avant depuis A) / (arrivées sur A). Un raccourci NON est une sortie ; un
   retour en arrière n'en est pas une.
8. **Sauts hors schéma** : une personne qui va de A à une étape plus loin sans
   passer par une flèche du schéma (par exemple `depenses_sports →
   out_of_network_sport`, 7 personnes le 5 oct.) n'a pas abandonné. Ces sauts ne
   sont pas dessinés (seuls les raccourcis du schéma existent) mais comptent
   comme sorties pour le taux d'abandon. Ils viennent probablement d'une page
   vue non enregistrée. Ils sont listés par le calcul (genre `saut`) pour être
   surveillés.
9. **Pages vues par personne** (tableau à côté du schéma, ajouté le 8 oct.) :
   pour chaque personne, nombre de pages différentes du graphe vues sur la
   période, pages d'entrée comprises. Une page vue plusieurs fois (retour en
   arrière, rechargement, autre jour) compte une fois ; `/mon-offre`,
   `/mon-panier` et `/bienvenue-chez-elsee` comptent chacune pour une page,
   quel que soit le parcours. Seules les personnes ayant vu au moins une page
   de app.elsee.care sont comptées (genre `pages_vues`, nombre de pages dans
   `de`) ; parmi elles, celles qui ont vu `/mon-offre` ou `/offres` (genre
   `pages_vues_offre`). Les personnes vues seulement sur www.elsee.care sont
   comptées à part (genre `hors_formulaire`) : GA4 les perd en passant sur le
   formulaire, et pour la même raison la page d'entrée www manque presque
   toujours aux personnes qui en viennent. Les pages vues sont comptées telles
   quelles, sans les règles 2 à 4 (une visite de `/pricing/cartecadeau` suivie
   d'un retour compte comme une page vue).
10. **Nombre leads** (encadré à côté de la période, ajouté le 8 oct.) :
    personnes qui ont donné leurs coordonnées (e-mail) sur la période. GA4 ne
    voit pas la saisie : un lead est compté au chargement de la page qui la
    suit, à l'un de ces trois moments (bloc `leads` de la configuration) :
    1. **avant `depenses_complements`** : arrivée sur
       `/signup/depenses_complements` dans une session entrée **avec
       coordonnées** ;
    2. **pop-up avant `bilan`** (obligatoire) : arrivée sur `/signup/bilan`
       juste après `/signup/bonus-abonnement`, dans une session entrée **sans
       coordonnées** ;
    3. **`en_savoir_plus_sur_vous`** : arrivée sur `/signup/depenses_sports`
       juste après `/signup/en_savoir_plus_sur_vous`, quelle que soit l'entrée
       (la page n'est montrée qu'aux personnes sans coordonnées).

    L'entrée de la session est la dernière page d'entrée vue dans la session :
    avec coordonnées pour `/signup-corpo`, `/obtenir-mon-offre`,
    `/offres-remboursement-elsee`, `/remboursement-complements-alimentaires` et
    `/signup` ouverte depuis www.elsee.care (GA4 ne garde que le domaine de la
    page d'où l'on vient) ; sans coordonnées pour `/social_signup` et `/signup`
    ouverte d'ailleurs (lien direct, publicité, e-mail). Une page ouverte depuis
    app.elsee.care (navigation dans le formulaire, retour en arrière) ne change
    pas l'entrée : `/signup-corpo → /signup` reste une entrée avec coordonnées.
    Une session sans page d'entrée (personne revenue au milieu du formulaire)
    ne compte pas aux moments 1 et 2 : on ne sait pas si elle avait déjà donné
    ses coordonnées. L'offre directe (`/signup → /mon-offre`) ne compte pas :
    ce sont des personnes déjà connues.

    **Une personne n'est lead qu'une fois** (Eglantine, 8 oct.) : à son
    premier moment, cherché sur tout l'historique lu (60 jours avant la
    période, et pas avant le 5 oct., début de l'export). Elle compte sur la
    période si ce premier moment y tombe ; si elle redonne ses coordonnées
    plus tard, elle n'est pas recomptée. Genre `leads` : total (`de` vide),
    répartition par moment de ce premier lead (`de` = moment), jour par jour
    (`de` vide, `jour` rempli). Les trois parts font le total, et les jours
    s'additionnent.

## 4. Résultats sur la journée du 5 octobre

Contrôle de cohérence ([`controle_coherence.sql`](../sql/calcul/controle_coherence.sql)) :
**aucun écart négatif**. Pour chaque étape, sorties + abandons dépassent les
arrivées de 0 à 6 personnes, celles qui ont pris deux sorties (par exemple OUI,
retour, puis NON). Les entrées dépassent les arrivées de 0 à 30 personnes,
celles qui sont arrivées par plusieurs chemins (allers-retours).

Les passages calculés correspondent à ceux de l'étape 1, par exemple :
`depenses_complements` → OUI 179, NON 21 ; `medecine_douce_step` →
`depenses_sports` 84, → `en_savoir_plus_sur_vous` 22 ;
`signup` → `depenses_complements` 157, → `/mon-offre` 11.

Taux d'abandon notables (une seule journée : à confirmer) :
`network_complements` 23 % (42 sur 180), `en_savoir_plus_sur_vous` 36 % (8 sur
22), `bonus-abonnement` 17 %, `/offres` 86 % (32 sur 37), `/mon-offre` du long
form 54 % (53 sur 98), `/pricing/cartecadeau` 83 % (10 sur 12).

Pages non rattachées à un parcours le 5 oct. : 33 personnes sur `/mon-offre`,
21 sur `/mon-panier` et les 5 personnes arrivées sur `/bienvenue-chez-elsee`.
Leurs visites précédentes datent d'avant le début de l'export (5 oct.) : la
règle 2.3 en rattachera de plus en plus au fil des jours. Tant que ce n'est pas
le cas, les inscriptions et les abandons sur `/mon-panier` (100 % ce jour-là)
sont à lire avec prudence.

## 5. Mise en place dans BigQuery (7 octobre)

Validé par Eglantine, qui a donné au compte de service le droit de créer des
datasets.

- Dataset **`elsee_funnel`** créé en région **EU**, comme l'export. Le bac à sable
  y applique une expiration de 60 jours aux tables et aux vues ; nous n'en créons
  pas.
- Fonction de table **`elsee_funnel.agregats(date_debut, date_fin)`** créée avec
  [`creer_fonction.sql`](../sql/calcul/creer_fonction.sql). Elle n'a pas de date
  d'expiration. Elle renvoie exactement les mêmes 546 lignes que
  [`agregats.sql`](../sql/calcul/agregats.sql) sur le 5 oct. Exemple :

  ```sql
  SELECT * FROM `ga4-chemin-form.elsee_funnel.agregats`(DATE '2026-10-05', DATE '2026-10-11')
  ```

- Le texte d'une fonction BigQuery est limité à 32 Ko : le générateur décrit
  donc le graphe de façon compacte et refuse de produire une fonction trop
  longue (23 Ko depuis l'ajout des leads et du chemin MAIL le 8 oct., pour 52
  étapes).
- Coût : la fonction lit les 60 jours qui précèdent la période (règle 2.3),
  soit environ 6 Mo par jour de données, au plus 370 Mo par appel. Le quota
  gratuit du bac à sable (1 To par mois) permet plus de 2 500 appels par mois ;
  la page gardera les résultats en cache.
