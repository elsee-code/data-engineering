-- Contrôle de cohérence du calcul
-- FICHIER GÉNÉRÉ par scripts/generer_sql.mjs à partir de config/graphe.json :
-- ne pas modifier à la main.
-- Script autonome (dates à régler ci-dessous). Lecture seule.
-- Pour chaque étape, sur toute la période :
--   sorties_fleches + sorties_sauts + abandons - arrivees = personnes ayant pris
--   plusieurs sorties (>= 0, petit) ;
--   entrees (flèches, sauts, retours, autres, débuts de session) - arrivees
--   = personnes arrivées par plusieurs chemins (>= 0, petit).
-- Un écart négatif signale une erreur de calcul.
DECLARE date_debut DATE DEFAULT DATE '2026-10-05';
DECLARE date_fin   DATE DEFAULT DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY);

WITH
etapes AS (
  -- n : numéro de l'étape ; atteint : n-ième caractère à 1 si l'étape n est plus
  -- loin en suivant les flèches ; rattache : voir par_derniere.
  SELECT * FROM UNNEST(ARRAY<STRUCT<id STRING, cle STRING, n INT64, atteint STRING, rattache ARRAY<INT64>>>[
    ('signup_corpo', 'app.elsee.care/signup-corpo', 1, '0000111101111111111111111111111111111111111111110000', [6, 7, 8]),
    ('remboursement_complements_alimentaires', 'www.elsee.care/remboursement-complements-alimentaires', 2, '0000111101111111111111111111111111111111111111110000', [6, 7, 8]),
    ('offres_remboursement_elsee', 'www.elsee.care/offres-remboursement-elsee', 3, '0000111101111111111111111111111111111111111111110000', [6, 7, 8]),
    ('obtenir_mon_offre', 'www.elsee.care/obtenir-mon-offre', 4, '0000111101111111111111111111111111111111111111110000', [6, 7, 8]),
    ('signup', 'app.elsee.care/signup', 5, '0000011101111111111111111111111111111111111111110000', [6, 7, 8]),
    ('mon_offre_directe', 'app.elsee.care/mon-offre', 6, '0000001100000000000000000000000000000000000000000000', [6, 7, 8]),
    ('mon_panier_directe', 'app.elsee.care/mon-panier', 7, '0000000100000000000000000000000000000000000000000000', [6, 7, 8]),
    ('bienvenue_directe', 'www.elsee.care/bienvenue-chez-elsee', 8, '0000000000000000000000000000000000000000000000000000', [6, 7, 8]),
    ('social_signup', 'app.elsee.care/social_signup', 9, '0000000001111111111111111111111111111111111111110000', [43, 41, 42]),
    ('depenses_complements', 'app.elsee.care/signup/depenses_complements', 10, '0000000000111111111111111111111111111111111111110000', [43, 41, 42]),
    ('montant_complements', 'app.elsee.care/signup/montant_complements', 11, '0000000000011111111111111111111111111111111111110000', [43, 41, 42]),
    ('network_complements', 'app.elsee.care/signup/network_complements', 12, '0000000000001111111111111111111111111111111111110000', [43, 41, 42]),
    ('recap_marques', 'app.elsee.care/signup/recap_marques', 13, '0000000000000111111111111111111111111111111111110000', [43, 41, 42]),
    ('depenses_complements_step', 'app.elsee.care/signup/depenses_complements_step', 14, '0000000000000011111111111111111111110000001111110000', [43, 44, 45]),
    ('sante_mentale_seances', 'app.elsee.care/signup/sante_mentale_seances', 15, '0000000000000001111111111111111111110000001111110000', [43, 44, 45]),
    ('montant_sante_mentale', 'app.elsee.care/signup/montant_sante_mentale', 16, '0000000000000000111111111111111111100000001111110000', [43, 44, 45]),
    ('md_seances', 'app.elsee.care/signup/md_seances', 17, '0000000000000000011111111111111111100000001111110000', [43, 44, 45]),
    ('montant_medecine_douce', 'app.elsee.care/signup/montant_medecine_douce', 18, '0000000000000000001111111111111111100000001111110000', [43, 44, 45]),
    ('soins_seances', 'app.elsee.care/signup/soins_seances', 19, '0000000000000000000111111111111111100000001111110000', [43, 44, 45]),
    ('montant_soins', 'app.elsee.care/signup/montant_soins', 20, '0000000000000000000011111111111111100000001111110000', [43, 44, 45]),
    ('network_info', 'app.elsee.care/signup/network_info', 21, '0000000000000000000001111111111111100000001111110000', [43, 44, 45]),
    ('prete_a_changer', 'app.elsee.care/signup/prete_a-changer', 22, '0000000000000000000000111111111111100000001111110000', [43, 44, 45]),
    ('medecine_douce_step', 'app.elsee.care/signup/medecine_douce_step', 23, '0000000000000000000000011111111111100000001111110000', [43, 44, 45]),
    ('en_savoir_plus_sur_vous', 'app.elsee.care/signup/en_savoir_plus_sur_vous', 24, '0000000000000000000000001111111111100000001111110000', [43, 44, 45]),
    ('depenses_sports', 'app.elsee.care/signup/depenses_sports', 25, '0000000000000000000000000111111111100000001111110000', [43, 44, 45]),
    ('network_sport', 'app.elsee.care/signup/network_sport', 26, '0000000000000000000000000011111111100000001111110000', [43, 44, 45]),
    ('out_of_network_sport', 'app.elsee.care/signup/out_of_network_sport', 27, '0000000000000000000000000001111111100000001111110000', [43, 44, 45]),
    ('sport_step', 'app.elsee.care/signup/sport_step', 28, '0000000000000000000000000000111111100000001111110000', [43, 44, 45]),
    ('depenses_produit', 'app.elsee.care/signup/depenses_produit', 29, '0000000000000000000000000000011111100000001111110000', [43, 44, 45]),
    ('network_produit', 'app.elsee.care/signup/network_produit', 30, '0000000000000000000000000000001111100000001111110000', [43, 44, 45]),
    ('out_of_network_produit', 'app.elsee.care/signup/out_of_network_produit', 31, '0000000000000000000000000000000111100000001111110000', [43, 44, 45]),
    ('depenses_app', 'app.elsee.care/signup/depenses_app', 32, '0000000000000000000000000000000011100000001111110000', [43, 44, 45]),
    ('out_of_network_app', 'app.elsee.care/signup/out_of_network_app', 33, '0000000000000000000000000000000001100000001111110000', [43, 44, 45]),
    ('final_step', 'app.elsee.care/signup/final_step', 34, '0000000000000000000000000000000000100000001111110000', [43, 44, 45]),
    ('offre_en_preparation', 'app.elsee.care/signup/offre_en_preparation', 35, '0000000000000000000000000000000000000000001111110000', [43, 44, 45]),
    ('sante_mentale_step', 'app.elsee.care/signup/sante_mentale_step', 36, '0000000000000000111111111111111111100000001111110000', [43, 44, 45]),
    ('recap_remboursements', 'app.elsee.care/signup/recap_remboursements', 37, '0000000000000000000000000000000000000111110000000000', [0, 41, 42]),
    ('bonus_abonnement', 'app.elsee.care/signup/bonus-abonnement', 38, '0000000000000000000000000000000000000011110000000000', [0, 41, 42]),
    ('bilan', 'app.elsee.care/signup/bilan', 39, '0000000000000000000000000000000000000001110000000000', [0, 41, 42]),
    ('offres', 'app.elsee.care/offres', 40, '0000000000000000000000000000000000000000110000000000', [0, 41, 42]),
    ('mon_panier_complements', 'app.elsee.care/mon-panier', 41, '0000000000000000000000000000000000000000010000000000', [0, 41, 42]),
    ('bienvenue_complements', 'www.elsee.care/bienvenue-chez-elsee', 42, '0000000000000000000000000000000000000000000000000000', [0, 41, 42]),
    ('mon_offre_long_form', 'app.elsee.care/mon-offre', 43, '0000000000000000000000000000000000000000000111110000', [43, 44, 45]),
    ('mon_panier_long_form', 'app.elsee.care/mon-panier', 44, '0000000000000000000000000000000000000000000010000000', [43, 44, 45]),
    ('bienvenue_long_form', 'www.elsee.care/bienvenue-chez-elsee', 45, '0000000000000000000000000000000000000000000000000000', [43, 44, 45]),
    ('cartecadeau', 'app.elsee.care/pricing/cartecadeau', 46, '0000000000000000000000000000000000000000000000110000', [0, 47, 48]),
    ('mon_panier_carte_cadeau', 'app.elsee.care/mon-panier', 47, '0000000000000000000000000000000000000000000000010000', [0, 47, 48]),
    ('bienvenue_carte_cadeau', 'www.elsee.care/bienvenue-chez-elsee', 48, '0000000000000000000000000000000000000000000000000000', [0, 47, 48]),
    ('mon_bilan_elsee', 'www.elsee.care/mon-bilan-elsee', 49, '0000000000000000000000000000000000000000000000000111', [50, 51, 52]),
    ('mon_offre_mail', 'app.elsee.care/mon-offre', 50, '0000000000000000000000000000000000000000000000000011', [50, 51, 52]),
    ('mon_panier_mail', 'app.elsee.care/mon-panier', 51, '0000000000000000000000000000000000000000000000000001', [50, 51, 52]),
    ('bienvenue_mail', 'www.elsee.care/bienvenue-chez-elsee', 52, '0000000000000000000000000000000000000000000000000000', [50, 51, 52])
  ])
),
chemins AS (
  -- Une ligne par page du graphe ; id_unique est vide si la page porte
  -- plusieurs étapes (une par parcours, ex. /mon-panier).
  SELECT cle, IF(COUNT(*) = 1, ANY_VALUE(id), NULL) AS id_unique
  FROM etapes
  GROUP BY cle
),
fleches AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<de STRING, vers STRING>>[
    ('obtenir_mon_offre', 'signup'),
    ('offres_remboursement_elsee', 'signup'),
    ('remboursement_complements_alimentaires', 'signup'),
    ('signup_corpo', 'signup'),
    ('signup', 'mon_offre_directe'),
    ('mon_offre_directe', 'mon_panier_directe'),
    ('mon_panier_directe', 'bienvenue_directe'),
    ('signup', 'depenses_complements'),
    ('social_signup', 'depenses_complements'),
    ('depenses_complements', 'montant_complements'),
    ('depenses_complements', 'sante_mentale_seances'),
    ('montant_complements', 'network_complements'),
    ('network_complements', 'recap_marques'),
    ('recap_marques', 'depenses_complements_step'),
    ('recap_marques', 'recap_remboursements'),
    ('depenses_complements_step', 'sante_mentale_seances'),
    ('recap_remboursements', 'bonus_abonnement'),
    ('bonus_abonnement', 'bilan'),
    ('bilan', 'offres'),
    ('offres', 'mon_panier_complements'),
    ('mon_panier_complements', 'bienvenue_complements'),
    ('sante_mentale_seances', 'montant_sante_mentale'),
    ('sante_mentale_seances', 'sante_mentale_step'),
    ('montant_sante_mentale', 'md_seances'),
    ('sante_mentale_step', 'md_seances'),
    ('md_seances', 'montant_medecine_douce'),
    ('md_seances', 'soins_seances'),
    ('montant_medecine_douce', 'soins_seances'),
    ('soins_seances', 'montant_soins'),
    ('soins_seances', 'medecine_douce_step'),
    ('montant_soins', 'network_info'),
    ('network_info', 'prete_a_changer'),
    ('prete_a_changer', 'medecine_douce_step'),
    ('medecine_douce_step', 'en_savoir_plus_sur_vous'),
    ('medecine_douce_step', 'depenses_sports'),
    ('en_savoir_plus_sur_vous', 'depenses_sports'),
    ('depenses_sports', 'network_sport'),
    ('depenses_sports', 'sport_step'),
    ('network_sport', 'out_of_network_sport'),
    ('out_of_network_sport', 'sport_step'),
    ('sport_step', 'depenses_produit'),
    ('depenses_produit', 'network_produit'),
    ('depenses_produit', 'depenses_app'),
    ('network_produit', 'out_of_network_produit'),
    ('out_of_network_produit', 'depenses_app'),
    ('depenses_app', 'out_of_network_app'),
    ('depenses_app', 'final_step'),
    ('out_of_network_app', 'final_step'),
    ('final_step', 'offre_en_preparation'),
    ('offre_en_preparation', 'mon_offre_long_form'),
    ('mon_offre_long_form', 'mon_panier_long_form'),
    ('mon_panier_long_form', 'bienvenue_long_form'),
    ('mon_offre_long_form', 'cartecadeau'),
    ('cartecadeau', 'mon_panier_carte_cadeau'),
    ('mon_panier_carte_cadeau', 'bienvenue_carte_cadeau'),
    ('mon_bilan_elsee', 'mon_offre_mail'),
    ('mon_offre_mail', 'mon_panier_mail'),
    ('mon_panier_mail', 'bienvenue_mail')
  ])
),
pages_multiples AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<k INT64, cle STRING>>[
    (0, 'app.elsee.care/mon-offre'),
    (1, 'app.elsee.care/mon-panier'),
    (2, 'www.elsee.care/bienvenue-chez-elsee')
  ])
),
par_precedente AS (
  -- Page à plusieurs parcours : étape selon la page précédente (flèche).
  SELECT pm.cle, f.de AS precedente, f.vers AS etape
  FROM fleches AS f
  JOIN etapes AS ev ON ev.id = f.vers
  JOIN pages_multiples AS pm ON pm.cle = ev.cle
),
par_derniere AS (
  -- Page à plusieurs parcours : étape selon la dernière étape vue par la
  -- personne (la plus proche en suivant les flèches, à défaut le même parcours).
  SELECT pm.cle, e.id AS derniere, c.id AS etape
  FROM etapes AS e
  CROSS JOIN UNNEST(e.rattache) AS r WITH OFFSET AS k
  JOIN pages_multiples AS pm ON pm.k = k
  JOIN etapes AS c ON c.n = r
),
replis AS (
  -- Page sans parcours déductible : étape de repli (chemin mail).
  SELECT * FROM UNNEST(ARRAY<STRUCT<cle STRING, etape STRING>>[
    ('app.elsee.care/mon-offre', 'mon_offre_mail'),
    ('app.elsee.care/mon-panier', 'mon_panier_mail'),
    ('www.elsee.care/bienvenue-chez-elsee', 'bienvenue_mail')
  ])
),
pages AS (
  -- Pages vues : 60 jours avant la période, pour retrouver le parcours des
  -- personnes qui reviennent (passe 3), et un jour après, pour les sessions qui
  -- passent minuit.
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS jour,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer') AS url_provenance,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM `ga4-chemin-form.analytics_383563328.events_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{8}$')
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(date_debut, INTERVAL 60 DAY))
                          AND FORMAT_DATE('%Y%m%d', DATE_ADD(date_fin, INTERVAL 1 DAY))
    AND event_name = 'page_view'
    AND user_pseudo_id IS NOT NULL
),
tunnel AS (
  -- Pages du graphe seulement (domaine + chemin sans paramètres, en minuscules,
  -- sans « / » final), numérotées dans l'ordre de la session (rang) et dans
  -- l'ordre de toutes les sessions de la personne (rang_personne) ; provenance :
  -- domaine de la page d'où l'on vient (leads).
  SELECT p.jour, p.user_pseudo_id, p.ga_session_id, p.cle, c.id_unique,
    LOWER(NET.HOST(p.url_provenance)) AS provenance,
    ROW_NUMBER() OVER (PARTITION BY p.user_pseudo_id, p.ga_session_id
                       ORDER BY p.event_timestamp, p.batch_ordering_id, p.batch_page_id, p.batch_event_index) AS rang,
    ROW_NUMBER() OVER (PARTITION BY p.user_pseudo_id
                       ORDER BY p.event_timestamp, p.ga_session_id, p.batch_ordering_id, p.batch_page_id, p.batch_event_index) AS rang_personne
  FROM (
    SELECT *,
      CONCAT(LOWER(NET.HOST(url)),
             IFNULL(NULLIF(REGEXP_REPLACE(LOWER(REGEXP_EXTRACT(url, r'^[a-zA-Z]+://[^/?#]+([^?#]*)')), r'/+$', ''), ''), '/')) AS cle
    FROM pages
    WHERE ga_session_id IS NOT NULL
  ) AS p
  JOIN chemins AS c USING (cle)
),
passe0 AS (
  SELECT *, id_unique AS etape FROM tunnel
),
passe1 AS (
  -- Passe 1, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe0
  ) AS x
  LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
  LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
),
passe2 AS (
  -- Passe 2, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe1
  ) AS x
  LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
  LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
),
passe3 AS (
  -- Passe 3, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe2
  ) AS x
  LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
  LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
),
passe4 AS (
  -- Passe 4, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe3
  ) AS x
  LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
  LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
),
passe5 AS (
  -- Passe 5, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (60 jours au plus) : l'étape de cette page la
  --      plus proche en suivant les flèches, à défaut celle du même parcours.
  SELECT x.* EXCEPT (etape, precedente, derniere_meme_page, derniere_etape_personne),
    COALESCE(x.id_unique, pp.etape, x.derniere_meme_page, pd.etape) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id ORDER BY rang_personne
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_etape_personne
    FROM passe4
  ) AS x
  LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
  LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
),
resolues AS (
  -- Une page qu'on ne peut rattacher à aucun parcours va, en dernier recours,
  -- dans l'étape de repli de sa page (après toutes les passes : le repli ne
  -- change le parcours d'aucune autre page) ; sans étape de repli, elle garde
  -- son chemin précédé de « ? » et coupe la suite des passages.
  SELECT x.jour, x.user_pseudo_id, x.ga_session_id, x.rang, COALESCE(x.etape, rp.etape, CONCAT('?', x.cle)) AS e
  FROM passe5 AS x
  LEFT JOIN replis AS rp ON rp.cle = x.cle
),
sans_rechargements AS (
  SELECT * EXCEPT (precedente)
  FROM (SELECT *, LAG(e) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente FROM resolues)
  WHERE precedente IS NULL OR precedente != e
),
sans_detours AS (
  -- Détours effacés : pour cartecadeau, une visite suivie d'un
  -- retour à la page d'où l'on venait, puis d'une flèche partant de cette page,
  -- compte comme si la personne n'avait pas vu l'étape.
  SELECT d.* EXCEPT (p, n1, n2)
  FROM (
    SELECT *,
      LAG(e) OVER w AS p, LEAD(e) OVER w AS n1, LEAD(e, 2) OVER w AS n2
    FROM sans_rechargements
    WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
  ) AS d
  LEFT JOIN fleches AS f ON f.de = d.p AND f.vers = d.n2
  WHERE NOT IFNULL(d.e IN ('cartecadeau')
                   AND d.n1 = d.p AND d.n2 != d.e AND f.de IS NOT NULL, FALSE)
),
suites AS (
  -- Après l'effacement d'un détour, la page d'avant et celle d'après sont
  -- identiques : on retire à nouveau les doublons, puis on prend la suivante.
  SELECT *,
    LEAD(e) OVER w AS vers,
    LAG(e) OVER w IS NULL AS premiere_de_la_session
  FROM (
    SELECT * EXCEPT (precedente)
    FROM (SELECT *, LAG(e) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente FROM sans_detours)
    WHERE precedente IS NULL OR precedente != e
  )
  WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
),
classees AS (
  -- Une ligne = une arrivée sur l'étape « de », datée du jour de cette page,
  -- et ce qui suit dans la session.
  SELECT s.jour, s.user_pseudo_id, s.e AS de, s.vers, s.premiere_de_la_session,
    CASE
      WHEN STARTS_WITH(s.e, '?') THEN 'non_rattache'
      WHEN s.vers IS NULL THEN 'fin'
      WHEN STARTS_WITH(s.vers, '?') THEN 'autre'
      WHEN f.de IS NOT NULL THEN 'fleche'
      WHEN SUBSTR(ed.atteint, ev.n, 1) = '1' THEN 'saut'
      WHEN SUBSTR(ev.atteint, ed.n, 1) = '1' THEN 'retour'
      ELSE 'autre'
    END AS genre
  FROM suites AS s
  LEFT JOIN fleches AS f ON f.de = s.e AND f.vers = s.vers
  LEFT JOIN etapes AS ed ON ed.id = s.e
  LEFT JOIN etapes AS ev ON ev.id = s.vers
),
periode AS (
  SELECT * FROM classees WHERE jour BETWEEN date_debut AND date_fin
),
faits AS (
  -- Faits par personne (ne sortent jamais de BigQuery).
  SELECT jour, user_pseudo_id, 'arrivees' AS genre, de, CAST(NULL AS STRING) AS vers
  FROM periode WHERE genre != 'non_rattache'
  UNION ALL
  SELECT jour, user_pseudo_id, 'continuent', de, NULL
  FROM periode WHERE genre IN ('fleche', 'saut')
  UNION ALL
  SELECT jour, user_pseudo_id, 'entrees_directes', de, NULL
  FROM periode WHERE premiere_de_la_session AND genre != 'non_rattache'
  UNION ALL
  SELECT jour, user_pseudo_id, genre, de, vers
  FROM periode WHERE genre IN ('fleche', 'saut', 'retour', 'autre')
  UNION ALL
  SELECT jour, user_pseudo_id, 'non_rattache', SUBSTR(de, 2), NULL
  FROM periode WHERE genre = 'non_rattache'
),
agregats AS (
  -- Utilisateurs distincts sur toute la période (jour vide), puis jour par jour.
  SELECT genre, de, vers, CAST(NULL AS DATE) AS jour, COUNT(DISTINCT user_pseudo_id) AS utilisateurs
  FROM faits GROUP BY genre, de, vers
  UNION ALL
  SELECT genre, de, vers, jour, COUNT(DISTINCT user_pseudo_id)
  FROM faits GROUP BY genre, de, vers, jour
),
pages_personne AS (
  -- Par personne, sur la période : pages différentes du graphe vues (une page
  -- vue plusieurs fois compte une fois, entrées comprises), au moins une page
  -- du formulaire (app.elsee.care) vue, formulaire commencé au début
  -- (app.elsee.care/signup-corpo, app.elsee.care/signup, app.elsee.care/social_signup), offre vue (app.elsee.care/mon-offre, app.elsee.care/offres).
  SELECT user_pseudo_id,
    COUNT(DISTINCT cle) AS pages,
    LOGICAL_OR(STARTS_WITH(cle, 'app.elsee.care/')) AS formulaire,
    LOGICAL_OR(cle IN UNNEST(['app.elsee.care/signup-corpo', 'app.elsee.care/signup', 'app.elsee.care/social_signup'])) AS debut,
    LOGICAL_OR(cle IN UNNEST(['app.elsee.care/mon-offre', 'app.elsee.care/offres'])) AS offre
  FROM tunnel
  WHERE jour BETWEEN date_debut AND date_fin
  GROUP BY user_pseudo_id
),
repartition AS (
  -- Personnes qui ont commencé le formulaire au début, selon le nombre de pages
  -- vues (de) ; en_cours_de_route : personnes arrivées sur le formulaire sans
  -- passer par son début (retour sur l'offre, reprise au milieu) ;
  -- hors_formulaire : personnes vues seulement sur les autres domaines (GA4 les
  -- perd en passant sur le formulaire).
  SELECT 'pages_vues' AS genre, CAST(pages AS STRING) AS de, CAST(NULL AS STRING) AS vers,
    CAST(NULL AS DATE) AS jour, COUNT(*) AS utilisateurs
  FROM pages_personne WHERE debut GROUP BY pages
  UNION ALL
  SELECT 'pages_vues_offre', CAST(pages AS STRING), NULL, NULL, COUNTIF(offre)
  FROM pages_personne WHERE debut GROUP BY pages
  UNION ALL
  SELECT 'en_cours_de_route', NULL, NULL, NULL, COUNTIF(formulaire AND NOT debut)
  FROM pages_personne
  UNION ALL
  SELECT 'hors_formulaire', NULL, NULL, NULL, COUNTIF(NOT formulaire)
  FROM pages_personne
),
leads_pages AS (
  -- Pages du graphe avec l'entrée de la session : coordonnées données à l'entrée
  -- (TRUE) ou plus tard (FALSE), d'après la dernière page d'entrée vue dans la
  -- session. Une page ouverte depuis app.elsee.care (navigation dans le
  -- formulaire, retour en arrière) n'est pas une nouvelle entrée.
  SELECT *,
    LAST_VALUE(a_l_entree IGNORE NULLS) OVER w AS entree,
    LAG(id_unique) OVER w AS precedente
  FROM (
    SELECT jour, user_pseudo_id, ga_session_id, rang, rang_personne, id_unique,
      CASE
        WHEN provenance = 'app.elsee.care' THEN NULL
        WHEN id_unique = 'signup_corpo' THEN TRUE
        WHEN id_unique = 'remboursement_complements_alimentaires' THEN TRUE
        WHEN id_unique = 'offres_remboursement_elsee' THEN TRUE
        WHEN id_unique = 'obtenir_mon_offre' THEN TRUE
        WHEN id_unique = 'signup' AND provenance = 'www.elsee.care' THEN TRUE
        WHEN id_unique = 'signup' THEN FALSE
        WHEN id_unique = 'social_signup' THEN FALSE
      END AS a_l_entree
    FROM tunnel
  )
  WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
),
leads_periode AS (
  -- Moments où la personne a donné ses coordonnées : chargement de la page qui
  -- suit la saisie (GA4 ne voit pas la saisie). Une personne n'est un lead
  -- qu'une fois : à son premier moment, sur tout l'historique lu (60 jours
  -- avant la période) ; elle compte si ce premier moment tombe dans la période.
  SELECT premier.* FROM (
    SELECT ARRAY_AGG(STRUCT(jour, moment) ORDER BY rang_personne LIMIT 1)[OFFSET(0)] AS premier
    FROM (
      SELECT jour, user_pseudo_id, rang_personne,
        CASE
          WHEN id_unique = 'depenses_complements' AND entree THEN 'avant_depenses_complements'
          WHEN id_unique = 'bilan' AND precedente = 'bonus_abonnement' AND NOT entree THEN 'popup_bilan'
          WHEN id_unique = 'depenses_sports' AND precedente = 'en_savoir_plus_sur_vous' THEN 'en_savoir_plus_sur_vous'
        END AS moment
      FROM leads_pages
    )
    WHERE moment IS NOT NULL
    GROUP BY user_pseudo_id
  )
  WHERE premier.jour BETWEEN date_debut AND date_fin
),
leads AS (
  -- Une ligne par personne dans leads_periode : total (de vide), répartition
  -- par moment, jour par jour (les jours s'additionnent).
  SELECT 'leads' AS genre, CAST(NULL AS STRING) AS de, CAST(NULL AS STRING) AS vers,
    CAST(NULL AS DATE) AS jour, COUNT(*) AS utilisateurs
  FROM leads_periode
  UNION ALL
  SELECT 'leads', moment, NULL, NULL, COUNT(*)
  FROM leads_periode GROUP BY moment
  UNION ALL
  SELECT 'leads', NULL, NULL, jour, COUNT(*)
  FROM leads_periode GROUP BY jour
),
resultat AS (
  -- Pas de chiffre faux : flèches non mesurables et abandons qui en dépendent
  -- laissés vides.
  SELECT genre, de, vers, jour,
    IF((genre = 'fleche' AND CONCAT(de, '>', vers) IN UNNEST(['obtenir_mon_offre>signup', 'offres_remboursement_elsee>signup', 'remboursement_complements_alimentaires>signup', 'mon_bilan_elsee>mon_offre_mail']))
       OR (genre = 'continuent' AND de IN UNNEST(['remboursement_complements_alimentaires', 'offres_remboursement_elsee', 'obtenir_mon_offre', 'mon_bilan_elsee'])),
       NULL, utilisateurs) AS utilisateurs
  FROM agregats
  UNION ALL
  SELECT * FROM repartition
  UNION ALL
  SELECT * FROM leads
),
-- Le contrôle porte sur les chiffres bruts (y compris non mesurables).
total AS (SELECT * FROM agregats WHERE jour IS NULL),
par_depart AS (
  SELECT de AS etape,
    IFNULL(MAX(IF(genre = 'arrivees', utilisateurs, NULL)), 0) AS arrivees,
    IFNULL(MAX(IF(genre = 'continuent', utilisateurs, NULL)), 0) AS continuent,
    IFNULL(MAX(IF(genre = 'entrees_directes', utilisateurs, NULL)), 0) AS entrees_directes,
    IFNULL(SUM(IF(genre = 'fleche', utilisateurs, 0)), 0) AS sorties_fleches,
    IFNULL(SUM(IF(genre = 'saut', utilisateurs, 0)), 0) AS sorties_sauts
  FROM total GROUP BY de
),
par_arrivee AS (
  SELECT vers AS etape, SUM(utilisateurs) AS entrees_par_passage
  FROM total WHERE genre IN ('fleche', 'saut', 'retour', 'autre')
  GROUP BY vers
)
SELECT
  e.id AS etape,
  IFNULL(d.arrivees, 0) AS arrivees,
  IFNULL(d.continuent, 0) AS continuent,
  IFNULL(d.arrivees - d.continuent, 0) AS abandons,
  ROUND(SAFE_DIVIDE(d.arrivees - d.continuent, d.arrivees), 3) AS taux_abandon,
  IFNULL(d.sorties_fleches, 0) AS sorties_fleches,
  IFNULL(d.sorties_sauts, 0) AS sorties_sauts,
  IFNULL(d.sorties_fleches + d.sorties_sauts - d.continuent, 0) AS ecart_sorties,
  IFNULL(a.entrees_par_passage, 0) + IFNULL(d.entrees_directes, 0) AS entrees,
  IFNULL(a.entrees_par_passage, 0) + IFNULL(d.entrees_directes, 0) - IFNULL(d.arrivees, 0) AS ecart_entrees
FROM etapes AS e
LEFT JOIN par_depart AS d ON d.etape = e.id
LEFT JOIN par_arrivee AS a ON a.etape = e.id
ORDER BY e.n;
