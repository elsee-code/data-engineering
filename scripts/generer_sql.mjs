#!/usr/bin/env node
// Génère, à partir de config/graphe.json, les requêtes de calcul du tunnel et la
// configuration de la page Apps Script.
//
// Usage : node scripts/generer_sql.mjs
// Écrit apps-script/Graphe.gs (le graphe pour la page) et, dans sql/calcul/ :
//   - agregats.sql            : script autonome (dates en tête), renvoie les agrégats ;
//   - controle_coherence.sql  : script autonome, contrôle « sorties + abandons ≈ arrivées » ;
//   - creer_fonction.sql      : crée la fonction de table elsee_funnel.agregats(date_debut, date_fin).
// Ne jamais modifier ces fichiers à la main : modifier la configuration, puis relancer.

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { createHash } from "node:crypto";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const racine = join(dirname(fileURLToPath(import.meta.url)), "..");
const texteConfig = readFileSync(join(racine, "config/graphe.json"), "utf8");
const graphe = JSON.parse(texteConfig);
const SOURCE = "`ga4-chemin-form.analytics_383563328.events_*`";
const FONCTION = "`ga4-chemin-form.elsee_funnel.agregats`";

// ---------------------------------------------------------------------------
// Vérification de la configuration
// ---------------------------------------------------------------------------
const erreurs = [];
const etapes = graphe.etapes;
const fleches = graphe.fleches;
const parId = new Map();
for (const e of etapes) {
  if (!/^[a-z0-9_]+$/.test(e.id)) erreurs.push(`id invalide : ${e.id}`);
  if (parId.has(e.id)) erreurs.push(`id en double : ${e.id}`);
  parId.set(e.id, e);
  if (!/^\/[a-z0-9_\-./]*[a-z0-9_\-]$/.test(e.chemin)) erreurs.push(`chemin invalide (minuscules, sans / final) : ${e.chemin}`);
  if (!graphe.domaines.includes(e.domaine)) erreurs.push(`domaine non retenu pour ${e.id} : ${e.domaine}`);
  if (!graphe.parcours[e.parcours]) erreurs.push(`parcours inconnu pour ${e.id} : ${e.parcours}`);
}
const clesFleches = new Set();
for (const f of fleches) {
  if (!parId.has(f.de)) erreurs.push(`flèche depuis une étape inconnue : ${f.de}`);
  if (!parId.has(f.vers)) erreurs.push(`flèche vers une étape inconnue : ${f.vers}`);
  if (!["normale", "oui", "non"].includes(f.type)) erreurs.push(`type de flèche inconnu : ${f.de} → ${f.vers} (${f.type})`);
  const cle = `${f.de}>${f.vers}`;
  if (clesFleches.has(cle)) erreurs.push(`flèche en double : ${f.de} → ${f.vers}`);
  clesFleches.add(cle);
}
const pagesVues = graphe.pages_vues;
if (!pagesVues) erreurs.push("bloc pages_vues absent");
else {
  if (!graphe.domaines.includes(pagesVues.formulaire)) erreurs.push(`pages_vues.formulaire : domaine non retenu : ${pagesVues.formulaire}`);
  if (!Array.isArray(pagesVues.offre) || !pagesVues.offre.length) erreurs.push("pages_vues.offre : liste d'étapes attendue");
  else for (const id of pagesVues.offre) if (!parId.has(id)) erreurs.push(`pages_vues.offre : étape inconnue : ${id}`);
  if (!pagesVues.position || !Number.isFinite(pagesVues.position.colonne) || !Number.isFinite(pagesVues.position.ligne)) {
    erreurs.push("pages_vues.position : colonne et ligne attendues");
  }
}
for (const e of etapes) {
  const sorties = fleches.filter((f) => f.de === e.id);
  const oui = sorties.filter((f) => f.type === "oui").length;
  const non = sorties.filter((f) => f.type === "non").length;
  if (oui !== non || oui > 1) erreurs.push(`page à question ${e.id} : il faut une flèche OUI et une flèche NON`);
}

