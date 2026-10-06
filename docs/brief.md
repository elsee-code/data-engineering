# Brief de la mission

> Texte de la mission transmis le 5 octobre 2026, déjà corrigé des décisions du
> 6 octobre (vues BigQuery au lieu de tables alimentées par une requête
> programmée, libellé du seuil compléments retiré). En cas de doute, le journal
> [`decisions.md`](decisions.md) **prime sur ce texte**.

## Mission : schéma du tunnel d'inscription Elsee, mis à jour chaque jour à partir de GA4

### Rôle
Ingénieur·e data senior, à l'aise avec GA4, l'export BigQuery de GA4, SQL, Google Apps Script et la visualisation en SVG. Pour Elsee (elsee.care), un programme de bien-être qui rembourse compléments alimentaires, médecine douce, thérapie, sport et santé féminine. Expliquer ses choix simplement et demander validation avant toute action irréversible.

### Objectif
Construire une page web privée qui redessine le schéma du tunnel d'inscription ([`reference/schema-tunnel.pdf`](reference/schema-tunnel.pdf)) sous forme de diagramme de flux, recalculé automatiquement chaque jour à partir des données GA4 :
- sur chaque étape : le nombre de personnes arrivées ;
- sur chaque flèche A → B : le nombre de personnes passées de A à B (comme les chiffres gris du schéma) ;
- juste au-dessus de ce nombre : le taux d'abandon de l'étape A.

Un seul filtre : la période (hier, 7 jours, 28 jours, 90 jours, mois en cours, mois précédent).
Le rendu reprend la disposition du schéma : colonne principale au centre, raccourcis « NON » à droite, branche compléments alimentaires en vert à gauche, short form et offre directe en haut (bleu et jaune), points d'entrée alignés en haut à gauche.

### Hors périmètre pour l'instant
Les sous-étapes 1 à 4 de /obtenir-mon-offre, les pop-ups (dont « POPUP LEAD ») et les marqueurs « LEAD » du schéma. Ne pas les traiter, mais garder une configuration qui permettra de les ajouter plus tard.

