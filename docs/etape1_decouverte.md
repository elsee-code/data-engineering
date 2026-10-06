# Étape 1 — Découverte : résultats

> **À valider par Eglantine avant l'étape 2.**
> Données : **une seule journée, le 5 octobre 2026**, seule table quotidienne
> disponible le 6 octobre. Les volumes sont donc faibles : les constats sont
> solides, les proportions restent à confirmer sur au moins 7 jours.
> Chaque chiffre vient d'une requête de [`sql/decouverte/`](../sql/decouverte/),
> et les résultats bruts (agrégats seulement) sont dans
> [`sql/decouverte/resultats/20261005/`](../sql/decouverte/resultats/20261005/).
> « Utilisateurs » = `user_pseudo_id` distincts, comme « Utilisateurs actifs »
> dans GA4.

## En bref

1. **Les 41 étapes du schéma existent dans les données**, avec le chemin prévu.
   `/social_signup` et `/signup/montant_sante_mentale` sont les bons chemins
   (`/signup/montant_sm` n'existe pas).
2. **Le formulaire est sur app.elsee.care**, pas sur elsee.care : seules
   `/obtenir-mon-offre`, `/offres-remboursement-elsee`,
   `/remboursement-complements-alimentaires` et `/bienvenue-chez-elsee` sont sur
   www.elsee.care.
3. **Les raccourcis NON arrivent bien là où le schéma le dit**, sauf un : le NON
   de `/signup/depenses_complements` mène à `/signup/sante_mentale_seances`, pas à
   `/signup/depenses_complements_step`.
4. **Problème majeur : GA4 perd la personne entre www.elsee.care et
   app.elsee.care.** Sur 281 sessions ouvertes sur app.elsee.care en venant de
   www.elsee.care, 7 seulement gardent l'identifiant vu sur www. Les flèches qui
   passent de www à app (`/obtenir-mon-offre → /signup`,
   `/offres-remboursement-elsee → /signup`…) ne sont donc presque pas
   mesurables. À l'intérieur d'app.elsee.care, le suivi est continu.
5. **`/signup/en_savoir_plus_sur_vous` n'est vue que par 1 personne sur 5** :
   84 personnes vont directement de `/signup/medecine_douce_step` à
   `/signup/depenses_sports`.

## 1. L'export GA4 (requêtes 01, 02, 03)

- Dataset `analytics_383563328` : région **EU**, expiration par défaut des
  tables 60 jours (bac à sable). Tables présentes : `events_20261005`
  (10 725 événements, créée le 6 oct. à 08:06 UTC, expire le 5 déc. 2026) et
  `pseudonymous_users_20261005`. Pas de table `events_intraday_` (pas d'export
  en continu).
- Fuseau horaire de la propriété : **Europe/Paris** (la journée du 5 oct. va de
  22:00 UTC le 4 à 22:00 UTC le 5).
- Journée du 5 oct. : 745 utilisateurs, 870 sessions, 6 536 pages vues, un seul
  flux de données. Aucun `user_id` envoyé.
- **Aucun événement sans identifiant ni marqué « analytics refusé »** : les
  personnes qui refusent les cookies n'envoient sans doute rien du tout à GA4
  (mode de consentement basique, ou blocage complet). Les chiffres ne couvrent
  alors que les personnes qui acceptent. À confirmer (question ouverte
  « réglages GA4 »).
- **Chaque étape du formulaire envoie un `page_view` avec son propre chemin** :
  on peut définir les étapes par le chemin, comme prévu.
- Événements utiles plus tard :
  - `step_form`, envoyé uniquement sur `/obtenir-mon-offre`, avec les
    paramètres `form_page_entree`, `form_nb_pages`, `form_derniere_page` et
    `form_type` : sans doute les sous-étapes 1 à 4 de `/obtenir-mon-offre`
    (hors périmètre pour l'instant) ;
  - `add_to_cart` sur `/mon-panier` (63 utilisateurs) ;
  - `order_paid` sur `/bienvenue-chez-elsee` (5 utilisateurs).

## 2. Domaines (requête 04)

| Domaine | Ce qu'on y trouve | Pages vues |
|---|---|---:|
| app.elsee.care | Le formulaire (`/signup…`, `/social_signup`, `/signup-corpo`), `/mon-offre`, `/offres`, `/pricing/cartecadeau`, `/mon-panier`, et aussi l'espace membre (`/home`, `/login`, `/remboursements`, `/envoyer-ma-facture`…) | 5 612 |
| www.elsee.care | Le site : `/obtenir-mon-offre`, `/offres-remboursement-elsee`, `/remboursement-complements-alimentaires`, `/bienvenue-chez-elsee` | 911 |
| elsee-v-0.webflow.io | Préproduction Webflow | 10 |
| appelsee-2k24.firebaseapp.com | Adresse technique de l'application | 2 |
| helloelsee.outgrow.us | Quiz Outgrow | 1 |

Proposition : ne retenir que **app.elsee.care et www.elsee.care**. Les trois
autres domaines sont des tests ou des outils tiers.

Chaque chemin n'a qu'une seule écriture (pas de variante en majuscules ou avec
« / » final).

## 3. Correspondance schéma ↔ données (requête 04)

Utilisateurs ayant vu la page le 5 oct., tous chemins confondus. Statut :
**trouvée** pour les 41 étapes.

| Bloc | Étape du schéma | Domaine réel | Utilisateurs |
|---|---|---|---:|
| Offre directe | `/obtenir-mon-offre` | www | 41 |
| Offre directe | `/signup` | app | 186 |
| Fin de parcours | `/mon-offre` | app | 139 |
| Fin de parcours | `/mon-panier` | app | 63 |
| Fin de parcours | `/bienvenue-chez-elsee` | www | 5 |
| Fin de parcours | `/pricing/cartecadeau` | app | 13 |
| Entrées | `/signup-corpo` | app | 3 |
| Entrées | `/social_signup` | app | 52 |
| Entrées | `/remboursement-complements-alimentaires` | www | 1 |
| Entrées | `/offres-remboursement-elsee` | www | 69 |
| Bloc compléments | `/signup/depenses_complements` | app | 204 |
| Bloc compléments | `/signup/montant_complements` | app | 182 |
| Bloc compléments | `/signup/network_complements` | app | 180 |
| Bloc compléments | `/signup/recap_marques` | app | 139 |
| Bloc compléments | `/signup/depenses_complements_step` | app | 91 |
| Branche verte | `/signup/recap_remboursements` | app | 43 |
| Branche verte | `/signup/bonus-abonnement` | app | 42 |
| Branche verte | `/signup/bilan` | app | 35 |
| Branche verte | `/offres` | app | 37 |
| Santé mentale | `/signup/sante_mentale_seances` | app | 112 |
| Santé mentale | `/signup/montant_sante_mentale` | app | 65 |
| Santé mentale | `/signup/sante_mentale_step` | app | 47 |
| Médecine douce et soins | `/signup/md_seances` | app | 107 |
| Médecine douce et soins | `/signup/montant_medecine_douce` | app | 101 |
| Médecine douce et soins | `/signup/soins_seances` | app | 107 |
| Médecine douce et soins | `/signup/montant_soins` | app | 89 |
| Médecine douce et soins | `/signup/network_info` | app | 84 |
| Médecine douce et soins | `/signup/prete_a-changer` | app | 86 |
| Médecine douce et soins | `/signup/medecine_douce_step` | app | 107 |
| Médecine douce et soins | `/signup/en_savoir_plus_sur_vous` | app | 22 |
| Sport, produits, apps | `/signup/depenses_sports` | app | 98 |
| Sport, produits, apps | `/signup/network_sport` | app | 81 |
| Sport, produits, apps | `/signup/out_of_network_sport` | app | 81 |
| Sport, produits, apps | `/signup/sport_step` | app | 95 |
| Sport, produits, apps | `/signup/depenses_produit` | app | 96 |
| Sport, produits, apps | `/signup/network_produit` | app | 73 |
| Sport, produits, apps | `/signup/out_of_network_produit` | app | 75 |
| Sport, produits, apps | `/signup/depenses_app` | app | 96 |
| Sport, produits, apps | `/signup/out_of_network_app` | app | 44 |
| Fin du long form | `/signup/final_step` | app | 91 |
| Fin du long form | `/signup/offre_en_preparation` | app | 96 |

## 4. Raccourcis NON : destination réelle (requête 06)

Passages observés dans la même session, en utilisateurs. Une même personne
peut figurer dans les deux colonnes (si elle revient en arrière et change de
réponse).

| Page à question | OUI : vers… | NON prévu au schéma | NON réel | Verdict |
|---|---|---|---|---|
| `depenses_complements` | `montant_complements` : 179 | `depenses_complements_step` (ou `sante_mentale_seances` sur le dernier schéma) | **`sante_mentale_seances` : 21** ; `depenses_complements_step` : 0 | NON → `sante_mentale_seances` |
| `sante_mentale_seances` | `montant_sante_mentale` : 62 | `sante_mentale_step` → `md_seances` | `sante_mentale_step` : 46, puis `md_seances` : 44 | Conforme |
| `md_seances` | `montant_medecine_douce` : 101 | `soins_seances` | `soins_seances` : 6 | Conforme |
| `soins_seances` | `montant_soins` : 89 | `medecine_douce_step` | `medecine_douce_step` : 21 | Conforme |
| `depenses_sports` | `network_sport` : 76 | `sport_step` | `sport_step` : 15 | Conforme (et 7 vers `out_of_network_sport`, voir 5) |
| `depenses_produit` | `network_produit` : 72 | `depenses_app` | `depenses_app` : 22 | Conforme (et 5 vers `out_of_network_produit`, voir 5) |
| `depenses_app` | `out_of_network_app` : 44 | `final_step` | `final_step` : 47 | Conforme (et 6 vers `offre_en_preparation`, voir 5) |

Conséquence pour le bloc compléments : `/signup/depenses_complements_step`
n'est atteinte que depuis `/signup/recap_marques` (90 personnes). Ce n'est donc
pas une page de convergence pour le raccourci NON.

## 5. Ce qui n'est pas dans le schéma

### Sauts vers l'avant absents du schéma (5 personnes ou plus)

| Passage observé | Utilisateurs | Remarque |
|---|---:|---|
| `medecine_douce_step` → `depenses_sports` | 84 | Saute `en_savoir_plus_sur_vous` (22 personnes y passent). Le partage se voit tout au long de la journée (requête 12) : ce n'est pas une mise en ligne en cours de journée. Étape conditionnelle ou test A/B ? |
| `sante_mentale_seances` → `md_seances` | 5 | Saute `montant_sante_mentale` et `sante_mentale_step` |
| `depenses_sports` → `out_of_network_sport` | 7 | Saute `network_sport` |
| `depenses_produit` → `out_of_network_produit` | 5 | Saute `network_produit` |
| `depenses_app` → `offre_en_preparation` | 6 | Saute `final_step` |
| `/offres-remboursement-elsee` → `/signup` | 9 | Le schéma la fait arriver directement sur `depenses_complements` : elle passe en fait par `/signup`, comme `/obtenir-mon-offre`. Idem pour `/signup-corpo` (2 vers `/signup`, 2 vers `depenses_complements`) |
| `/pricing/cartecadeau` → `/mon-offre` | 8 | Le schéma prévoit `/pricing/cartecadeau` → `/mon-panier` (2 personnes seulement) |

### Retours en arrière fréquents

Normaux (bouton « précédent ») et, par définition, **pas une poursuite** :
`network_complements → montant_complements` (31), `network_sport →
depenses_sports` (24), `network_produit → depenses_produit` (17), `/mon-panier →
/mon-offre` (17), `montant_complements → depenses_complements` (14),
`recap_marques → network_complements` (10), `/mon-offre →
offre_en_preparation` (7), `/mon-offre → /signup` (6)…

### Pages réelles hors schéma

| Page | Utilisateurs | Ce que c'est (à confirmer) |
|---|---:|---|
| app `/remboursements` | 107 | Espace membre. Le motif des requêtes de découverte l'a prise à tort pour une page du tunnel (préfixe « remboursement ») : 105 personnes sur 107 ne vont ensuite vers aucune page du tunnel. À exclure. |
| app `/success` | 9 | Vue après `/mon-panier` (4) et après `/bienvenue-chez-elsee` (2). Page de confirmation de l'application ? |
| app `/signin_freemium` | 17 | Parcours « freemium » ? |
| app `/jaiunecartecadeau`, `/signin-carte-cadeau` | 1 et 1 | Utilisation d'une carte cadeau ? |
| www `/remboursement-endometriose` | 4 | Page d'atterrissage proche des entrées, mais personne n'en part vers le formulaire ce jour-là |
| app `/signup/preparation-offre`, `/signup_social` | 1 et 1 | Anciennes variantes de `offre_en_preparation` et `social_signup` ? Négligeables |

## 6. Suivi inter-domaines et ruptures de session (requêtes 05, 08, 09, 11, 13)

### www.elsee.care → app.elsee.care : l'identifiant est perdu

- **281 sessions s'ouvrent sur app.elsee.care avec www.elsee.care comme
  provenance.** Seules **7** gardent l'identifiant GA4 vu sur www ; **201** sont
  des « premières visites » pour GA4. Le paramètre `_gl` du suivi inter-domaines
  est pourtant dans l'URL d'arrivée dans 54 cas.
- Sur www, les événements portent le paramètre `linker_domains` ; sur app, non.
  www décore donc bien les liens, mais l'application ne reprend pas
  l'identifiant.
- Sur 186 personnes arrivées sur `/signup`, **161 y ouvrent une nouvelle
  session** en venant de www.elsee.care.
- Conséquences :
  - les flèches www → app ne sont presque pas mesurables : `/obtenir-mon-offre
    → /signup` 10 personnes sur 41, `/offres-remboursement-elsee → /signup` 9
    sur 69 ; le reste semble « abandonner » alors qu'il continue sous un autre
    identifiant ;
  - une même personne compte comme deux utilisateurs, une fois sur www, une
    fois sur app.
- La page de provenance ne permet pas de contourner le problème : sur
  app.elsee.care, elle est réduite au domaine (`https://www.elsee.care/`), sans
  le chemin (requête 13).
- Corriger la reprise de l'identifiant relève de la configuration des balises
  GA4 sur app.elsee.care (GTM ou code de l'application). Nous ne modifions ni
  GTM ni GA4 : c'est à la personne qui gère ces balises.

### Dans app.elsee.care : continu

Les pages `/signup/…` du milieu du formulaire n'ouvrent presque jamais de
session (1 ou 2 personnes par page) : les passages entre étapes du formulaire
sont fiables. En fin de parcours, des sessions s'ouvrent directement sur
`/mon-offre` (32 personnes, dont 3 depuis Gmail) et `/mon-panier` (12) : des
personnes qui reviennent plus tard, par exemple depuis un e-mail.

### Paiement et retour vers www.elsee.care

- Parcours : `/mon-panier` (app) → **checkout.stripe.com** →
  `/bienvenue-chez-elsee` (www), où part l'événement `order_paid`.
- 3 personnes passent de `/mon-panier` à `/bienvenue-chez-elsee` dans la même
  session. Les 2 personnes revenues de Stripe ce jour-là ont gardé leur
  identifiant et leur session. Dans ce sens, le suivi semble tenir, mais il y a
  trop peu de cas pour conclure : à revoir sur 7 jours, avant de trancher la
  règle des 24 h (question ouverte du 6 oct.).

### Comparaison avec les explorations GA4 de référence

L'exploration « Offre directe » compte 659 personnes sur `/obtenir-mon-offre`
puis 553 sur `/signup` (8 sept. – 5 oct.). Elle semble donc voir ce passage, que
l'export ne voit presque pas. Trois explications possibles : l'entonnoir est
« ouvert » (on peut y entrer directement à l'étape `/signup`), GA4 relie les
identités autrement (signaux Google, identité combinée), ou la rupture est
récente. La recette (7 jours au moins, à partir du 12 oct.) tranchera.

## 7. Questions pour Eglantine (à trancher avant l'étape 2)

1. **Valider le tableau de correspondance** (section 3) et les deux domaines
   retenus (section 2).
2. **Raccourci NON de `depenses_complements`** : dessiner la flèche vers
   `sante_mentale_seances` (comme sur le dernier schéma) ?
3. **`/signup/en_savoir_plus_sur_vous`** : sur quel critère cette page est-elle
   montrée (1 personne sur 5) ? Ajouter au dessin la flèche directe
   `medecine_douce_step → depenses_sports` (84 personnes) ?
4. **Sauts hors schéma** (section 5) : ajouter ces flèches au graphe, ou les
   regrouper dans une flèche « autres passages » par page ?
5. **Entrées** : `/offres-remboursement-elsee` et `/signup-corpo` passent par
   `/signup`. Redessiner ces flèches vers `/signup` ?
6. **Carte cadeau** : `/pricing/cartecadeau` renvoie surtout vers `/mon-offre`.
   Garder la flèche du schéma vers `/mon-panier`, ajouter le retour, ou les
   deux ?
7. **Suivi www → app** : qui peut corriger la reprise de l'identifiant sur
   app.elsee.care ? Quelque chose a-t-il changé récemment sur l'application ?
   En attendant, **proposition** : pour les flèches www → app, afficher les
   arrivées sur les pages de www, mais ni nombre de passages ni taux d'abandon
   (mention « non mesurable : suivi inter-domaines »), plutôt que des chiffres
   faux.
8. **Pages hors schéma** : que sont `/success`, `/signin_freemium` et les pages
   carte cadeau ? Font-elles partie du tunnel ?
9. **Filtres** : exclure `/remboursements` (espace membre) et les domaines de
   test, comme proposé ?