// Pages (domaine + chemin) portées par plusieurs étapes, une par parcours :
// l'étape se déduit de la page précédente. Une même page précédente ne doit
// donc mener qu'à une seule de ces étapes.
const cle = (e) => `${e.domaine}${e.chemin}`;
const parPage = new Map();
for (const e of etapes) parPage.set(cle(e), [...(parPage.get(cle(e)) ?? []), e.id]);
const pagesMultiples = [...parPage].filter(([, ids]) => ids.length > 1);
for (const [page, ids] of pagesMultiples) {
  const vues = new Map();
  for (const f of fleches.filter((f) => ids.includes(f.vers))) {
    if (vues.has(f.de) && vues.get(f.de) !== f.vers) erreurs.push(`${page} : ${f.de} mène à deux étapes (${vues.get(f.de)}, ${f.vers})`);
    vues.set(f.de, f.vers);
  }
}

// Leads : les étapes citées doivent porter seules leur page (le calcul les
// reconnaît sans les règles de rattachement à un parcours).
const leads = graphe.leads;
const COORDONNEES = ["a_l_entree", "plus_tard"];
const etapeSeule = (id, ou) => {
  if (!parId.has(id)) erreurs.push(`${ou} : étape inconnue : ${id}`);
  else if (parPage.get(cle(parId.get(id))).length > 1) erreurs.push(`${ou} : ${id} partage sa page avec une autre étape`);
};
if (!leads) erreurs.push("bloc leads absent");
else {
  if (!graphe.domaines.includes(leads.provenance_interne)) erreurs.push(`leads.provenance_interne : domaine non retenu : ${leads.provenance_interne}`);
  if (!Array.isArray(leads.entrees) || !leads.entrees.length) erreurs.push("leads.entrees : liste attendue");
  else for (const e of leads.entrees) {
    etapeSeule(e.etape, "leads.entrees");
    if (!COORDONNEES.includes(e.coordonnees)) erreurs.push(`leads.entrees : coordonnees inconnu pour ${e.etape} : ${e.coordonnees}`);
    if (e.provenance !== undefined && !/^[a-z0-9.-]+$/.test(e.provenance)) erreurs.push(`leads.entrees : provenance invalide pour ${e.etape} : ${e.provenance}`);
  }
  if (!Array.isArray(leads.moments) || !leads.moments.length) erreurs.push("leads.moments : liste attendue");
  else {
    const ids = new Set();
    for (const m of leads.moments) {
      if (!/^[a-z0-9_]+$/.test(m.id) || ids.has(m.id)) erreurs.push(`leads.moments : id invalide ou en double : ${m.id}`);
      ids.add(m.id);
      if (!m.libelle) erreurs.push(`leads.moments : libellé manquant pour ${m.id}`);
      etapeSeule(m.page, `leads.moments (${m.id})`);
      if (m.apres !== undefined) etapeSeule(m.apres, `leads.moments (${m.id})`);
      if (m.entree !== undefined && !COORDONNEES.includes(m.entree)) erreurs.push(`leads.moments : entree inconnue pour ${m.id} : ${m.entree}`);
    }
  }
}

// Fermeture transitive : (a, b) si b est plus loin que a en suivant les flèches.
const suivants = new Map(etapes.map((e) => [e.id, fleches.filter((f) => f.de === e.id).map((f) => f.vers)]));
const atteignables = [];
for (const e of etapes) {
  const vus = new Set();
  const pile = [...suivants.get(e.id)];
  while (pile.length) {
    const n = pile.pop();
    if (n === e.id) { erreurs.push(`le graphe a une boucle passant par ${e.id}`); break; }
    if (vus.has(n)) continue;
    vus.add(n);
    pile.push(...suivants.get(n));
  }
  for (const n of [...vus].sort()) atteignables.push([e.id, n]);
}

