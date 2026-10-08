# Journal des décisions

Le plus récent en haut. Chaque entrée dit ce qui a été décidé, par qui, et
pourquoi. Ce journal prime sur [`brief.md`](brief.md).

## Où en est le projet

| Étape | État |
|---|---|
| 0. Informations et accès manquants | Faite le 5 oct. ; réponses reçues le 6 oct. (voir ci-dessous) |
| 1. Découverte | Faite et validée le 6 oct. : [`etape1_decouverte.md`](etape1_decouverte.md) |
| 2. Calcul (config du graphe + calcul) | Fait et validé le 7 oct. : fonction `elsee_funnel.agregats(date_debut, date_fin)` ([`etape2_calcul.md`](etape2_calcul.md)) |
| 3. Affichage Apps Script | **En cours** : page écrite et testée hors ligne ; mise en ligne par Eglantine avec [`deploiement_apps_script.md`](deploiement_apps_script.md) (déploiement de test, puis publication) |
| 4. Automatisation et alertes | **En cours** : vérification quotidienne et alertes écrites et testées hors ligne ; à installer par Eglantine ([`deploiement_apps_script.md`](deploiement_apps_script.md), section 6) |
| 5. Documentation | À faire |

## Questions encore ouvertes

**Étape 3** : Eglantine met la page en ligne en suivant
[`deploiement_apps_script.md`](deploiement_apps_script.md), d'abord en
déploiement de test, et fait ses retours avant la publication.

**Nombre leads** (8 oct.) : la fonction BigQuery est à jour (un lead par
personne). Eglantine remplace `Page.html`, `Graphe.gs` et `Code.gs` dans Apps
Script et publie une nouvelle version
([`deploiement_apps_script.md`](deploiement_apps_script.md), « Mettre à jour la
page plus tard »). Cela met aussi en ligne le tableau « Pages vues par
personne » s'il ne l'est pas encore.

Autres questions :

- **Réglages GA4** (utiles pour expliquer les écarts à la recette) : mode de
  consentement (Consent Mode v2 basique ou avancé, outil de consentement),
  identité pour les rapports (combinée, observée ou basée sur l'appareil).
- **Définition des étapes des quatre explorations** : entonnoir ouvert ou
  fermé, « suivie directement de » ou « suivie de », type de condition sur le
  chemin, pages regroupées dans l'étape « Entrée » du long form. L'export PDF ne
  le montre pas.
- **Recette** : le fichier de référence couvre le 8 sept. – 5 oct., avant
  l'export BigQuery. Il faudra le même export des quatre explorations sur une
  période d'au moins 7 jours couverte par l'export (au plus tôt du 5 au 11 oct.,
  disponible le 12 oct.).

## 2026-10-08 — Un lead par personne (Eglantine)

Réponse d'Eglantine aux choix de mise en œuvre du nombre de leads (entrée
suivante) : « j'ai juste besoin de savoir si un utilisateur a complété à un
moment ou un autre dans son parcours le formulaire (donc lead 1 fois max par
utilisateur) ».

1. **Personne revenue en cours de formulaire** (session sans page d'entrée) :
   confirmé, elle ne compte ni avant `depenses_complements` ni à la pop-up.
2. **Un lead au plus par personne** : chaque personne est lead une seule fois,
   à son premier moment, cherché sur tout l'historique lu (60 jours avant la
   période, et pas avant le 5 oct., début de l'export). Elle compte sur la
   période si ce premier moment y tombe. Une personne déjà lead avant la
   période n'est pas recomptée, même si elle redonne ses coordonnées. Cela
   remplace la règle « une fois par période » de l'entrée suivante.

Conséquence : les leads jour par jour s'additionnent pour donner le total de la
période. Limite : « personne » = identifiant GA4 (un navigateur sur un
appareil) ; la même personne sur un autre appareil compte à part.

Testé en lecture seule : mêmes chiffres sur les 5 et 6 oct. (323 ; 145 le 6
seul), car personne n'a été lead les deux jours ; règle vérifiée sur un jeu
d'essai fictif (une personne lead le 5 puis le 7 ne compte pas sur le 7 ; une
personne passée par deux moments compte une fois, au premier). Lignes hors
leads inchangées.

