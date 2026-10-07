-- Agrégats du tunnel sur une période
-- FICHIER GÉNÉRÉ par scripts/generer_sql.mjs à partir de config/graphe.json :
-- ne pas modifier à la main.
-- Script autonome (dates à régler ci-dessous). Lecture seule.
-- Une ligne par (genre, de, vers, jour). jour vide = toute la période.
--   arrivees          : utilisateurs arrivés sur l'étape « de »
--   continuent        : utilisateurs ayant pris au moins une sortie vers l'avant
--                       (flèche ou saut) ; taux d'abandon = 1 - continuent / arrivees
--   fleche            : utilisateurs passés de « de » à « vers » par une flèche du graphe
--   saut              : passage vers l'avant hors flèche (pages intermédiaires non vues)
--   retour, autre     : retours en arrière et autres passages hors graphe
--   entrees_directes  : utilisateurs dont la session commence sur l'étape (contrôle)
--   non_rattache      : pages à plusieurs parcours sans parcours déductible (contrôle)
-- Cases vides : chiffre non mesurable (suivi www → app), à ne pas afficher.
DECLARE date_debut DATE DEFAULT DATE '2026-10-05';
DECLARE date_fin   DATE DEFAULT DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY);

WITH
etapes AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<id STRING, cle STRING, ordre INT64>>[
    ('signup_corpo', 'app.elsee.care/signup-corpo', 1),
    ('remboursement_complements_alimentaires', 'www.elsee.care/remboursement-complements-alimentaires', 2),
    ('offres_remboursement_elsee', 'www.elsee.care/offres-remboursement-elsee', 3),
    ('obtenir_mon_offre', 'www.elsee.care/obtenir-mon-offre', 4),
    ('signup', 'app.elsee.care/signup', 5),
    ('mon_offre_directe', 'app.elsee.care/mon-offre', 6),
    ('mon_panier_directe', 'app.elsee.care/mon-panier', 7),
    ('bienvenue_directe', 'www.elsee.care/bienvenue-chez-elsee', 8),
    ('social_signup', 'app.elsee.care/social_signup', 9),
    ('depenses_complements', 'app.elsee.care/signup/depenses_complements', 10),
    ('montant_complements', 'app.elsee.care/signup/montant_complements', 11),
    ('network_complements', 'app.elsee.care/signup/network_complements', 12),
    ('recap_marques', 'app.elsee.care/signup/recap_marques', 13),
    ('depenses_complements_step', 'app.elsee.care/signup/depenses_complements_step', 14),
    ('sante_mentale_seances', 'app.elsee.care/signup/sante_mentale_seances', 15),
    ('montant_sante_mentale', 'app.elsee.care/signup/montant_sante_mentale', 16),
    ('md_seances', 'app.elsee.care/signup/md_seances', 17),
    ('montant_medecine_douce', 'app.elsee.care/signup/montant_medecine_douce', 18),
    ('soins_seances', 'app.elsee.care/signup/soins_seances', 19),
    ('montant_soins', 'app.elsee.care/signup/montant_soins', 20),
    ('network_info', 'app.elsee.care/signup/network_info', 21),
    ('prete_a_changer', 'app.elsee.care/signup/prete_a-changer', 22),
    ('medecine_douce_step', 'app.elsee.care/signup/medecine_douce_step', 23),
    ('en_savoir_plus_sur_vous', 'app.elsee.care/signup/en_savoir_plus_sur_vous', 24),
    ('depenses_sports', 'app.elsee.care/signup/depenses_sports', 25),
    ('network_sport', 'app.elsee.care/signup/network_sport', 26),
    ('out_of_network_sport', 'app.elsee.care/signup/out_of_network_sport', 27),
    ('sport_step', 'app.elsee.care/signup/sport_step', 28),
    ('depenses_produit', 'app.elsee.care/signup/depenses_produit', 29),
    ('network_produit', 'app.elsee.care/signup/network_produit', 30),
    ('out_of_network_produit', 'app.elsee.care/signup/out_of_network_produit', 31),
    ('depenses_app', 'app.elsee.care/signup/depenses_app', 32),
    ('out_of_network_app', 'app.elsee.care/signup/out_of_network_app', 33),
    ('final_step', 'app.elsee.care/signup/final_step', 34),
    ('offre_en_preparation', 'app.elsee.care/signup/offre_en_preparation', 35),
    ('sante_mentale_step', 'app.elsee.care/signup/sante_mentale_step', 36),
    ('recap_remboursements', 'app.elsee.care/signup/recap_remboursements', 37),
    ('bonus_abonnement', 'app.elsee.care/signup/bonus-abonnement', 38),
    ('bilan', 'app.elsee.care/signup/bilan', 39),
    ('offres', 'app.elsee.care/offres', 40),
    ('mon_panier_complements', 'app.elsee.care/mon-panier', 41),
    ('bienvenue_complements', 'www.elsee.care/bienvenue-chez-elsee', 42),
    ('mon_offre_long_form', 'app.elsee.care/mon-offre', 43),
    ('mon_panier_long_form', 'app.elsee.care/mon-panier', 44),
    ('bienvenue_long_form', 'www.elsee.care/bienvenue-chez-elsee', 45),
    ('cartecadeau', 'app.elsee.care/pricing/cartecadeau', 46),
    ('mon_panier_carte_cadeau', 'app.elsee.care/mon-panier', 47),
    ('bienvenue_carte_cadeau', 'www.elsee.care/bienvenue-chez-elsee', 48)
  ])
),
chemins AS (
  -- Une ligne par page du graphe ; id_unique est vide si la page porte
  -- plusieurs étapes (une par parcours, ex. /mon-panier).
  SELECT cle, IF(COUNT(*) = 1, ANY_VALUE(id), NULL) AS id_unique
  FROM etapes
  GROUP BY cle
),
fleches AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<de STRING, vers STRING>>[
    ('obtenir_mon_offre', 'signup'),
    ('offres_remboursement_elsee', 'signup'),
    ('remboursement_complements_alimentaires', 'signup'),
    ('signup_corpo', 'signup'),
    ('signup', 'mon_offre_directe'),
    ('mon_offre_directe', 'mon_panier_directe'),
    ('mon_panier_directe', 'bienvenue_directe'),
    ('signup', 'depenses_complements'),
    ('social_signup', 'depenses_complements'),
    ('depenses_complements', 'montant_complements'),
    ('depenses_complements', 'sante_mentale_seances'),
    ('montant_complements', 'network_complements'),
    ('network_complements', 'recap_marques'),
    ('recap_marques', 'depenses_complements_step'),
    ('recap_marques', 'recap_remboursements'),
    ('depenses_complements_step', 'sante_mentale_seances'),
    ('recap_remboursements', 'bonus_abonnement'),
    ('bonus_abonnement', 'bilan'),
    ('bilan', 'offres'),
    ('offres', 'mon_panier_complements'),
    ('mon_panier_complements', 'bienvenue_complements'),
    ('sante_mentale_seances', 'montant_sante_mentale'),
    ('sante_mentale_seances', 'sante_mentale_step'),
    ('montant_sante_mentale', 'md_seances'),
    ('sante_mentale_step', 'md_seances'),
    ('md_seances', 'montant_medecine_douce'),
    ('md_seances', 'soins_seances'),
    ('montant_medecine_douce', 'soins_seances'),
    ('soins_seances', 'montant_soins'),
    ('soins_seances', 'medecine_douce_step'),
    ('montant_soins', 'network_info'),
    ('network_info', 'prete_a_changer'),
    ('prete_a_changer', 'medecine_douce_step'),
    ('medecine_douce_step', 'en_savoir_plus_sur_vous'),
    ('medecine_douce_step', 'depenses_sports'),
    ('en_savoir_plus_sur_vous', 'depenses_sports'),
    ('depenses_sports', 'network_sport'),
    ('depenses_sports', 'sport_step'),
    ('network_sport', 'out_of_network_sport'),
    ('out_of_network_sport', 'sport_step'),
    ('sport_step', 'depenses_produit'),
    ('depenses_produit', 'network_produit'),
    ('depenses_produit', 'depenses_app'),
    ('network_produit', 'out_of_network_produit'),
    ('out_of_network_produit', 'depenses_app'),
    ('depenses_app', 'out_of_network_app'),
    ('depenses_app', 'final_step'),
    ('out_of_network_app', 'final_step'),
    ('final_step', 'offre_en_preparation'),
    ('offre_en_preparation', 'mon_offre_long_form'),
    ('mon_offre_long_form', 'mon_panier_long_form'),
    ('mon_panier_long_form', 'bienvenue_long_form'),
    ('mon_offre_long_form', 'cartecadeau'),
    ('cartecadeau', 'mon_panier_carte_cadeau'),
    ('mon_panier_carte_cadeau', 'bienvenue_carte_cadeau')
  ])
),
atteignables AS (
  -- (de, vers) : vers est plus loin que de en suivant les flèches.
  SELECT * FROM UNNEST(ARRAY<STRUCT<de STRING, vers STRING>>[
    ('signup_corpo', 'bienvenue_carte_cadeau'),
    ('signup_corpo', 'bienvenue_complements'),
    ('signup_corpo', 'bienvenue_directe'),
    ('signup_corpo', 'bienvenue_long_form'),
    ('signup_corpo', 'bilan'),
    ('signup_corpo', 'bonus_abonnement'),
    ('signup_corpo', 'cartecadeau'),
    ('signup_corpo', 'depenses_app'),
    ('signup_corpo', 'depenses_complements'),
    ('signup_corpo', 'depenses_complements_step'),
    ('signup_corpo', 'depenses_produit'),
    ('signup_corpo', 'depenses_sports'),
    ('signup_corpo', 'en_savoir_plus_sur_vous'),
    ('signup_corpo', 'final_step'),
    ('signup_corpo', 'md_seances'),
    ('signup_corpo', 'medecine_douce_step'),
    ('signup_corpo', 'mon_offre_directe'),
    ('signup_corpo', 'mon_offre_long_form'),
    ('signup_corpo', 'mon_panier_carte_cadeau'),
    ('signup_corpo', 'mon_panier_complements'),
    ('signup_corpo', 'mon_panier_directe'),
    ('signup_corpo', 'mon_panier_long_form'),
    ('signup_corpo', 'montant_complements'),
    ('signup_corpo', 'montant_medecine_douce'),
    ('signup_corpo', 'montant_sante_mentale'),
    ('signup_corpo', 'montant_soins'),
    ('signup_corpo', 'network_complements'),
    ('signup_corpo', 'network_info'),
    ('signup_corpo', 'network_produit'),
    ('signup_corpo', 'network_sport'),
    ('signup_corpo', 'offre_en_preparation'),
    ('signup_corpo', 'offres'),
    ('signup_corpo', 'out_of_network_app'),
    ('signup_corpo', 'out_of_network_produit'),
    ('signup_corpo', 'out_of_network_sport'),
    ('signup_corpo', 'prete_a_changer'),
    ('signup_corpo', 'recap_marques'),
    ('signup_corpo', 'recap_remboursements'),
    ('signup_corpo', 'sante_mentale_seances'),
    ('signup_corpo', 'sante_mentale_step'),
    ('signup_corpo', 'signup'),
    ('signup_corpo', 'soins_seances'),
    ('signup_corpo', 'sport_step'),
    ('remboursement_complements_alimentaires', 'bienvenue_carte_cadeau'),
    ('remboursement_complements_alimentaires', 'bienvenue_complements'),
    ('remboursement_complements_alimentaires', 'bienvenue_directe'),
    ('remboursement_complements_alimentaires', 'bienvenue_long_form'),
    ('remboursement_complements_alimentaires', 'bilan'),
    ('remboursement_complements_alimentaires', 'bonus_abonnement'),
    ('remboursement_complements_alimentaires', 'cartecadeau'),
    ('remboursement_complements_alimentaires', 'depenses_app'),
    ('remboursement_complements_alimentaires', 'depenses_complements'),
    ('remboursement_complements_alimentaires', 'depenses_complements_step'),
    ('remboursement_complements_alimentaires', 'depenses_produit'),
    ('remboursement_complements_alimentaires', 'depenses_sports'),
    ('remboursement_complements_alimentaires', 'en_savoir_plus_sur_vous'),
    ('remboursement_complements_alimentaires', 'final_step'),
    ('remboursement_complements_alimentaires', 'md_seances'),
    ('remboursement_complements_alimentaires', 'medecine_douce_step'),
    ('remboursement_complements_alimentaires', 'mon_offre_directe'),
    ('remboursement_complements_alimentaires', 'mon_offre_long_form'),
    ('remboursement_complements_alimentaires', 'mon_panier_carte_cadeau'),
    ('remboursement_complements_alimentaires', 'mon_panier_complements'),
    ('remboursement_complements_alimentaires', 'mon_panier_directe'),
    ('remboursement_complements_alimentaires', 'mon_panier_long_form'),
    ('remboursement_complements_alimentaires', 'montant_complements'),
    ('remboursement_complements_alimentaires', 'montant_medecine_douce'),
    ('remboursement_complements_alimentaires', 'montant_sante_mentale'),
    ('remboursement_complements_alimentaires', 'montant_soins'),
    ('remboursement_complements_alimentaires', 'network_complements'),
    ('remboursement_complements_alimentaires', 'network_info'),
    ('remboursement_complements_alimentaires', 'network_produit'),
    ('remboursement_complements_alimentaires', 'network_sport'),
    ('remboursement_complements_alimentaires', 'offre_en_preparation'),
    ('remboursement_complements_alimentaires', 'offres'),
    ('remboursement_complements_alimentaires', 'out_of_network_app'),
    ('remboursement_complements_alimentaires', 'out_of_network_produit'),
    ('remboursement_complements_alimentaires', 'out_of_network_sport'),
    ('remboursement_complements_alimentaires', 'prete_a_changer'),
    ('remboursement_complements_alimentaires', 'recap_marques'),
    ('remboursement_complements_alimentaires', 'recap_remboursements'),
    ('remboursement_complements_alimentaires', 'sante_mentale_seances'),
    ('remboursement_complements_alimentaires', 'sante_mentale_step'),
    ('remboursement_complements_alimentaires', 'signup'),
    ('remboursement_complements_alimentaires', 'soins_seances'),
    ('remboursement_complements_alimentaires', 'sport_step'),
    ('offres_remboursement_elsee', 'bienvenue_carte_cadeau'),
    ('offres_remboursement_elsee', 'bienvenue_complements'),
    ('offres_remboursement_elsee', 'bienvenue_directe'),
    ('offres_remboursement_elsee', 'bienvenue_long_form'),
    ('offres_remboursement_elsee', 'bilan'),
    ('offres_remboursement_elsee', 'bonus_abonnement'),
    ('offres_remboursement_elsee', 'cartecadeau'),
    ('offres_remboursement_elsee', 'depenses_app'),
    ('offres_remboursement_elsee', 'depenses_complements'),
    ('offres_remboursement_elsee', 'depenses_complements_step'),
    ('offres_remboursement_elsee', 'depenses_produit'),
    ('offres_remboursement_elsee', 'depenses_sports'),
    ('offres_remboursement_elsee', 'en_savoir_plus_sur_vous'),
    ('offres_remboursement_elsee', 'final_step'),
    ('offres_remboursement_elsee', 'md_seances'),
    ('offres_remboursement_elsee', 'medecine_douce_step'),
    ('offres_remboursement_elsee', 'mon_offre_directe'),
    ('offres_remboursement_elsee', 'mon_offre_long_form'),
    ('offres_remboursement_elsee', 'mon_panier_carte_cadeau'),
    ('offres_remboursement_elsee', 'mon_panier_complements'),
    ('offres_remboursement_elsee', 'mon_panier_directe'),
    ('offres_remboursement_elsee', 'mon_panier_long_form'),
    ('offres_remboursement_elsee', 'montant_complements'),
    ('offres_remboursement_elsee', 'montant_medecine_douce'),
    ('offres_remboursement_elsee', 'montant_sante_mentale'),
    ('offres_remboursement_elsee', 'montant_soins'),
    ('offres_remboursement_elsee', 'network_complements'),
    ('offres_remboursement_elsee', 'network_info'),
    ('offres_remboursement_elsee', 'network_produit'),
    ('offres_remboursement_elsee', 'network_sport'),
    ('offres_remboursement_elsee', 'offre_en_preparation'),
    ('offres_remboursement_elsee', 'offres'),
    ('offres_remboursement_elsee', 'out_of_network_app'),
    ('offres_remboursement_elsee', 'out_of_network_produit'),
    ('offres_remboursement_elsee', 'out_of_network_sport'),
    ('offres_remboursement_elsee', 'prete_a_changer'),
    ('offres_remboursement_elsee', 'recap_marques'),
    ('offres_remboursement_elsee', 'recap_remboursements'),
    ('offres_remboursement_elsee', 'sante_mentale_seances'),
    ('offres_remboursement_elsee', 'sante_mentale_step'),
    ('offres_remboursement_elsee', 'signup'),
    ('offres_remboursement_elsee', 'soins_seances'),
    ('offres_remboursement_elsee', 'sport_step'),
    ('obtenir_mon_offre', 'bienvenue_carte_cadeau'),
    ('obtenir_mon_offre', 'bienvenue_complements'),
    ('obtenir_mon_offre', 'bienvenue_directe'),
    ('obtenir_mon_offre', 'bienvenue_long_form'),
    ('obtenir_mon_offre', 'bilan'),
    ('obtenir_mon_offre', 'bonus_abonnement'),
    ('obtenir_mon_offre', 'cartecadeau'),
    ('obtenir_mon_offre', 'depenses_app'),
    ('obtenir_mon_offre', 'depenses_complements'),
    ('obtenir_mon_offre', 'depenses_complements_step'),
    ('obtenir_mon_offre', 'depenses_produit'),
    ('obtenir_mon_offre', 'depenses_sports'),
    ('obtenir_mon_offre', 'en_savoir_plus_sur_vous'),
    ('obtenir_mon_offre', 'final_step'),
    ('obtenir_mon_offre', 'md_seances'),
    ('obtenir_mon_offre', 'medecine_douce_step'),
    ('obtenir_mon_offre', 'mon_offre_directe'),
    ('obtenir_mon_offre', 'mon_offre_long_form'),
    ('obtenir_mon_offre', 'mon_panier_carte_cadeau'),
    ('obtenir_mon_offre', 'mon_panier_complements'),
    ('obtenir_mon_offre', 'mon_panier_directe'),
    ('obtenir_mon_offre', 'mon_panier_long_form'),
    ('obtenir_mon_offre', 'montant_complements'),
    ('obtenir_mon_offre', 'montant_medecine_douce'),
    ('obtenir_mon_offre', 'montant_sante_mentale'),
    ('obtenir_mon_offre', 'montant_soins'),
    ('obtenir_mon_offre', 'network_complements'),
    ('obtenir_mon_offre', 'network_info'),
    ('obtenir_mon_offre', 'network_produit'),
    ('obtenir_mon_offre', 'network_sport'),
    ('obtenir_mon_offre', 'offre_en_preparation'),
    ('obtenir_mon_offre', 'offres'),
    ('obtenir_mon_offre', 'out_of_network_app'),
    ('obtenir_mon_offre', 'out_of_network_produit'),
    ('obtenir_mon_offre', 'out_of_network_sport'),
    ('obtenir_mon_offre', 'prete_a_changer'),
    ('obtenir_mon_offre', 'recap_marques'),
    ('obtenir_mon_offre', 'recap_remboursements'),
    ('obtenir_mon_offre', 'sante_mentale_seances'),
    ('obtenir_mon_offre', 'sante_mentale_step'),
    ('obtenir_mon_offre', 'signup'),
    ('obtenir_mon_offre', 'soins_seances'),
    ('obtenir_mon_offre', 'sport_step'),
    ('signup', 'bienvenue_carte_cadeau'),
    ('signup', 'bienvenue_complements'),
    ('signup', 'bienvenue_directe'),
    ('signup', 'bienvenue_long_form'),
    ('signup', 'bilan'),
    ('signup', 'bonus_abonnement'),
    ('signup', 'cartecadeau'),
    ('signup', 'depenses_app'),
    ('signup', 'depenses_complements'),
    ('signup', 'depenses_complements_step'),
    ('signup', 'depenses_produit'),
    ('signup', 'depenses_sports'),
    ('signup', 'en_savoir_plus_sur_vous'),
    ('signup', 'final_step'),
    ('signup', 'md_seances'),
    ('signup', 'medecine_douce_step'),
    ('signup', 'mon_offre_directe'),
    ('signup', 'mon_offre_long_form'),
    ('signup', 'mon_panier_carte_cadeau'),
    ('signup', 'mon_panier_complements'),
    ('signup', 'mon_panier_directe'),
    ('signup', 'mon_panier_long_form'),
    ('signup', 'montant_complements'),
    ('signup', 'montant_medecine_douce'),
    ('signup', 'montant_sante_mentale'),
    ('signup', 'montant_soins'),
    ('signup', 'network_complements'),
    ('signup', 'network_info'),
    ('signup', 'network_produit'),
    ('signup', 'network_sport'),
    ('signup', 'offre_en_preparation'),
    ('signup', 'offres'),
    ('signup', 'out_of_network_app'),
    ('signup', 'out_of_network_produit'),
    ('signup', 'out_of_network_sport'),
    ('signup', 'prete_a_changer'),
    ('signup', 'recap_marques'),
    ('signup', 'recap_remboursements'),
    ('signup', 'sante_mentale_seances'),
    ('signup', 'sante_mentale_step'),
    ('signup', 'soins_seances'),
    ('signup', 'sport_step'),
    ('mon_offre_directe', 'bienvenue_directe'),
    ('mon_offre_directe', 'mon_panier_directe'),
    ('mon_panier_directe', 'bienvenue_directe'),
    ('social_signup', 'bienvenue_carte_cadeau'),
    ('social_signup', 'bienvenue_complements'),
    ('social_signup', 'bienvenue_long_form'),
    ('social_signup', 'bilan'),
    ('social_signup', 'bonus_abonnement'),
    ('social_signup', 'cartecadeau'),
    ('social_signup', 'depenses_app'),
    ('social_signup', 'depenses_complements'),
    ('social_signup', 'depenses_complements_step'),
    ('social_signup', 'depenses_produit'),
    ('social_signup', 'depenses_sports'),
    ('social_signup', 'en_savoir_plus_sur_vous'),
    ('social_signup', 'final_step'),
    ('social_signup', 'md_seances'),
    ('social_signup', 'medecine_douce_step'),
    ('social_signup', 'mon_offre_long_form'),
    ('social_signup', 'mon_panier_carte_cadeau'),
    ('social_signup', 'mon_panier_complements'),
    ('social_signup', 'mon_panier_long_form'),
    ('social_signup', 'montant_complements'),
    ('social_signup', 'montant_medecine_douce'),
    ('social_signup', 'montant_sante_mentale'),
    ('social_signup', 'montant_soins'),
    ('social_signup', 'network_complements'),
    ('social_signup', 'network_info'),
    ('social_signup', 'network_produit'),
    ('social_signup', 'network_sport'),
    ('social_signup', 'offre_en_preparation'),
    ('social_signup', 'offres'),
    ('social_signup', 'out_of_network_app'),
    ('social_signup', 'out_of_network_produit'),
    ('social_signup', 'out_of_network_sport'),
    ('social_signup', 'prete_a_changer'),
    ('social_signup', 'recap_marques'),
    ('social_signup', 'recap_remboursements'),
    ('social_signup', 'sante_mentale_seances'),
    ('social_signup', 'sante_mentale_step'),
    ('social_signup', 'soins_seances'),
    ('social_signup', 'sport_step'),
    ('depenses_complements', 'bienvenue_carte_cadeau'),
    ('depenses_complements', 'bienvenue_complements'),
    ('depenses_complements', 'bienvenue_long_form'),
    ('depenses_complements', 'bilan'),
    ('depenses_complements', 'bonus_abonnement'),
    ('depenses_complements', 'cartecadeau'),
    ('depenses_complements', 'depenses_app'),
    ('depenses_complements', 'depenses_complements_step'),
    ('depenses_complements', 'depenses_produit'),
    ('depenses_complements', 'depenses_sports'),
    ('depenses_complements', 'en_savoir_plus_sur_vous'),
    ('depenses_complements', 'final_step'),
    ('depenses_complements', 'md_seances'),
    ('depenses_complements', 'medecine_douce_step'),
    ('depenses_complements', 'mon_offre_long_form'),
    ('depenses_complements', 'mon_panier_carte_cadeau'),
    ('depenses_complements', 'mon_panier_complements'),
    ('depenses_complements', 'mon_panier_long_form'),
    ('depenses_complements', 'montant_complements'),
    ('depenses_complements', 'montant_medecine_douce'),
    ('depenses_complements', 'montant_sante_mentale'),
    ('depenses_complements', 'montant_soins'),
    ('depenses_complements', 'network_complements'),
    ('depenses_complements', 'network_info'),
    ('depenses_complements', 'network_produit'),
    ('depenses_complements', 'network_sport'),
    ('depenses_complements', 'offre_en_preparation'),
    ('depenses_complements', 'offres'),
    ('depenses_complements', 'out_of_network_app'),
    ('depenses_complements', 'out_of_network_produit'),
    ('depenses_complements', 'out_of_network_sport'),
    ('depenses_complements', 'prete_a_changer'),
    ('depenses_complements', 'recap_marques'),
    ('depenses_complements', 'recap_remboursements'),
    ('depenses_complements', 'sante_mentale_seances'),
    ('depenses_complements', 'sante_mentale_step'),
    ('depenses_complements', 'soins_seances'),
    ('depenses_complements', 'sport_step'),
    ('montant_complements', 'bienvenue_carte_cadeau'),
    ('montant_complements', 'bienvenue_complements'),
    ('montant_complements', 'bienvenue_long_form'),
    ('montant_complements', 'bilan'),
    ('montant_complements', 'bonus_abonnement'),
    ('montant_complements', 'cartecadeau'),
    ('montant_complements', 'depenses_app'),
    ('montant_complements', 'depenses_complements_step'),
    ('montant_complements', 'depenses_produit'),
    ('montant_complements', 'depenses_sports'),
    ('montant_complements', 'en_savoir_plus_sur_vous'),
    ('montant_complements', 'final_step'),
    ('montant_complements', 'md_seances'),
    ('montant_complements', 'medecine_douce_step'),
    ('montant_complements', 'mon_offre_long_form'),
    ('montant_complements', 'mon_panier_carte_cadeau'),
    ('montant_complements', 'mon_panier_complements'),
    ('montant_complements', 'mon_panier_long_form'),
    ('montant_complements', 'montant_medecine_douce'),
    ('montant_complements', 'montant_sante_mentale'),
    ('montant_complements', 'montant_soins'),
    ('montant_complements', 'network_complements'),
    ('montant_complements', 'network_info'),
    ('montant_complements', 'network_produit'),
    ('montant_complements', 'network_sport'),
    ('montant_complements', 'offre_en_preparation'),
    ('montant_complements', 'offres'),
    ('montant_complements', 'out_of_network_app'),
    ('montant_complements', 'out_of_network_produit'),
    ('montant_complements', 'out_of_network_sport'),
    ('montant_complements', 'prete_a_changer'),
    ('montant_complements', 'recap_marques'),
    ('montant_complements', 'recap_remboursements'),
    ('montant_complements', 'sante_mentale_seances'),
    ('montant_complements', 'sante_mentale_step'),
    ('montant_complements', 'soins_seances'),
    ('montant_complements', 'sport_step'),
    ('network_complements', 'bienvenue_carte_cadeau'),
    ('network_complements', 'bienvenue_complements'),
    ('network_complements', 'bienvenue_long_form'),
    ('network_complements', 'bilan'),
    ('network_complements', 'bonus_abonnement'),
    ('network_complements', 'cartecadeau'),
    ('network_complements', 'depenses_app'),
    ('network_complements', 'depenses_complements_step'),
    ('network_complements', 'depenses_produit'),
    ('network_complements', 'depenses_sports'),
    ('network_complements', 'en_savoir_plus_sur_vous'),
    ('network_complements', 'final_step'),
    ('network_complements', 'md_seances'),
    ('network_complements', 'medecine_douce_step'),
    ('network_complements', 'mon_offre_long_form'),
    ('network_complements', 'mon_panier_carte_cadeau'),
    ('network_complements', 'mon_panier_complements'),
    ('network_complements', 'mon_panier_long_form'),
    ('network_complements', 'montant_medecine_douce'),
    ('network_complements', 'montant_sante_mentale'),
    ('network_complements', 'montant_soins'),
    ('network_complements', 'network_info'),
    ('network_complements', 'network_produit'),
    ('network_complements', 'network_sport'),
    ('network_complements', 'offre_en_preparation'),
    ('network_complements', 'offres'),
    ('network_complements', 'out_of_network_app'),
    ('network_complements', 'out_of_network_produit'),
    ('network_complements', 'out_of_network_sport'),
    ('network_complements', 'prete_a_changer'),
    ('network_complements', 'recap_marques'),
    ('network_complements', 'recap_remboursements'),
    ('network_complements', 'sante_mentale_seances'),
    ('network_complements', 'sante_mentale_step'),
    ('network_complements', 'soins_seances'),
    ('network_complements', 'sport_step'),
    ('recap_marques', 'bienvenue_carte_cadeau'),
    ('recap_marques', 'bienvenue_complements'),
    ('recap_marques', 'bienvenue_long_form'),
    ('recap_marques', 'bilan'),
    ('recap_marques', 'bonus_abonnement'),
    ('recap_marques', 'cartecadeau'),
    ('recap_marques', 'depenses_app'),
    ('recap_marques', 'depenses_complements_step'),
    ('recap_marques', 'depenses_produit'),
    ('recap_marques', 'depenses_sports'),
    ('recap_marques', 'en_savoir_plus_sur_vous'),
    ('recap_marques', 'final_step'),
    ('recap_marques', 'md_seances'),
    ('recap_marques', 'medecine_douce_step'),
    ('recap_marques', 'mon_offre_long_form'),
    ('recap_marques', 'mon_panier_carte_cadeau'),
    ('recap_marques', 'mon_panier_complements'),
    ('recap_marques', 'mon_panier_long_form'),
    ('recap_marques', 'montant_medecine_douce'),
    ('recap_marques', 'montant_sante_mentale'),
    ('recap_marques', 'montant_soins'),
    ('recap_marques', 'network_info'),
    ('recap_marques', 'network_produit'),
    ('recap_marques', 'network_sport'),
    ('recap_marques', 'offre_en_preparation'),
    ('recap_marques', 'offres'),
    ('recap_marques', 'out_of_network_app'),
    ('recap_marques', 'out_of_network_produit'),
    ('recap_marques', 'out_of_network_sport'),
    ('recap_marques', 'prete_a_changer'),
    ('recap_marques', 'recap_remboursements'),
    ('recap_marques', 'sante_mentale_seances'),
    ('recap_marques', 'sante_mentale_step'),
    ('recap_marques', 'soins_seances'),
    ('recap_marques', 'sport_step'),
    ('depenses_complements_step', 'bienvenue_carte_cadeau'),
    ('depenses_complements_step', 'bienvenue_long_form'),
    ('depenses_complements_step', 'cartecadeau'),
    ('depenses_complements_step', 'depenses_app'),
    ('depenses_complements_step', 'depenses_produit'),
    ('depenses_complements_step', 'depenses_sports'),
    ('depenses_complements_step', 'en_savoir_plus_sur_vous'),
    ('depenses_complements_step', 'final_step'),
    ('depenses_complements_step', 'md_seances'),
    ('depenses_complements_step', 'medecine_douce_step'),
    ('depenses_complements_step', 'mon_offre_long_form'),
    ('depenses_complements_step', 'mon_panier_carte_cadeau'),
    ('depenses_complements_step', 'mon_panier_long_form'),
    ('depenses_complements_step', 'montant_medecine_douce'),
    ('depenses_complements_step', 'montant_sante_mentale'),
    ('depenses_complements_step', 'montant_soins'),
    ('depenses_complements_step', 'network_info'),
    ('depenses_complements_step', 'network_produit'),
    ('depenses_complements_step', 'network_sport'),
    ('depenses_complements_step', 'offre_en_preparation'),
    ('depenses_complements_step', 'out_of_network_app'),
    ('depenses_complements_step', 'out_of_network_produit'),
    ('depenses_complements_step', 'out_of_network_sport'),
    ('depenses_complements_step', 'prete_a_changer'),
    ('depenses_complements_step', 'sante_mentale_seances'),
    ('depenses_complements_step', 'sante_mentale_step'),
    ('depenses_complements_step', 'soins_seances'),
    ('depenses_complements_step', 'sport_step'),
    ('sante_mentale_seances', 'bienvenue_carte_cadeau'),
    ('sante_mentale_seances', 'bienvenue_long_form'),
    ('sante_mentale_seances', 'cartecadeau'),
    ('sante_mentale_seances', 'depenses_app'),
    ('sante_mentale_seances', 'depenses_produit'),
    ('sante_mentale_seances', 'depenses_sports'),
    ('sante_mentale_seances', 'en_savoir_plus_sur_vous'),
    ('sante_mentale_seances', 'final_step'),
    ('sante_mentale_seances', 'md_seances'),
    ('sante_mentale_seances', 'medecine_douce_step'),
    ('sante_mentale_seances', 'mon_offre_long_form'),
    ('sante_mentale_seances', 'mon_panier_carte_cadeau'),
    ('sante_mentale_seances', 'mon_panier_long_form'),
    ('sante_mentale_seances', 'montant_medecine_douce'),
    ('sante_mentale_seances', 'montant_sante_mentale'),
    ('sante_mentale_seances', 'montant_soins'),
    ('sante_mentale_seances', 'network_info'),
    ('sante_mentale_seances', 'network_produit'),
    ('sante_mentale_seances', 'network_sport'),
    ('sante_mentale_seances', 'offre_en_preparation'),
    ('sante_mentale_seances', 'out_of_network_app'),
    ('sante_mentale_seances', 'out_of_network_produit'),
    ('sante_mentale_seances', 'out_of_network_sport'),
    ('sante_mentale_seances', 'prete_a_changer'),
    ('sante_mentale_seances', 'sante_mentale_step'),
    ('sante_mentale_seances', 'soins_seances'),
    ('sante_mentale_seances', 'sport_step'),
    ('montant_sante_mentale', 'bienvenue_carte_cadeau'),
    ('montant_sante_mentale', 'bienvenue_long_form'),
    ('montant_sante_mentale', 'cartecadeau'),
    ('montant_sante_mentale', 'depenses_app'),
    ('montant_sante_mentale', 'depenses_produit'),
    ('montant_sante_mentale', 'depenses_sports'),
    ('montant_sante_mentale', 'en_savoir_plus_sur_vous'),
    ('montant_sante_mentale', 'final_step'),
    ('montant_sante_mentale', 'md_seances'),
    ('montant_sante_mentale', 'medecine_douce_step'),
    ('montant_sante_mentale', 'mon_offre_long_form'),
    ('montant_sante_mentale', 'mon_panier_carte_cadeau'),
    ('montant_sante_mentale', 'mon_panier_long_form'),
    ('montant_sante_mentale', 'montant_medecine_douce'),
    ('montant_sante_mentale', 'montant_soins'),
    ('montant_sante_mentale', 'network_info'),
    ('montant_sante_mentale', 'network_produit'),
    ('montant_sante_mentale', 'network_sport'),
    ('montant_sante_mentale', 'offre_en_preparation'),
    ('montant_sante_mentale', 'out_of_network_app'),
    ('montant_sante_mentale', 'out_of_network_produit'),
    ('montant_sante_mentale', 'out_of_network_sport'),
    ('montant_sante_mentale', 'prete_a_changer'),
    ('montant_sante_mentale', 'soins_seances'),
    ('montant_sante_mentale', 'sport_step'),
    ('md_seances', 'bienvenue_carte_cadeau'),
    ('md_seances', 'bienvenue_long_form'),
    ('md_seances', 'cartecadeau'),
    ('md_seances', 'depenses_app'),
    ('md_seances', 'depenses_produit'),
    ('md_seances', 'depenses_sports'),
    ('md_seances', 'en_savoir_plus_sur_vous'),
    ('md_seances', 'final_step'),
    ('md_seances', 'medecine_douce_step'),
    ('md_seances', 'mon_offre_long_form'),
    ('md_seances', 'mon_panier_carte_cadeau'),
    ('md_seances', 'mon_panier_long_form'),
    ('md_seances', 'montant_medecine_douce'),
    ('md_seances', 'montant_soins'),
    ('md_seances', 'network_info'),
    ('md_seances', 'network_produit'),
    ('md_seances', 'network_sport'),
    ('md_seances', 'offre_en_preparation'),
    ('md_seances', 'out_of_network_app'),
    ('md_seances', 'out_of_network_produit'),
    ('md_seances', 'out_of_network_sport'),
    ('md_seances', 'prete_a_changer'),
    ('md_seances', 'soins_seances'),
    ('md_seances', 'sport_step'),
    ('montant_medecine_douce', 'bienvenue_carte_cadeau'),
    ('montant_medecine_douce', 'bienvenue_long_form'),
    ('montant_medecine_douce', 'cartecadeau'),
    ('montant_medecine_douce', 'depenses_app'),
    ('montant_medecine_douce', 'depenses_produit'),
    ('montant_medecine_douce', 'depenses_sports'),
    ('montant_medecine_douce', 'en_savoir_plus_sur_vous'),
    ('montant_medecine_douce', 'final_step'),
    ('montant_medecine_douce', 'medecine_douce_step'),
    ('montant_medecine_douce', 'mon_offre_long_form'),
    ('montant_medecine_douce', 'mon_panier_carte_cadeau'),
    ('montant_medecine_douce', 'mon_panier_long_form'),
    ('montant_medecine_douce', 'montant_soins'),
    ('montant_medecine_douce', 'network_info'),
    ('montant_medecine_douce', 'network_produit'),
    ('montant_medecine_douce', 'network_sport'),
    ('montant_medecine_douce', 'offre_en_preparation'),
    ('montant_medecine_douce', 'out_of_network_app'),
    ('montant_medecine_douce', 'out_of_network_produit'),
    ('montant_medecine_douce', 'out_of_network_sport'),
    ('montant_medecine_douce', 'prete_a_changer'),
    ('montant_medecine_douce', 'soins_seances'),
    ('montant_medecine_douce', 'sport_step'),
    ('soins_seances', 'bienvenue_carte_cadeau'),
    ('soins_seances', 'bienvenue_long_form'),
    ('soins_seances', 'cartecadeau'),
    ('soins_seances', 'depenses_app'),
    ('soins_seances', 'depenses_produit'),
    ('soins_seances', 'depenses_sports'),
    ('soins_seances', 'en_savoir_plus_sur_vous'),
    ('soins_seances', 'final_step'),
    ('soins_seances', 'medecine_douce_step'),
    ('soins_seances', 'mon_offre_long_form'),
    ('soins_seances', 'mon_panier_carte_cadeau'),
    ('soins_seances', 'mon_panier_long_form'),
    ('soins_seances', 'montant_soins'),
    ('soins_seances', 'network_info'),
    ('soins_seances', 'network_produit'),
    ('soins_seances', 'network_sport'),
    ('soins_seances', 'offre_en_preparation'),
    ('soins_seances', 'out_of_network_app'),
    ('soins_seances', 'out_of_network_produit'),
    ('soins_seances', 'out_of_network_sport'),
    ('soins_seances', 'prete_a_changer'),
    ('soins_seances', 'sport_step'),
    ('montant_soins', 'bienvenue_carte_cadeau'),
    ('montant_soins', 'bienvenue_long_form'),
    ('montant_soins', 'cartecadeau'),
    ('montant_soins', 'depenses_app'),
    ('montant_soins', 'depenses_produit'),
    ('montant_soins', 'depenses_sports'),
    ('montant_soins', 'en_savoir_plus_sur_vous'),
    ('montant_soins', 'final_step'),
    ('montant_soins', 'medecine_douce_step'),
    ('montant_soins', 'mon_offre_long_form'),
    ('montant_soins', 'mon_panier_carte_cadeau'),
    ('montant_soins', 'mon_panier_long_form'),
    ('montant_soins', 'network_info'),
    ('montant_soins', 'network_produit'),
    ('montant_soins', 'network_sport'),
    ('montant_soins', 'offre_en_preparation'),
    ('montant_soins', 'out_of_network_app'),
    ('montant_soins', 'out_of_network_produit'),
    ('montant_soins', 'out_of_network_sport'),
    ('montant_soins', 'prete_a_changer'),
    ('montant_soins', 'sport_step'),
    ('network_info', 'bienvenue_carte_cadeau'),
    ('network_info', 'bienvenue_long_form'),
    ('network_info', 'cartecadeau'),
    ('network_info', 'depenses_app'),
    ('network_info', 'depenses_produit'),
    ('network_info', 'depenses_sports'),
    ('network_info', 'en_savoir_plus_sur_vous'),
    ('network_info', 'final_step'),
    ('network_info', 'medecine_douce_step'),
    ('network_info', 'mon_offre_long_form'),
    ('network_info', 'mon_panier_carte_cadeau'),
    ('network_info', 'mon_panier_long_form'),
    ('network_info', 'network_produit'),
    ('network_info', 'network_sport'),
    ('network_info', 'offre_en_preparation'),
    ('network_info', 'out_of_network_app'),
    ('network_info', 'out_of_network_produit'),
    ('network_info', 'out_of_network_sport'),
    ('network_info', 'prete_a_changer'),
    ('network_info', 'sport_step'),
    ('prete_a_changer', 'bienvenue_carte_cadeau'),
    ('prete_a_changer', 'bienvenue_long_form'),
    ('prete_a_changer', 'cartecadeau'),
    ('prete_a_changer', 'depenses_app'),
    ('prete_a_changer', 'depenses_produit'),
    ('prete_a_changer', 'depenses_sports'),
    ('prete_a_changer', 'en_savoir_plus_sur_vous'),
    ('prete_a_changer', 'final_step'),
    ('prete_a_changer', 'medecine_douce_step'),
    ('prete_a_changer', 'mon_offre_long_form'),
    ('prete_a_changer', 'mon_panier_carte_cadeau'),
    ('prete_a_changer', 'mon_panier_long_form'),
    ('prete_a_changer', 'network_produit'),
    ('prete_a_changer', 'network_sport'),
    ('prete_a_changer', 'offre_en_preparation'),
    ('prete_a_changer', 'out_of_network_app'),
    ('prete_a_changer', 'out_of_network_produit'),
    ('prete_a_changer', 'out_of_network_sport'),
    ('prete_a_changer', 'sport_step'),
    ('medecine_douce_step', 'bienvenue_carte_cadeau'),
    ('medecine_douce_step', 'bienvenue_long_form'),
    ('medecine_douce_step', 'cartecadeau'),
    ('medecine_douce_step', 'depenses_app'),
    ('medecine_douce_step', 'depenses_produit'),
    ('medecine_douce_step', 'depenses_sports'),
    ('medecine_douce_step', 'en_savoir_plus_sur_vous'),
    ('medecine_douce_step', 'final_step'),
    ('medecine_douce_step', 'mon_offre_long_form'),
    ('medecine_douce_step', 'mon_panier_carte_cadeau'),
    ('medecine_douce_step', 'mon_panier_long_form'),
    ('medecine_douce_step', 'network_produit'),
    ('medecine_douce_step', 'network_sport'),
    ('medecine_douce_step', 'offre_en_preparation'),
    ('medecine_douce_step', 'out_of_network_app'),
    ('medecine_douce_step', 'out_of_network_produit'),
    ('medecine_douce_step', 'out_of_network_sport'),
    ('medecine_douce_step', 'sport_step'),
    ('en_savoir_plus_sur_vous', 'bienvenue_carte_cadeau'),
    ('en_savoir_plus_sur_vous', 'bienvenue_long_form'),
    ('en_savoir_plus_sur_vous', 'cartecadeau'),
    ('en_savoir_plus_sur_vous', 'depenses_app'),
    ('en_savoir_plus_sur_vous', 'depenses_produit'),
    ('en_savoir_plus_sur_vous', 'depenses_sports'),
    ('en_savoir_plus_sur_vous', 'final_step'),
    ('en_savoir_plus_sur_vous', 'mon_offre_long_form'),
    ('en_savoir_plus_sur_vous', 'mon_panier_carte_cadeau'),
    ('en_savoir_plus_sur_vous', 'mon_panier_long_form'),
    ('en_savoir_plus_sur_vous', 'network_produit'),
    ('en_savoir_plus_sur_vous', 'network_sport'),
    ('en_savoir_plus_sur_vous', 'offre_en_preparation'),
    ('en_savoir_plus_sur_vous', 'out_of_network_app'),
    ('en_savoir_plus_sur_vous', 'out_of_network_produit'),
    ('en_savoir_plus_sur_vous', 'out_of_network_sport'),
    ('en_savoir_plus_sur_vous', 'sport_step'),
    ('depenses_sports', 'bienvenue_carte_cadeau'),
    ('depenses_sports', 'bienvenue_long_form'),
    ('depenses_sports', 'cartecadeau'),
    ('depenses_sports', 'depenses_app'),
    ('depenses_sports', 'depenses_produit'),
    ('depenses_sports', 'final_step'),
    ('depenses_sports', 'mon_offre_long_form'),
    ('depenses_sports', 'mon_panier_carte_cadeau'),
    ('depenses_sports', 'mon_panier_long_form'),
    ('depenses_sports', 'network_produit'),
    ('depenses_sports', 'network_sport'),
    ('depenses_sports', 'offre_en_preparation'),
    ('depenses_sports', 'out_of_network_app'),
    ('depenses_sports', 'out_of_network_produit'),
    ('depenses_sports', 'out_of_network_sport'),
    ('depenses_sports', 'sport_step'),
    ('network_sport', 'bienvenue_carte_cadeau'),
    ('network_sport', 'bienvenue_long_form'),
    ('network_sport', 'cartecadeau'),
    ('network_sport', 'depenses_app'),
    ('network_sport', 'depenses_produit'),
    ('network_sport', 'final_step'),
    ('network_sport', 'mon_offre_long_form'),
    ('network_sport', 'mon_panier_carte_cadeau'),
    ('network_sport', 'mon_panier_long_form'),
    ('network_sport', 'network_produit'),
    ('network_sport', 'offre_en_preparation'),
    ('network_sport', 'out_of_network_app'),
    ('network_sport', 'out_of_network_produit'),
    ('network_sport', 'out_of_network_sport'),
    ('network_sport', 'sport_step'),
    ('out_of_network_sport', 'bienvenue_carte_cadeau'),
    ('out_of_network_sport', 'bienvenue_long_form'),
    ('out_of_network_sport', 'cartecadeau'),
    ('out_of_network_sport', 'depenses_app'),
    ('out_of_network_sport', 'depenses_produit'),
    ('out_of_network_sport', 'final_step'),
    ('out_of_network_sport', 'mon_offre_long_form'),
    ('out_of_network_sport', 'mon_panier_carte_cadeau'),
    ('out_of_network_sport', 'mon_panier_long_form'),
    ('out_of_network_sport', 'network_produit'),
    ('out_of_network_sport', 'offre_en_preparation'),
    ('out_of_network_sport', 'out_of_network_app'),
    ('out_of_network_sport', 'out_of_network_produit'),
    ('out_of_network_sport', 'sport_step'),
    ('sport_step', 'bienvenue_carte_cadeau'),
    ('sport_step', 'bienvenue_long_form'),
    ('sport_step', 'cartecadeau'),
    ('sport_step', 'depenses_app'),
    ('sport_step', 'depenses_produit'),
    ('sport_step', 'final_step'),
    ('sport_step', 'mon_offre_long_form'),
    ('sport_step', 'mon_panier_carte_cadeau'),
    ('sport_step', 'mon_panier_long_form'),
    ('sport_step', 'network_produit'),
    ('sport_step', 'offre_en_preparation'),
    ('sport_step', 'out_of_network_app'),
    ('sport_step', 'out_of_network_produit'),
    ('depenses_produit', 'bienvenue_carte_cadeau'),
    ('depenses_produit', 'bienvenue_long_form'),
    ('depenses_produit', 'cartecadeau'),
    ('depenses_produit', 'depenses_app'),
    ('depenses_produit', 'final_step'),
    ('depenses_produit', 'mon_offre_long_form'),
    ('depenses_produit', 'mon_panier_carte_cadeau'),
    ('depenses_produit', 'mon_panier_long_form'),
    ('depenses_produit', 'network_produit'),
    ('depenses_produit', 'offre_en_preparation'),
    ('depenses_produit', 'out_of_network_app'),
    ('depenses_produit', 'out_of_network_produit'),
    ('network_produit', 'bienvenue_carte_cadeau'),
    ('network_produit', 'bienvenue_long_form'),
    ('network_produit', 'cartecadeau'),
    ('network_produit', 'depenses_app'),
    ('network_produit', 'final_step'),
    ('network_produit', 'mon_offre_long_form'),
    ('network_produit', 'mon_panier_carte_cadeau'),
    ('network_produit', 'mon_panier_long_form'),
    ('network_produit', 'offre_en_preparation'),
    ('network_produit', 'out_of_network_app'),
    ('network_produit', 'out_of_network_produit'),
    ('out_of_network_produit', 'bienvenue_carte_cadeau'),
    ('out_of_network_produit', 'bienvenue_long_form'),
    ('out_of_network_produit', 'cartecadeau'),
    ('out_of_network_produit', 'depenses_app'),
    ('out_of_network_produit', 'final_step'),
    ('out_of_network_produit', 'mon_offre_long_form'),
    ('out_of_network_produit', 'mon_panier_carte_cadeau'),
    ('out_of_network_produit', 'mon_panier_long_form'),
    ('out_of_network_produit', 'offre_en_preparation'),
    ('out_of_network_produit', 'out_of_network_app'),
    ('depenses_app', 'bienvenue_carte_cadeau'),
    ('depenses_app', 'bienvenue_long_form'),
    ('depenses_app', 'cartecadeau'),
    ('depenses_app', 'final_step'),
    ('depenses_app', 'mon_offre_long_form'),
    ('depenses_app', 'mon_panier_carte_cadeau'),
    ('depenses_app', 'mon_panier_long_form'),
    ('depenses_app', 'offre_en_preparation'),
    ('depenses_app', 'out_of_network_app'),
    ('out_of_network_app', 'bienvenue_carte_cadeau'),
    ('out_of_network_app', 'bienvenue_long_form'),
    ('out_of_network_app', 'cartecadeau'),
    ('out_of_network_app', 'final_step'),
    ('out_of_network_app', 'mon_offre_long_form'),
    ('out_of_network_app', 'mon_panier_carte_cadeau'),
    ('out_of_network_app', 'mon_panier_long_form'),
    ('out_of_network_app', 'offre_en_preparation'),
    ('final_step', 'bienvenue_carte_cadeau'),
    ('final_step', 'bienvenue_long_form'),
    ('final_step', 'cartecadeau'),
    ('final_step', 'mon_offre_long_form'),
    ('final_step', 'mon_panier_carte_cadeau'),
    ('final_step', 'mon_panier_long_form'),
    ('final_step', 'offre_en_preparation'),
    ('offre_en_preparation', 'bienvenue_carte_cadeau'),
    ('offre_en_preparation', 'bienvenue_long_form'),
    ('offre_en_preparation', 'cartecadeau'),
    ('offre_en_preparation', 'mon_offre_long_form'),
    ('offre_en_preparation', 'mon_panier_carte_cadeau'),
    ('offre_en_preparation', 'mon_panier_long_form'),
    ('sante_mentale_step', 'bienvenue_carte_cadeau'),
    ('sante_mentale_step', 'bienvenue_long_form'),
    ('sante_mentale_step', 'cartecadeau'),
    ('sante_mentale_step', 'depenses_app'),
    ('sante_mentale_step', 'depenses_produit'),
    ('sante_mentale_step', 'depenses_sports'),
    ('sante_mentale_step', 'en_savoir_plus_sur_vous'),
    ('sante_mentale_step', 'final_step'),
    ('sante_mentale_step', 'md_seances'),
    ('sante_mentale_step', 'medecine_douce_step'),
    ('sante_mentale_step', 'mon_offre_long_form'),
    ('sante_mentale_step', 'mon_panier_carte_cadeau'),
    ('sante_mentale_step', 'mon_panier_long_form'),
    ('sante_mentale_step', 'montant_medecine_douce'),
    ('sante_mentale_step', 'montant_soins'),
    ('sante_mentale_step', 'network_info'),
    ('sante_mentale_step', 'network_produit'),
    ('sante_mentale_step', 'network_sport'),
    ('sante_mentale_step', 'offre_en_preparation'),
    ('sante_mentale_step', 'out_of_network_app'),
    ('sante_mentale_step', 'out_of_network_produit'),
    ('sante_mentale_step', 'out_of_network_sport'),
    ('sante_mentale_step', 'prete_a_changer'),
    ('sante_mentale_step', 'soins_seances'),
    ('sante_mentale_step', 'sport_step'),
    ('recap_remboursements', 'bienvenue_complements'),
    ('recap_remboursements', 'bilan'),
    ('recap_remboursements', 'bonus_abonnement'),
    ('recap_remboursements', 'mon_panier_complements'),
    ('recap_remboursements', 'offres'),
    ('bonus_abonnement', 'bienvenue_complements'),
    ('bonus_abonnement', 'bilan'),
    ('bonus_abonnement', 'mon_panier_complements'),
    ('bonus_abonnement', 'offres'),
    ('bilan', 'bienvenue_complements'),
    ('bilan', 'mon_panier_complements'),
    ('bilan', 'offres'),
    ('offres', 'bienvenue_complements'),
    ('offres', 'mon_panier_complements'),
    ('mon_panier_complements', 'bienvenue_complements'),
    ('mon_offre_long_form', 'bienvenue_carte_cadeau'),
    ('mon_offre_long_form', 'bienvenue_long_form'),
    ('mon_offre_long_form', 'cartecadeau'),
    ('mon_offre_long_form', 'mon_panier_carte_cadeau'),
    ('mon_offre_long_form', 'mon_panier_long_form'),
    ('mon_panier_long_form', 'bienvenue_long_form'),
    ('cartecadeau', 'bienvenue_carte_cadeau'),
    ('cartecadeau', 'mon_panier_carte_cadeau'),
    ('mon_panier_carte_cadeau', 'bienvenue_carte_cadeau')
  ])
),
pages AS (
  -- Pages vues : 60 jours avant la période, pour retrouver le parcours des
  -- personnes qui reviennent (passe 3), et un jour après, pour les sessions qui
  -- passent minuit.
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS jour,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(date_debut, INTERVAL 60 DAY))
                          AND FORMAT_DATE('%Y%m%d', DATE_ADD(date_fin, INTERVAL 1 DAY))
    AND event_name = 'page_view'
    AND user_pseudo_id IS NOT NULL
),
tunnel AS (
  -- Pages du graphe seulement (domaine + chemin sans paramètres, en minuscules,
  -- sans « / » final), numérotées dans l'ordre de la session (rang) et dans
  -- l'ordre de toutes les sessions de la personne (rang_personne).
  SELECT p.jour, p.user_pseudo_id, p.ga_session_id, p.cle, c.id_unique,
    ROW_NUMBER() OVER (PARTITION BY p.user_pseudo_id, p.ga_session_id
                       ORDER BY p.event_timestamp, p.batch_ordering_id, p.batch_page_id, p.batch_event_index) AS rang,
    ROW_NUMBER() OVER (PARTITION BY p.user_pseudo_id
                       ORDER BY p.event_timestamp, p.ga_session_id, p.batch_ordering_id, p.batch_page_id, p.batch_event_index) AS rang_personne
  FROM (
    SELECT *,
      CONCAT(LOWER(NET.HOST(url)),
             IFNULL(NULLIF(REGEXP_REPLACE(LOWER(REGEXP_EXTRACT(url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')), r'/+$', ''), ''), '/')) AS cle
    FROM pages
    WHERE ga_session_id IS NOT NULL
  ) AS p
  JOIN chemins AS c USING (cle)
),
passe0 AS (
  SELECT *, id_unique AS etape FROM tunnel
),
passe1 AS (
  -- Passe 1, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT * EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(
      id_unique,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE precedente WHEN 'signup' THEN 'mon_offre_directe' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE precedente WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE precedente WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END,
      derniere_meme_page,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_offre_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_offre_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_offre_directe' WHEN 'obtenir_mon_offre' THEN 'mon_offre_directe' WHEN 'signup' THEN 'mon_offre_directe' WHEN 'mon_offre_directe' THEN 'mon_offre_directe' WHEN 'mon_panier_directe' THEN 'mon_offre_directe' WHEN 'bienvenue_directe' THEN 'mon_offre_directe' WHEN 'social_signup' THEN 'mon_offre_long_form' WHEN 'depenses_complements' THEN 'mon_offre_long_form' WHEN 'montant_complements' THEN 'mon_offre_long_form' WHEN 'network_complements' THEN 'mon_offre_long_form' WHEN 'recap_marques' THEN 'mon_offre_long_form' WHEN 'depenses_complements_step' THEN 'mon_offre_long_form' WHEN 'sante_mentale_seances' THEN 'mon_offre_long_form' WHEN 'montant_sante_mentale' THEN 'mon_offre_long_form' WHEN 'md_seances' THEN 'mon_offre_long_form' WHEN 'montant_medecine_douce' THEN 'mon_offre_long_form' WHEN 'soins_seances' THEN 'mon_offre_long_form' WHEN 'montant_soins' THEN 'mon_offre_long_form' WHEN 'network_info' THEN 'mon_offre_long_form' WHEN 'prete_a_changer' THEN 'mon_offre_long_form' WHEN 'medecine_douce_step' THEN 'mon_offre_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_offre_long_form' WHEN 'depenses_sports' THEN 'mon_offre_long_form' WHEN 'network_sport' THEN 'mon_offre_long_form' WHEN 'out_of_network_sport' THEN 'mon_offre_long_form' WHEN 'sport_step' THEN 'mon_offre_long_form' WHEN 'depenses_produit' THEN 'mon_offre_long_form' WHEN 'network_produit' THEN 'mon_offre_long_form' WHEN 'out_of_network_produit' THEN 'mon_offre_long_form' WHEN 'depenses_app' THEN 'mon_offre_long_form' WHEN 'out_of_network_app' THEN 'mon_offre_long_form' WHEN 'final_step' THEN 'mon_offre_long_form' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' WHEN 'sante_mentale_step' THEN 'mon_offre_long_form' WHEN 'mon_offre_long_form' THEN 'mon_offre_long_form' WHEN 'mon_panier_long_form' THEN 'mon_offre_long_form' WHEN 'bienvenue_long_form' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_panier_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_panier_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_panier_directe' WHEN 'obtenir_mon_offre' THEN 'mon_panier_directe' WHEN 'signup' THEN 'mon_panier_directe' WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'mon_panier_directe' THEN 'mon_panier_directe' WHEN 'bienvenue_directe' THEN 'mon_panier_directe' WHEN 'social_signup' THEN 'mon_panier_complements' WHEN 'depenses_complements' THEN 'mon_panier_complements' WHEN 'montant_complements' THEN 'mon_panier_complements' WHEN 'network_complements' THEN 'mon_panier_complements' WHEN 'recap_marques' THEN 'mon_panier_complements' WHEN 'depenses_complements_step' THEN 'mon_panier_long_form' WHEN 'sante_mentale_seances' THEN 'mon_panier_long_form' WHEN 'montant_sante_mentale' THEN 'mon_panier_long_form' WHEN 'md_seances' THEN 'mon_panier_long_form' WHEN 'montant_medecine_douce' THEN 'mon_panier_long_form' WHEN 'soins_seances' THEN 'mon_panier_long_form' WHEN 'montant_soins' THEN 'mon_panier_long_form' WHEN 'network_info' THEN 'mon_panier_long_form' WHEN 'prete_a_changer' THEN 'mon_panier_long_form' WHEN 'medecine_douce_step' THEN 'mon_panier_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_panier_long_form' WHEN 'depenses_sports' THEN 'mon_panier_long_form' WHEN 'network_sport' THEN 'mon_panier_long_form' WHEN 'out_of_network_sport' THEN 'mon_panier_long_form' WHEN 'sport_step' THEN 'mon_panier_long_form' WHEN 'depenses_produit' THEN 'mon_panier_long_form' WHEN 'network_produit' THEN 'mon_panier_long_form' WHEN 'out_of_network_produit' THEN 'mon_panier_long_form' WHEN 'depenses_app' THEN 'mon_panier_long_form' WHEN 'out_of_network_app' THEN 'mon_panier_long_form' WHEN 'final_step' THEN 'mon_panier_long_form' WHEN 'offre_en_preparation' THEN 'mon_panier_long_form' WHEN 'sante_mentale_step' THEN 'mon_panier_long_form' WHEN 'recap_remboursements' THEN 'mon_panier_complements' WHEN 'bonus_abonnement' THEN 'mon_panier_complements' WHEN 'bilan' THEN 'mon_panier_complements' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_panier_complements' THEN 'mon_panier_complements' WHEN 'bienvenue_complements' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'mon_panier_long_form' THEN 'mon_panier_long_form' WHEN 'bienvenue_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'mon_panier_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'bienvenue_directe' WHEN 'remboursement_complements_alimentaires' THEN 'bienvenue_directe' WHEN 'offres_remboursement_elsee' THEN 'bienvenue_directe' WHEN 'obtenir_mon_offre' THEN 'bienvenue_directe' WHEN 'signup' THEN 'bienvenue_directe' WHEN 'mon_offre_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'bienvenue_directe' THEN 'bienvenue_directe' WHEN 'social_signup' THEN 'bienvenue_complements' WHEN 'depenses_complements' THEN 'bienvenue_complements' WHEN 'montant_complements' THEN 'bienvenue_complements' WHEN 'network_complements' THEN 'bienvenue_complements' WHEN 'recap_marques' THEN 'bienvenue_complements' WHEN 'depenses_complements_step' THEN 'bienvenue_long_form' WHEN 'sante_mentale_seances' THEN 'bienvenue_long_form' WHEN 'montant_sante_mentale' THEN 'bienvenue_long_form' WHEN 'md_seances' THEN 'bienvenue_long_form' WHEN 'montant_medecine_douce' THEN 'bienvenue_long_form' WHEN 'soins_seances' THEN 'bienvenue_long_form' WHEN 'montant_soins' THEN 'bienvenue_long_form' WHEN 'network_info' THEN 'bienvenue_long_form' WHEN 'prete_a_changer' THEN 'bienvenue_long_form' WHEN 'medecine_douce_step' THEN 'bienvenue_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'bienvenue_long_form' WHEN 'depenses_sports' THEN 'bienvenue_long_form' WHEN 'network_sport' THEN 'bienvenue_long_form' WHEN 'out_of_network_sport' THEN 'bienvenue_long_form' WHEN 'sport_step' THEN 'bienvenue_long_form' WHEN 'depenses_produit' THEN 'bienvenue_long_form' WHEN 'network_produit' THEN 'bienvenue_long_form' WHEN 'out_of_network_produit' THEN 'bienvenue_long_form' WHEN 'depenses_app' THEN 'bienvenue_long_form' WHEN 'out_of_network_app' THEN 'bienvenue_long_form' WHEN 'final_step' THEN 'bienvenue_long_form' WHEN 'offre_en_preparation' THEN 'bienvenue_long_form' WHEN 'sante_mentale_step' THEN 'bienvenue_long_form' WHEN 'recap_remboursements' THEN 'bienvenue_complements' WHEN 'bonus_abonnement' THEN 'bienvenue_complements' WHEN 'bilan' THEN 'bienvenue_complements' WHEN 'offres' THEN 'bienvenue_complements' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'bienvenue_complements' THEN 'bienvenue_complements' WHEN 'mon_offre_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'bienvenue_long_form' THEN 'bienvenue_long_form' WHEN 'cartecadeau' THEN 'bienvenue_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe0
  )
),
passe2 AS (
  -- Passe 2, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT * EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(
      id_unique,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE precedente WHEN 'signup' THEN 'mon_offre_directe' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE precedente WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE precedente WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END,
      derniere_meme_page,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_offre_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_offre_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_offre_directe' WHEN 'obtenir_mon_offre' THEN 'mon_offre_directe' WHEN 'signup' THEN 'mon_offre_directe' WHEN 'mon_offre_directe' THEN 'mon_offre_directe' WHEN 'mon_panier_directe' THEN 'mon_offre_directe' WHEN 'bienvenue_directe' THEN 'mon_offre_directe' WHEN 'social_signup' THEN 'mon_offre_long_form' WHEN 'depenses_complements' THEN 'mon_offre_long_form' WHEN 'montant_complements' THEN 'mon_offre_long_form' WHEN 'network_complements' THEN 'mon_offre_long_form' WHEN 'recap_marques' THEN 'mon_offre_long_form' WHEN 'depenses_complements_step' THEN 'mon_offre_long_form' WHEN 'sante_mentale_seances' THEN 'mon_offre_long_form' WHEN 'montant_sante_mentale' THEN 'mon_offre_long_form' WHEN 'md_seances' THEN 'mon_offre_long_form' WHEN 'montant_medecine_douce' THEN 'mon_offre_long_form' WHEN 'soins_seances' THEN 'mon_offre_long_form' WHEN 'montant_soins' THEN 'mon_offre_long_form' WHEN 'network_info' THEN 'mon_offre_long_form' WHEN 'prete_a_changer' THEN 'mon_offre_long_form' WHEN 'medecine_douce_step' THEN 'mon_offre_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_offre_long_form' WHEN 'depenses_sports' THEN 'mon_offre_long_form' WHEN 'network_sport' THEN 'mon_offre_long_form' WHEN 'out_of_network_sport' THEN 'mon_offre_long_form' WHEN 'sport_step' THEN 'mon_offre_long_form' WHEN 'depenses_produit' THEN 'mon_offre_long_form' WHEN 'network_produit' THEN 'mon_offre_long_form' WHEN 'out_of_network_produit' THEN 'mon_offre_long_form' WHEN 'depenses_app' THEN 'mon_offre_long_form' WHEN 'out_of_network_app' THEN 'mon_offre_long_form' WHEN 'final_step' THEN 'mon_offre_long_form' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' WHEN 'sante_mentale_step' THEN 'mon_offre_long_form' WHEN 'mon_offre_long_form' THEN 'mon_offre_long_form' WHEN 'mon_panier_long_form' THEN 'mon_offre_long_form' WHEN 'bienvenue_long_form' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_panier_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_panier_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_panier_directe' WHEN 'obtenir_mon_offre' THEN 'mon_panier_directe' WHEN 'signup' THEN 'mon_panier_directe' WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'mon_panier_directe' THEN 'mon_panier_directe' WHEN 'bienvenue_directe' THEN 'mon_panier_directe' WHEN 'social_signup' THEN 'mon_panier_complements' WHEN 'depenses_complements' THEN 'mon_panier_complements' WHEN 'montant_complements' THEN 'mon_panier_complements' WHEN 'network_complements' THEN 'mon_panier_complements' WHEN 'recap_marques' THEN 'mon_panier_complements' WHEN 'depenses_complements_step' THEN 'mon_panier_long_form' WHEN 'sante_mentale_seances' THEN 'mon_panier_long_form' WHEN 'montant_sante_mentale' THEN 'mon_panier_long_form' WHEN 'md_seances' THEN 'mon_panier_long_form' WHEN 'montant_medecine_douce' THEN 'mon_panier_long_form' WHEN 'soins_seances' THEN 'mon_panier_long_form' WHEN 'montant_soins' THEN 'mon_panier_long_form' WHEN 'network_info' THEN 'mon_panier_long_form' WHEN 'prete_a_changer' THEN 'mon_panier_long_form' WHEN 'medecine_douce_step' THEN 'mon_panier_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_panier_long_form' WHEN 'depenses_sports' THEN 'mon_panier_long_form' WHEN 'network_sport' THEN 'mon_panier_long_form' WHEN 'out_of_network_sport' THEN 'mon_panier_long_form' WHEN 'sport_step' THEN 'mon_panier_long_form' WHEN 'depenses_produit' THEN 'mon_panier_long_form' WHEN 'network_produit' THEN 'mon_panier_long_form' WHEN 'out_of_network_produit' THEN 'mon_panier_long_form' WHEN 'depenses_app' THEN 'mon_panier_long_form' WHEN 'out_of_network_app' THEN 'mon_panier_long_form' WHEN 'final_step' THEN 'mon_panier_long_form' WHEN 'offre_en_preparation' THEN 'mon_panier_long_form' WHEN 'sante_mentale_step' THEN 'mon_panier_long_form' WHEN 'recap_remboursements' THEN 'mon_panier_complements' WHEN 'bonus_abonnement' THEN 'mon_panier_complements' WHEN 'bilan' THEN 'mon_panier_complements' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_panier_complements' THEN 'mon_panier_complements' WHEN 'bienvenue_complements' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'mon_panier_long_form' THEN 'mon_panier_long_form' WHEN 'bienvenue_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'mon_panier_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'bienvenue_directe' WHEN 'remboursement_complements_alimentaires' THEN 'bienvenue_directe' WHEN 'offres_remboursement_elsee' THEN 'bienvenue_directe' WHEN 'obtenir_mon_offre' THEN 'bienvenue_directe' WHEN 'signup' THEN 'bienvenue_directe' WHEN 'mon_offre_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'bienvenue_directe' THEN 'bienvenue_directe' WHEN 'social_signup' THEN 'bienvenue_complements' WHEN 'depenses_complements' THEN 'bienvenue_complements' WHEN 'montant_complements' THEN 'bienvenue_complements' WHEN 'network_complements' THEN 'bienvenue_complements' WHEN 'recap_marques' THEN 'bienvenue_complements' WHEN 'depenses_complements_step' THEN 'bienvenue_long_form' WHEN 'sante_mentale_seances' THEN 'bienvenue_long_form' WHEN 'montant_sante_mentale' THEN 'bienvenue_long_form' WHEN 'md_seances' THEN 'bienvenue_long_form' WHEN 'montant_medecine_douce' THEN 'bienvenue_long_form' WHEN 'soins_seances' THEN 'bienvenue_long_form' WHEN 'montant_soins' THEN 'bienvenue_long_form' WHEN 'network_info' THEN 'bienvenue_long_form' WHEN 'prete_a_changer' THEN 'bienvenue_long_form' WHEN 'medecine_douce_step' THEN 'bienvenue_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'bienvenue_long_form' WHEN 'depenses_sports' THEN 'bienvenue_long_form' WHEN 'network_sport' THEN 'bienvenue_long_form' WHEN 'out_of_network_sport' THEN 'bienvenue_long_form' WHEN 'sport_step' THEN 'bienvenue_long_form' WHEN 'depenses_produit' THEN 'bienvenue_long_form' WHEN 'network_produit' THEN 'bienvenue_long_form' WHEN 'out_of_network_produit' THEN 'bienvenue_long_form' WHEN 'depenses_app' THEN 'bienvenue_long_form' WHEN 'out_of_network_app' THEN 'bienvenue_long_form' WHEN 'final_step' THEN 'bienvenue_long_form' WHEN 'offre_en_preparation' THEN 'bienvenue_long_form' WHEN 'sante_mentale_step' THEN 'bienvenue_long_form' WHEN 'recap_remboursements' THEN 'bienvenue_complements' WHEN 'bonus_abonnement' THEN 'bienvenue_complements' WHEN 'bilan' THEN 'bienvenue_complements' WHEN 'offres' THEN 'bienvenue_complements' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'bienvenue_complements' THEN 'bienvenue_complements' WHEN 'mon_offre_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'bienvenue_long_form' THEN 'bienvenue_long_form' WHEN 'cartecadeau' THEN 'bienvenue_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe1
  )
),
passe3 AS (
  -- Passe 3, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT * EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(
      id_unique,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE precedente WHEN 'signup' THEN 'mon_offre_directe' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE precedente WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE precedente WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END,
      derniere_meme_page,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_offre_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_offre_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_offre_directe' WHEN 'obtenir_mon_offre' THEN 'mon_offre_directe' WHEN 'signup' THEN 'mon_offre_directe' WHEN 'mon_offre_directe' THEN 'mon_offre_directe' WHEN 'mon_panier_directe' THEN 'mon_offre_directe' WHEN 'bienvenue_directe' THEN 'mon_offre_directe' WHEN 'social_signup' THEN 'mon_offre_long_form' WHEN 'depenses_complements' THEN 'mon_offre_long_form' WHEN 'montant_complements' THEN 'mon_offre_long_form' WHEN 'network_complements' THEN 'mon_offre_long_form' WHEN 'recap_marques' THEN 'mon_offre_long_form' WHEN 'depenses_complements_step' THEN 'mon_offre_long_form' WHEN 'sante_mentale_seances' THEN 'mon_offre_long_form' WHEN 'montant_sante_mentale' THEN 'mon_offre_long_form' WHEN 'md_seances' THEN 'mon_offre_long_form' WHEN 'montant_medecine_douce' THEN 'mon_offre_long_form' WHEN 'soins_seances' THEN 'mon_offre_long_form' WHEN 'montant_soins' THEN 'mon_offre_long_form' WHEN 'network_info' THEN 'mon_offre_long_form' WHEN 'prete_a_changer' THEN 'mon_offre_long_form' WHEN 'medecine_douce_step' THEN 'mon_offre_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_offre_long_form' WHEN 'depenses_sports' THEN 'mon_offre_long_form' WHEN 'network_sport' THEN 'mon_offre_long_form' WHEN 'out_of_network_sport' THEN 'mon_offre_long_form' WHEN 'sport_step' THEN 'mon_offre_long_form' WHEN 'depenses_produit' THEN 'mon_offre_long_form' WHEN 'network_produit' THEN 'mon_offre_long_form' WHEN 'out_of_network_produit' THEN 'mon_offre_long_form' WHEN 'depenses_app' THEN 'mon_offre_long_form' WHEN 'out_of_network_app' THEN 'mon_offre_long_form' WHEN 'final_step' THEN 'mon_offre_long_form' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' WHEN 'sante_mentale_step' THEN 'mon_offre_long_form' WHEN 'mon_offre_long_form' THEN 'mon_offre_long_form' WHEN 'mon_panier_long_form' THEN 'mon_offre_long_form' WHEN 'bienvenue_long_form' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_panier_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_panier_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_panier_directe' WHEN 'obtenir_mon_offre' THEN 'mon_panier_directe' WHEN 'signup' THEN 'mon_panier_directe' WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'mon_panier_directe' THEN 'mon_panier_directe' WHEN 'bienvenue_directe' THEN 'mon_panier_directe' WHEN 'social_signup' THEN 'mon_panier_complements' WHEN 'depenses_complements' THEN 'mon_panier_complements' WHEN 'montant_complements' THEN 'mon_panier_complements' WHEN 'network_complements' THEN 'mon_panier_complements' WHEN 'recap_marques' THEN 'mon_panier_complements' WHEN 'depenses_complements_step' THEN 'mon_panier_long_form' WHEN 'sante_mentale_seances' THEN 'mon_panier_long_form' WHEN 'montant_sante_mentale' THEN 'mon_panier_long_form' WHEN 'md_seances' THEN 'mon_panier_long_form' WHEN 'montant_medecine_douce' THEN 'mon_panier_long_form' WHEN 'soins_seances' THEN 'mon_panier_long_form' WHEN 'montant_soins' THEN 'mon_panier_long_form' WHEN 'network_info' THEN 'mon_panier_long_form' WHEN 'prete_a_changer' THEN 'mon_panier_long_form' WHEN 'medecine_douce_step' THEN 'mon_panier_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_panier_long_form' WHEN 'depenses_sports' THEN 'mon_panier_long_form' WHEN 'network_sport' THEN 'mon_panier_long_form' WHEN 'out_of_network_sport' THEN 'mon_panier_long_form' WHEN 'sport_step' THEN 'mon_panier_long_form' WHEN 'depenses_produit' THEN 'mon_panier_long_form' WHEN 'network_produit' THEN 'mon_panier_long_form' WHEN 'out_of_network_produit' THEN 'mon_panier_long_form' WHEN 'depenses_app' THEN 'mon_panier_long_form' WHEN 'out_of_network_app' THEN 'mon_panier_long_form' WHEN 'final_step' THEN 'mon_panier_long_form' WHEN 'offre_en_preparation' THEN 'mon_panier_long_form' WHEN 'sante_mentale_step' THEN 'mon_panier_long_form' WHEN 'recap_remboursements' THEN 'mon_panier_complements' WHEN 'bonus_abonnement' THEN 'mon_panier_complements' WHEN 'bilan' THEN 'mon_panier_complements' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_panier_complements' THEN 'mon_panier_complements' WHEN 'bienvenue_complements' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'mon_panier_long_form' THEN 'mon_panier_long_form' WHEN 'bienvenue_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'mon_panier_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'bienvenue_directe' WHEN 'remboursement_complements_alimentaires' THEN 'bienvenue_directe' WHEN 'offres_remboursement_elsee' THEN 'bienvenue_directe' WHEN 'obtenir_mon_offre' THEN 'bienvenue_directe' WHEN 'signup' THEN 'bienvenue_directe' WHEN 'mon_offre_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'bienvenue_directe' THEN 'bienvenue_directe' WHEN 'social_signup' THEN 'bienvenue_complements' WHEN 'depenses_complements' THEN 'bienvenue_complements' WHEN 'montant_complements' THEN 'bienvenue_complements' WHEN 'network_complements' THEN 'bienvenue_complements' WHEN 'recap_marques' THEN 'bienvenue_complements' WHEN 'depenses_complements_step' THEN 'bienvenue_long_form' WHEN 'sante_mentale_seances' THEN 'bienvenue_long_form' WHEN 'montant_sante_mentale' THEN 'bienvenue_long_form' WHEN 'md_seances' THEN 'bienvenue_long_form' WHEN 'montant_medecine_douce' THEN 'bienvenue_long_form' WHEN 'soins_seances' THEN 'bienvenue_long_form' WHEN 'montant_soins' THEN 'bienvenue_long_form' WHEN 'network_info' THEN 'bienvenue_long_form' WHEN 'prete_a_changer' THEN 'bienvenue_long_form' WHEN 'medecine_douce_step' THEN 'bienvenue_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'bienvenue_long_form' WHEN 'depenses_sports' THEN 'bienvenue_long_form' WHEN 'network_sport' THEN 'bienvenue_long_form' WHEN 'out_of_network_sport' THEN 'bienvenue_long_form' WHEN 'sport_step' THEN 'bienvenue_long_form' WHEN 'depenses_produit' THEN 'bienvenue_long_form' WHEN 'network_produit' THEN 'bienvenue_long_form' WHEN 'out_of_network_produit' THEN 'bienvenue_long_form' WHEN 'depenses_app' THEN 'bienvenue_long_form' WHEN 'out_of_network_app' THEN 'bienvenue_long_form' WHEN 'final_step' THEN 'bienvenue_long_form' WHEN 'offre_en_preparation' THEN 'bienvenue_long_form' WHEN 'sante_mentale_step' THEN 'bienvenue_long_form' WHEN 'recap_remboursements' THEN 'bienvenue_complements' WHEN 'bonus_abonnement' THEN 'bienvenue_complements' WHEN 'bilan' THEN 'bienvenue_complements' WHEN 'offres' THEN 'bienvenue_complements' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'bienvenue_complements' THEN 'bienvenue_complements' WHEN 'mon_offre_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'bienvenue_long_form' THEN 'bienvenue_long_form' WHEN 'cartecadeau' THEN 'bienvenue_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe2
  )
),
passe4 AS (
  -- Passe 4, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT * EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(
      id_unique,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE precedente WHEN 'signup' THEN 'mon_offre_directe' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE precedente WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE precedente WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END,
      derniere_meme_page,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_offre_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_offre_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_offre_directe' WHEN 'obtenir_mon_offre' THEN 'mon_offre_directe' WHEN 'signup' THEN 'mon_offre_directe' WHEN 'mon_offre_directe' THEN 'mon_offre_directe' WHEN 'mon_panier_directe' THEN 'mon_offre_directe' WHEN 'bienvenue_directe' THEN 'mon_offre_directe' WHEN 'social_signup' THEN 'mon_offre_long_form' WHEN 'depenses_complements' THEN 'mon_offre_long_form' WHEN 'montant_complements' THEN 'mon_offre_long_form' WHEN 'network_complements' THEN 'mon_offre_long_form' WHEN 'recap_marques' THEN 'mon_offre_long_form' WHEN 'depenses_complements_step' THEN 'mon_offre_long_form' WHEN 'sante_mentale_seances' THEN 'mon_offre_long_form' WHEN 'montant_sante_mentale' THEN 'mon_offre_long_form' WHEN 'md_seances' THEN 'mon_offre_long_form' WHEN 'montant_medecine_douce' THEN 'mon_offre_long_form' WHEN 'soins_seances' THEN 'mon_offre_long_form' WHEN 'montant_soins' THEN 'mon_offre_long_form' WHEN 'network_info' THEN 'mon_offre_long_form' WHEN 'prete_a_changer' THEN 'mon_offre_long_form' WHEN 'medecine_douce_step' THEN 'mon_offre_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_offre_long_form' WHEN 'depenses_sports' THEN 'mon_offre_long_form' WHEN 'network_sport' THEN 'mon_offre_long_form' WHEN 'out_of_network_sport' THEN 'mon_offre_long_form' WHEN 'sport_step' THEN 'mon_offre_long_form' WHEN 'depenses_produit' THEN 'mon_offre_long_form' WHEN 'network_produit' THEN 'mon_offre_long_form' WHEN 'out_of_network_produit' THEN 'mon_offre_long_form' WHEN 'depenses_app' THEN 'mon_offre_long_form' WHEN 'out_of_network_app' THEN 'mon_offre_long_form' WHEN 'final_step' THEN 'mon_offre_long_form' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' WHEN 'sante_mentale_step' THEN 'mon_offre_long_form' WHEN 'mon_offre_long_form' THEN 'mon_offre_long_form' WHEN 'mon_panier_long_form' THEN 'mon_offre_long_form' WHEN 'bienvenue_long_form' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_panier_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_panier_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_panier_directe' WHEN 'obtenir_mon_offre' THEN 'mon_panier_directe' WHEN 'signup' THEN 'mon_panier_directe' WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'mon_panier_directe' THEN 'mon_panier_directe' WHEN 'bienvenue_directe' THEN 'mon_panier_directe' WHEN 'social_signup' THEN 'mon_panier_complements' WHEN 'depenses_complements' THEN 'mon_panier_complements' WHEN 'montant_complements' THEN 'mon_panier_complements' WHEN 'network_complements' THEN 'mon_panier_complements' WHEN 'recap_marques' THEN 'mon_panier_complements' WHEN 'depenses_complements_step' THEN 'mon_panier_long_form' WHEN 'sante_mentale_seances' THEN 'mon_panier_long_form' WHEN 'montant_sante_mentale' THEN 'mon_panier_long_form' WHEN 'md_seances' THEN 'mon_panier_long_form' WHEN 'montant_medecine_douce' THEN 'mon_panier_long_form' WHEN 'soins_seances' THEN 'mon_panier_long_form' WHEN 'montant_soins' THEN 'mon_panier_long_form' WHEN 'network_info' THEN 'mon_panier_long_form' WHEN 'prete_a_changer' THEN 'mon_panier_long_form' WHEN 'medecine_douce_step' THEN 'mon_panier_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_panier_long_form' WHEN 'depenses_sports' THEN 'mon_panier_long_form' WHEN 'network_sport' THEN 'mon_panier_long_form' WHEN 'out_of_network_sport' THEN 'mon_panier_long_form' WHEN 'sport_step' THEN 'mon_panier_long_form' WHEN 'depenses_produit' THEN 'mon_panier_long_form' WHEN 'network_produit' THEN 'mon_panier_long_form' WHEN 'out_of_network_produit' THEN 'mon_panier_long_form' WHEN 'depenses_app' THEN 'mon_panier_long_form' WHEN 'out_of_network_app' THEN 'mon_panier_long_form' WHEN 'final_step' THEN 'mon_panier_long_form' WHEN 'offre_en_preparation' THEN 'mon_panier_long_form' WHEN 'sante_mentale_step' THEN 'mon_panier_long_form' WHEN 'recap_remboursements' THEN 'mon_panier_complements' WHEN 'bonus_abonnement' THEN 'mon_panier_complements' WHEN 'bilan' THEN 'mon_panier_complements' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_panier_complements' THEN 'mon_panier_complements' WHEN 'bienvenue_complements' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'mon_panier_long_form' THEN 'mon_panier_long_form' WHEN 'bienvenue_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'mon_panier_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'bienvenue_directe' WHEN 'remboursement_complements_alimentaires' THEN 'bienvenue_directe' WHEN 'offres_remboursement_elsee' THEN 'bienvenue_directe' WHEN 'obtenir_mon_offre' THEN 'bienvenue_directe' WHEN 'signup' THEN 'bienvenue_directe' WHEN 'mon_offre_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'bienvenue_directe' THEN 'bienvenue_directe' WHEN 'social_signup' THEN 'bienvenue_complements' WHEN 'depenses_complements' THEN 'bienvenue_complements' WHEN 'montant_complements' THEN 'bienvenue_complements' WHEN 'network_complements' THEN 'bienvenue_complements' WHEN 'recap_marques' THEN 'bienvenue_complements' WHEN 'depenses_complements_step' THEN 'bienvenue_long_form' WHEN 'sante_mentale_seances' THEN 'bienvenue_long_form' WHEN 'montant_sante_mentale' THEN 'bienvenue_long_form' WHEN 'md_seances' THEN 'bienvenue_long_form' WHEN 'montant_medecine_douce' THEN 'bienvenue_long_form' WHEN 'soins_seances' THEN 'bienvenue_long_form' WHEN 'montant_soins' THEN 'bienvenue_long_form' WHEN 'network_info' THEN 'bienvenue_long_form' WHEN 'prete_a_changer' THEN 'bienvenue_long_form' WHEN 'medecine_douce_step' THEN 'bienvenue_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'bienvenue_long_form' WHEN 'depenses_sports' THEN 'bienvenue_long_form' WHEN 'network_sport' THEN 'bienvenue_long_form' WHEN 'out_of_network_sport' THEN 'bienvenue_long_form' WHEN 'sport_step' THEN 'bienvenue_long_form' WHEN 'depenses_produit' THEN 'bienvenue_long_form' WHEN 'network_produit' THEN 'bienvenue_long_form' WHEN 'out_of_network_produit' THEN 'bienvenue_long_form' WHEN 'depenses_app' THEN 'bienvenue_long_form' WHEN 'out_of_network_app' THEN 'bienvenue_long_form' WHEN 'final_step' THEN 'bienvenue_long_form' WHEN 'offre_en_preparation' THEN 'bienvenue_long_form' WHEN 'sante_mentale_step' THEN 'bienvenue_long_form' WHEN 'recap_remboursements' THEN 'bienvenue_complements' WHEN 'bonus_abonnement' THEN 'bienvenue_complements' WHEN 'bilan' THEN 'bienvenue_complements' WHEN 'offres' THEN 'bienvenue_complements' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'bienvenue_complements' THEN 'bienvenue_complements' WHEN 'mon_offre_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'bienvenue_long_form' THEN 'bienvenue_long_form' WHEN 'cartecadeau' THEN 'bienvenue_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe3
  )
),
passe5 AS (
  -- Passe 5, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT * EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(
      id_unique,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE precedente WHEN 'signup' THEN 'mon_offre_directe' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE precedente WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE precedente WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END,
      derniere_meme_page,
      CASE cle
      WHEN 'app.elsee.care/mon-offre' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_offre_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_offre_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_offre_directe' WHEN 'obtenir_mon_offre' THEN 'mon_offre_directe' WHEN 'signup' THEN 'mon_offre_directe' WHEN 'mon_offre_directe' THEN 'mon_offre_directe' WHEN 'mon_panier_directe' THEN 'mon_offre_directe' WHEN 'bienvenue_directe' THEN 'mon_offre_directe' WHEN 'social_signup' THEN 'mon_offre_long_form' WHEN 'depenses_complements' THEN 'mon_offre_long_form' WHEN 'montant_complements' THEN 'mon_offre_long_form' WHEN 'network_complements' THEN 'mon_offre_long_form' WHEN 'recap_marques' THEN 'mon_offre_long_form' WHEN 'depenses_complements_step' THEN 'mon_offre_long_form' WHEN 'sante_mentale_seances' THEN 'mon_offre_long_form' WHEN 'montant_sante_mentale' THEN 'mon_offre_long_form' WHEN 'md_seances' THEN 'mon_offre_long_form' WHEN 'montant_medecine_douce' THEN 'mon_offre_long_form' WHEN 'soins_seances' THEN 'mon_offre_long_form' WHEN 'montant_soins' THEN 'mon_offre_long_form' WHEN 'network_info' THEN 'mon_offre_long_form' WHEN 'prete_a_changer' THEN 'mon_offre_long_form' WHEN 'medecine_douce_step' THEN 'mon_offre_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_offre_long_form' WHEN 'depenses_sports' THEN 'mon_offre_long_form' WHEN 'network_sport' THEN 'mon_offre_long_form' WHEN 'out_of_network_sport' THEN 'mon_offre_long_form' WHEN 'sport_step' THEN 'mon_offre_long_form' WHEN 'depenses_produit' THEN 'mon_offre_long_form' WHEN 'network_produit' THEN 'mon_offre_long_form' WHEN 'out_of_network_produit' THEN 'mon_offre_long_form' WHEN 'depenses_app' THEN 'mon_offre_long_form' WHEN 'out_of_network_app' THEN 'mon_offre_long_form' WHEN 'final_step' THEN 'mon_offre_long_form' WHEN 'offre_en_preparation' THEN 'mon_offre_long_form' WHEN 'sante_mentale_step' THEN 'mon_offre_long_form' WHEN 'mon_offre_long_form' THEN 'mon_offre_long_form' WHEN 'mon_panier_long_form' THEN 'mon_offre_long_form' WHEN 'bienvenue_long_form' THEN 'mon_offre_long_form' END
      WHEN 'app.elsee.care/mon-panier' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'mon_panier_directe' WHEN 'remboursement_complements_alimentaires' THEN 'mon_panier_directe' WHEN 'offres_remboursement_elsee' THEN 'mon_panier_directe' WHEN 'obtenir_mon_offre' THEN 'mon_panier_directe' WHEN 'signup' THEN 'mon_panier_directe' WHEN 'mon_offre_directe' THEN 'mon_panier_directe' WHEN 'mon_panier_directe' THEN 'mon_panier_directe' WHEN 'bienvenue_directe' THEN 'mon_panier_directe' WHEN 'social_signup' THEN 'mon_panier_complements' WHEN 'depenses_complements' THEN 'mon_panier_complements' WHEN 'montant_complements' THEN 'mon_panier_complements' WHEN 'network_complements' THEN 'mon_panier_complements' WHEN 'recap_marques' THEN 'mon_panier_complements' WHEN 'depenses_complements_step' THEN 'mon_panier_long_form' WHEN 'sante_mentale_seances' THEN 'mon_panier_long_form' WHEN 'montant_sante_mentale' THEN 'mon_panier_long_form' WHEN 'md_seances' THEN 'mon_panier_long_form' WHEN 'montant_medecine_douce' THEN 'mon_panier_long_form' WHEN 'soins_seances' THEN 'mon_panier_long_form' WHEN 'montant_soins' THEN 'mon_panier_long_form' WHEN 'network_info' THEN 'mon_panier_long_form' WHEN 'prete_a_changer' THEN 'mon_panier_long_form' WHEN 'medecine_douce_step' THEN 'mon_panier_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'mon_panier_long_form' WHEN 'depenses_sports' THEN 'mon_panier_long_form' WHEN 'network_sport' THEN 'mon_panier_long_form' WHEN 'out_of_network_sport' THEN 'mon_panier_long_form' WHEN 'sport_step' THEN 'mon_panier_long_form' WHEN 'depenses_produit' THEN 'mon_panier_long_form' WHEN 'network_produit' THEN 'mon_panier_long_form' WHEN 'out_of_network_produit' THEN 'mon_panier_long_form' WHEN 'depenses_app' THEN 'mon_panier_long_form' WHEN 'out_of_network_app' THEN 'mon_panier_long_form' WHEN 'final_step' THEN 'mon_panier_long_form' WHEN 'offre_en_preparation' THEN 'mon_panier_long_form' WHEN 'sante_mentale_step' THEN 'mon_panier_long_form' WHEN 'recap_remboursements' THEN 'mon_panier_complements' WHEN 'bonus_abonnement' THEN 'mon_panier_complements' WHEN 'bilan' THEN 'mon_panier_complements' WHEN 'offres' THEN 'mon_panier_complements' WHEN 'mon_panier_complements' THEN 'mon_panier_complements' WHEN 'bienvenue_complements' THEN 'mon_panier_complements' WHEN 'mon_offre_long_form' THEN 'mon_panier_long_form' WHEN 'mon_panier_long_form' THEN 'mon_panier_long_form' WHEN 'bienvenue_long_form' THEN 'mon_panier_long_form' WHEN 'cartecadeau' THEN 'mon_panier_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'mon_panier_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'mon_panier_carte_cadeau' END
      WHEN 'www.elsee.care/bienvenue-chez-elsee' THEN CASE derniere_etape_personne WHEN 'signup_corpo' THEN 'bienvenue_directe' WHEN 'remboursement_complements_alimentaires' THEN 'bienvenue_directe' WHEN 'offres_remboursement_elsee' THEN 'bienvenue_directe' WHEN 'obtenir_mon_offre' THEN 'bienvenue_directe' WHEN 'signup' THEN 'bienvenue_directe' WHEN 'mon_offre_directe' THEN 'bienvenue_directe' WHEN 'mon_panier_directe' THEN 'bienvenue_directe' WHEN 'bienvenue_directe' THEN 'bienvenue_directe' WHEN 'social_signup' THEN 'bienvenue_complements' WHEN 'depenses_complements' THEN 'bienvenue_complements' WHEN 'montant_complements' THEN 'bienvenue_complements' WHEN 'network_complements' THEN 'bienvenue_complements' WHEN 'recap_marques' THEN 'bienvenue_complements' WHEN 'depenses_complements_step' THEN 'bienvenue_long_form' WHEN 'sante_mentale_seances' THEN 'bienvenue_long_form' WHEN 'montant_sante_mentale' THEN 'bienvenue_long_form' WHEN 'md_seances' THEN 'bienvenue_long_form' WHEN 'montant_medecine_douce' THEN 'bienvenue_long_form' WHEN 'soins_seances' THEN 'bienvenue_long_form' WHEN 'montant_soins' THEN 'bienvenue_long_form' WHEN 'network_info' THEN 'bienvenue_long_form' WHEN 'prete_a_changer' THEN 'bienvenue_long_form' WHEN 'medecine_douce_step' THEN 'bienvenue_long_form' WHEN 'en_savoir_plus_sur_vous' THEN 'bienvenue_long_form' WHEN 'depenses_sports' THEN 'bienvenue_long_form' WHEN 'network_sport' THEN 'bienvenue_long_form' WHEN 'out_of_network_sport' THEN 'bienvenue_long_form' WHEN 'sport_step' THEN 'bienvenue_long_form' WHEN 'depenses_produit' THEN 'bienvenue_long_form' WHEN 'network_produit' THEN 'bienvenue_long_form' WHEN 'out_of_network_produit' THEN 'bienvenue_long_form' WHEN 'depenses_app' THEN 'bienvenue_long_form' WHEN 'out_of_network_app' THEN 'bienvenue_long_form' WHEN 'final_step' THEN 'bienvenue_long_form' WHEN 'offre_en_preparation' THEN 'bienvenue_long_form' WHEN 'sante_mentale_step' THEN 'bienvenue_long_form' WHEN 'recap_remboursements' THEN 'bienvenue_complements' WHEN 'bonus_abonnement' THEN 'bienvenue_complements' WHEN 'bilan' THEN 'bienvenue_complements' WHEN 'offres' THEN 'bienvenue_complements' WHEN 'mon_panier_complements' THEN 'bienvenue_complements' WHEN 'bienvenue_complements' THEN 'bienvenue_complements' WHEN 'mon_offre_long_form' THEN 'bienvenue_long_form' WHEN 'mon_panier_long_form' THEN 'bienvenue_long_form' WHEN 'bienvenue_long_form' THEN 'bienvenue_long_form' WHEN 'cartecadeau' THEN 'bienvenue_carte_cadeau' WHEN 'mon_panier_carte_cadeau' THEN 'bienvenue_carte_cadeau' WHEN 'bienvenue_carte_cadeau' THEN 'bienvenue_carte_cadeau' END
      END) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe4
  )
),
resolues AS (
  -- Une page qu'on ne peut rattacher à aucun parcours garde son chemin,
  -- précédé de « ? » : elle coupe la suite des passages.
  SELECT jour, user_pseudo_id, ga_session_id, rang, IFNULL(etape, CONCAT('?', cle)) AS e
  FROM passe5
),
sans_rechargements AS (
  SELECT * EXCEPT (precedente)
  FROM (SELECT *, LAG(e) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente FROM resolues)
  WHERE precedente IS NULL OR precedente != e
),
sans_detours AS (
  -- Détours effacés : pour cartecadeau, une visite suivie d'un
  -- retour à la page d'où l'on venait, puis d'une flèche partant de cette page,
  -- compte comme si la personne n'avait pas vu l'étape.
  SELECT * EXCEPT (p, n1, n2)
  FROM (
    SELECT *,
      LAG(e) OVER w AS p, LEAD(e) OVER w AS n1, LEAD(e, 2) OVER w AS n2
    FROM sans_rechargements
    WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
  )
  WHERE NOT IFNULL(e IN ('cartecadeau')
                   AND n1 = p AND n2 != e
                   AND CONCAT(p, '>', n2) IN UNNEST(['obtenir_mon_offre>signup', 'offres_remboursement_elsee>signup', 'remboursement_complements_alimentaires>signup', 'signup_corpo>signup', 'signup>mon_offre_directe', 'mon_offre_directe>mon_panier_directe', 'mon_panier_directe>bienvenue_directe', 'signup>depenses_complements', 'social_signup>depenses_complements', 'depenses_complements>montant_complements', 'depenses_complements>sante_mentale_seances', 'montant_complements>network_complements', 'network_complements>recap_marques', 'recap_marques>depenses_complements_step', 'recap_marques>recap_remboursements', 'depenses_complements_step>sante_mentale_seances', 'recap_remboursements>bonus_abonnement', 'bonus_abonnement>bilan', 'bilan>offres', 'offres>mon_panier_complements', 'mon_panier_complements>bienvenue_complements', 'sante_mentale_seances>montant_sante_mentale', 'sante_mentale_seances>sante_mentale_step', 'montant_sante_mentale>md_seances', 'sante_mentale_step>md_seances', 'md_seances>montant_medecine_douce', 'md_seances>soins_seances', 'montant_medecine_douce>soins_seances', 'soins_seances>montant_soins', 'soins_seances>medecine_douce_step', 'montant_soins>network_info', 'network_info>prete_a_changer', 'prete_a_changer>medecine_douce_step', 'medecine_douce_step>en_savoir_plus_sur_vous', 'medecine_douce_step>depenses_sports', 'en_savoir_plus_sur_vous>depenses_sports', 'depenses_sports>network_sport', 'depenses_sports>sport_step', 'network_sport>out_of_network_sport', 'out_of_network_sport>sport_step', 'sport_step>depenses_produit', 'depenses_produit>network_produit', 'depenses_produit>depenses_app', 'network_produit>out_of_network_produit', 'out_of_network_produit>depenses_app', 'depenses_app>out_of_network_app', 'depenses_app>final_step', 'out_of_network_app>final_step', 'final_step>offre_en_preparation', 'offre_en_preparation>mon_offre_long_form', 'mon_offre_long_form>mon_panier_long_form', 'mon_panier_long_form>bienvenue_long_form', 'mon_offre_long_form>cartecadeau', 'cartecadeau>mon_panier_carte_cadeau', 'mon_panier_carte_cadeau>bienvenue_carte_cadeau']), FALSE)
),
suites AS (
  -- Après l'effacement d'un détour, la page d'avant et celle d'après sont
  -- identiques : on retire à nouveau les doublons, puis on prend la suivante.
  SELECT *,
    LEAD(e) OVER w AS vers,
    LAG(e) OVER w IS NULL AS premiere_de_la_session
  FROM (
    SELECT * EXCEPT (precedente)
    FROM (SELECT *, LAG(e) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente FROM sans_detours)
    WHERE precedente IS NULL OR precedente != e
  )
  WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
),
classees AS (
  -- Une ligne = une arrivée sur l'étape « de », datée du jour de cette page,
  -- et ce qui suit dans la session.
  SELECT s.jour, s.user_pseudo_id, s.e AS de, s.vers, s.premiere_de_la_session,
    CASE
      WHEN STARTS_WITH(s.e, '?') THEN 'non_rattache'
      WHEN s.vers IS NULL THEN 'fin'
      WHEN STARTS_WITH(s.vers, '?') THEN 'autre'
      WHEN f.de IS NOT NULL THEN 'fleche'
      WHEN a.de IS NOT NULL THEN 'saut'
      WHEN r.de IS NOT NULL THEN 'retour'
      ELSE 'autre'
    END AS genre
  FROM suites AS s
  LEFT JOIN fleches AS f ON f.de = s.e AND f.vers = s.vers
  LEFT JOIN atteignables AS a ON a.de = s.e AND a.vers = s.vers
  LEFT JOIN atteignables AS r ON r.de = s.vers AND r.vers = s.e
),
periode AS (
  SELECT * FROM classees WHERE jour BETWEEN date_debut AND date_fin
),
faits AS (
  -- Faits par personne (ne sortent jamais de BigQuery).
  SELECT jour, user_pseudo_id, 'arrivees' AS genre, de, CAST(NULL AS STRING) AS vers
  FROM periode WHERE genre != 'non_rattache'
  UNION ALL
  SELECT jour, user_pseudo_id, 'continuent', de, NULL
  FROM periode WHERE genre IN ('fleche', 'saut')
  UNION ALL
  SELECT jour, user_pseudo_id, 'entrees_directes', de, NULL
  FROM periode WHERE premiere_de_la_session AND genre != 'non_rattache'
  UNION ALL
  SELECT jour, user_pseudo_id, genre, de, vers
  FROM periode WHERE genre IN ('fleche', 'saut', 'retour', 'autre')
  UNION ALL
  SELECT jour, user_pseudo_id, 'non_rattache', SUBSTR(de, 2), NULL
  FROM periode WHERE genre = 'non_rattache'
),
agregats AS (
  -- Utilisateurs distincts sur toute la période (jour vide), puis jour par jour.
  SELECT genre, de, vers, CAST(NULL AS DATE) AS jour, COUNT(DISTINCT user_pseudo_id) AS utilisateurs
  FROM faits GROUP BY genre, de, vers
  UNION ALL
  SELECT genre, de, vers, jour, COUNT(DISTINCT user_pseudo_id)
  FROM faits GROUP BY genre, de, vers, jour
),
resultat AS (
  -- Pas de chiffre faux : flèches non mesurables et abandons qui en dépendent
  -- laissés vides.
  SELECT genre, de, vers, jour,
    IF((genre = 'fleche' AND CONCAT(de, '>', vers) IN UNNEST(['obtenir_mon_offre>signup', 'offres_remboursement_elsee>signup', 'remboursement_complements_alimentaires>signup']))
       OR (genre = 'continuent' AND de IN UNNEST(['remboursement_complements_alimentaires', 'offres_remboursement_elsee', 'obtenir_mon_offre'])),
       NULL, utilisateurs) AS utilisateurs
  FROM agregats
)
SELECT * FROM resultat
ORDER BY genre, de, vers, jour;
