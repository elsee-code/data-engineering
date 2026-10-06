# Journal des décisions

Le plus récent en haut. Chaque entrée dit ce qui a été décidé, par qui, et
pourquoi. Ce journal prime sur [`brief.md`](brief.md).

## Où en est le projet

| Étape | État |
|---|---|
| 0. Informations et accès manquants | Faite le 5 oct. ; réponses reçues le 6 oct. (voir ci-dessous) |
| 1. Découverte | Requêtes écrites dans [`sql/decouverte/`](../sql/decouverte/), **pas encore exécutées** : la clé fournie est incomplète (voir l'entrée du 6 oct., 2e session) |
| 2. Calcul (config du graphe + vues) | À faire après validation de l'étape 1 |
| 3. Affichage (Apps Script ou Odoo : à trancher) | À faire |
| 4. Automatisation et alertes | À faire |
| 5. Documentation | À faire |

## Questions encore ouvertes

Non bloquantes pour l'étape 1.

- **Outil d'affichage** : le brief du dépôt prévoit une page web Apps Script ;
  le texte de mission renvoyé le 6 oct. (2e session) parle d'un module Odoo 17
  sur backoffice.elsee.care. Lequel fait foi ? Les étapes 1 et 2 (découverte,
  vues BigQuery) sont les mêmes dans les deux cas.
- **Passages sur plusieurs sessions** (à trancher à l'étape 2, chiffres de la
  requête 08 à l'appui) : les explorations GA4 comptent une étape même si elle
  a lieu dans une autre session, des heures plus tard ; le brief exige la même
  session pour un passage. Voir l'entrée du 6 oct., 2e session.
- **Réglages GA4** (utiles pour expliquer les écarts à la recette) : mode de
  consentement (Consent Mode v2 basique ou avancé, outil de consentement),
  identité pour les rapports (combinée, observée ou basée sur l'appareil).
- **Définition des étapes des quatre explorations** : entonnoir ouvert ou
  fermé, « suivie directement de » ou « suivie de », type de condition sur le
  chemin, pages regroupées dans l'étape « Entrée » du long form. L'export PDF ne
  le montre pas.
- **Recette** : le fichier de référence couvre le 8 sept. – 5 oct., avant
  l'export BigQuery. Il faudra le même export des quatre explorations sur une
  période d'au moins 7 jours couverte par l'export.
- **Domaines de test** qui enverraient des données dans la propriété (staging,
  webflow.io, localhost…).
- Pour les étapes 3 et 4 : compte propriétaire du script Apps Script, qui doit
  voir la page (tout le monde en @elsee.care ?), destinataires des alertes, qui
  lance `clasp push`.

## 2026-10-06 (2e session) — Nouveau fichier de référence, clé d'accès

### Fichier de référence remplacé (Eglantine)

L'export « Rapport form (1) » (7 sept. – 4 oct.) était faux : il écrivait
/social-signup au lieu de /social_signup, et des informations manquaient. Il
est supprimé du dépôt et remplacé par « data (4) » :
[`reference/explorations-ga4_2026-09-08_2026-10-05.pdf`](reference/explorations-ga4_2026-09-08_2026-10-05.pdf).

- Le chemin de l'entrée « social » est **/social_signup** (à vérifier quand
  même avec la requête 04).
- Période : 8 sept. – 5 oct. 2026. Quatre explorations, en utilisateurs actifs :

| Exploration | Étapes et utilisateurs |
|---|---|
| Long form | Entrée 5 767 → depenses_complements 4 131 → sante_mentale_seances 2 388 → soins_seances 2 352 → medecine_douce_step 2 313 → sport_step 2 099 → final_step 1 947 → /mon-offre 1 918 → /mon-panier 527 → /bienvenue-chez-elsee 7 |
| Compléments | recap_marques 2 965 → recap_remboursements 823 → bonus-abonnement 776 → bilan 669 → /offres 596 → /mon-panier 113 → /bienvenue-chez-elsee 10 |
| Offre directe | /obtenir-mon-offre 659 → /signup 553 → /mon-offre 304 → /mon-panier 99 → /bienvenue-chez-elsee 9 |
| Bloc compléments | depenses_complements 4 131 → montant_complements 3 789 → network_complements 3 729 → recap_marques 2 959 → depenses_complements_step 2 108 → « sante_mentale_step ou montant_sm » 2 003 → md_seances 1 999 |

### Ce que ces chiffres suggèrent (pistes à vérifier à l'étape 1)

- **Chemin de « montant santé mentale »** : l'étape 6 du bloc compléments
  s'appelle « /sante_mentale_step ou /montant_sm ». Le vrai chemin est peut-être
  /signup/montant_sm et non /signup/montant_sante_mentale comme sur le schéma.
- **Raccourci NON de depenses_complements** : 91,7 % des personnes vont sur
  montant_complements. Au plus 342 personnes (8,3 %) prennent le raccourci NON
  ou abandonnent. Ces chiffres ne disent pas où arrive le raccourci
  (depenses_complements_step ou sante_mentale_seances) : la requête 06
  tranchera.
- **Branche verte** : sur recap_marques, 823 personnes partent vers
  recap_remboursements et 2 108 continuent vers depenses_complements_step ;
  l'abandon réel y est d'environ 1 %. La vraie perte du bloc est entre
  network_complements et recap_marques (770 personnes, 20,6 %).
- **Très peu de confirmations** : 7 à 10 personnes sur /bienvenue-chez-elsee
  contre 99 à 527 sur /mon-panier, et des temps écoulés moyens de 5 h 52 entre
  /offres et /mon-panier, 1 h 17 entre /mon-panier et /bienvenue-chez-elsee.
  Les explorations GA4 comptent donc des étapes faites dans une autre session,
  parfois des heures plus tard. Notre définition des passages exige la même
  session : elle comptera moins de passages vers /mon-panier et
  /bienvenue-chez-elsee. La requête 08 mesurera l'ampleur ; la règle est à
  trancher à l'étape 2.

### Clé du compte de service : incomplète

La variable `GCP_SA_KEY_JSON` est bien présente, mais elle ne contient que la
**clé privée** (valide, RSA 2048 bits), pas le fichier JSON complet : il manque
notamment l'adresse du compte (`client_email`). Impossible de s'authentifier,
l'étape 1 n'a donc pas pu être exécutée.

À faire par Eglantine : remplacer la valeur de `GCP_SA_KEY_JSON` par le fichier
JSON entier, **encodé en base64 sur une seule ligne** (sur Mac :
`base64 -i cle.json | pbcopy`, puis coller), puis ouvrir une nouvelle session.
Le JSON brut sur une ligne est aussi accepté.

Ajouté : [`scripts/activer_cle_gcp.sh`](../scripts/activer_cle_gcp.sh), qui
écrit la clé hors du dépôt (`~/.config/elsee/sa.json`, droits 600) sans
l'afficher, vérifie qu'elle est complète et active le compte de service. La
session cloud définit un jeton factice `CLOUDSDK_AUTH_ACCESS_TOKEN` qui fait
échouer `bq` (« Invalid Credentials ») : lancer `bq` avec
`env -u CLOUDSDK_AUTH_ACCESS_TOKEN`.

## 2026-10-06 — Réponses à l'étape 0 (Eglantine)

- **Le projet ga4-chemin-form reste en bac à sable BigQuery (pas de
  facturation).** Conséquences :
  - pas de requête programmée ni de DML (INSERT, MERGE…) ;
  - les tables `elsee_funnel` alimentées chaque jour sont **remplacées par des
    vues** ;
  - en bac à sable, tables et vues expirent 60 jours après leur création :
    l'export GA4 garde donc un historique glissant de 60 jours (suffisant), et il
    faut **un script qui recrée les vues** avant leur expiration.
- **Période éditable sur la page**, avec des valeurs recalculées pour la période
  choisie (pas seulement des préréglages).
- **Pas besoin des arrivées sans page précédente** dans la session : on ne les
  affiche pas.
- **Libellé du seuil compléments retiré** du dessin. La branche verte est
  simplement le chemin pris par les personnes déclarant plus de 350 € de
  dépenses en compléments dans le questionnaire.
- **Chiffres gris du schéma** : illustration de l'affichage attendu, pas une
  référence chiffrée.
- Référence pour la recette : export des explorations GA4. Le premier fichier
  (7 sept. – 4 oct.) était faux ; remplacé dans la 2e session du 6 oct. (voir
  plus haut).
- Accès BigQuery : Eglantine a ajouté une clé JSON de compte de service dans
  l'environnement cloud. Elle n'était pas visible dans la session du 6 oct. (les
  variables d'environnement ne sont lues qu'à l'ouverture d'une session).
  Vérifiée dans la 2e session : incomplète (voir plus haut).

### Architecture révisée (proposition, à valider à l'étape 2)

1. **Vues dans `elsee_funnel`** (même région que l'export), construites à partir
   de la configuration du graphe. Plus de job de nuit : les vues lisent toujours
   l'état courant des tables GA4, données tardives comprises. Le recalcul des 3
   derniers jours devient inutile.
2. **La page calcule à la demande** : quand on choisit une période, Apps Script
   lance une requête paramétrée (date de début, date de fin) sur ces vues.
   BigQuery fait les comptages ; seuls des agrégats reviennent à la page. Les
   résultats sont mis en cache quelques heures pour que la page reste rapide.
3. **Un déclencheur Apps Script quotidien** recrée les vues (elles n'expirent
   donc jamais) et vérifie que la table de la veille est arrivée ; e-mail
   d'alerte sinon.
4. **Préréglages de période** : hier, 7 jours, 28 jours, mois en cours, mois
   précédent, plus une période libre. « 90 jours » est retiré (au-delà des 60
   jours conservés). En fin de mois, « mois précédent » peut être tronqué de
   quelques jours : la page affiche alors la période réellement couverte.

À vérifier dès l'accès BigQuery : qu'un `CREATE OR REPLACE VIEW` est bien
autorisé en bac à sable et qu'il repousse l'expiration de la vue ; si une
fonction de table (`CREATE TABLE FUNCTION`) est autorisée et n'expire pas, elle
peut remplacer la requête paramétrée écrite dans Apps Script.

### Ce que montraient les explorations GA4 (7 sept. – 4 oct.)

Analyse retirée : elle portait sur l'export erroné remplacé dans la 2e session
du 6 oct. (voir plus haut). Le constat « très peu de confirmations » reste
valable avec le nouveau fichier.

## 2026-10-05 — Étape 0

Liste des informations et accès manquants envoyée. Constat : aucun accès Google
Cloud dans la session, dépôt vide, le premier PDF ne contenait que le schéma.
