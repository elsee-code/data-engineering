#!/usr/bin/env bash
# Active la clé du compte de service fournie par la session cloud, sans jamais
# l'afficher.
#
# Lit la variable d'environnement GCP_SA_KEY_JSON, qui peut contenir :
#   - le fichier JSON de la clé, tel quel ;
#   - ou ce même fichier encodé en base64 sur une ligne (plus sûr à coller dans
#     les réglages de l'environnement : sur Mac, `base64 -i cle.json | pbcopy`).
# Écrit la clé hors du dépôt (~/.config/elsee/sa.json, droits 600), puis lance
# `gcloud auth activate-service-account`.
#
# Usage : scripts/activer_cle_gcp.sh
# Ensuite, lancer bq sans le jeton factice de la session :
#   env -u CLOUDSDK_AUTH_ACCESS_TOKEN bq query --project_id=ga4-chemin-form ...
set -euo pipefail

if [[ -z "${GCP_SA_KEY_JSON:-}" ]]; then
  echo "Variable GCP_SA_KEY_JSON absente : l'ajouter dans les réglages de l'environnement cloud, puis ouvrir une nouvelle session." >&2
  exit 1
fi

dossier="${HOME}/.config/elsee"
cle="${dossier}/sa.json"
mkdir -p "$dossier"
chmod 700 "$dossier"
umask 077

# Normalise la clé (JSON brut ou base64) et vérifie les champs utiles.
# Seuls le type, le projet et l'adresse du compte sont affichés.
python3 -I - "$cle" <<'PY'
import base64, binascii, json, os, re, sys

valeur = os.environ["GCP_SA_KEY_JSON"].strip()
cle = None
try:
    cle = json.loads(valeur)
except ValueError:
    try:
        cle = json.loads(base64.b64decode(re.sub(r"\s", "", valeur), validate=True))
    except (binascii.Error, ValueError):
        pass

if not isinstance(cle, dict):
    if re.fullmatch(r"(?:[A-Za-z0-9+/=]|\\n)+", valeur):
        sys.exit("GCP_SA_KEY_JSON ne contient que la clé privée, pas le fichier "
                 "JSON complet (il manque notamment client_email). Y mettre le "
                 "fichier JSON entier, de préférence encodé en base64 sur une ligne.")
    sys.exit("GCP_SA_KEY_JSON n'est ni un JSON ni un JSON encodé en base64.")

manquants = [c for c in ("type", "project_id", "private_key", "client_email", "token_uri")
             if not cle.get(c)]
if cle.get("type") != "service_account" or manquants:
    sys.exit(f"Clé incomplète ou d'un autre type. Champs manquants : {', '.join(manquants) or 'aucun'} ; "
             f"type : {cle.get('type')!r}.")

with open(sys.argv[1], "w") as f:
    json.dump(cle, f)
print(f"Clé valide : compte {cle['client_email']} (projet {cle['project_id']}).")
PY

chmod 600 "$cle"
env -u CLOUDSDK_AUTH_ACCESS_TOKEN gcloud auth activate-service-account --key-file="$cle" --quiet
env -u CLOUDSDK_AUTH_ACCESS_TOKEN gcloud config set project ga4-chemin-form --quiet
echo "Compte de service activé. Clé écrite dans ${cle} (hors du dépôt)."
