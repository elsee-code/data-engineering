#!/usr/bin/env node
// Génère les requêtes de calcul du tunnel à partir de config/graphe.json.
//
// Usage : node scripts/generer_sql.mjs
// Écrit, dans sql/calcul/ :
//   - agregats.sql            : script autonome (dates en tête), renvoie les agrégats ;
//   - controle_coherence.sql  : script autonome, contrôle « sorties + abandons ≈ arrivées » ;
//   - creer_fonction.sql      : crée la fonction de table elsee_funnel.agregats(date_debut, date_fin).
// Ne jamais modifier ces fichiers à la main : modifier la configuration, puis relancer.

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const racine = join(dirname(fileURLToPath(import.meta.url)), "..");
const graphe = JSON.parse(readFileSync(join(racine, "config/graphe.json"), "utf8"));
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

// Pour chaque page multiple : étape selon la page précédente.
const casPagesMultiples = pagesMultiples
  .map(([page, ids]) => {
    const quand = fleches
      .filter((f) => ids.includes(f.vers))
      .map((f) => `WHEN ${q(f.de)} THEN ${q(f.vers)}`)
      .join(" ");
    return `      WHEN ${q(page)} THEN CASE precedente ${quand} END`;
  })
  .join("\n");
const nbPasses = pagesMultiples.length + 1;

function passe(n) {
  return `passe${n} AS (
  -- Passe ${n} : étape d'après la page précédente, sinon la même étape que la
  -- dernière fois que cette page a été vue dans la session (retour en arrière).
  SELECT * EXCEPT (etape, precedente, derniere_meme_page),
    COALESCE(
      id_unique,
      CASE cle
${casPagesMultiples}
      END,
      derniere_meme_page) AS etape
  FROM (
    SELECT *,
      LAG(etape) OVER (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang) AS precedente,
      LAST_VALUE(etape IGNORE NULLS) OVER (
        PARTITION BY user_pseudo_id, ga_session_id, cle ORDER BY rang
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS derniere_meme_page
    FROM passe${n - 1}
  )
)`;
}

// Corps commun : des pages vues jusqu'aux passages classés, une ligne par page
// du graphe vue (après rechargements et détours effacés), avec la page suivante.
const corps = `etapes AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<id STRING, cle STRING, ordre INT64>>[
${liste(etapes.map((e, i) => `(${q(e.id)}, ${q(cle(e))}, ${i + 1})`))}
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
atteignables AS (
  -- (de, vers) : vers est plus loin que de en suivant les flèches.
  SELECT * FROM UNNEST(ARRAY<STRUCT<de STRING, vers STRING>>[
${liste(atteignables.map(([a, b]) => `(${q(a)}, ${q(b)})`))}
  ])
),
pages AS (
  -- Pages vues, avec un jour de marge de chaque côté pour suivre les sessions
  -- qui passent minuit.
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS jour,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url,
    event_timestamp, batch_ordering_id, batch_page_id, batch_event_index
  FROM ${SOURCE}
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\\d{8}$')
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(date_debut, INTERVAL 1 DAY))
                          AND FORMAT_DATE('%Y%m%d', DATE_ADD(date_fin, INTERVAL 1 DAY))
    AND event_name = 'page_view'
    AND user_pseudo_id IS NOT NULL
),
tunnel AS (
  -- Pages du graphe seulement (domaine + chemin sans paramètres, en minuscules,
  -- sans « / » final), numérotées dans l'ordre de la session.
  SELECT p.jour, p.user_pseudo_id, p.ga_session_id, p.cle, c.id_unique,
    ROW_NUMBER() OVER (PARTITION BY p.user_pseudo_id, p.ga_session_id
                       ORDER BY p.event_timestamp, p.batch_ordering_id, p.batch_page_id, p.batch_event_index) AS rang
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
  SELECT * EXCEPT (p, n1, n2)
  FROM (
    SELECT *,
      LAG(e) OVER w AS p, LEAD(e) OVER w AS n1, LEAD(e, 2) OVER w AS n2
    FROM sans_rechargements
    WINDOW w AS (PARTITION BY user_pseudo_id, ga_session_id ORDER BY rang)
  )
  WHERE NOT IFNULL(${effaces.length ? `e IN (${effaces.map(q).join(", ")})` : "FALSE"}
                   AND n1 = p AND n2 != e
                   AND CONCAT(p, '>', n2) IN UNNEST(${sqlTableau(fleches.map((f) => `${f.de}>${f.vers}`))}), FALSE)
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
      WHEN a.de IS NOT NULL THEN 'saut'
      WHEN r.de IS NOT NULL THEN 'retour'
      ELSE 'autre'
    END AS genre
  FROM suites AS s
  LEFT JOIN fleches AS f ON f.de = s.e AND f.vers = s.vers
  LEFT JOIN atteignables AS a ON a.de = s.e AND a.vers = s.vers
  LEFT JOIN atteignables AS r ON r.de = s.vers AND r.vers = s.e
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
resultat AS (
  -- Pas de chiffre faux : flèches non mesurables et abandons qui en dépendent
  -- laissés vides.
  SELECT genre, de, vers, jour,
    IF((genre = 'fleche' AND CONCAT(de, '>', vers) IN UNNEST(${sqlTableau(nonMesurables.map((f) => `${f.de}>${f.vers}`))}))
       OR (genre = 'continuent' AND de IN UNNEST(${sqlTableau(sansSortieMesurable)})),
       NULL, utilisateurs) AS utilisateurs
  FROM agregats
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
ORDER BY e.ordre;
`,

  "creer_fonction.sql":
    entete("Création de la fonction de table elsee_funnel.agregats(date_debut, date_fin)", [
      "À lancer seulement après validation (écriture dans elsee_funnel).",
      "Même calcul et même résultat que agregats.sql.",
      "Exemple : SELECT * FROM `ga4-chemin-form.elsee_funnel.agregats`(DATE '2026-10-05', DATE '2026-10-11')",
    ]) + `CREATE OR REPLACE TABLE FUNCTION ${FONCTION}(date_debut DATE, date_fin DATE) AS (\nWITH\n${corps}\nSELECT * FROM resultat\n);\n`,
};

const dossier = join(racine, "sql/calcul");
mkdirSync(dossier, { recursive: true });
for (const [nom, texte] of Object.entries(fichiers)) writeFileSync(join(dossier, nom), texte);
console.log(
  `Configuration valide : ${etapes.length} étapes, ${fleches.length} flèches, ` +
    `${pagesMultiples.length} pages à plusieurs parcours, ${atteignables.length} paires atteignables.\n` +
    `Écrit : ${Object.keys(fichiers).map((n) => "sql/calcul/" + n).join(", ")}`
);