Fonction BigQuery `elsee_funnel.agregats` remplacée le 8 oct., sur accord
d'Eglantine : elle renvoie exactement les mêmes lignes que `agregats.sql` sur
les 5 et 6 oct. (871 lignes) et sur le 6 oct. seul (514 lignes). Reste à faire
par Eglantine : remplacer `Page.html`, `Graphe.gs` et `Code.gs` dans Apps
Script, puis publier une nouvelle version.

## 2026-10-08 — Nombre leads (Eglantine)

Demande : un encadré « Nombre leads », le nombre de personnes qui ont donné
leurs coordonnées (e-mail) sur la période choisie.

Règles validées par Eglantine (reformulation de sa demande, puis réponses à
quatre questions) :

1. **GA4 ne voit pas la saisie** : un lead est compté au chargement de la page
   qui la suit, à l'un de trois moments selon l'entrée de la personne :
   - entrée par `/obtenir-mon-offre`, `/offres-remboursement-elsee`,
     `/remboursement-complements-alimentaires` ou `/signup-corpo` :
     coordonnées données juste avant `/signup/depenses_complements`, compté à
     l'arrivée sur cette page ;
   - entrée directe (`/social_signup` ou `/signup`), chemin compléments :
     pop-up entre `bonus-abonnement` et `bilan` (sans changement d'adresse),
     compté à l'arrivée sur `bilan` ;
   - entrée directe, long form : `en_savoir_plus_sur_vous`, compté à l'arrivée
     sur la page suivante, `depenses_sports`.
2. **La pop-up est obligatoire** : arriver sur `bilan` juste après
   `bonus-abonnement` prouve que l'e-mail a été donné.
3. **Offre directe** (`/signup → /mon-offre` sans `depenses_complements`) : ce
   sont des personnes déjà connues, **pas comptées**.
4. **Reconnaître l'entrée** (GA4 perd la personne entre www et app, et ne garde
   que le domaine de la page d'où l'on vient) : `/signup` ouverte depuis
   www.elsee.care, ou `/signup-corpo` = coordonnées déjà données ;
   `/social_signup`, ou `/signup` ouverte sans venir de www.elsee.care (lien
   direct, publicité, e-mail) = entrée directe.
5. **Affichage** : encadré « Nombre leads » à côté de la période, avec une bulle
   d'aide (répartition entre les trois moments, courbe par jour), repris dans
   l'export PNG.

Précisions de mise en œuvre ([`etape2_calcul.md`](etape2_calcul.md), règle 10) :
l'entrée est celle de la session (dernière page d'entrée vue) ; une page
ouverte depuis app.elsee.care (retour en arrière dans le formulaire) ne la
change pas, si bien que `/signup-corpo → /signup` reste une entrée avec
coordonnées. Une session sans page d'entrée (personne revenue au milieu du
formulaire) ne compte ni à `depenses_complements` ni à `bilan`, faute de
savoir. Une personne compte une fois sur la période ; la répartition la range à
son premier moment, donc les trois parts font le total.

Vérifié dans les données (5 et 6 oct.) : 340 personnes arrivent sur `/signup`
depuis www.elsee.care, 8 seulement d'ailleurs ; les entrées directes passent
surtout par `/social_signup` (90 personnes). Sur `bilan`, les 70 arrivées
après `bonus-abonnement` se partagent entre 57 entrées avec coordonnées (pas de
pop-up) et 13 entrées directes.

