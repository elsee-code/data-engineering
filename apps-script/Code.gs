/**
 * Schéma du tunnel d'inscription Elsee : application web Apps Script.
 *
 * La page (Page.html) demande au serveur l'état des données (lireEtat), puis
 * les chiffres d'une période (lireTunnel). Le serveur interroge BigQuery avec le
 * compte du propriétaire du script : la fonction elsee_funnel.agregats ne
 * renvoie que des agrégats, aucun identifiant de personne ne sort de BigQuery.
 * Les résultats sont gardés en cache quelques heures.
 *
 * Alertes : verifierChaqueJour, lancé chaque jour par un déclencheur (installé
 * une fois avec installerDeclencheur), écrit à hello@elsee.care seulement en cas
 * de gros problème (export GA4 arrêté, calcul en échec, tunnel à zéro).
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
const DESTINATAIRE_ALERTES = 'hello@elsee.care';
const HEURE_VERIFICATION = 15; // heure de Paris
const RETARD_MAX_JOURS = 2; // alerte si ni hier ni avant-hier ne sont arrivés
const RAPPEL_JOURS = 3; // un même problème n'est rappelé que tous les 3 jours

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
  return Object.assign({}, etatDonnees_(false), { graphe: GRAPHE, aujourdhui: aujourdhui_() });
}

function etatDonnees_(sansCache) {
  const cle = 'etat|' + GRAPHE.empreinte;
  let etat = sansCache ? null : lireCache_(cle);
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
  return etat;
}

/**
 * Chiffres du tunnel du jour debut au jour fin (inclus), au format AAAA-MM-JJ.
 * totaux : [genre, de, vers, utilisateurs] sur toute la période ;
 * jours  : [genre, de, vers, jour, utilisateurs] jour par jour (arrivées,
 *          sorties, flèches et leads seulement, pour les courbes).
 */
function lireTunnel(debut, fin) {
  verifierAcces_();
  verifierPeriode_(debut, fin);
  const etat = etatDonnees_(false);
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
        .filter((l) => l[3] !== null && ['arrivees', 'continuent', 'fleche', 'leads'].indexOf(l[0]) >= 0)
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
  const leads = resultat.totaux.find((l) => l[0] === 'leads' && !l[1]);
  console.log('Nombre leads : ' + (leads ? leads[3] : 'indisponible (fonction BigQuery pas à jour)') + '.');
  console.log('Installation correcte.');
}

// ---------------------------------------------------------------------------
// Alertes
// ---------------------------------------------------------------------------

/**
 * Vérification quotidienne. N'écrit qu'en cas de gros problème :
 * - aucune nouvelle journée GA4 depuis plus de RETARD_MAX_JOURS jours ;
 * - la fonction de calcul elsee_funnel.agregats échoue ;
 * - aucune personne sur les étapes du tunnel alors que GA4 a des données.
 */
function verifierChaqueJour() {
  const problemes = [];
  const aujourdhui = aujourdhui_();
  let etat = null;
  try {
    etat = etatDonnees_(true);
  } catch (e) {
    problemes.push('Lecture de l’export GA4 impossible dans BigQuery : ' + e.message);
  }
  if (etat && !etat.dernierJour) problemes.push('Aucune table de l’export GA4 dans BigQuery.');
  if (etat && etat.dernierJour) {
    if (etat.dernierJour < ajouterJours_(aujourdhui, -RETARD_MAX_JOURS)) {
      problemes.push('Aucune nouvelle donnée GA4 depuis le ' + etat.dernierJour + ' : l’export quotidien ' +
        'de GA4 vers BigQuery semble arrêté (vérifier la liaison BigQuery dans l’administration de GA4).');
    }
    try {
      const lignes = requete_(
        'SELECT de, utilisateurs FROM ' + FONCTION + "(@jour, @jour) WHERE jour IS NULL AND genre = 'arrivees'",
        [parametreDate_('jour', etat.dernierJour)]
      );
      const total = lignes.reduce((s, l) => s + Number(l[1] || 0), 0);
      if (total === 0) {
        problemes.push('Aucune personne comptée sur les étapes du tunnel le ' + etat.dernierJour +
          ', alors que GA4 a envoyé des données : les adresses des pages du formulaire ont peut-être ' +
          'changé (à reporter dans config/graphe.json).');
      }
    } catch (e) {
      problemes.push('Le calcul du tunnel (fonction BigQuery elsee_funnel.agregats) échoue : ' + e.message);
    }
  }
  signaler_(problemes);
}

