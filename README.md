# data-engineering

## Schéma du tunnel d'inscription Elsee

Page web privée qui redessine le tunnel d'inscription d'Elsee sous forme de
diagramme de flux, avec, pour la période choisie, les arrivées sur chaque étape,
les passages sur chaque flèche et le taux d'abandon de chaque étape. Les
chiffres sont calculés dans BigQuery à partir de l'export quotidien de GA4.

- Brief : [`docs/brief.md`](docs/brief.md)
- Décisions et état d'avancement : [`docs/decisions.md`](docs/decisions.md)
- Documents de référence (schéma, explorations GA4) : [`docs/reference/`](docs/reference/)
- Requêtes de découverte (étape 1) : [`sql/decouverte/`](sql/decouverte/)
- Activation de la clé BigQuery dans une session cloud : [`scripts/activer_cle_gcp.sh`](scripts/activer_cle_gcp.sh)

Le README complet (installation, configuration, ajout d'une étape, dépannage)
viendra à l'étape 5.
