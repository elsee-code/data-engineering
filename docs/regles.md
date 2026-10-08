# Règles de calcul et d'affichage

Toutes les règles en vigueur, validées par Eglantine (état au 8 octobre 2026).
Le calcul les applique dans BigQuery (requêtes générées par
[`scripts/generer_sql.mjs`](../scripts/generer_sql.mjs)), la page dans
[`apps-script/Page.html`](../apps-script/Page.html), à partir de la seule
description du tunnel : [`config/graphe.json`](../config/graphe.json). Les
dates et raisons des décisions sont dans [`decisions.md`](decisions.md).

## 1. Les données

- **Source** : l'export quotidien de GA4 vers BigQuery (dataset
  `analytics_383563328`, région EU), qui existe depuis le **5 octobre 2026**.
  Chaque journée arrive dans le courant du lendemain, parfois l'après-midi.
  Le projet est en bac à sable : les tables expirent au bout de 60 jours, donc
  l'historique est glissant sur 60 jours.
- **Pages vues** (`page_view`) : une étape = une page, sauf les pages 2 à 4
  de `/obtenir-mon-offre`, suivies par l'événement `step_form` (section 4). Une page =
  domaine + chemin, sans paramètres, en minuscules, sans « / » final. Seuls
  app.elsee.care et www.elsee.care comptent ; les pages hors schéma sont
  ignorées (espace membre, `/homefirstvisit`, www.elsee.care/carte-cadeau…).
- **Unité** : la personne, c'est-à-dire l'identifiant GA4 (`user_pseudo_id` :
  un navigateur sur un appareil). Chaque chiffre est un nombre de personnes
  distinctes sur la période, plus une série jour par jour pour les courbes.
  Une **visite** est une session GA4. Fuseau horaire : Europe/Paris.
- **Confidentialité** : aucun identifiant ne sort de BigQuery ; la page ne
  reçoit que des totaux.

## 2. Le schéma

61 étapes et 67 flèches, décrites dans `config/graphe.json`.

| Chemin | Étapes |
|---|---|
| Short form (bleu) | `/obtenir-mon-offre` (SITE, www.elsee.care) : un formulaire de 4 pages à la même adresse, page 1 → page 2 → page 3 → page 4 → `/signup` |
| Entrées | `/offres-remboursement-elsee`, `/remboursement-complements-alimentaires` (www.elsee.care) et `/signup-corpo` (CORPO) mènent à `/signup` ; `/social_signup` (SOCIAL) mène à `depenses_complements` |
| Offre directe (jaune) | `/signup` → `/mon-offre` → `/mon-panier` → paiement ok |
| Long form | `/signup` → `depenses_complements` → … → `final_step` → `offre_en_preparation` → `/mon-offre` → `/mon-panier` → paiement ok |
| Compléments alimentaires (vert) | `recap_marques` → `recap_remboursements` → `bonus-abonnement` → `bilan` → `/offres` → `/mon-panier` → paiement ok |
| MAIL | `/mon-bilan-elsee` (www.elsee.care, lien des e-mails) → `/mon-offre` → `/mon-panier` → paiement ok |
| Carte cadeau | après chaque `/mon-offre` (offre directe, long form, MAIL), sa propre branche `/pricing/cartecadeau` → `/mon-panier` → paiement ok |

- **Pages à question** : une flèche OUI et un raccourci NON, qui saute des
  pages (par exemple `depenses_complements` NON → `sante_mentale_seances`).
  Prendre un raccourci NON est une poursuite, jamais un abandon.
- `medecine_douce_step` mène à `en_savoir_plus_sur_vous` (coordonnées pas
  encore données) ou directement à `depenses_sports`.
- **Flèches non mesurables** : page 4 de `/obtenir-mon-offre`,
  `/offres-remboursement-elsee`, `/remboursement-complements-alimentaires` →
  `/signup` et `/mon-bilan-elsee` → `/mon-offre` passent de www.elsee.care à
  app.elsee.care, où GA4 perd la personne. Elles sont dessinées en pointillés,
  sans chiffre, et leur page de départ n'a pas de taux d'abandon : **aucun
  chiffre faux**.
