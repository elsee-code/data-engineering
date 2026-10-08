-- Création de la fonction de table elsee_funnel.agregats(date_debut, date_fin)
-- FICHIER GÉNÉRÉ par scripts/generer_sql.mjs à partir de config/graphe.json :
-- ne pas modifier à la main.
-- À lancer seulement après validation (écriture dans elsee_funnel).
-- Même calcul et même résultat que agregats.sql.
-- Exemple : SELECT * FROM `ga4-chemin-form.elsee_funnel.agregats`(DATE '2026-10-05', DATE '2026-10-11')
CREATE OR REPLACE TABLE FUNCTION `ga4-chemin-form.elsee_funnel.agregats`(date_debut DATE, date_fin DATE) AS (
WITH
etapes AS (
SELECT * FROM UNNEST(ARRAY<STRUCT<id STRING, cle STRING, n INT64, atteint STRING, rattache ARRAY<INT64>>>[
('signup_corpo', 'app.elsee.care/signup-corpo', 1, '01efffffffffe1c0', [9, 10, 11, 56]),
('remboursement_complements_alimentaires', 'www.elsee.care/remboursement-complements-alimentaires', 2, '01efffffffffe1c0', [9, 10, 11, 56]),
('offres_remboursement_elsee', 'www.elsee.care/offres-remboursement-elsee', 3, '01efffffffffe1c0', [9, 10, 11, 56]),
('obtenir_mon_offre', 'www.elsee.care/obtenir-mon-offre', 4, '0fefffffffffe1c0', [9, 10, 11, 56]),
('obtenir_mon_offre_2', 'step_form:/obtenir-mon-offre-2', 5, '07efffffffffe1c0', [9, 10, 11, 56]),
('obtenir_mon_offre_3', 'step_form:/obtenir-mon-offre-3', 6, '03efffffffffe1c0', [9, 10, 11, 56]),
('obtenir_mon_offre_4', 'step_form:/obtenir-mon-offre-4', 7, '01efffffffffe1c0', [9, 10, 11, 56]),
('signup', 'app.elsee.care/signup', 8, '00efffffffffe1c0', [9, 10, 11, 56]),
('mon_offre_directe', 'app.elsee.care/mon-offre', 9, '00600000000001c0', [9, 10, 11, 56]),
('mon_panier_directe', 'app.elsee.care/mon-panier', 10, '0020000000000000', [9, 10, 11, 0]),
('paiement_ok_directe', 'www.elsee.care/bienvenue-chez-elsee', 11, '0000000000000000', [9, 10, 11, 0]),
('social_signup', 'app.elsee.care/social_signup', 12, '000fffffffffe000', [46, 44, 45, 49]),
('depenses_complements', 'app.elsee.care/signup/depenses_complements', 13, '0007ffffffffe000', [46, 44, 45, 49]),
('montant_complements', 'app.elsee.care/signup/montant_complements', 14, '0003ffffffffe000', [46, 44, 45, 49]),
('network_complements', 'app.elsee.care/signup/network_complements', 15, '0001ffffffffe000', [46, 44, 45, 49]),
('recap_marques', 'app.elsee.care/signup/recap_marques', 16, '0000ffffffffe000', [46, 44, 45, 49]),
('depenses_complements_step', 'app.elsee.care/signup/depenses_complements_step', 17, '00007ffffe07e000', [46, 47, 48, 49]),
('sante_mentale_seances', 'app.elsee.care/signup/sante_mentale_seances', 18, '00003ffffe07e000', [46, 47, 48, 49]),
('montant_sante_mentale', 'app.elsee.care/signup/montant_sante_mentale', 19, '00001ffffc07e000', [46, 47, 48, 49]),
('md_seances', 'app.elsee.care/signup/md_seances', 20, '00000ffffc07e000', [46, 47, 48, 49]),
('montant_medecine_douce', 'app.elsee.care/signup/montant_medecine_douce', 21, '000007fffc07e000', [46, 47, 48, 49]),
('soins_seances', 'app.elsee.care/signup/soins_seances', 22, '000003fffc07e000', [46, 47, 48, 49]),
('montant_soins', 'app.elsee.care/signup/montant_soins', 23, '000001fffc07e000', [46, 47, 48, 49]),
('network_info', 'app.elsee.care/signup/network_info', 24, '000000fffc07e000', [46, 47, 48, 49]),
('prete_a_changer', 'app.elsee.care/signup/prete_a-changer', 25, '0000007ffc07e000', [46, 47, 48, 49]),
('medecine_douce_step', 'app.elsee.care/signup/medecine_douce_step', 26, '0000003ffc07e000', [46, 47, 48, 49]),
('en_savoir_plus_sur_vous', 'app.elsee.care/signup/en_savoir_plus_sur_vous', 27, '0000001ffc07e000', [46, 47, 48, 49]),
('depenses_sports', 'app.elsee.care/signup/depenses_sports', 28, '0000000ffc07e000', [46, 47, 48, 49]),
('network_sport', 'app.elsee.care/signup/network_sport', 29, '00000007fc07e000', [46, 47, 48, 49]),
('out_of_network_sport', 'app.elsee.care/signup/out_of_network_sport', 30, '00000003fc07e000', [46, 47, 48, 49]),
('sport_step', 'app.elsee.care/signup/sport_step', 31, '00000001fc07e000', [46, 47, 48, 49]),
('depenses_produit', 'app.elsee.care/signup/depenses_produit', 32, '00000000fc07e000', [46, 47, 48, 49]),
('network_produit', 'app.elsee.care/signup/network_produit', 33, '000000007c07e000', [46, 47, 48, 49]),
('out_of_network_produit', 'app.elsee.care/signup/out_of_network_produit', 34, '000000003c07e000', [46, 47, 48, 49]),
('depenses_app', 'app.elsee.care/signup/depenses_app', 35, '000000001c07e000', [46, 47, 48, 49]),
('out_of_network_app', 'app.elsee.care/signup/out_of_network_app', 36, '000000000c07e000', [46, 47, 48, 49]),
('final_step', 'app.elsee.care/signup/final_step', 37, '000000000407e000', [46, 47, 48, 49]),
('offre_en_preparation', 'app.elsee.care/signup/offre_en_preparation', 38, '000000000007e000', [46, 47, 48, 49]),
('sante_mentale_step', 'app.elsee.care/signup/sante_mentale_step', 39, '00001ffffc07e000', [46, 47, 48, 49]),
('recap_remboursements', 'app.elsee.care/signup/recap_remboursements', 40, '0000000000f80000', [0, 44, 45, 0]),
('bonus_abonnement', 'app.elsee.care/signup/bonus-abonnement', 41, '0000000000780000', [0, 44, 45, 0]),
('bilan', 'app.elsee.care/signup/bilan', 42, '0000000000380000', [0, 44, 45, 0]),
('offres', 'app.elsee.care/offres', 43, '0000000000180000', [0, 44, 45, 0]),
('mon_panier_complements', 'app.elsee.care/mon-panier', 44, '0000000000080000', [0, 44, 45, 0]),
('paiement_ok_complements', 'www.elsee.care/bienvenue-chez-elsee', 45, '0000000000000000', [0, 44, 45, 0]),
('mon_offre_long_form', 'app.elsee.care/mon-offre', 46, '000000000003e000', [46, 47, 48, 49]),
('mon_panier_long_form', 'app.elsee.care/mon-panier', 47, '0000000000010000', [46, 47, 48, 0]),
('paiement_ok_long_form', 'www.elsee.care/bienvenue-chez-elsee', 48, '0000000000000000', [46, 47, 48, 0]),
('cartecadeau_long_form', 'app.elsee.care/pricing/cartecadeau', 49, '0000000000006000', [0, 50, 51, 49]),
('mon_panier_cc_long_form', 'app.elsee.care/mon-panier', 50, '0000000000002000', [0, 50, 51, 49]),
('paiement_ok_cc_long_form', 'www.elsee.care/bienvenue-chez-elsee', 51, '0000000000000000', [0, 50, 51, 49]),
('mon_bilan_elsee', 'www.elsee.care/mon-bilan-elsee', 52, '0000000000000e38', [53, 54, 55, 59]),
('mon_offre_mail', 'app.elsee.care/mon-offre', 53, '0000000000000638', [53, 54, 55, 59]),
('mon_panier_mail', 'app.elsee.care/mon-panier', 54, '0000000000000200', [53, 54, 55, 0]),
('paiement_ok_mail', 'www.elsee.care/bienvenue-chez-elsee', 55, '0000000000000000', [53, 54, 55, 0]),
('cartecadeau_directe', 'app.elsee.care/pricing/cartecadeau', 56, '00000000000000c0', [0, 57, 58, 56]),
('mon_panier_cc_directe', 'app.elsee.care/mon-panier', 57, '0000000000000040', [0, 57, 58, 56]),
('paiement_ok_cc_directe', 'www.elsee.care/bienvenue-chez-elsee', 58, '0000000000000000', [0, 57, 58, 56]),
('cartecadeau_mail', 'app.elsee.care/pricing/cartecadeau', 59, '0000000000000018', [0, 60, 61, 59]),
('mon_panier_cc_mail', 'app.elsee.care/mon-panier', 60, '0000000000000008', [0, 60, 61, 59]),
('paiement_ok_cc_mail', 'www.elsee.care/bienvenue-chez-elsee', 61, '0000000000000000', [0, 60, 61, 59])
])
),
chemins AS (
SELECT cle, IF(COUNT(*) = 1, ANY_VALUE(id), NULL) AS id_unique
FROM etapes
GROUP BY cle
),
fleches AS (
SELECT * FROM UNNEST(ARRAY<STRUCT<de STRING, vers STRING>>[
('obtenir_mon_offre', 'obtenir_mon_offre_2'),
('obtenir_mon_offre_2', 'obtenir_mon_offre_3'),
('obtenir_mon_offre_3', 'obtenir_mon_offre_4'),
('obtenir_mon_offre_4', 'signup'),
('offres_remboursement_elsee', 'signup'),
('remboursement_complements_alimentaires', 'signup'),
('signup_corpo', 'signup'),
('signup', 'mon_offre_directe'),
('mon_offre_directe', 'mon_panier_directe'),
('mon_panier_directe', 'paiement_ok_directe'),
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
('mon_panier_complements', 'paiement_ok_complements'),
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
('mon_panier_long_form', 'paiement_ok_long_form'),
('mon_offre_long_form', 'cartecadeau_long_form'),
('cartecadeau_long_form', 'mon_panier_cc_long_form'),
('mon_panier_cc_long_form', 'paiement_ok_cc_long_form'),
('mon_bilan_elsee', 'mon_offre_mail'),
('mon_offre_mail', 'mon_panier_mail'),
('mon_panier_mail', 'paiement_ok_mail'),
('mon_offre_directe', 'cartecadeau_directe'),
('cartecadeau_directe', 'mon_panier_cc_directe'),
('mon_panier_cc_directe', 'paiement_ok_cc_directe'),
('mon_offre_mail', 'cartecadeau_mail'),
('cartecadeau_mail', 'mon_panier_cc_mail'),
('mon_panier_cc_mail', 'paiement_ok_cc_mail')
])
),
pages_multiples AS (
SELECT * FROM UNNEST(ARRAY<STRUCT<k INT64, cle STRING>>[
(0, 'app.elsee.care/mon-offre'),
(1, 'app.elsee.care/mon-panier'),
(2, 'www.elsee.care/bienvenue-chez-elsee'),
(3, 'app.elsee.care/pricing/cartecadeau')
])
),
par_precedente AS (
SELECT pm.cle, f.de AS precedente, f.vers AS etape
FROM fleches AS f
JOIN etapes AS ev ON ev.id = f.vers
JOIN pages_multiples AS pm ON pm.cle = ev.cle
),
par_derniere AS (
SELECT pm.cle, e.id AS derniere, c.id AS etape
FROM etapes AS e
CROSS JOIN UNNEST(e.rattache) AS r WITH OFFSET AS k
JOIN pages_multiples AS pm ON pm.k = k
JOIN etapes AS c ON c.n = r
),
replis AS (
SELECT * FROM UNNEST(ARRAY<STRUCT<cle STRING, etape STRING>>[
('app.elsee.care/mon-offre', 'mon_offre_mail'),
('app.elsee.care/mon-panier', 'mon_panier_mail'),
('www.elsee.care/bienvenue-chez-elsee', 'paiement_ok_mail'),
('app.elsee.care/pricing/cartecadeau', 'cartecadeau_mail')
])
),
pages AS (
SELECT
PARSE_DATE('%Y%m%d', event_date) AS jour,
user_pseudo_id,
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer') AS url_provenance,
event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
FROM `ga4-chemin-form.analytics_383563328.events_*`
WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(date_debut, INTERVAL 60 DAY))
AND FORMAT_DATE('%Y%m%d', DATE_ADD(date_fin, INTERVAL 1 DAY))
AND event_name = 'page_view'
AND user_pseudo_id IS NOT NULL
),
tunnel AS (
SELECT p.jour, p.user_pseudo_id, p.ga_session_id, p.cle, c.id_unique, p.provenance,
ROW_NUMBER() OVER (PARTITION BY p.user_pseudo_id, p.ga_session_id
ORDER BY p.event_timestamp, p.batch_ordering_id, p.batch_page_id, p.batch_event_index) AS rang,
ROW_NUMBER() OVER (PARTITION BY p.user_pseudo_id
ORDER BY p.event_timestamp, p.ga_session_id, p.batch_ordering_id, p.batch_page_id, p.batch_event_index) AS rang_personne
FROM (
SELECT * EXCEPT (cle_vue, page_avant),
CASE
WHEN cle_vue = 'www.elsee.care/bienvenue-chez-elsee' THEN IF(page_avant IN UNNEST(['app.elsee.care/mon-panier']) OR provenance IN UNNEST(['checkout.stripe.com']), 'www.elsee.care/bienvenue-chez-elsee', NULL)
WHEN cle_vue = 'app.elsee.care/success' THEN IF(page_avant IN UNNEST(['app.elsee.care/mon-panier', 'www.elsee.care/bienvenue-chez-elsee']) OR provenance IN UNNEST(['checkout.stripe.com']), 'www.elsee.care/bienvenue-chez-elsee', NULL)
ELSE cle_vue
END AS cle
FROM (
SELECT *,
LAG(cle_vue) OVER (PARTITION BY user_pseudo_id, ga_session_id
ORDER BY event_timestamp, batch_ordering_id, batch_page_id, batch_event_index) AS page_avant
FROM (
SELECT *,
CONCAT(LOWER(NET.HOST(url)),
IFNULL(NULLIF(REGEXP_REPLACE(LOWER(REGEXP_EXTRACT(url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')), r'/+$', ''), ''), '/')) AS cle_vue,
LOWER(NET.HOST(url_provenance)) AS provenance
FROM pages
WHERE ga_session_id IS NOT NULL
)
)
) AS p
JOIN chemins AS c USING (cle)
),
passe0 AS (
SELECT * EXCEPT (cle_avant), id_unique AS etape
FROM (SELECT *, LAG(cle) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS cle_avant FROM tunnel)
WHERE cle_avant IS NULL OR cle_avant != cle
),
passe1 AS (
SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_session, derniere_etape_personne),
COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
FROM (
SELECT *,
LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_session,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id ORDER BY rang_personne
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
FROM passe0
) AS x
LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
LEFT JOIN par_derniere AS pd ON pd.cle = x.cle
AND pd.derniere = IF(x.cle = 'www.elsee.care/bienvenue-chez-elsee' AND x.provenance IN UNNEST(['checkout.stripe.com']),
x.derniere_etape_personne, x.derniere_etape_session)
),
passe2 AS (
SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_session, derniere_etape_personne),
COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
FROM (
SELECT *,
LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_session,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id ORDER BY rang_personne
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
FROM passe1
) AS x
LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
LEFT JOIN par_derniere AS pd ON pd.cle = x.cle
AND pd.derniere = IF(x.cle = 'www.elsee.care/bienvenue-chez-elsee' AND x.provenance IN UNNEST(['checkout.stripe.com']),
x.derniere_etape_personne, x.derniere_etape_session)
),
passe3 AS (
SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_session, derniere_etape_personne),
COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
FROM (
SELECT *,
LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_session,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id ORDER BY rang_personne
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
FROM passe2
) AS x
LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
LEFT JOIN par_derniere AS pd ON pd.cle = x.cle
AND pd.derniere = IF(x.cle = 'www.elsee.care/bienvenue-chez-elsee' AND x.provenance IN UNNEST(['checkout.stripe.com']),
x.derniere_etape_personne, x.derniere_etape_session)
),
passe4 AS (
SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_session, derniere_etape_personne),
COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
FROM (
SELECT *,
LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_session,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id ORDER BY rang_personne
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
FROM passe3
) AS x
LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
LEFT JOIN par_derniere AS pd ON pd.cle = x.cle
AND pd.derniere = IF(x.cle = 'www.elsee.care/bienvenue-chez-elsee' AND x.provenance IN UNNEST(['checkout.stripe.com']),
x.derniere_etape_personne, x.derniere_etape_session)
),
passe5 AS (
SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_session, derniere_etape_personne),
COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
FROM (
SELECT *,
LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_session,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id ORDER BY rang_personne
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
FROM passe4
) AS x
LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
LEFT JOIN par_derniere AS pd ON pd.cle = x.cle
AND pd.derniere = IF(x.cle = 'www.elsee.care/bienvenue-chez-elsee' AND x.provenance IN UNNEST(['checkout.stripe.com']),
x.derniere_etape_personne, x.derniere_etape_session)
),
repli0 AS (
SELECT x.* EXCEPT (etape), x.etape IS NULL AS par_repli, COALESCE(x.etape, rp.etape) AS etape
FROM passe5 AS x
LEFT JOIN replis AS rp ON rp.cle = x.cle
),
repli1 AS (
SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
IF(x.par_repli, COALESCE(pp.etape, x.derniere_meme_page, pd.etape, x.etape), x.etape) AS etape
FROM (
SELECT *,
LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id ORDER BY rang_personne
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
FROM repli0
) AS x
LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
AND x.cle = 'www.elsee.care/bienvenue-chez-elsee' AND x.provenance IN UNNEST(['checkout.stripe.com'])
),
repli2 AS (
SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
IF(x.par_repli, COALESCE(pp.etape, x.derniere_meme_page, pd.etape, x.etape), x.etape) AS etape
FROM (
SELECT *,
LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id ORDER BY rang_personne
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
FROM repli1
) AS x
LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
AND x.cle = 'www.elsee.care/bienvenue-chez-elsee' AND x.provenance IN UNNEST(['checkout.stripe.com'])
),
repli3 AS (
SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
IF(x.par_repli, COALESCE(pp.etape, x.derniere_meme_page, pd.etape, x.etape), x.etape) AS etape
FROM (
SELECT *,
LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
LAST_VALUE(etape IGNORE NULLS) OVER (
PARTITION BY user_pseudo_id ORDER BY rang_personne
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
FROM repli2
) AS x
LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
AND x.cle = 'www.elsee.care/bienvenue-chez-elsee' AND x.provenance IN UNNEST(['checkout.stripe.com'])
),
resolues AS (
SELECT jour, user_pseudo_id, ga_session_id, rang, IFNULL(etape, CONCAT('?', cle)) AS e
FROM repli3
),
sans_rechargements AS (
SELECT * EXCEPT (precedente)
FROM (SELECT *, LAG(e) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente FROM resolues)
WHERE precedente IS NULL OR precedente != e
),
sans_detours AS (
SELECT d.* EXCEPT (p, n1, n2)
FROM (
SELECT *,
LAG(e) OVER w AS p, LEAD(e) OVER w AS n1, LEAD(e, 2) OVER w AS n2
FROM sans_rechargements
WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
) AS d
LEFT JOIN fleches AS f ON f.de = d.p AND f.vers = d.n2
WHERE NOT IFNULL(d.e IN ('cartecadeau_long_form', 'cartecadeau_directe', 'cartecadeau_mail')
AND d.n1 = d.p AND d.n2 != d.e AND f.de IS NOT NULL, FALSE)
),
suites AS (
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
SELECT s.jour, s.user_pseudo_id, s.e AS de, s.vers, s.premiere_de_la_session,
CASE
WHEN STARTS_WITH(s.e, '?') THEN 'non_rattache'
WHEN s.vers IS NULL THEN 'fin'
WHEN STARTS_WITH(s.vers, '?') THEN 'autre'
WHEN f.de IS NOT NULL THEN 'fleche'
WHEN CAST(CONCAT('0x', SUBSTR(ed.atteint, DIV(ev.n + 3, 4), 1)) AS INT64) & (8 >> MOD(ev.n - 1, 4)) > 0 THEN 'saut'
WHEN CAST(CONCAT('0x', SUBSTR(ev.atteint, DIV(ed.n + 3, 4), 1)) AS INT64) & (8 >> MOD(ed.n - 1, 4)) > 0 THEN 'retour'
ELSE 'autre'
END AS genre
FROM suites AS s
LEFT JOIN fleches AS f ON f.de = s.e AND f.vers = s.vers
LEFT JOIN etapes AS ed ON ed.id = s.e
LEFT JOIN etapes AS ev ON ev.id = s.vers
),
periode AS (
SELECT * FROM classees WHERE jour BETWEEN date_debut AND date_fin
),
sous_etapes AS (
SELECT s.jour, s.user_pseudo_id, MAX(s.rang) AS m, LOGICAL_OR(t.vu IS NOT NULL) AS vu
FROM (
SELECT PARSE_DATE('%Y%m%d', event_date) AS jour, user_pseudo_id,
(SELECT o + 1 FROM UNNEST(['/obtenir-mon-offre-1', '/obtenir-mon-offre-2', '/obtenir-mon-offre-3', '/obtenir-mon-offre-4']) AS v WITH OFFSET o
WHERE v = (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_derniere_page')) AS rang,
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url
FROM `ga4-chemin-form.analytics_383563328.events_*`
WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', date_debut) AND FORMAT_DATE('%Y%m%d', date_fin)
AND event_name = 'step_form'
AND user_pseudo_id IS NOT NULL
) AS s
LEFT JOIN (SELECT DISTINCT jour, user_pseudo_id, TRUE AS vu FROM tunnel WHERE id_unique = 'obtenir_mon_offre') AS t
ON t.jour = s.jour AND t.user_pseudo_id = s.user_pseudo_id
WHERE s.rang IS NOT NULL
AND CONCAT(LOWER(NET.HOST(s.url)),
IFNULL(NULLIF(REGEXP_REPLACE(LOWER(REGEXP_EXTRACT(s.url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')), r'/+$', ''), ''), '/')) = 'www.elsee.care/obtenir-mon-offre'
GROUP BY s.jour, s.user_pseudo_id
),
sous_faits AS (
SELECT * FROM UNNEST(ARRAY<STRUCT<seuil INT64, vu BOOL, genre STRING, de STRING, vers STRING>>[
(2, TRUE, 'continuent', 'obtenir_mon_offre', NULL),
(2, TRUE, 'fleche', 'obtenir_mon_offre', 'obtenir_mon_offre_2'),
(2, NULL, 'arrivees', 'obtenir_mon_offre_2', NULL),
(3, NULL, 'continuent', 'obtenir_mon_offre_2', NULL),
(3, NULL, 'fleche', 'obtenir_mon_offre_2', 'obtenir_mon_offre_3'),
(3, NULL, 'arrivees', 'obtenir_mon_offre_3', NULL),
(4, NULL, 'continuent', 'obtenir_mon_offre_3', NULL),
(4, NULL, 'fleche', 'obtenir_mon_offre_3', 'obtenir_mon_offre_4'),
(4, NULL, 'arrivees', 'obtenir_mon_offre_4', NULL),
(2, FALSE, 'entrees_directes', 'obtenir_mon_offre_2', NULL)
])
),
faits AS (
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
UNION ALL
SELECT s.jour, s.user_pseudo_id, f.genre, f.de, f.vers
FROM sous_etapes AS s
JOIN sous_faits AS f ON s.m >= f.seuil AND (f.vu IS NULL OR f.vu = s.vu)
),
agregats AS (
SELECT genre, de, vers, CAST(NULL AS DATE) AS jour, COUNT(DISTINCT user_pseudo_id) AS utilisateurs
FROM faits GROUP BY genre, de, vers
UNION ALL
SELECT genre, de, vers, jour, COUNT(DISTINCT user_pseudo_id)
FROM faits GROUP BY genre, de, vers, jour
),
pages_personne AS (
SELECT user_pseudo_id,
COUNT(DISTINCT cle) AS pages,
LOGICAL_OR(STARTS_WITH(cle, 'app.elsee.care/')) AS formulaire,
LOGICAL_OR(cle IN UNNEST(['app.elsee.care/signup-corpo', 'app.elsee.care/signup', 'app.elsee.care/social_signup'])) AS debut,
LOGICAL_OR(cle IN UNNEST(['app.elsee.care/mon-offre', 'app.elsee.care/offres'])) AS offre
FROM tunnel
WHERE jour BETWEEN date_debut AND date_fin
GROUP BY user_pseudo_id
),
repartition AS (
SELECT 'pages_vues' AS genre, CAST(pages AS STRING) AS de, CAST(NULL AS STRING) AS vers,
CAST(NULL AS DATE) AS jour, COUNT(*) AS utilisateurs
FROM pages_personne WHERE debut GROUP BY pages
UNION ALL
SELECT 'pages_vues_offre', CAST(pages AS STRING), NULL, NULL, COUNTIF(offre)
FROM pages_personne WHERE debut GROUP BY pages
UNION ALL
SELECT 'en_cours_de_route', NULL, NULL, NULL, COUNTIF(formulaire AND NOT debut)
FROM pages_personne
UNION ALL
SELECT 'hors_formulaire', NULL, NULL, NULL, COUNTIF(NOT formulaire)
FROM pages_personne
),
leads_pages AS (
SELECT *,
LAST_VALUE(a_l_entree IGNORE NULLS) OVER w AS entree,
LAG(id_unique) OVER w AS precedente
FROM (
SELECT jour, user_pseudo_id, ga_session_id, rang, rang_personne, id_unique,
CASE
WHEN provenance = 'app.elsee.care' THEN NULL
WHEN id_unique = 'signup_corpo' THEN TRUE
WHEN id_unique = 'remboursement_complements_alimentaires' THEN TRUE
WHEN id_unique = 'offres_remboursement_elsee' THEN TRUE
WHEN id_unique = 'obtenir_mon_offre' THEN TRUE
WHEN id_unique = 'signup' AND provenance = 'www.elsee.care' THEN TRUE
WHEN id_unique = 'signup' THEN FALSE
WHEN id_unique = 'social_signup' THEN FALSE
END AS a_l_entree
FROM tunnel
)
WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
),
leads_periode AS (
SELECT premier.* FROM (
SELECT ARRAY_AGG(STRUCT(jour, moment) ORDER BY rang_personne LIMIT 1)[OFFSET(0)] AS premier
FROM (
SELECT jour, user_pseudo_id, rang_personne,
CASE
WHEN id_unique = 'depenses_complements' AND entree THEN 'avant_depenses_complements'
WHEN id_unique = 'bilan' AND precedente = 'bonus_abonnement' AND NOT entree THEN 'popup_bilan'
WHEN id_unique = 'depenses_sports' AND precedente = 'en_savoir_plus_sur_vous' THEN 'en_savoir_plus_sur_vous'
END AS moment
FROM leads_pages
)
WHERE moment IS NOT NULL
GROUP BY user_pseudo_id
)
WHERE premier.jour BETWEEN date_debut AND date_fin
),
leads AS (
SELECT 'leads' AS genre, CAST(NULL AS STRING) AS de, CAST(NULL AS STRING) AS vers,
CAST(NULL AS DATE) AS jour, COUNT(*) AS utilisateurs
FROM leads_periode
UNION ALL
SELECT 'leads', moment, NULL, NULL, COUNT(*)
FROM leads_periode GROUP BY moment
UNION ALL
SELECT 'leads', NULL, NULL, jour, COUNT(*)
FROM leads_periode GROUP BY jour
),
resultat AS (
SELECT genre, de, vers, jour,
IF((genre = 'fleche' AND CONCAT(de, '>', vers) IN UNNEST(['obtenir_mon_offre_4>signup', 'offres_remboursement_elsee>signup', 'remboursement_complements_alimentaires>signup', 'mon_bilan_elsee>mon_offre_mail']))
OR (genre = 'continuent' AND de IN UNNEST(['remboursement_complements_alimentaires', 'offres_remboursement_elsee', 'obtenir_mon_offre_4', 'mon_bilan_elsee'])),
NULL, utilisateurs) AS utilisateurs
FROM agregats
UNION ALL
SELECT * FROM repartition
UNION ALL
SELECT * FROM leads
)
SELECT * FROM resultat
);
