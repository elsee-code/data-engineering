-- 09 — L'identifiant GA4 survit-il au passage www.elsee.care → app.elsee.care ?
-- La requête 05 compte les sessions qui s'ouvrent sur app.elsee.care avec
-- www.elsee.care comme provenance (rupture de session). Celle-ci dit si, dans
-- ces sessions, la personne garde le même user_pseudo_id que sur www (seule la
-- session est coupée) ou si GA4 la voit comme une nouvelle personne
-- (événement first_visit, identifiant jamais vu sur www).
-- « dont_parametre_gl_dans_url » : l'URL d'arrivée porte le paramètre _gl du
-- suivi inter-domaines (le lien a bien été décoré par www).
-- Lecture seule. Ne renvoie que des agrégats.

DECLARE date_debut STRING DEFAULT '20261005';
DECLARE date_fin   STRING DEFAULT FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY));

WITH ev AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    event_name,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'))) AS domaine,
    LOWER(NET.HOST((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer'))) AS provenance,
    REGEXP_CONTAINS((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'), r'[?&]_gl=') AS avec_gl,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN date_debut AND date_fin
    AND user_pseudo_id IS NOT NULL
),
-- Sessions qui commencent sur app.elsee.care avec www.elsee.care comme provenance.
entrees_app AS (
  SELECT user_pseudo_id, ga_session_id,
    ARRAY_AGG(STRUCT(domaine, provenance, avec_gl, event_timestamp)
              ORDER BY event_timestamp, batch_ordering_id, batch_page_id, batch_event_index LIMIT 1)[OFFSET(0)] AS e
  FROM ev
  WHERE event_name = 'page_view' AND ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),
coupees AS (
  SELECT * FROM entrees_app
  WHERE e.domaine = 'app.elsee.care' AND e.provenance = 'www.elsee.care'
)
SELECT
  COUNT(*) AS sessions_app_ouvertes_depuis_www,
  COUNTIF(EXISTS (SELECT 1 FROM ev WHERE ev.user_pseudo_id = c.user_pseudo_id
                  AND ev.domaine = 'www.elsee.care' AND ev.event_name = 'page_view'
                  AND ev.event_timestamp < c.e.event_timestamp)) AS dont_meme_identifiant_vu_avant_sur_www,
  COUNTIF(EXISTS (SELECT 1 FROM ev WHERE ev.user_pseudo_id = c.user_pseudo_id
                  AND ev.ga_session_id = c.ga_session_id AND ev.event_name = 'first_visit')) AS dont_premiere_visite_ga4,
  COUNTIF(c.e.avec_gl) AS dont_parametre_gl_dans_url
FROM coupees AS c;
