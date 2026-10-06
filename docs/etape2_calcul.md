# Étape 2 — Calcul : configuration du graphe et requêtes

> **En cours.** La configuration et le calcul sont écrits et testés en lecture
> seule sur la journée du 5 octobre 2026. Rien n'a encore été créé dans
> BigQuery : la création de `elsee_funnel` et de la fonction de calcul attend la
> validation d'Eglantine (section 5).

## 1. Les fichiers

| Fichier | Rôle |
|---|---|
| [`config/graphe.json`](../config/graphe.json) | **Seule description du tunnel** : étapes (page, domaine, parcours, position dans le dessin) et flèches (normale, OUI, NON). Le calcul et, à l'étape 3, la page s'en servent. Voir [`config/README.md`](../config/README.md). |
| [`scripts/generer_sql.mjs`](../scripts/generer_sql.mjs) | Vérifie la configuration, puis écrit les requêtes de `sql/calcul/`. À relancer après chaque modification de la configuration : `node scripts/generer_sql.mjs`. |
| [`sql/calcul/agregats.sql`](../sql/calcul/agregats.sql) | Calcul complet sur une période (dates en tête du fichier). Ne renvoie que des agrégats. |
| [`sql/calcul/controle_coherence.sql`](../sql/calcul/controle_coherence.sql) | Contrôle « sorties + abandons ≈ arrivées » pour chaque étape. |
| [`sql/calcul/creer_fonction.sql`](../sql/calcul/creer_fonction.sql) | Crée la fonction `elsee_funnel.agregats(date_debut, date_fin)`, que la page interrogera. **Pas encore lancé.** |

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
   `/bienvenue-chez-elsee`) : déduite de la page du graphe vue juste avant dans
   la session (par exemple `/mon-panier` après `/offres` = parcours compléments).
   Si la page précédente ne donne pas le parcours (retour en arrière), c'est le
   même parcours que la dernière fois que cette page a été vue dans la session.
   Sinon, la page n'est rattachée à aucun parcours (voir 5.2).
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
form 54 % (52 sur 96), `/pricing/cartecadeau` 83 % (10 sur 12).

## 5. Décisions à prendre avant de créer quoi que ce soit

### 5.1 Création dans BigQuery

Proposition : créer le dataset `elsee_funnel` (région **EU**, comme l'export),
puis la fonction de table `elsee_funnel.agregats(date_debut, date_fin)` avec
[`creer_fonction.sql`](../sql/calcul/creer_fonction.sql). La page l'interrogera
pour la période choisie et ne recevra que des agrégats. Une fonction remplace les
vues prévues : elle prend la période en paramètre et ne lit que les tables
utiles (environ 6 Mo par jour de données, soit au plus 350 Mo pour 60 jours,
dans le quota gratuit du bac à sable). À vérifier juste après création : qu'une
fonction de table est autorisée en bac à sable et si elle expire.

Le compte de service ne peut pas créer le dataset aujourd'hui. Deux
possibilités : Eglantine crée `elsee_funnel` (région EU) et donne au compte le
rôle « Éditeur de données BigQuery » dessus, ou elle donne au compte le rôle
« Utilisateur BigQuery » sur le projet pour qu'il le crée.

### 5.2 Sessions qui commencent sur `/mon-offre`, `/mon-panier` ou `/bienvenue-chez-elsee`

Des personnes reviennent plus tard directement sur ces pages (lien dans un
e-mail, retour du paiement). Sans page précédente dans la session, on ne sait
pas à quel parcours les rattacher. Le 5 oct. : 38 personnes sur `/mon-offre`,
24 sur `/mon-panier` et **les 5 personnes arrivées sur `/bienvenue-chez-elsee`**
ne sont rattachées à aucun parcours. Le schéma n'afficherait donc aucune
inscription, et un taux d'abandon de 100 % sur `/mon-panier`.

Proposition : rattacher ces sessions au dernier parcours que la même personne a
suivi dans une session précédente (sur les 60 jours conservés). Les personnes
sans parcours connu ne sont pas affichées (décision du 6 oct. sur les arrivées
sans page précédente). Le 5 oct., seules 3 personnes avaient une session
précédente le même jour ([requête 14](../sql/decouverte/14_parcours_sessions_precedentes.sql)) :
l'export ne commence que le 5 oct., l'effet se mesurera au fil des jours.

Cette règle remplacerait la règle des 24 h proposée pour `/mon-panier →
/bienvenue-chez-elsee` : le 5 oct., les personnes revenues du paiement Stripe
ont toutes gardé leur session.