### Contexte (à vérifier, ne rien tenir pour acquis)
- Le formulaire est sur elsee.care ; l'offre, le panier et le paiement sur app.elsee.care. Le suivi inter-domaines est configuré dans GA4 : vérifier dans les données qu'une même session continue bien d'un domaine à l'autre.
- Une étape = une page (chemin d'URL).
- Google Cloud : projet ga4-chemin-form, dataset d'export analytics_383563328 (propriété GA4 383563328). Export quotidien activé le 5 octobre 2026, donc aucune donnée avant cette date.
- Référence chiffrée : quatre explorations « entonnoir » GA4 (long form, compléments, offre directe, bloc compléments) du 8 sept. au 5 oct. 2026 ([`reference/explorations-ga4_2026-09-08_2026-10-05.pdf`](reference/explorations-ga4_2026-09-08_2026-10-05.pdf), remplace le fichier erroné du 7 sept. au 4 oct.). Ordres de grandeur sur cette période : 5 767 entrées dans le long form, 2 965 utilisateurs sur /signup/recap_marques, 659 sur /obtenir-mon-offre.

### Comment fonctionnent les flèches « NON »
Ce sont des raccourcis, pas des branches parallèles. Plusieurs pages posent une question (par exemple « Avez-vous des dépenses en compléments ? »). Si l'utilisateur répond oui, il suit les pages de détail ; s'il répond non, le formulaire l'envoie directement plusieurs étapes plus loin, en sautant ces pages.
Conséquences :
- Prendre un raccourci NON est une poursuite du parcours, jamais un abandon.
- Les pages sautées reçoivent mécaniquement moins de monde : ce n'est pas de l'abandon.
- La page d'arrivée d'un raccourci reçoit deux flux (chemin OUI et raccourci NON) : ses arrivées les additionnent, et le dessin montre les deux flèches entrantes.
- Les pages de convergence (les pages _step, /signup/sante_mentale_seances, /signup/md_seances, /signup/soins_seances, /signup/final_step) voient passer tous les parcours : ce sont les meilleurs points de contrôle.

### Le graphe du schéma (base de la configuration)
Une ligne = une suite de flèches. Les chemins sont ceux du schéma ; les vrais chemins sont à confirmer avec les données.

Short form et offre directe
- /obtenir-mon-offre → /signup
- /signup → /mon-offre → /mon-panier → /bienvenue-chez-elsee (offre directe)
- /signup → /signup/depenses_complements (entrée du long form)

Autres entrées du long form (toutes mènent à /signup/depenses_complements)
- /signup-corpo
- /social_signup
- /remboursement-complements-alimentaires
- /offres-remboursement-elsee

Bloc compléments
- /signup/depenses_complements → /signup/montant_complements (OUI) → /signup/network_complements → /signup/recap_marques → /signup/depenses_complements_step
- Raccourci NON : /signup/depenses_complements → /signup/depenses_complements_step (saute montant, network et recap_marques) [sur le dernier schéma, la flèche semble arriver sur /signup/sante_mentale_seances : à trancher avec les données]
- /signup/recap_marques → /signup/recap_remboursements (branche compléments alimentaires)

Branche compléments alimentaires (vert)
- /signup/recap_remboursements → /signup/bonus-abonnement → /signup/bilan → /offres → /mon-panier → /bienvenue-chez-elsee

Santé mentale
- /signup/depenses_complements_step → /signup/sante_mentale_seances
- /signup/sante_mentale_seances → /signup/montant_sante_mentale (OUI) → /signup/md_seances
- Raccourci NON : /signup/sante_mentale_seances → /signup/sante_mentale_step → /signup/md_seances (saute montant_sante_mentale)

Médecine douce et soins
- /signup/md_seances → /signup/montant_medecine_douce (OUI) → /signup/soins_seances
- Raccourci NON : /signup/md_seances → /signup/soins_seances (saute montant_medecine_douce)
- /signup/soins_seances → /signup/montant_soins (OUI) → /signup/network_info → /signup/prete_a-changer → /signup/medecine_douce_step
- Raccourci NON : /signup/soins_seances → /signup/medecine_douce_step (saute montant_soins, network_info et prete_a-changer)
- /signup/medecine_douce_step → /signup/en_savoir_plus_sur_vous (nouvelle étape) → /signup/depenses_sports

Sport, produits, apps
- /signup/depenses_sports → /signup/network_sport (OUI) → /signup/out_of_network_sport → /signup/sport_step
- Raccourci NON : /signup/depenses_sports → /signup/sport_step (saute network_sport et out_of_network_sport)
- /signup/sport_step → /signup/depenses_produit
- /signup/depenses_produit → /signup/network_produit (OUI) → /signup/out_of_network_produit → /signup/depenses_app
- Raccourci NON : /signup/depenses_produit → /signup/depenses_app (saute network_produit et out_of_network_produit)
- /signup/depenses_app → /signup/out_of_network_app (OUI) → /signup/final_step
- Raccourci NON : /signup/depenses_app → /signup/final_step (saute out_of_network_app)

Fin du long form
- /signup/final_step → /signup/offre_en_preparation → /mon-offre
- /mon-offre → /mon-panier → /bienvenue-chez-elsee
- /mon-offre → /pricing/cartecadeau → /mon-panier → /bienvenue-chez-elsee

Points d'attention
- /mon-offre, /mon-panier et /bienvenue-chez-elsee apparaissent dans plusieurs parcours (offre directe, long form, compléments, carte cadeau). Rattacher chaque passage au bon parcours d'après les pages précédentes de la session, sans jamais le compter deux fois.
- Le chemin de l'entrée « social » est /social_signup (confirmé par Eglantine le 6 oct. ; l'ancien export qui écrivait /social-signup était faux). Le vérifier quand même dans les données, comme les deux nouvelles entrées.
- Le schéma peut contenir des erreurs : toute transition observée dans les données mais absente du graphe doit être remontée, jamais ignorée.

### Définitions à respecter
- Unité : utilisateurs distincts (user_pseudo_id), comme « Utilisateurs actifs » dans les explorations GA4.
- Arrivées sur une étape : utilisateurs distincts ayant atteint l'étape sur la période, tous chemins confondus.
- Passage A → B : dans une même session (user_pseudo_id + ga_session_id), B est la première étape du graphe atteinte après A, en ignorant les pages hors graphe et les rechargements de A. Un utilisateur compte une fois par flèche sur la période.
- Taux d'abandon de A : part des utilisateurs arrivés sur A qui n'ont fait aucun passage vers une étape suivante prévue au graphe, soit 1 − (utilisateurs ayant au moins un passage sortant de A) / (arrivées sur A). Un retour en arrière n'est pas une poursuite ; un raccourci NON en est une.
- Page à question (OUI / NON) : un seul taux d'abandon pour la page, calculé sur les deux sorties, plus la répartition OUI / NON en % sur les deux flèches.
- Périodes : des utilisateurs distincts ne s'additionnent pas d'un jour à l'autre. Calculer chaque période du filtre en entier, plus une série quotidienne pour les courbes d'évolution.
- Données tardives : GA4 peut compléter une table quotidienne quelques jours après sa création.

