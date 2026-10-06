-- 14 — Sessions qui commencent sur /mon-offre, /mon-panier ou /bienvenue-chez-elsee
-- Ces pages appartiennent à plusieurs parcours (offre directe, long form,
-- compléments, carte cadeau) : le parcours se déduit de la page précédente.
-- Quand la session commence sur l'une d'elles (retour par un lien, un e-mail,
-- le paiement), il n'y a pas de page précédente dans la session.
-- Cette requête regarde si la même personne a vu, dans une session précédente,
-- une page du tunnel qui donne le parcours, et combien de temps avant.
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));

CREATE TEMP FUNCTION chemin(url STRING) AS (
  IF(url IS NULL, NULL,
     IFNULL(NULLIF(REGEXP_REPLACE(LOWER(REGEXP_EXTRACT(url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')), r'/+$', ''), ''), '/'))
);

WITH pv AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    chemin((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')) AS chemin,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'))) AS domaine,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view' AND user_pseudo_id IS NOT NULL
),
tunnel AS (
  SELECT *,
    -- Parcours donné par la page (pages à un seul parcours seulement).
    CASE
      WHEN chemin = '/signup/offre_en_preparation' OR chemin = '/signup/final_step' THEN 'long form'
      WHEN chemin IN ('/offres', '/signup/bilan', '/signup/bonus-abonnement', '/signup/recap_remboursements') THEN 'compléments'
      WHEN chemin = '/pricing/cartecadeau' THEN 'carte cadeau'
      WHEN chemin = '/signup' THEN 'offre directe ou début du long form'
      WHEN STARTS_WITH(chemin, '/signup/') THEN 'long form (en cours)'
    END AS parcours_donne,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id, ga_session_id
                       ORDER BY event_timestamp, batch_ordering_id, batch_page_id, batch_event_index) AS rang
  FROM pv
  WHERE domaine IN ('app.elsee.care', 'www.elsee.care')
    AND ga_session_id IS NOT NULL
    AND (STARTS_WITH(chemin, '/signup') OR chemin IN ('/mon-offre', '/mon-panier', '/bienvenue-chez-elsee', '/offres', '/pricing/cartecadeau', '/social_signup'))
),
debuts AS (
  -- Première page du tunnel de chaque session, si c'est une page à plusieurs parcours.
  SELECT user_pseudo_id, ga_session_id, chemin, event_timestamp
  FROM tunnel
  WHERE rang = 1 AND chemin IN ('/mon-offre', '/mon-panier', '/bienvenue-chez-elsee')
),
avec_passe AS (
  SELECT d.chemin, d.user_pseudo_id, d.event_timestamp AS debut,
    ARRAY_AGG(STRUCT(t.parcours_donne, t.event_timestamp) ORDER BY t.event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS dernier
  FROM debuts AS d
  LEFT JOIN tunnel AS t
    ON t.user_pseudo_id = d.user_pseudo_id
   AND t.ga_session_id != d.ga_session_id
   AND t.event_timestamp < d.event_timestamp
   AND t.parcours_donne IS NOT NULL
  GROUP BY d.chemin, d.user_pseudo_id, d.ga_session_id, d.event_timestamp
)
SELECT
  chemin AS premiere_page_de_la_session,
  IFNULL(dernier.parcours_donne, '(aucune page du tunnel avant)') AS parcours_dans_une_session_precedente,
  CASE
    WHEN dernier.event_timestamp IS NULL THEN ''
    WHEN debut - dernier.event_timestamp < 3600 * 1000000 THEN 'moins de 1 h avant'
    WHEN debut - dernier.event_timestamp < 24 * 3600 * 1000000 THEN '1 à 24 h avant'
    ELSE 'plus de 24 h avant'
  END AS delai,
  COUNT(DISTINCT user_pseudo_id) AS utilisateurs
FROM avec_passe
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC;
