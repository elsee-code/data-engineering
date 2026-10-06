-- 07 — Pages hors motif vues juste après une page du tunnel
-- Question : le motif de la requête 06 rate-t-il des pages du formulaire ?
-- (étape au chemin inattendu, page d'erreur, page de connexion, paiement…)
-- Pour chaque page du tunnel, on regarde la page vue immédiatement après dans la
-- session, quand elle ne correspond pas au motif.
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut   STRING DEFAULT '20261005';
DECLARE date_fin     STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));
DECLARE motif_tunnel STRING DEFAULT r'^/(signup|social|obtenir-mon-offre|mon-offre|mon-panier|bienvenue|offres|pricing|remboursement)';

CREATE TEMP FUNCTION chemin(url STRING) AS (
  IF(url IS NULL, NULL,
     IFNULL(NULLIF(REGEXP_REPLACE(LOWER(REGEXP_EXTRACT(url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')), r'/+$', ''), ''), '/'))
);

WITH pages_vues AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view'
    AND user_pseudo_id IS NOT NULL
),
suites AS (
  SELECT
    user_pseudo_id,
    CONCAT(LOWER(NET.HOST(url)), chemin(url))   AS page,
    REGEXP_CONTAINS(chemin(url), motif_tunnel)  AS est_tunnel,
    LEAD(CONCAT(LOWER(NET.HOST(url)), chemin(url)))  OVER w AS page_suivante,
    LEAD(REGEXP_CONTAINS(chemin(url), motif_tunnel)) OVER w AS suivante_est_tunnel
  FROM pages_vues
  WHERE ga_session_id IS NOT NULL
  WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id
               ORDER BY event_timestamp, batch_ordering_id, batch_page_id, batch_event_index)
)
SELECT
  page                            AS depuis_page_du_tunnel,
  page_suivante                   AS vers_page_hors_motif,
  COUNT(DISTINCT user_pseudo_id)  AS utilisateurs,
  COUNT(*)                        AS occurrences
FROM suites
WHERE est_tunnel
  AND page_suivante IS NOT NULL
  AND NOT suivante_est_tunnel
GROUP BY depuis_page_du_tunnel, vers_page_hors_motif
ORDER BY utilisateurs DESC
LIMIT 300;