/** À lancer une fois depuis l'éditeur : installe la vérification quotidienne. */
function installerDeclencheur() {
  for (const d of ScriptApp.getProjectTriggers()) {
    if (d.getHandlerFunction() === 'verifierChaqueJour') ScriptApp.deleteTrigger(d);
  }
  ScriptApp.newTrigger('verifierChaqueJour').timeBased().everyDays(1)
    .atHour(HEURE_VERIFICATION).inTimezone(FUSEAU).create();
  console.log('Vérification installée : chaque jour entre ' + HEURE_VERIFICATION + ' h et ' +
    (HEURE_VERIFICATION + 1) + ' h (heure de Paris). Alertes envoyées à ' + DESTINATAIRE_ALERTES + '.');
}

/** À lancer depuis l'éditeur pour vérifier que les e-mails d'alerte arrivent. */
function testerAlerte() {
  MailApp.sendEmail(DESTINATAIRE_ALERTES, '[Tunnel Elsee] Essai d’alerte',
    'Ceci est un essai : les alertes du schéma du tunnel d’inscription arrivent bien à cette adresse.');
  console.log('E-mail d’essai envoyé à ' + DESTINATAIRE_ALERTES + '.');
}

function signaler_(problemes) {
  const proprietes = PropertiesService.getScriptProperties();
  if (!problemes.length) {
    proprietes.deleteProperty('derniere_alerte');
    console.log('Vérification : tout va bien.');
    return;
  }
  const texte = problemes.map((p) => '- ' + p).join('\n');
  const precedente = JSON.parse(proprietes.getProperty('derniere_alerte') || 'null');
  const maintenant = Date.now();
  if (precedente && precedente.texte === texte && maintenant - precedente.le < RAPPEL_JOURS * 86400000) {
    console.log('Problème déjà signalé, pas de nouvel e-mail :\n' + texte);
    return;
  }
  let adresse = '';
  try {
    adresse = ScriptApp.getService().getUrl() || '';
  } catch (e) {
    adresse = '';
  }
  MailApp.sendEmail(DESTINATAIRE_ALERTES, '[Tunnel Elsee] Problème sur le schéma du tunnel',
    'Bonjour,\n\n' +
    'La vérification quotidienne du schéma du tunnel d’inscription a trouvé un problème :\n\n' +
    texte + '\n\n' +
    (adresse ? 'La page : ' + adresse + '\n' : '') +
    'Que faire : voir la rubrique « Dépannage » de docs/deploiement_apps_script.md dans le dépôt ' +
    'data-engineering, ou transmettre ce message.\n\n' +
    'Cet e-mail n’est envoyé qu’en cas de problème important. Tant que le problème dure, ' +
    'il est rappelé tous les ' + RAPPEL_JOURS + ' jours.\n');
  proprietes.setProperty('derniere_alerte', JSON.stringify({ texte: texte, le: maintenant }));
  console.log('Alerte envoyée à ' + DESTINATAIRE_ALERTES + ' :\n' + texte);
}

// ---------------------------------------------------------------------------

function aujourdhui_() {
  return Utilities.formatDate(new Date(), FUSEAU, 'yyyy-MM-dd');
}

function ajouterJours_(jour, n) {
  const d = new Date(jour + 'T00:00:00Z');
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

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
