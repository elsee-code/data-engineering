-- 11 — L'identifiant GA4 survit-il au retour vers www.elsee.care ?
-- Pages vues sur www.elsee.care (dont /bienvenue-chez-elsee) dont la provenance
-- est app.elsee.care ou la page de paiement Stripe : la personne a-t-elle le
-- même user_pseudo_id, et la même session, que sur app.elsee.care avant ?
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));
WITH pv AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'))) AS domaine,
    REGEXP_EXTRACT(LOWER((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')), r'^[a-z]+://[^/?#]+(/[^?#]*)') AS chemin,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer'))) AS provenance,
    event_timestamp
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND event_name = 'page_view' AND user_pseudo_id IS NOT NULL
),
-- Pages vues sur www.elsee.care venant de app.elsee.care ou de Stripe.
retours AS (
  SELECT * FROM pv
  WHERE domaine = 'www.elsee.care' AND provenance IN ('app.elsee.care', 'checkout.stripe.com')
)
SELECT
  provenance,
  COUNT(DISTINCT user_pseudo_id) AS utilisateurs,
  COUNT(DISTINCT IF(EXISTS (SELECT 1 FROM pv p WHERE p.user_pseudo_id = r.user_pseudo_id
                             AND p.domaine = 'app.elsee.care' AND p.event_timestamp < r.event_timestamp),
                    user_pseudo_id, NULL)) AS dont_meme_identifiant_vu_avant_sur_app,
  COUNT(DISTINCT IF(EXISTS (SELECT 1 FROM pv p WHERE p.user_pseudo_id = r.user_pseudo_id
                             AND p.ga_session_id = r.ga_session_id
                             AND p.domaine = 'app.elsee.care' AND p.event_timestamp < r.event_timestamp),
                    user_pseudo_id, NULL)) AS dont_meme_session_que_sur_app
FROM retours r
GROUP BY provenance
;
