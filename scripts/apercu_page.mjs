#!/usr/bin/env node
// Aperçu local de la page Apps Script, sans Apps Script.
//
// Remplace google.script.run par des réponses fixes : le graphe (Graphe.gs) et
// des agrégats lus dans un fichier CSV (colonnes genre, de, vers, jour,
// utilisateurs), tel que le renvoie :
//   bq query --format=csv 'SELECT genre, de, vers, jour, utilisateurs
//     FROM `ga4-chemin-form.elsee_funnel.agregats`(DATE "…", DATE "…")'
// Le CSV ne contient que des agrégats : aucun identifiant de personne.
//
// Usage : node scripts/apercu_page.mjs agregats.csv premier-jour dernier-jour sortie.html [aujourd'hui]
// La page s'ouvre sur « 7 jours », ramenée aux jours disponibles. Par défaut,
// aujourd'hui = lendemain du dernier jour (les données d'hier sont arrivées).

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const [csv, premierJour, dernierJour, sortie, aujourdhuiImpose] = process.argv.slice(2);
if (!sortie) {
  console.error("Usage : node scripts/apercu_page.mjs agregats.csv premier-jour dernier-jour sortie.html");
  process.exit(1);
}
const racine = join(dirname(fileURLToPath(import.meta.url)), "..");
const page = readFileSync(join(racine, "apps-script/Page.html"), "utf8");
const GRAPHE = new Function(readFileSync(join(racine, "apps-script/Graphe.gs"), "utf8") + "; return GRAPHE;")();

// Même mise en forme que lireTunnel (Code.gs).
const lignes = readFileSync(csv, "utf8").trim().split("\n").slice(1).map((l) => l.split(","));
const valeur = (v) => (v === "" ? null : v);
const nombre = (v) => (v === "" ? null : Number(v));
const donnees = {
  debut: premierJour,
  fin: dernierJour,
  calculeLe: new Date().toISOString(),
  totaux: lignes.filter((l) => l[3] === "").map((l) => [l[0], l[1], valeur(l[2]), nombre(l[4])]),
  jours: lignes
    .filter((l) => l[3] !== "" && ["arrivees", "continuent", "fleche"].includes(l[0]))
    .map((l) => [l[0], l[1], valeur(l[2]), l[3], nombre(l[4])]),
};
const etat = {
  graphe: GRAPHE,
  premierJour,
  dernierJour,
  miseAJour: new Date().toISOString(),
  aujourdhui: aujourdhuiImpose || new Date(Date.parse(dernierJour) + 86400000).toISOString().slice(0, 10),
};

const imitation = `<script>
window.google = { script: { run: (() => {
  const reponses = { lireEtat: () => (${JSON.stringify(etat)}), lireTunnel: () => (${JSON.stringify(donnees)}) };
  const appel = (succes, echec) => new Proxy({}, { get: (_, nom) => {
    if (nom === 'withSuccessHandler') return (f) => appel(f, echec);
    if (nom === 'withFailureHandler') return (f) => appel(succes, f);
    return (...args) => setTimeout(() => { try { succes(reponses[nom](...args)); } catch (e) { echec(e); } }, 50);
  } });
  return appel(() => {}, (e) => console.error(e));
})() } };
</script>`;

writeFileSync(sortie, page.replace("<body>", "<body>\n" + imitation));
console.log(`Aperçu écrit : ${sortie}`);
