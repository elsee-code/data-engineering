/**
 * Schéma du tunnel d'inscription Elsee : application web Apps Script.
 *
 * La page (Page.html) demande au serveur l'état des données (lireEtat), puis
 * les chiffres d'une période (lireTunnel). Le serveur interroge BigQuery avec le
 * compte du propriétaire du script : la fonction elsee_funnel.agregats ne
 * renvoie que des agrégats, aucun identifiant de personne ne sort de BigQuery.
 * Les résultats sont gardés en cache quelques heures.
 *
 * Graphe.gs (généré à partir de config/graphe.json) définit GRAPHE.
 */

const PROJET = 'ga4-chemin-form';
const LIEU = 'EU';
const FONCTION = '`ga4-chemin-form.elsee_funnel.agregats`';
const TABLES_EXPORT = '`ga4-chemin-form.analytics_383563328.__TABLES__`';
const DOMAINE_AUTORISE = 'elsee.care';
const FUSEAU = 'Europe/Paris';
const DUREE_CACHE_ETAT = 15 * 60; // secondes
const DUREE_CACHE_TUNNEL = 6 * 60 * 60; // le maximum permis par CacheService
const PERIODE_MAX_JOURS = 400;

/** Page d'accueil de l'application web. */
function doGet() {
  try {
    verifierAcces_();
  } catch (e) {
    return HtmlService.createHtmlOutput(
      '<p style="font-family:sans-serif;padding:24px">' + e.message + '</p>'
    ).setTitle('Tunnel d’inscription Elsee');
  }
  return HtmlService.createHtmlOutputFromFile('Page')
    .setTitle('Tunnel d’inscription Elsee')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

/**
 * État des données : graphe, date du jour à Paris, premier et dernier jour
 * disponibles dans l'export GA4, heure de la dernière mise à jour.
 */
function lireEtat() {
  verifierAcces_();
  const cle = 'etat|' + GRAPHE.empreinte;
  let etat = lireCache_(cle);
  if (!etat) {
    const [ligne] = requete_(
      "SELECT\n" +
        "  FORMAT_DATE('%F', PARSE_DATE('%Y%m%d', MIN(SUBSTR(table_id, 8)))),\n" +
        "  FORMAT_DATE('%F', PARSE_DATE('%Y%m%d', MAX(SUBSTR(table_id, 8)))),\n" +
        "  FORMAT_TIMESTAMP('%FT%TZ', TIMESTAMP_MILLIS(MAX(last_modified_time)))\n" +
        'FROM ' + TABLES_EXPORT + '\n' +
        "WHERE REGEXP_CONTAINS(table_id, r'^events_\\d{8}$')"
    );
    etat = {
      premierJour: ligne ? ligne[0] : null,
      dernierJour: ligne ? ligne[1] : null,
      miseAJour: ligne ? ligne[2] : null,
    };
    ecrireCache_(cle, etat, DUREE_CACHE_ETAT);
  }
  return Object.assign({}, etat, {
    graphe: GRAPHE,
    aujourdhui: Utilities.formatDate(new Date(), FUSEAU, 'yyyy-MM-dd'),
  });
}

/**
 * Chiffres du tunnel du jour debut au jour fin (inclus), au format AAAA-MM-JJ.
 * totaux : [genre, de, vers, utilisateurs] sur toute la période ;
 * jours  : [genre, de, vers, jour, utilisateurs] jour par jour (arrivées,
 *          sorties et flèches seulement, pour les courbes).
 */
function lireTunnel(debut, fin) {
  verifierAcces_();
  verifierPeriode_(debut, fin);
  const etat = lireEtat();
  const cle = ['tunnel', debut, fin, etat.miseAJour, GRAPHE.empreinte].join('|');
  let resultat = lireCache_(cle);
  if (!resultat) {
    const lignes = requete_(
      'SELECT genre, de, vers, jour, utilisateurs FROM ' + FONCTION + '(@debut, @fin)',
      [parametreDate_('debut', debut), parametreDate_('fin', fin)]
    );
    const nombre = (v) => (v === null || v === undefined ? null : Number(v));
    resultat = {
      debut: debut,
      fin: fin,
      calculeLe: new Date().toISOString(),
      totaux: lignes.filter((l) => l[3] === null).map((l) => [l[0], l[1], l[2], nombre(l[4])]),
      jours: lignes
        .filter((l) => l[3] !== null && ['arrivees', 'continuent', 'fleche'].indexOf(l[0]) >= 0)
        .map((l) => [l[0], l[1], l[2], l[3], nombre(l[4])]),
    };
    ecrireCache_(cle, resultat, DUREE_CACHE_TUNNEL);
  }
  return resultat;
}

/**
 * À lancer depuis l'éditeur (bouton Exécuter) pour vérifier l'installation :
 * accès à BigQuery, données disponibles, calcul d'une journée.
 */
function testerInstallation() {
  const etat = lireEtat();
  console.log('Compte : ' + Session.getActiveUser().getEmail());
  console.log('Données disponibles du ' + etat.premierJour + ' au ' + etat.dernierJour +
    ' (dernière mise à jour : ' + etat.miseAJour + ').');
  const resultat = lireTunnel(etat.dernierJour, etat.dernierJour);
  const arrivees = resultat.totaux.filter((l) => l[0] === 'arrivees');
  const signup = arrivees.find((l) => l[1] === 'signup');
  console.log('Calcul du ' + etat.dernierJour + ' : ' + arrivees.length + ' étapes avec des arrivées, dont /signup : ' +
    (signup ? signup[3] : 0) + ' personnes.');
  console.log('Installation correcte.');
}

// ---------------------------------------------------------------------------

function verifierAcces_() {
  const email = (Session.getActiveUser().getEmail() || '').toLowerCase();
  if (!email.endsWith('@' + DOMAINE_AUTORISE)) {
    throw new Error('Page réservée aux comptes @' + DOMAINE_AUTORISE + '.');
  }
  return email;
}

function verifierPeriode_(debut, fin) {
  const format = /^\d{4}-\d{2}-\d{2}$/;
  if (!format.test(debut) || !format.test(fin)) throw new Error('Dates invalides.');
  const jours = (Date.parse(fin) - Date.parse(debut)) / 86400000;
  if (!(jours >= 0)) throw new Error('La date de début doit précéder la date de fin.');
  if (jours > PERIODE_MAX_JOURS) throw new Error('Période trop longue.');
}

function parametreDate_(nom, valeur) {
  return { name: nom, parameterType: { type: 'DATE' }, parameterValue: { value: valeur } };
}

/** Lance une requête BigQuery et renvoie toutes les lignes (tableaux de valeurs). */
function requete_(sql, parametres) {
  const demande = { query: sql, useLegacySql: false, location: LIEU, timeoutMs: 60000 };
  if (parametres) {
    demande.parameterMode = 'NAMED';
    demande.queryParameters = parametres;
  }
  let reponse = BigQuery.Jobs.query(demande, PROJET);
  const job = reponse.jobReference;
  const options = { location: job.location || LIEU };
  const limite = Date.now() + 4 * 60 * 1000;
  while (!reponse.jobComplete) {
    if (Date.now() > limite) {
      throw new Error('BigQuery met trop de temps à répondre. Réessayez dans quelques minutes.');
    }
    Utilities.sleep(1000);
    reponse = BigQuery.Jobs.getQueryResults(PROJET, job.jobId, options);
  }
  let lignes = reponse.rows || [];
  let jeton = reponse.pageToken;
  while (jeton) {
    const page = BigQuery.Jobs.getQueryResults(
      PROJET, job.jobId, Object.assign({ pageToken: jeton }, options)
    );
    lignes = lignes.concat(page.rows || []);
    jeton = page.pageToken;
  }
  return lignes.map((l) => l.f.map((c) => c.v));
}

// Cache : valeur JSON compressée, découpée en morceaux (100 Ko au plus par clé).

function lireCache_(cle) {
  const cache = CacheService.getScriptCache();
  const nombre = cache.get(cle + ':n');
  if (!nombre) return null;
  const cles = [];
  for (let i = 0; i < Number(nombre); i++) cles.push(cle + ':' + i);
  const morceaux = cache.getAll(cles);
  if (cles.some((c) => !(c in morceaux))) return null;
  const octets = Utilities.base64Decode(cles.map((c) => morceaux[c]).join(''));
  const texte = Utilities.ungzip(Utilities.newBlob(octets, 'application/x-gzip')).getDataAsString();
  return JSON.parse(texte);
}

function ecrireCache_(cle, valeur, duree) {
  const compresse = Utilities.gzip(Utilities.newBlob(JSON.stringify(valeur), 'application/json'));
  const texte = Utilities.base64Encode(compresse.getBytes());
  const TAILLE = 90000;
  const morceaux = {};
  let n = 0;
  for (let i = 0; i < texte.length; i += TAILLE) morceaux[cle + ':' + n++] = texte.slice(i, i + TAILLE);
  morceaux[cle + ':n'] = String(n);
  try {
    CacheService.getScriptCache().putAll(morceaux, duree);
  } catch (e) {
    console.warn('Cache non écrit : ' + e.message);
  }
}
