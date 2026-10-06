-- 12 — Après /signup/medecine_douce_step : nouvelle étape ou non, heure par heure
-- /signup/en_savoir_plus_sur_vous (nouvelle étape du schéma) n'est vue que par
-- une partie des personnes. Si elle avait été mise en ligne en cours de
-- période, elle n'apparaîtrait qu'à partir d'une certaine heure.
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));
WITH pv AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    REGEXP_EXTRACT(LOWER((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')), r'^[a-z]+://[^/?#]+(/[^?#]*)') AS chemin,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view' AND user_pseudo_id IS NOT NULL
),
suites AS (
  SELECT chemin, event_timestamp, user_pseudo_id,
    LEAD(chemin) OVER (PARTITION BY user_pseudo_id, ga_session_id
                       ORDER BY event_timestamp, batch_ordering_id, batch_page_id, batch_event_index) AS suivante
  FROM pv
  WHERE REGEXP_CONTAINS(chemin, r'^/signup')
)
SELECT
  FORMAT_TIMESTAMP('%H', TIMESTAMP_MICROS(event_timestamp), 'Europe/Paris') AS heure_paris,
  COUNT(DISTINCT IF(suivante = '/signup/en_savoir_plus_sur_vous', user_pseudo_id, NULL)) AS vers_en_savoir_plus,
  COUNT(DISTINCT IF(suivante = '/signup/depenses_sports', user_pseudo_id, NULL))         AS vers_depenses_sports
FROM suites
WHERE chemin = '/signup/medecine_douce_step'
GROUP BY heure_paris
ORDER BY heure_paris
;
