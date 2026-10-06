-- 08 — Pages du tunnel sur lesquelles une session démarre
-- Une page d'entrée (/signup, /obtenir-mon-offre…) qui ouvre une session, c'est
-- normal. Une page du milieu ou de la fin du tunnel qui ouvre une session signale
-- une rupture : suivi inter-domaines cassé, retour d'une page de paiement externe
-- non exclue des sites référents, inactivité de plus de 30 minutes…
-- Notre définition des passages exige la même session : ces ruptures font
-- disparaître des passages. On regarde d'où viennent ces sessions (domaine de
-- provenance de leur première page).
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
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer'))) AS domaine_provenance,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view'
    AND user_pseudo_id IS NOT NULL
),
rangees AS (
  SELECT
    user_pseudo_id,
    CONCAT(LOWER(NET.HOST(url)), chemin(url))  AS page,
    REGEXP_CONTAINS(chemin(url), motif_tunnel) AS est_tunnel,
    domaine_provenance,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id, ga_session_id
                       ORDER BY event_timestamp, batch_ordering_id, batch_page_id, batch_event_index) AS rang
  FROM pages_vues
  WHERE ga_session_id IS NOT NULL
),
par_page AS (
  SELECT page, COUNT(DISTINCT user_pseudo_id) AS utilisateurs_sur_la_page
  FROM rangees
  WHERE est_tunnel
  GROUP BY page
)
SELECT
  r.page,
  p.utilisateurs_sur_la_page,
  IFNULL(r.domaine_provenance, '(aucune provenance)') AS provenance_en_debut_de_session,
  COUNT(DISTINCT r.user_pseudo_id)                    AS utilisateurs_arrives_en_debut_de_session
FROM rangees AS r
JOIN par_page AS p USING (page)
WHERE r.est_tunnel
  AND r.rang = 1
GROUP BY r.page, p.utilisateurs_sur_la_page, provenance_en_debut_de_session
ORDER BY p.utilisateurs_sur_la_page DESC, utilisateurs_arrives_en_debut_de_session DESC;
