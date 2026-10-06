-- 05 — Le suivi inter-domaines fonctionne-t-il ?
-- Si oui, quelqu'un qui passe d'elsee.care à app.elsee.care reste dans la même
-- session (même user_pseudo_id et même ga_session_id).
-- Si non, une nouvelle session démarre sur app.elsee.care avec elsee.care comme
-- page de provenance : c'est ce que compte « sessions_app_coupees_depuis_le_site ».
-- Taux de rupture ≈ coupees / (coupees + sessions_site_puis_app).
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut  STRING DEFAULT '20261005';
DECLARE date_fin    STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));
-- Domaine de l'application, d'après le brief : à confirmer avec la requête 04.
DECLARE domaine_app STRING DEFAULT 'app.elsee.care';

WITH pages_vues AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'))) AS domaine,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer'))) AS domaine_provenance,
    REGEXP_CONTAINS((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'), r'[?&]_gl=') AS avec_parametre_gl,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view'
    AND user_pseudo_id IS NOT NULL
),
classees AS (
  SELECT
    *,
    domaine = domaine_app AS est_app,
    domaine != domaine_app AND REGEXP_CONTAINS(domaine, r'(^|\.)elsee\.care$') AS est_site,
    domaine_provenance != domaine_app AND REGEXP_CONTAINS(domaine_provenance, r'(^|\.)elsee\.care$') AS vient_du_site
  FROM pages_vues
),
sessions AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    LOGICAL_OR(est_app)  AS voit_app,
    LOGICAL_OR(est_site) AS voit_site,
    ARRAY_AGG(STRUCT(est_app, vient_du_site, avec_parametre_gl)
              ORDER BY event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
              LIMIT 1)[OFFSET(0)] AS entree
  FROM classees
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),
utilisateurs AS (
  SELECT user_pseudo_id, LOGICAL_OR(est_app) AS voit_app, LOGICAL_OR(est_site) AS voit_site
  FROM classees
  GROUP BY user_pseudo_id
)
SELECT
  COUNT(*)                                                         AS sessions,
  COUNTIF(voit_app)                                                AS sessions_avec_app,
  COUNTIF(voit_app AND voit_site)                                  AS sessions_site_puis_app,
  COUNTIF(entree.est_app)                                          AS sessions_commencant_sur_app,
  COUNTIF(entree.est_app AND IFNULL(entree.vient_du_site, FALSE))  AS sessions_app_coupees_depuis_le_site,
  COUNTIF(entree.est_app AND entree.avec_parametre_gl)             AS sessions_app_entree_avec_parametre_gl,
  (SELECT COUNTIF(voit_app AND voit_site)     FROM utilisateurs)   AS utilisateurs_site_et_app,
  (SELECT COUNTIF(voit_app AND NOT voit_site) FROM utilisateurs)   AS utilisateurs_app_seulement
FROM sessions;
