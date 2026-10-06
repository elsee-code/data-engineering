-- 02 — Volumes par jour, consentement et fuseau horaire
-- Questions :
--   - combien d'événements, de pages vues, d'utilisateurs et de sessions par jour ?
--   - quelle part des événements n'a pas d'identifiant (refus de cookies) ?
--   - des user_id sont-ils envoyés ?
--   - fuseau de la propriété : premier et dernier événement de chaque journée en UTC
--     (une journée qui commence à 22:00 UTC la veille = Europe/Paris en heure d'été).
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));

SELECT
  event_date,
  COUNT(*)                                                 AS evenements,
  COUNTIF(event_name = 'page_view')                        AS pages_vues,
  COUNT(DISTINCT user_pseudo_id)                           AS utilisateurs,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '.', CAST(
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)))
                                                           AS sessions,
  COUNTIF(user_pseudo_id IS NULL)                          AS evenements_sans_identifiant,
  COUNTIF(privacy_info.analytics_storage = 'No')           AS evenements_analytics_refuse,
  COUNTIF(user_id IS NOT NULL)                             AS evenements_avec_user_id,
  COUNT(DISTINCT stream_id)                                AS flux_de_donnees,
  MIN(TIMESTAMP_MICROS(event_timestamp))                   AS premier_evenement_utc,
  MAX(TIMESTAMP_MICROS(event_timestamp))                   AS dernier_evenement_utc
FROM `ga4-chemin-form.analytics_383563328.events_*`
WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
  AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
GROUP BY event_date
ORDER BY event_date;
