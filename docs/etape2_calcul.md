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

- 41 pages, 48 étapes : `/mon-offre`, `/mon-panier` et `/bienvenue-chez-elsee`
  existent une fois par parcours (offre directe, long form, compléments, carte
  cadeau), comme sur le schéma.
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
  sans changement d'adresse), marqueurs LEAD.

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
   4. sinon, la page n'est rattachée à aucun parcours et n'est pas affichée
      (décision du 6 oct. sur les arrivées sans page précédente). Le calcul la
      compte à part (genre `non_rattache`) pour contrôle.
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
  longue (19 Ko aujourd'hui, pour 48 étapes).
- Coût : la fonction lit les 60 jours qui précèdent la période (règle 2.3),
  soit environ 6 Mo par jour de données, au plus 370 Mo par appel. Le quota
  gratuit du bac à sable (1 To par mois) permet plus de 2 500 appels par mois ;
  la page gardera les résultats en cache.
