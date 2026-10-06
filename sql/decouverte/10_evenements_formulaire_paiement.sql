-- 10 — Événements du formulaire, du panier et du paiement
-- Sur quelles pages partent step_form, form_start, click_form, add_to_cart et
-- order_paid, avec quelle provenance et quels paramètres (noms seulement, pas
-- les valeurs) ? Inclut les pages vues de /success et /bienvenue-chez-elsee.
-- Sert à repérer la page de paiement (domaine de provenance) et les
-- événements utiles plus tard (sous-étapes de /obtenir-mon-offre).
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));
CREATE TEMP FUNCTION chemin(url STRING) AS (
  IF(url IS NULL, NULL,
     IFNULL(NULLIF(REGEXP_REPLACE(LOWER(REGEXP_EXTRACT(url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')), r'/+$', ''), ''), '/'))
);
WITH ev AS (
  SELECT
    user_pseudo_id, event_name, event_timestamp,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer'))) AS provenance,
    ARRAY(SELECT key FROM UNNEST(event_params) ORDER BY key) AS cles
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
)
SELECT
  event_name,
  CONCAT(LOWER(NET.HOST(url)), chemin(url)) AS page,
  IFNULL(provenance, '(aucune)') AS provenance,
  ARRAY_TO_STRING(cles, ' ') AS parametres,
  COUNT(DISTINCT user_pseudo_id) AS utilisateurs,
  COUNT(*) AS evenements
FROM ev
WHERE event_name IN ('step_form', 'form_start', 'click_form', 'add_to_cart', 'order_paid')
   OR (event_name = 'page_view' AND REGEXP_CONTAINS(chemin(url), r'^/(success|bienvenue-chez-elsee)$'))
GROUP BY 1, 2, 3, 4
ORDER BY event_name, utilisateurs DESC
;