### Architecture cible (d'origine — révisée le 6 octobre, voir decisions.md)
1. Source : l'export BigQuery quotidien de GA4 (tables events_AAAAMMJJ du dataset analytics_383563328).
2. Calcul dans BigQuery : ~~une requête programmée quotidienne qui écrit des tables agrégées~~ → **des vues** dans un dataset dédié, elsee_funnel, dans la même région que le dataset d'export.
3. Configuration unique du graphe : un fichier versionné (YAML ou JSON) qui décrit les étapes (id, libellé, chemin, parcours, couleur, position dans le dessin) et les flèches (source, cible, type : normale, OUI ou raccourci NON). La requête et la page utilisent cette même configuration. Ajouter une page au formulaire = modifier ce seul fichier.
4. Affichage : une application web Google Apps Script (HtmlService), créée avec un compte Google d'Elsee qui a accès au projet ga4-chemin-form.
   - Elle lit des agrégats calculés dans BigQuery via le service avancé BigQuery. Le script s'exécute avec le compte de son propriétaire : aucune clé à stocker.
   - Elle dessine le diagramme en SVG à partir de la configuration du graphe, avec le filtre période, des infobulles détaillées et un export PNG.
   - Elle affiche la date de la dernière mise à jour des données, et un message clair si les données du jour manquent.
   - Accès réservé aux comptes Elsee (domaine Google Workspace si disponible, sinon liste d'adresses autorisées vérifiée par le script).
   - Le code du script est versionné dans le dépôt Git (par exemple avec clasp).

### Contraintes
- Aucun identifiant utilisateur (user_pseudo_id, ga_session_id) ne sort de BigQuery : la page ne lit que des agrégats.
- Données BigQuery en région UE.
- Aucun secret dans le code ni dans le dépôt.
- Lecture seule sur le dataset d'export GA4 ; écritures limitées au dataset elsee_funnel.
- Ne modifier ni GTM ni GA4 sans accord.
- Ne rien deviner : si une information manque (chemin réel d'une page, accès), la demander.
- Interface et documentation en français.

### Démarche, dans cet ordre, avec validation à chaque étape
0. Lister les informations et accès manquants avant d'écrire du code.
1. Découverte : requêtes qui listent les domaines et les chemins du tunnel avec leurs volumes, et les transitions réellement observées. Tableau de correspondance schéma ↔ données réelles, avec les étapes du schéma introuvables, les pages réelles absentes du schéma, et la destination réelle de chaque raccourci NON. Attendre la validation.
2. Calcul : fichier de configuration du graphe, vues, et un contrôle de cohérence (pour chaque étape, passages sortants + abandons ≈ arrivées).
3. Affichage : application web Apps Script, d'abord en déploiement de test, puis publiée.
4. Automatisation et alertes : e-mail si la table de la veille manque ou si la recréation des vues échoue.
5. Documentation : README (installation, configuration, ajout d'une étape, dépannage) et guide d'utilisation d'une page.

### Recette
- Sur une période d'au moins 7 jours complets après le 5 octobre 2026, rejouer les trois explorations GA4 et comparer les arrivées sur les pages qu'elles ont en commun avec le schéma, en priorité les pages de convergence. Expliquer chaque écart important (consentement aux cookies, modélisation GA4, définition des étapes).
- Attention : si une étape d'une exploration GA4 linéaire est une page sautée par un raccourci NON, l'exploration compte comme abandons les personnes qui ont pris le raccourci. Ses taux d'abandon ne sont alors pas comparables à ceux du schéma.
- Chaque nombre affiché est traçable jusqu'à une requête SQL.
- Le dispositif tourne seul plusieurs jours de suite sans intervention.

### Livrables
Requêtes SQL (découverte et calcul), fichier de configuration du graphe, code Apps Script de la page, README de déploiement, guide d'utilisation.
