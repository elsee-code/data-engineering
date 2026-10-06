-- 04 — Domaines et chemins vus en page_view
-- Questions :
--   - sur quels domaines tourne le tunnel (elsee.care, www., app., préproduction…) ?
--   - quels sont les vrais chemins de chaque étape, avec leurs volumes ?
--   - un même chemin existe-t-il sous plusieurs variantes (majuscules, / final) ?
-- Les chemins sont normalisés : sans paramètres ni ancre, en minuscules, sans
-- « / » final. « variantes_brutes » compte les écritures d'origine regroupées.
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut   STRING DEFAULT '20261005';
DECLARE date_fin     STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));
-- Préfixes large maille pour repérer les pages candidates du tunnel.
DECLARE motif_tunnel STRING DEFAULT r'^/(signup|social|obtenir-mon-offre|mon-offre|mon-panier|bienvenue|offres|pricing|remboursement)';

CREATE TEMP FUNCTION chemin_brut(url STRING) AS (
  REGEXP_EXTRACT(url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')
);
CREATE TEMP FUNCTION chemin(url STRING) AS (
  IF(url IS NULL, NULL,
     IFNULL(NULLIF(REGEXP_REPLACE(LOWER(chemin_brut(url)), r'/+$', ''), ''), '/'))
);

WITH pages_vues AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value    FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
    stream_id
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view'
)
SELECT
  LOWER(NET.HOST(url))                                          AS domaine,
  chemin(url)                                                   AS chemin,
  REGEXP_CONTAINS(chemin(url), motif_tunnel)                    AS candidat_tunnel,
  COUNT(DISTINCT user_pseudo_id)                                AS utilisateurs,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '.', CAST(ga_session_id AS STRING))) AS sessions,
  COUNT(*)                                                      AS pages_vues,
  COUNT(DISTINCT chemin_brut(url))                              AS variantes_brutes,
  STRING_AGG(DISTINCT stream_id)                                AS flux_de_donnees
FROM pages_vues
GROUP BY domaine, chemin, candidat_tunnel
ORDER BY candidat_tunnel DESC, utilisateurs DESC
LIMIT 1000;