if (erreurs.length) {
  console.error("Configuration invalide :\n- " + erreurs.join("\n- "));
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Génération du SQL
// ---------------------------------------------------------------------------
const q = (s) => `'${s}'`;
const liste = (lignes, indent = "    ") => lignes.map((l) => indent + l).join(",\n");
const effaces = etapes.filter((e) => e.effacer_si_retour).map((e) => e.id);
const nonMesurables = fleches.filter((f) => f.mesurable === false);
// Étapes dont aucune sortie n'est mesurable : pas de taux d'abandon.
const sansSortieMesurable = etapes
  .filter((e) => {
    const s = fleches.filter((f) => f.de === e.id);
    return s.length > 0 && s.every((f) => f.mesurable === false);
  })
  .map((e) => e.id);
// Pages (domaine + chemin) qui montrent son offre à la personne.
const pagesOffre = [...new Set(pagesVues.offre.map((id) => cle(parId.get(id))))];

// Encodages compacts : le texte d'une fonction BigQuery est limité à 32 Ko.
// Chaque étape a un numéro (1, 2, …) dans l'ordre de la configuration.
const numero = new Map(etapes.map((e, i) => [e.id, i + 1]));
// atteint : chaîne de 0 et de 1 ; le n-ième caractère vaut 1 si l'étape
// numéro n est plus loin en suivant les flèches.
const atteint = new Map(
  etapes.map((e) => {
    const plusLoin = new Set(atteignables.filter(([a]) => a === e.id).map(([, b]) => b));
    return [e.id, etapes.map((x) => (plusLoin.has(x.id) ? "1" : "0")).join("")];
  })
);
// rattache : pour chaque page à plusieurs parcours (dans l'ordre de
// pagesMultiples), numéro de l'étape à retenir quand cette étape-ci est la
// dernière vue par la personne (0 : aucune). On prend l'étape de la page la plus
// proche en suivant les flèches (ex. après /offres, /mon-panier du parcours
// compléments) ; si aucune n'est atteignable, celle du même parcours.
function distances(depart) {
  const d = new Map([[depart, 0]]);
  const file = [depart];
  while (file.length) {
    const n = file.shift();
    for (const s of suivants.get(n)) if (!d.has(s)) { d.set(s, d.get(n) + 1); file.push(s); }
  }
  return d;
}
const rattache = new Map(
  etapes.map((e) => {
    const d = distances(e.id);
    return [
      e.id,
      pagesMultiples.map(([, ids]) => {
        const proches = ids.filter((i) => d.has(i)).sort((a, b) => d.get(a) - d.get(b));
        const choix = proches[0] ?? ids.find((i) => parId.get(i).parcours === e.parcours);
        return choix ? numero.get(choix) : 0;
      }),
    ];
  })
);
const nbPasses = pagesMultiples.length + 2;
const JOURS_RECUL = 60;

function passe(n) {
  return `passe${n} AS (
  -- Passe ${n}, pour les pages à plusieurs parcours, dans l'ordre :
  --   1. d'après la page précédente dans la session ;
  --   2. sinon, la même étape que la dernière fois que cette page a été vue dans
  --      la session (retour en arrière) ;
  --   3. sinon, d'après la dernière étape vue par la personne, dans cette session
  --      ou une précédente (${JOURS_RECUL} jours au plus) : l'étape de cette page la
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
    FROM passe${n - 1}
  ) AS x
  LEFT JOIN par_precedente AS pp ON pp.cle = x.cle AND pp.precedente = x.precedente
  LEFT JOIN par_derniere AS pd ON pd.cle = x.cle AND pd.derniere = x.derniere_etape_personne
)`;
}

// Corps commun : des pages vues jusqu'aux passages classés, une ligne par page
// du graphe vue (après rechargements et détours effacés), avec la page suivante.
const corps = `etapes AS (
  -- n : numéro de l'étape ; atteint : n-ième caractère à 1 si l'étape n est plus
  -- loin en suivant les flèches ; rattache : voir par_derniere.
  SELECT * FROM UNNEST(ARRAY<STRUCT<id STRING, cle STRING, n INT64, atteint STRING, rattache ARRAY<INT64>>>[
${liste(etapes.map((e) => `(${q(e.id)}, ${q(cle(e))}, ${numero.get(e.id)}, ${q(atteint.get(e.id))}, [${rattache.get(e.id).join(", ")}])`))}
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
${liste(fleches.map((f) => `(${q(f.de)}, ${q(f.vers)})`))}
  ])
),
pages_multiples AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<k INT64, cle STRING>>[
${liste(pagesMultiples.map(([page], k) => `(${k}, ${q(page)})`))}
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
pages AS (
  -- Pages vues : ${JOURS_RECUL} jours avant la période, pour retrouver le parcours des
  -- personnes qui reviennent (passe 3), et un jour après, pour les sessions qui
  -- passent minuit.
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS jour,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer') AS url_provenance,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM ${SOURCE}
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\\d{8}$')
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(date_debut, INTERVAL ${JOURS_RECUL} DAY))
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
${Array.from({ length: nbPasses }, (_, i) => passe(i + 1)).join(",\n")},
resolues AS (
  -- Une page qu'on ne peut rattacher à aucun parcours garde son chemin,
  -- précédé de « ? » : elle coupe la suite des passages.
  SELECT jour, user_pseudo_id, ga_session_id, rang, IFNULL(etape, CONCAT('?', cle)) AS e
  FROM passe${nbPasses}
),
sans_rechargements AS (
  SELECT * EXCEPT (precedente)
  FROM (SELECT *, LAG(e) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente FROM resolues)
  WHERE precedente IS NULL OR precedente != e
),
sans_detours AS (
  -- Détours effacés : pour ${effaces.length ? effaces.join(", ") : "aucune étape"}, une visite suivie d'un
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
  WHERE NOT IFNULL(${effaces.length ? `d.e IN (${effaces.map(q).join(", ")})` : "FALSE"}
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
  -- du formulaire (${pagesVues.formulaire}) vue, offre vue (${pagesOffre.join(", ")}).
  SELECT user_pseudo_id,
    COUNT(DISTINCT cle) AS pages,
    LOGICAL_OR(STARTS_WITH(cle, ${q(pagesVues.formulaire + "/")})) AS formulaire,
    LOGICAL_OR(cle IN UNNEST(${sqlTableau(pagesOffre)})) AS offre
  FROM tunnel
  WHERE jour BETWEEN date_debut AND date_fin
  GROUP BY user_pseudo_id
),
repartition AS (
  -- Personnes arrivées sur le formulaire, selon le nombre de pages vues (de) ;
  -- hors_formulaire : personnes vues seulement sur les autres domaines (GA4 les
  -- perd en passant sur le formulaire).
  SELECT 'pages_vues' AS genre, CAST(pages AS STRING) AS de, CAST(NULL AS STRING) AS vers,
    CAST(NULL AS DATE) AS jour, COUNT(*) AS utilisateurs
  FROM pages_personne WHERE formulaire GROUP BY pages
  UNION ALL
  SELECT 'pages_vues_offre', CAST(pages AS STRING), NULL, NULL, COUNTIF(offre)
  FROM pages_personne WHERE formulaire GROUP BY pages
  UNION ALL
  SELECT 'hors_formulaire', NULL, NULL, NULL, COUNTIF(NOT formulaire)
  FROM pages_personne
),
leads_pages AS (
  -- Pages du graphe avec l'entrée de la session : coordonnées données à l'entrée
  -- (TRUE) ou plus tard (FALSE), d'après la dernière page d'entrée vue dans la
  -- session. Une page ouverte depuis ${leads.provenance_interne} (navigation dans le
  -- formulaire, retour en arrière) n'est pas une nouvelle entrée.
  SELECT *,
    LAST_VALUE(a_l_entree IGNORE NULLS) OVER w AS entree,
    LAG(id_unique) OVER w AS precedente
  FROM (
    SELECT jour, user_pseudo_id, ga_session_id, rang, rang_personne, id_unique,
      CASE
        WHEN provenance = ${q(leads.provenance_interne)} THEN NULL
${leads.entrees.map((e) => `        WHEN id_unique = ${q(e.etape)}${e.provenance ? ` AND provenance = ${q(e.provenance)}` : ""} THEN ${e.coordonnees === "a_l_entree" ? "TRUE" : "FALSE"}`).join("\n")}
      END AS a_l_entree
    FROM tunnel
  )
  WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
),
leads_periode AS (
  -- Moments où la personne a donné ses coordonnées : chargement de la page qui
  -- suit la saisie (GA4 ne voit pas la saisie). Une personne n'est un lead
  -- qu'une fois : à son premier moment, sur tout l'historique lu (${JOURS_RECUL} jours
  -- avant la période) ; elle compte si ce premier moment tombe dans la période.
  SELECT premier.* FROM (
    SELECT ARRAY_AGG(STRUCT(jour, moment) ORDER BY rang_personne LIMIT 1)[OFFSET(0)] AS premier
    FROM (
      SELECT jour, user_pseudo_id, rang_personne,
        CASE
${leads.moments.map((m) => `          WHEN ${[
  `id_unique = ${q(m.page)}`,
  m.apres ? `precedente = ${q(m.apres)}` : null,
  m.entree === "a_l_entree" ? "entree" : m.entree === "plus_tard" ? "NOT entree" : null,
].filter(Boolean).join(" AND ")} THEN ${q(m.id)}`).join("\n")}
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
    IF((genre = 'fleche' AND CONCAT(de, '>', vers) IN UNNEST(${sqlTableau(nonMesurables.map((f) => `${f.de}>${f.vers}`))}))
       OR (genre = 'continuent' AND de IN UNNEST(${sqlTableau(sansSortieMesurable)})),
       NULL, utilisateurs) AS utilisateurs
  FROM agregats
  UNION ALL
  SELECT * FROM repartition
  UNION ALL
  SELECT * FROM leads
)`;

function sqlTableau(valeurs) {
  return valeurs.length ? `[${valeurs.map(q).join(", ")}]` : "ARRAY<STRING>[]";
}

const entete = (titre, lignes) =>
  [
    `-- ${titre}`,
    "-- FICHIER GÉNÉRÉ par scripts/generer_sql.mjs à partir de config/graphe.json :",
    "-- ne pas modifier à la main.",
    ...lignes.map((l) => (l ? `-- ${l}` : "--")),
    "",
  ].join("\n");

const declarations = `DECLARE date_debut DATE DEFAULT DATE '2026-10-05';
DECLARE date_fin   DATE DEFAULT DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 1 DAY);
`;

// Texte de la fonction, sans les commentaires : BigQuery le limite à 32 Ko.
const corpsFonction = `WITH\n${corps}\nSELECT * FROM resultat`
  .split("\n")
  .filter((l) => !/^\s*--/.test(l))
  .join("\n");
const tailleFonction = Buffer.byteLength(corpsFonction, "utf8");
const TAILLE_MAX = 32768;
if (tailleFonction > TAILLE_MAX) {
  console.error(`Texte de la fonction trop long : ${tailleFonction} octets (maximum ${TAILLE_MAX}).`);
  process.exit(1);
}

const fichiers = {
  "agregats.sql":
    entete("Agrégats du tunnel sur une période", [
      "Script autonome (dates à régler ci-dessous). Lecture seule.",
      "Une ligne par (genre, de, vers, jour). jour vide = toute la période.",
      "  arrivees          : utilisateurs arrivés sur l'étape « de »",
      "  continuent        : utilisateurs ayant pris au moins une sortie vers l'avant",
      "                      (flèche ou saut) ; taux d'abandon = 1 - continuent / arrivees",
      "  fleche            : utilisateurs passés de « de » à « vers » par une flèche du graphe",
      "  saut              : passage vers l'avant hors flèche (pages intermédiaires non vues)",
      "  retour, autre     : retours en arrière et autres passages hors graphe",
      "  entrees_directes  : utilisateurs dont la session commence sur l'étape (contrôle)",
      "  non_rattache      : pages à plusieurs parcours sans parcours déductible (contrôle)",
      "  pages_vues        : personnes arrivées sur le formulaire ayant vu « de » pages",
      "                      différentes du graphe sur la période (entrées comprises)",
      "  pages_vues_offre  : parmi elles, celles qui ont vu leur offre",
      "  hors_formulaire   : personnes vues seulement hors du formulaire (non comptées",
      "                      dans pages_vues)",
      "  leads             : personnes dont le premier lead (coordonnées données) tombe",
      "                      dans la période : total (de vide), par moment de recueil",
      "                      (de = moment), jour par jour (de vide)",
      "Cases vides : chiffre non mesurable (suivi www → app), à ne pas afficher.",
    ]) + declarations + `\nWITH\n${corps}\nSELECT * FROM resultat\nORDER BY genre, de, vers, jour;\n`,

  "controle_coherence.sql":
    entete("Contrôle de cohérence du calcul", [
      "Script autonome (dates à régler ci-dessous). Lecture seule.",
      "Pour chaque étape, sur toute la période :",
      "  sorties_fleches + sorties_sauts + abandons - arrivees = personnes ayant pris",
      "  plusieurs sorties (>= 0, petit) ;",
      "  entrees (flèches, sauts, retours, autres, débuts de session) - arrivees",
      "  = personnes arrivées par plusieurs chemins (>= 0, petit).",
      "Un écart négatif signale une erreur de calcul.",
    ]) +
    declarations +
    `\nWITH\n${corps},
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
`,

  "creer_fonction.sql":
    entete("Création de la fonction de table elsee_funnel.agregats(date_debut, date_fin)", [
      "À lancer seulement après validation (écriture dans elsee_funnel).",
      "Même calcul et même résultat que agregats.sql.",
      "Exemple : SELECT * FROM `ga4-chemin-form.elsee_funnel.agregats`(DATE '2026-10-05', DATE '2026-10-11')",
    ]) + `CREATE OR REPLACE TABLE FUNCTION ${FONCTION}(date_debut DATE, date_fin DATE) AS (\n${corpsFonction}\n);\n`,
};

const dossier = join(racine, "sql/calcul");
mkdirSync(dossier, { recursive: true });
for (const [nom, texte] of Object.entries(fichiers)) writeFileSync(join(dossier, nom), texte);

// Graphe pour la page Apps Script, avec une empreinte de la configuration (le
// cache de la page en dépend : une nouvelle configuration vide le cache).
const empreinte = createHash("sha1").update(texteConfig).digest("hex").slice(0, 10);
mkdirSync(join(racine, "apps-script"), { recursive: true });
writeFileSync(
  join(racine, "apps-script/Graphe.gs"),
  [
    "// FICHIER GÉNÉRÉ par scripts/generer_sql.mjs à partir de config/graphe.json :",
    "// ne pas modifier à la main.",
    `const GRAPHE = ${JSON.stringify({ ...graphe, empreinte }, null, 2)};`,
    "",
  ].join("\n")
);
console.log(
  `Configuration valide : ${etapes.length} étapes, ${fleches.length} flèches, ` +
    `${pagesMultiples.length} pages à plusieurs parcours, ${atteignables.length} paires atteignables.\n` +
    `Texte de la fonction : ${tailleFonction} octets sur ${TAILLE_MAX}.\n` +
    `Écrit : ${Object.keys(fichiers).map((n) => "sql/calcul/" + n).join(", ")}, apps-script/Graphe.gs`
);
