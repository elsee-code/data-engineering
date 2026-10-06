-- 13 — Depuis quelle page de www.elsee.care arrive-t-on sur le formulaire ?
-- Le passage www.elsee.care → app.elsee.care perd le plus souvent l'identifiant
-- GA4 (requête 09) : on ne peut pas suivre la personne d'un domaine à l'autre.
-- Mais la première page vue sur app.elsee.care garde l'adresse complète de la
-- page de provenance (page_referrer). Cette requête compte, pour chaque page
-- d'arrivée du tunnel sur app.elsee.care, les utilisateurs (identifiant côté
-- app) selon le chemin de la page www.elsee.care d'où ils viennent.
-- Résultat au 5 oct. 2026 : la provenance est toujours réduite au domaine
-- (« / ») par la politique de provenance des navigateurs. Cette piste ne
-- permet donc pas de savoir de quelle page de www on vient.
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));

CREATE TEMP FUNCTION chemin(url STRING) AS (
  IF(url IS NULL, NULL,
     IFNULL(NULLIF(REGEXP_REPLACE(LOWER(REGEXP_EXTRACT(url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')), r'/+$', ''), ''), '/'))
);

WITH pages_vues AS (
  SELECT
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer') AS provenance
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view'
    AND user_pseudo_id IS NOT NULL
)
SELECT
  chemin(url)        AS arrivee_sur_app,
  chemin(provenance) AS depuis_www,
  COUNT(DISTINCT user_pseudo_id) AS utilisateurs,
  COUNT(*)                       AS pages_vues
FROM pages_vues
WHERE LOWER(NET.HOST(url)) = 'app.elsee.care'
  AND LOWER(NET.HOST(provenance)) = 'www.elsee.care'
  AND REGEXP_CONTAINS(chemin(url), r'^/(signup|social_signup|mon-offre|offres|mon-panier)')
GROUP BY arrivee_sur_app, depuis_www
ORDER BY arrivee_sur_app, utilisateurs DESC;
