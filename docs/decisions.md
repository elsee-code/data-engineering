# Journal des décisions

Le plus récent en haut. Chaque entrée dit ce qui a été décidé, par qui, et
pourquoi. Ce journal prime sur [`brief.md`](brief.md).

## Où en est le projet

| Étape | État |
|---|---|
| 0. Informations et accès manquants | Faite le 5 oct. ; réponses reçues le 6 oct. (voir ci-dessous) |
| 1. Découverte | Requêtes écrites dans [`sql/decouverte/`](../sql/decouverte/), **pas encore exécutées** : accès BigQuery à brancher |
| 2. Calcul (config du graphe + vues) | À faire après validation de l'étape 1 |
| 3. Affichage Apps Script | À faire |
| 4. Automatisation et alertes | À faire |
| 5. Documentation | À faire |

## Questions encore ouvertes

Non bloquantes pour l'étape 1.

- **Réglages GA4** (utiles pour expliquer les écarts à la recette) : mode de
  consentement (Consent Mode v2 basique ou avancé, outil de consentement),
  identité pour les rapports (combinée, observée ou basée sur l'appareil).
- **Définition des étapes des trois explorations** : entonnoir ouvert ou fermé,
  « suivie directement de » ou « suivie de », type de condition sur le chemin.
  L'export PDF ne le montre pas.
- **Domaines de test** qui enverraient des données dans la propriété (staging,
  webflow.io, localhost…).
- Pour les étapes 3 et 4 : compte propriétaire du script Apps Script, qui doit
  voir la page (tout le monde en @elsee.care ?), destinataires des alertes, qui
  lance `clasp push`.

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
- Référence pour la recette : export des trois explorations du 7 sept. au
  4 oct. 2026, rangé dans
  [`reference/explorations-ga4_2026-09-07_2026-10-04.pdf`](reference/explorations-ga4_2026-09-07_2026-10-04.pdf).
- Accès BigQuery : Eglantine a ajouté une clé JSON de compte de service dans
  l'environnement cloud. Elle n'était pas visible dans la session du 6 oct. (les
  variables d'environnement ne sont lues qu'à l'ouverture d'une session) : à
  vérifier dans la session suivante.

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

### Ce que montrent les explorations GA4 (7 sept. – 4 oct.)

- Le chemin réel de l'entrée « social » est **/social-signup** (tiret) dans les
  explorations ; le schéma écrit /social_signup. À confirmer dans les données.
- La page de confirmation s'appelle bien **/bienvenue-chez-elsee**.
- Les deux nouvelles entrées (/remboursement-complements-alimentaires,
  /offres-remboursement-elsee) n'apparaissent pas dans les explorations.
- Les annotations d'Eglantine confirment la logique du brief : dans un entonnoir
  linéaire, les départs vers une autre branche comptent comme des abandons.
  Entrée : 645 abandons dont 326 partent vers l'offre directe, soit 6,7 %
  d'abandon réel. /signup/depenses_complements : 1 705 abandons dont 812
  partent vers la branche compléments, soit 21,9 % d'abandon réel.
- **Très peu de confirmations** : 7 à 12 utilisateurs sur /bienvenue-chez-elsee
  selon l'entonnoir, contre 114 à environ 500 sur /mon-panier. Soit c'est la
  réalité, soit le passage par une page de paiement externe coupe la session
  (domaine de paiement non exclu des sites référents). Notre définition des
  passages exige la même session : il faut le vérifier à l'étape 1 (requête
  `08_ruptures_de_session.sql`).

## 2026-10-05 — Étape 0

Liste des informations et accès manquants envoyée. Constat : aucun accès Google
Cloud dans la session, dépôt vide, le premier PDF ne contenait que le schéma.
