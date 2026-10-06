-- 03 — Inventaire des événements
-- Question : le formulaire envoie-t-il un page_view par étape, ou des événements
-- personnalisés (étape de formulaire, lead…) qu'il faudrait connaître ?
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));

SELECT
  event_name,
  COUNT(*)                        AS evenements,
  COUNT(DISTINCT user_pseudo_id)  AS utilisateurs,
  COUNTIF(REGEXP_CONTAINS(
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'),
    r'/signup'))                  AS evenements_sur_une_page_signup
FROM `ga4-chemin-form.analytics_383563328.events_*`
WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
  AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
GROUP BY event_name
ORDER BY evenements DESC;
