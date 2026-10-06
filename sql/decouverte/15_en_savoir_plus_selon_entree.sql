-- 15 — Qui voit /signup/en_savoir_plus_sur_vous ?
-- D'après Eglantine, cette page recueille les coordonnées des personnes qui ne
-- les ont pas encore données : celles arrivées par /social_signup ou
-- directement par /signup. Celles venues de /obtenir-mon-offre,
-- /offres-remboursement-elsee, /signup-corpo ou
-- /remboursement-complements-alimentaires les ont déjà données avant
-- /signup/depenses_complements.
-- Pour les sessions passées par /signup/medecine_douce_step : première page de
-- la session sur app.elsee.care et sa provenance, et si la personne voit la page.
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));
WITH pv AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    REGEXP_EXTRACT(LOWER((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')), r'^[a-z]+://[^/?#]+(/[^?#]*)') AS chemin,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'))) AS domaine,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer'))) AS provenance,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view' AND user_pseudo_id IS NOT NULL
),
sessions AS (
  SELECT user_pseudo_id, ga_session_id,
    ARRAY_AGG(STRUCT(chemin, provenance) ORDER BY event_timestamp, batch_ordering_id, batch_page_id, batch_event_index LIMIT 1)[OFFSET(0)] AS entree,
    LOGICAL_OR(chemin = '/signup/medecine_douce_step') AS voit_mds,
    LOGICAL_OR(chemin = '/signup/en_savoir_plus_sur_vous') AS voit_espsv
  FROM pv WHERE domaine = 'app.elsee.care' AND ga_session_id IS NOT NULL
  GROUP BY 1, 2
)
SELECT
  entree.chemin AS premiere_page_app_de_la_session,
  IFNULL(entree.provenance, '(aucune)') AS provenance,
  COUNT(DISTINCT IF(voit_espsv, user_pseudo_id, NULL)) AS voient_en_savoir_plus,
  COUNT(DISTINCT IF(NOT voit_espsv, user_pseudo_id, NULL)) AS ne_la_voient_pas
FROM sessions
WHERE voit_mds
GROUP BY 1, 2
ORDER BY 3 + 4 DESC
;