Premiers chiffres (5 et 6 oct., à confirmer) : **323 leads** (178 le 5, 145 le
6), dont 287 avant `depenses_complements` (89 %), 23 par
`en_savoir_plus_sur_vous` (7 %) et 13 par la pop-up (4 %). 5 personnes au plus
passent par deux moments (par exemple la pop-up, puis une nouvelle entrée par
www.elsee.care jusqu'à `depenses_complements`) : elles comptent une fois.

Réalisé : bloc `leads` dans [`config/graphe.json`](../config/graphe.json)
(entrées, moments, libellés de la bulle), genre `leads` dans le calcul, encadré
dans la page et dans l'export PNG, courbe par jour transmise par `Code.gs`, et
nombre de leads affiché par `testerInstallation`. Testé : calcul en lecture
seule sur les 5 et 6 oct., dont les 865 lignes existantes sont identiques à
celles de la fonction en place ; page dans Chromium (ordinateur, téléphone,
bulle, export PNG ; « indisponible » plutôt que zéro avec l'ancienne
fonction), aucune erreur. Texte de la fonction : 22 Ko sur 32.

Fonction BigQuery `elsee_funnel.agregats` remplacée le 8 oct., sur accord
d'Eglantine : elle renvoie exactement les mêmes lignes que `agregats.sql` sur
les 5 et 6 oct. (871 lignes, dont les leads). La page déjà en ligne continue de
fonctionner (elle ignore les nouvelles lignes). Reste à faire par Eglantine :
remplacer `Page.html`, `Graphe.gs` et `Code.gs` dans Apps Script, puis publier
une nouvelle version.

## 2026-10-08 — Tableau « Pages vues par personne » (Eglantine)

Demande : à côté du schéma, la répartition des personnes selon le nombre total
de pages vues, pages d'entrée comprises, pour savoir au bout de combien de
pages les gens se lassent du questionnaire.

Choix validés par Eglantine :

1. **Personnes comptées : celles arrivées sur le formulaire** (au moins une
   page de app.elsee.care). Toutes leurs pages du schéma comptent, entrées
   comprises (`/signup-corpo`, `/social_signup`, `/signup` ; une entrée de
   www.elsee.care seulement quand GA4 garde la personne, ce qui est rare). Les
   personnes vues seulement sur www.elsee.care sont données à part, sous le
   tableau : GA4 les perd en passant sur le formulaire (étape 1), elles
   gonfleraient sinon la ligne « 1 page ».
2. **Une page vue plusieurs fois compte une fois** : nombre de pages
   différentes vues sur la période (jusqu'où la personne est allée).
3. **Colonne « dont ont vu leur offre »** (`/mon-offre` ou `/offres`) : sans
   elle, une personne qui finit en peu de pages grâce aux raccourcis NON se
   confondrait avec une personne qui abandonne.

Réalisé : bloc `pages_vues` dans [`config/graphe.json`](../config/graphe.json)
(domaine du formulaire, étapes « offre », position du tableau), trois genres
de plus dans le calcul (`pages_vues`, `pages_vues_offre`, `hors_formulaire` ;
[`etape2_calcul.md`](etape2_calcul.md), règle 9), tableau dessiné dans le
schéma, dans l'espace libre à droite de la colonne principale (il est donc
aussi dans l'export PNG) : une ligne par nombre de pages, avec une barre
(rouge : arrêtées sans voir leur offre ; gris : ont vu leur offre), le nombre
de personnes, leur part, le nombre ayant vu leur offre et la part ayant vu au
moins ce nombre de pages ; bulle d'aide sur chaque ligne. Testé en lecture
seule sur les 5 et 6 oct. (contrôle de cohérence toujours sans écart négatif,
fonction validée par simulation) et dans Chromium (aucune erreur). Si la page
reçoit les chiffres de l'ancienne fonction, le tableau l'indique au lieu
d'afficher des zéros.

Premiers chiffres (5 et 6 oct., deux jours seulement : à confirmer) : 532
personnes arrivées sur le formulaire, 155 vues seulement sur www.elsee.care.

- 1 page : 116 personnes, dont 54 ont vu leur offre (retour direct sur
  `/mon-offre` ou `/offres`, par un lien ou un e-mail).
- **4 pages : 71 personnes, dont 64 arrêtées sans voir leur offre** ; 62
  d'entre elles s'arrêtent sur `network_complements`, après `/signup` (ou
  `/social_signup`), `depenses_complements` et `montant_complements`. C'est le
  plus gros point d'arrêt.
- 9 pages : 46 personnes, dont 44 ont vu leur offre (c'est la longueur de la
  branche compléments jusqu'à `/offres`).
- 23 à 28 pages : 131 personnes, presque toutes allées jusqu'à leur offre (long
  form).

Fonction BigQuery `elsee_funnel.agregats` remplacée le 8 oct., sur accord
d'Eglantine : elle renvoie exactement les mêmes lignes que `agregats.sql` sur
les 5 et 6 oct. (866 lignes). La page déjà en ligne continue de fonctionner
(elle ignore les nouvelles lignes). Reste à faire par Eglantine : remplacer
`Page.html` et `Graphe.gs` dans Apps Script, puis publier une nouvelle version.

## 2026-10-08 — Premier essai de la page par Eglantine

La page tourne dans Apps Script avec les données des 5 et 6 oct. Corrigé après
son essai :

- « Hier » quand la journée d'hier n'est pas encore arrivée : la page affiche
  la dernière journée disponible (« Dernière journée disponible : le … »), au
  lieu d'une erreur sous le schéma d'une autre période.
- Période sans données (ex. « Mois précédent », avant le début de l'export) ou
  invalide : le schéma est masqué et l'en-tête indique la période choisie.
- « Période libre » s'affiche dès le clic.
- La table du 6 oct. est arrivée à 15 h 51 (celle du 5 à 10 h 06) : le message
  ne dit plus « dans la matinée » mais « dans le courant du lendemain, parfois
  l'après-midi ». La vérification de 15 h tolère un jour de retard : pas
  d'alerte pour cela.
- Contrôle de cohérence sur les 5 et 6 oct. : aucun écart négatif. Aucune
  inscription (`/bienvenue-chez-elsee`, 5 personnes) n'est encore rattachée à un
  parcours : aucune de ces personnes n'a de visite du tunnel dans l'export
  avant son inscription (elles ont dû remplir le formulaire avant le 5 oct.).

## 2026-10-07 — Alertes (étape 4)

Eglantine : alertes à **hello@elsee.care**, **seulement en cas de gros
problème**. Retenu comme « gros problème » (la page afficherait des chiffres
faux ou périmés) :

1. **aucune nouvelle journée GA4 depuis plus de 2 jours** (ni hier ni
   avant-hier) : l'export GA4 vers BigQuery semble arrêté. Un retard d'un jour,
   qui arrive parfois, ne déclenche rien ;
2. **le calcul échoue** : la fonction `elsee_funnel.agregats` a disparu ou
   renvoie une erreur ;
3. **le tunnel tombe à zéro** sur la dernière journée alors que GA4 a des
   données (adresses du formulaire changées, par exemple).

Vérification chaque jour entre 15 h et 16 h (heure de Paris), par un
déclencheur Apps Script (`verifierChaqueJour`), installé une fois par
Eglantine avec `installerDeclencheur`. Un même problème n'est rappelé que tous
les 3 jours ; un problème résolu n'envoie rien. Cela remplace la règle du brief
(« e-mail si la table de la veille manque ou si la recréation des vues
échoue ») : il n'y a plus de vues à recréer, et un seul jour de retard n'est
pas un gros problème. Testé hors ligne sur 10 scénarios (imitations des
services Google).

## 2026-10-07 — Affichage des taux (Eglantine)

- **Tous les taux d'abandon sont dans les étapes** (en rouge, après le nombre
  d'arrivées), et plus jamais sur les flèches. Cela remplace la règle du brief
  (« juste au-dessus du nombre de la flèche : le taux d'abandon de l'étape A »),
  qui mettait le taux tantôt sur la flèche, tantôt dans l'étape.
- Les flèches portent le nombre de personnes passées et, quand l'étape de départ
  a plusieurs sorties, la répartition en %. **Cette répartition fait toujours
  100 %** : arrondi par la méthode des plus forts restes (avant : OUI 90 % +
  NON 11 % = 101 %).

## 2026-10-07 — Étape 2 validée, étape 3 : la page Apps Script

Eglantine a répondu aux questions posées pour l'étape 3, ce qui vaut validation
de l'étape 2 (les questions étaient posées à cette condition) :

1. **Propriétaire du script : hello@elsee.care**, propriétaire du projet
   `ga4-chemin-form`. La page s'exécute avec ce compte (« Exécuter en tant que :
   moi ») : aucune clé à stocker.
2. **Accès : tout le monde en @elsee.care** (déploiement réservé au domaine,
   plus une vérification de l'adresse par le script).
3. **Mise en ligne par Eglantine**, par copier-coller dans l'éditeur Apps
   Script (pas d'installation) : guide
   [`deploiement_apps_script.md`](deploiement_apps_script.md).

Réalisé :

- [`apps-script/`](../apps-script/) : `Code.gs` (serveur : état des données,
  appel de `elsee_funnel.agregats`, cache de 6 h vidé à chaque nouvelle donnée
  ou configuration, fonction `testerInstallation`), `Page.html` (schéma SVG,
  filtre période, bulles d'aide avec courbe des arrivées par jour, export PNG,
  détails et contrôles), `Graphe.gs` (généré à partir de `config/graphe.json`),
  `appsscript.json`.
- Périodes : hier, 7 jours, 28 jours, mois en cours, mois précédent, période
  libre ; ramenées aux jours disponibles, avec la période réellement couverte
  affichée. Message si les données d'hier ne sont pas encore arrivées.
- Flèches www → app en pointillés, sans chiffre (non mesurables). Taux
  d'abandon en rouge sur la flèche (une seule sortie) ou dans l'étape (plusieurs
  sorties, avec la répartition en % sur chaque flèche). Passages hors schéma et
  pages sans parcours listés sous le schéma.
- Testé hors Apps Script : page avec les vrais agrégats du 5 oct. dans Chromium
  (aucune erreur, bulles, export PNG, affichage sur téléphone) ; serveur avec
  des imitations des services Google (pagination BigQuery, cache découpé,
  refus des comptes extérieurs).
- Dans la configuration, les étapes de l'offre directe sont espacées (colonnes
  1,3 / 2,6 / 3,9) pour laisser la place aux chiffres, et chaque parcours peut
  avoir un titre positionné (`titre`).

## 2026-10-07 — `elsee_funnel` et la fonction de calcul créés

Sur confirmation écrite d'Eglantine (« oui, crée elsee_funnel et la
fonction »), après qu'elle a donné au compte de service le droit de créer des
datasets :

- dataset `ga4-chemin-form.elsee_funnel` créé en région EU (expiration par
  défaut des tables et vues : 60 jours, imposée par le bac à sable) ;
- fonction de table `elsee_funnel.agregats(date_debut, date_fin)` créée. Elle
  n'a pas de date d'expiration : **pas besoin de recréer des vues chaque jour**,
  le déclencheur quotidien de l'étape 4 n'aura qu'à vérifier l'arrivée des
  données (et que la fonction existe toujours) ;
- première tentative refusée par BigQuery (texte de fonction limité à 32 Ko,
  le nôtre en faisait 100) : le générateur encode désormais le graphe de façon
  compacte (19 Ko) et vérifie la taille. Résultats identiques, ligne par ligne,
  avant et après, et entre la fonction et `agregats.sql`.

## 2026-10-07 — Rattachement des personnes qui reviennent (Eglantine)

**Validé** : une personne dont la session commence sur `/mon-offre`,
`/mon-panier` ou `/bienvenue-chez-elsee` (retour par un lien, un e-mail) est
rattachée au parcours de la dernière étape qu'elle a vue dans une session
précédente, sur les 60 jours conservés. Cette règle **remplace celle des 24 h**
proposée pour `/mon-panier → /bienvenue-chez-elsee`.

Mise en œuvre ([`scripts/generer_sql.mjs`](../scripts/generer_sql.mjs)) : pour
ces trois pages, le parcours vient, dans l'ordre, de la page précédente dans la
session, puis d'un passage antérieur sur la même page dans la session (retour
en arrière), puis de la dernière étape vue par la personne, dans cette session
ou une précédente (60 jours au plus). Dans ce dernier cas, on prend l'étape de
la page la plus proche en suivant les flèches (après `/offres`, `/mon-panier`
du parcours compléments ; après `/signup`, l'offre directe), à défaut celle du
même parcours. Le calcul lit donc 60 jours de données avant la période (environ
6 Mo par jour, dans le quota gratuit).

Sur la seule journée du 5 oct., l'effet est faible : `/mon-offre` non rattachées
33 au lieu de 38, `/mon-panier` 21 au lieu de 24, `/bienvenue-chez-elsee` 5 sur
5 (leurs visites précédentes datent d'avant l'export). Il grandira au fil des
jours. Contrôle de cohérence toujours sans écart négatif.

## 2026-10-06 (4e session, suite) — Étape 1 validée, étape 2 commencée

Réponses d'Eglantine aux questions de l'étape 1 (section 7 de
[`etape1_decouverte.md`](etape1_decouverte.md)), avec un nouveau schéma qui
remplace [`reference/schema-tunnel.pdf`](reference/schema-tunnel.pdf) :

1. **Tableau de correspondance validé. Seuls app.elsee.care et www.elsee.care
   comptent.**
2. **Raccourci NON de `depenses_complements` → `sante_mentale_seances`.**
3. **`en_savoir_plus_sur_vous`** recueille les coordonnées (e-mail, téléphone).
   Entrée par `/obtenir-mon-offre`, `/offres-remboursement-elsee`,
   `/signup-corpo` ou `/remboursement-complements-alimentaires` : coordonnées
   recueillies juste avant `/signup/depenses_complements`. Entrée directe par
   `/social_signup` ou `/signup` : recueillies plus tard, par une pop-up entre
   `bonus-abonnement` et `bilan` (sans changement d'adresse) sur le chemin
   compléments, ou par `en_savoir_plus_sur_vous` sur le long form. Donc **deux
   passages** depuis `medecine_douce_step` : vers `en_savoir_plus_sur_vous` et
   directement vers `depenses_sports`. Vérifié dans les données
   ([requête 15](../sql/decouverte/15_en_savoir_plus_selon_entree.sql)).
4. **Seuls les raccourcis du schéma existent** : pas de nouvelle flèche pour les
   sauts observés. Ils ne sont pas dessinés ; ils comptent comme sorties (pas
   comme abandons) et restent listés par le calcul (`etape2_calcul.md`, règle 8).
5. **Entrées (nouveau schéma)** : `/signup-corpo`,
   `/remboursement-complements-alimentaires` et `/offres-remboursement-elsee` →
   `/signup` ; `/social_signup` → `/signup/depenses_complements`.
6. **Carte cadeau** : une personne qui revient de `/pricing/cartecadeau` vers
   `/mon-offre` puis va sur `/mon-panier` compte comme passée directement par le
   chemin de gauche, sans avoir vu `/pricing/cartecadeau`.
7. **Pas de chiffre faux** : rien n'est affiché sur les flèches www → app.
8. **Pages hors schéma** (`/success`, `/signin_freemium`, carte cadeau…) :
   ignorées.
9. **Pas d'autre filtre** que les deux domaines.

Étape 2 commencée : configuration [`config/graphe.json`](../config/graphe.json),
générateur [`scripts/generer_sql.mjs`](../scripts/generer_sql.mjs), calcul et
contrôle de cohérence dans [`sql/calcul/`](../sql/calcul/), testés en lecture
seule sur le 5 oct. (contrôle sans écart négatif). Choix : une **fonction de
table** `elsee_funnel.agregats(date_debut, date_fin)` à la place des vues (la
période est un paramètre). Détail et décisions restantes :
[`etape2_calcul.md`](etape2_calcul.md). [`brief.md`](brief.md) est mis à jour
avec le nouveau graphe.

## 2026-10-06 (4e session, suite) — Étape 1 exécutée

Eglantine a donné au compte de service le rôle « Lecteur de données BigQuery »
sur `analytics_383563328` : la lecture fonctionne. Les requêtes 01 à 08 ont
tourné sur la seule table disponible (5 oct.), complétées par les requêtes 09 à
13 pour creuser ce qu'elles montraient. Analyse complète, tableau de
correspondance et questions : [`etape1_decouverte.md`](etape1_decouverte.md).

Constats principaux :

- Dataset en région **EU**, fuseau Europe/Paris, une table par jour, pas
  d'export en continu.
- Les 41 étapes du schéma existent avec le chemin prévu. `/social_signup` et
  `/signup/montant_sante_mentale` sont confirmés (`/signup/montant_sm`
  n'existe pas).
- Le formulaire est sur **app.elsee.care** (et non sur elsee.care comme le dit
  le brief) ; `/obtenir-mon-offre`, `/offres-remboursement-elsee`,
  `/remboursement-complements-alimentaires` et `/bienvenue-chez-elsee` sont sur
  www.elsee.care.
- Le raccourci NON de `depenses_complements` mène à `sante_mentale_seances`
  (pas à `depenses_complements_step`). Les autres raccourcis NON sont conformes
  au schéma.
- **GA4 perd l'identifiant entre www.elsee.care et app.elsee.care** (7 sessions
  sur 281 le gardent). Les flèches www → app ne sont presque pas mesurables
  tant que ce n'est pas corrigé côté balises (hors de notre périmètre).
- Le paiement passe par checkout.stripe.com, puis revient sur
  `/bienvenue-chez-elsee` (événement `order_paid`).

Rien n'a été créé dans BigQuery (lecture seule).

Branches : `main` contient tout le travail. La suppression des anciennes
branches demandée par Eglantine a échoué : GitHub refuse la suppression depuis
la session (erreur 403), et la branche par défaut du dépôt était encore
`claude/beautiful-turing-haxwv7` (une branche par défaut ne peut pas être
supprimée). Les deux anciennes branches sont entièrement contenues dans `main` :
les supprimer ne perd rien. À faire par Eglantine sur GitHub :

1. Settings → General → Default branch → choisir `main` ;
2. puis onglet Code → Branches → supprimer `claude/beautiful-turing-haxwv7` et
   `claude/gifted-ride-oin2dt` (icône corbeille).

## 2026-10-06 (4e session) — Une seule branche principale : `main`

Demande d'Eglantine : fusionner le travail dans une branche principale, pour que
les prochaines sessions partent toujours du bon endroit.

- Avant : chaque session travaillait sur sa propre branche `claude/…`, et la
  branche par défaut du dépôt (`claude/beautiful-turing-haxwv7`) était restée
  au premier commit. Une nouvelle session repartait donc d'un état périmé.
- Désormais : **`main` contient tout le travail.** Chaque session part de
  `main`, travaille sur sa branche de session, puis fusionne son travail dans
  `main` (avance rapide, sans réécrire l'historique) et pousse `main` avant de
  finir. Règle ajoutée à [`CLAUDE.md`](../CLAUDE.md).
- À faire par Eglantine : sur GitHub, dépôt `data-engineering` → Settings →
  General → Default branch → choisir `main`. Ensuite, les anciennes branches
  `claude/beautiful-turing-haxwv7` et `claude/gifted-ride-oin2dt` pourront être
  supprimées (sur son accord).

## 2026-10-06 (4e session) — Clé acceptée, mais pas de droit de lecture

La nouvelle clé (base64) est acceptée par Google :
[`scripts/activer_cle_gcp.sh`](../scripts/activer_cle_gcp.sh) active bien
`funnel-dev@ga4-chemin-form.iam.gserviceaccount.com`. L'avertissement « Cloud
Resource Manager API has not been used » qui s'affiche est sans effet sur
BigQuery.

Mais le compte peut seulement lancer des requêtes : il ne voit aucun dataset du
projet, et la lecture de `analytics_383563328` est refusée
(« bigquery.tables.list denied », « User does not have permission to query
table … events_* »). **L'étape 1 n'a toujours pas pu être exécutée.**

À faire par Eglantine : dans la console Google Cloud, BigQuery → ouvrir le
dataset `analytics_383563328` → Partage → Autorisations → Ajouter un compte
principal : `funnel-dev@ga4-chemin-form.iam.gserviceaccount.com`, rôle
**Lecteur de données BigQuery** (`roles/bigquery.dataViewer`). Ce rôle donne la
lecture seule, sur ce seul dataset. Pas besoin de changer la clé ; le droit
peut mettre quelques minutes à s'appliquer.

Le script vérifie maintenant ce droit de lecture à la fin (requête simulée, rien
n'est lu ni facturé) et le signale clairement s'il manque.

## 2026-10-06 (3e session) — Clé du compte de service : complète mais refusée

`GCP_SA_KEY_JSON` contient maintenant le fichier JSON complet, cohérent
(`client_email`, `client_x509_cert_url` et `project_id` désignent tous
`funnel-dev@ga4-chemin-form.iam.gserviceaccount.com`), et la clé privée est
lisible (RSA 2048 bits). Mais Google refuse la connexion (« Invalid JWT
Signature »), deux fois de suite, l'horloge de la session étant à l'heure.

Cause : comparée aux certificats publics du compte, la clé du fichier (ID
commençant par `12a4df00`) ne fait partie d'aucune des deux clés actives
(`1e9c0cfe…`, `b40ed416…`). Elle a donc été supprimée après téléchargement, ou
le fichier a été modifié à la main (clé privée ou ID venant d'ailleurs).

À faire par Eglantine : console Google Cloud → IAM et administration → Comptes
de service → `funnel-dev` → onglet Clés → Ajouter une clé → Créer une clé →
JSON. Mettre le fichier téléchargé **tel quel, sans le modifier**, dans
`GCP_SA_KEY_JSON` (base64 sur une ligne : `base64 -i cle.json | pbcopy`), puis
ouvrir une nouvelle session. Les clés inutilisées pourront ensuite être
supprimées.

## 2026-10-06 (2e session) — Réponses d'Eglantine

- **Affichage : page web Apps Script**, pas de module Odoo (Eglantine ne peut
  pas l'ouvrir dans Odoo). Le brief du dépôt reste valable ; le texte de mission
  qui parlait d'Odoo est écarté.
- **Une page de paiement sépare /mon-panier et /bienvenue-chez-elsee** : le
  retour du paiement ouvre sans doute une nouvelle session. Avec la règle du
  brief (passage dans la même session), la flèche /mon-panier →
  /bienvenue-chez-elsee serait presque toujours vide.

  Proposition, à valider : pour cette seule flèche, compter le passage si le
  même utilisateur (`user_pseudo_id`) voit /bienvenue-chez-elsee après
  /mon-panier, dans la même session ou dans une session suivante, **dans les
  24 h**. Le parcours (offre directe, long form, compléments, carte cadeau) est
  celui du dernier /mon-panier vu avant. Les autres flèches gardent la règle de
  la même session. Les requêtes 05 et 08 de l'étape 1 diront d'où reviennent
  ces sessions (domaine de paiement) et si l'utilisateur garde bien le même
  identifiant.

  À noter : ajouter le domaine de paiement aux « sites référents indésirables »
  de GA4 éviterait la coupure de session à l'avenir (sans effet sur
  l'historique). Ce réglage GA4 relève d'Eglantine : nous ne modifions pas GA4.

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