- **Seules les flèches du schéma sont dessinées.** Les autres passages
  observés sont listés sous le schéma (section 5).

## 3. Rattacher une page à son chemin

`/mon-offre`, `/pricing/cartecadeau`, `/mon-panier` et « paiement ok »
existent dans plusieurs chemins. Chaque visite d'une de ces pages va, dans
l'ordre :

1. dans l'étape où mène la flèche venant de la page du schéma vue juste avant
   dans la visite (`/mon-panier` après `/offres` = compléments) ;
2. sinon (retour en arrière), dans la même étape que la dernière fois que la
   page a été vue dans la visite ;
3. sinon, d'après la dernière étape vue dans la visite : l'étape de cette page
   la plus proche en suivant les flèches, à défaut celle du même chemin ;
4. sinon, dans le **chemin MAIL**. C'est le cas d'une personne qui revient
   (lien d'un e-mail, retour plus tard) : elle n'est jamais rattachée à son
   ancien chemin. Les chemins du formulaire ne comptent ainsi que les
   personnes qui y arrivent dans la même visite, après avoir répondu. Les
   pages suivantes de la visite suivent ensuite les flèches (après
   `/pricing/cartecadeau` du chemin MAIL, son propre `/mon-panier`).

**Exception** : « paiement ok » en revenant de Stripe (checkout.stripe.com).
Le paiement ouvre souvent une nouvelle visite, ce n'est pas un retour par
e-mail : le paiement reprend le chemin de la dernière étape vue par la
personne (son `/mon-panier`), sur 60 jours au plus.

## 4. Pages particulières

- **Paiement ok** : `/bienvenue-chez-elsee` (www.elsee.care) et `/success`
  (app.elsee.care) forment une seule case, la fin de chaque chemin ;
  `/bienvenue-chez-elsee` puis `/success` compte une fois. Elles ne comptent
  que juste après `/mon-panier` (ou après `/bienvenue-chez-elsee` pour
  `/success`), ou en revenant de Stripe. Vues ailleurs (espace membre, mot de
  passe oublié, début de visite sans provenance), elles sont ignorées. C'est la
  règle la plus proche des ventes réelles : 7, 3 et 4 « paiement ok » les 5, 6
  et 7 octobre, pour 6, 4 et 3 ventes.
- **Les 4 pages de `/obtenir-mon-offre`** (même adresse) : la balise GTM
  envoie l'événement `step_form` à chaque nouvelle page affichée, avec
  `form_derniere_page` = `/obtenir-mon-offre-1` à `-4`. Un retour en arrière
  ne renvoie rien.
  - **Page atteinte** : pour chaque personne et chaque jour, la page la plus
    loin atteinte.
  - **Page 1** : arrivées d'après les pages vues de `/obtenir-mon-offre`, comme
    toute page.
  - **Pages 2 à 4** : arrivées d'après l'événement.
  - **Passages** : le passage page 1 → page 2 n'est compté que si GA4 a vu la
    page 1. Sinon (cookies acceptés en cours de formulaire, par exemple), c'est
    une arrivée directe sur la page 2.
  - **Page 4 → `/signup`** : flèche non mesurable, donc pas de taux d'abandon
    sur la page 4. Une partie des personnes restées sur la page 4 est passée
    sur `/signup` (sous un autre identifiant GA4).
  - **Saut vers `/signup`** : une personne que GA4 suit jusqu'à `/signup` sans
    voir les pages 2 à 4 a continué. Ce « saut » compte comme une sortie de la
    page 1.
  - Les événements envoyés depuis une autre page sont ignorés.
- **Rechargements** : une page vue plusieurs fois de suite compte une fois.
- **Détour par la carte cadeau** : `/mon-offre` → `/pricing/cartecadeau` →
  `/mon-offre` → `/mon-panier` compte comme `/mon-offre` → `/mon-panier`, sans
  la carte cadeau. Si la personne revient sur `/mon-offre` puis s'arrête, sa
  visite de la carte cadeau est gardée.

## 5. Les chiffres du schéma

- **Arrivées** (en gras dans l'étape) : personnes ayant vu l'étape sur la
  période, tous chemins confondus.
- **Passages A → B** (en gris sur la flèche) : B est l'étape du schéma vue juste
  après A dans la même visite, et la flèche A → B existe. Une personne compte
  une fois par flèche ; le passage est daté du jour où elle était sur A.
- **Répartition en %** sur les flèches d'une étape qui a plusieurs sorties :
  arrondie pour faire exactement 100 % (méthode des plus forts restes).
- **Taux d'abandon de A** (en rouge, toujours dans l'étape) : 1 − (personnes
  ayant au moins une sortie vers l'avant depuis A) / (arrivées sur A). Un
  raccourci NON est une sortie. Un **saut** (étape plus loin sans flèche, page
  non enregistrée par GA4) en est une aussi : il n'est pas dessiné mais il est
  listé. Un retour en arrière n'est pas une sortie, ni les autres passages
  hors schéma (par exemple reprendre le questionnaire depuis `/mon-offre`).
- **Flèches d'entrée** (chemin MAIL, par la gauche ou par la droite) :
  personnes dont la visite commence sur la page.
- **Bulles d'aide** : détail de l'étape ou de la flèche, et courbe des arrivées
  par jour.
- **« Détails et contrôles »**, sous le schéma : passages hors schéma (sauts,
  retours, autres).
- **Contrôle de cohérence**
  ([`controle_coherence.sql`](../sql/calcul/controle_coherence.sql)) : pour
  chaque étape, sorties + abandons et entrées dépassent les arrivées de
  quelques personnes (celles qui prennent deux sorties ou arrivent par deux
  chemins). Un écart négatif signale une erreur de calcul.

## 6. Tableau « Pages vues par personne »

À droite du schéma, il montre au bout de combien de pages les gens se lassent
du formulaire.

- **Personnes comptées** : celles qui ont commencé le formulaire au début sur
  la période, c'est-à-dire vu `/signup`, `/social_signup` ou `/signup-corpo`.
- **Comptées à part**, sous le tableau :
  - les personnes arrivées en cours de route (retour direct sur leur offre,
    reprise au milieu du questionnaire) ;
  - les personnes vues seulement sur www.elsee.care (GA4 les perd en passant
    sur le formulaire ; pour la même raison, leur page d'entrée www manque
    presque toujours).
- **Pages** : nombre de pages différentes du schéma vues sur la période, pages
  d'entrée comprises. Une page vue plusieurs fois compte une fois, quel que
  soit le chemin. « Paiement ok » compte pour une page (section 4), mais le
  détour par la carte cadeau n'est pas effacé : une visite de
  `/pricing/cartecadeau` compte toujours.
- **Colonnes** : personnes et part, dont ont vu leur offre (`/mon-offre` ou
  `/offres` ; barre grise, sinon rouge), part ayant vu au moins ce nombre de
  pages.

## 7. Nombre leads

Encadré à côté de la période : personnes qui ont donné leurs coordonnées
(e-mail). GA4 ne voit pas la saisie : un lead est compté au chargement de la
page qui la suit, à l'un de trois moments.

| Moment | Compté à l'arrivée sur | Condition |
|---|---|---|
| Avant `depenses_complements` | `depenses_complements` | visite entrée avec coordonnées |
| Pop-up avant `bilan` (obligatoire) | `bilan`, juste après `bonus-abonnement` | visite entrée sans coordonnées |
| `en_savoir_plus_sur_vous` | `depenses_sports`, juste après `en_savoir_plus_sur_vous` | aucune (la page n'est montrée qu'aux personnes sans coordonnées) |

- **Entrée de la visite** : c'est la dernière page d'entrée vue.
  - **Avec coordonnées** : `/signup-corpo`, les entrées de www.elsee.care, et
    `/signup` ouverte depuis www.elsee.care.
  - **Sans coordonnées** : `/social_signup`, et `/signup` ouverte d'ailleurs
    (lien direct, publicité, e-mail).
  - Une page ouverte depuis app.elsee.care (navigation dans le formulaire) ne
    change pas l'entrée. Une visite sans page d'entrée (retour au milieu du
    formulaire) ne compte pas aux deux premiers moments.
- **Pas comptée** : l'offre directe (`/signup` → `/mon-offre`), qui concerne des
  personnes déjà connues.
- **Un lead au plus par personne** : la personne est comptée à son premier
  moment, sur tout l'historique lu (60 jours avant la période). Elle compte sur
  la période si ce premier moment y tombe. Les leads par jour s'additionnent ;
  la bulle d'aide les répartit entre les trois moments.

## 8. Clients

Encadré à côté du nombre de leads : personnes arrivées sur « paiement ok »
(section 4) sur la période, tous chemins confondus. C'est la somme des cases
« paiement ok » du schéma ; la bulle d'aide les répartit par chemin et donne
la courbe par jour. Une même personne ne compterait deux fois que si elle
payait dans deux chemins, ce qui n'arrive pas dans les données (vérifié sur
les 5 – 7 octobre). À comparer aux ventes réelles (section 11).

## 9. La page

- **Accès** : comptes @elsee.care seulement. La page interroge BigQuery avec le
  compte hello@elsee.care, propriétaire du script.
- **Périodes** : hier, 7 jours, 28 jours, mois en cours, mois précédent,
  période libre. Elles sont ramenées aux jours disponibles, et la période
  réellement couverte est affichée.
  - Si la journée d'hier n'est pas encore arrivée, « Hier » montre la dernière
    journée disponible, avec un message.
  - Une période sans données masque le schéma.
- **Cache** : les résultats sont gardés 6 heures. Le cache est vidé à
  l'arrivée d'une nouvelle journée ou au changement de configuration. Un
  calcul prend environ 40 secondes.
- **Export PNG** : le schéma et le tableau, avec la période, le nombre de
  leads et de clients.
- **Fonction BigQuery plus ancienne que la page** : le tableau et les leads
  affichent « indisponible », pas des zéros.

## 10. Alertes

Un e-mail est envoyé à hello@elsee.care, **seulement en cas de gros
problème** :
- aucune nouvelle journée GA4 depuis plus de 2 jours ;
- la fonction de calcul échoue ;
- personne sur les étapes du tunnel alors que GA4 a des données (adresses du
  formulaire changées).

La vérification tourne chaque jour entre 15 h et 16 h (déclencheur Apps Script
`verifierChaqueJour`). Un même problème n'est rappelé que tous les 3 jours. Un
seul jour de retard de GA4 ne déclenche rien.

## 11. Limites connues

- **www.elsee.care → app.elsee.care** : GA4 perd presque toujours la personne
  (le 5 octobre, 7 sessions sur 281 gardaient leur identifiant). D'où les
  flèches non mesurables, et une même personne peut compter deux fois, une
  fois sur chaque site. Le corriger relève des balises GA4 de l'application,
  hors de notre périmètre.
- **Consentement** : les personnes qui refusent les cookies ne sont pas vues.
  Les chiffres sont plus bas que la réalité (leads, ventes).
- **Personne = navigateur** : la même personne sur deux appareils compte deux
  fois. Un acheteur vu sous deux identifiants explique un « paiement ok » de
  trop certains jours.
- **Ventes dans les rapports GA4** : l'événement GA4 `order_paid` n'est envoyé
  que sur `/bienvenue-chez-elsee`, jamais sur `/success`. Les rapports de ventes
  de GA4 en manquent, ce qui est à signaler à la personne qui gère GTM. Le
  schéma n'utilise pas cet événement.
- **Historique** : 60 jours au plus, et rien avant le 5 octobre 2026.
- **Taille du calcul** : BigQuery limite le texte de la fonction à 32 Ko et
  elle en fait 29,5. Quelques étapes de plus passent ; un gros ajout demandera
  de réorganiser le calcul.
