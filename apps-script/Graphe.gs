// FICHIER GÉNÉRÉ par scripts/generer_sql.mjs à partir de config/graphe.json :
// ne pas modifier à la main.
const GRAPHE = {
  "version": 1,
  "mis_a_jour_le": "2026-10-08",
  "source": "docs/reference/schema-tunnel.pdf (schéma du 6 oct. 2026) et réponses d'Eglantine du 6 oct. ; chemin MAIL ajouté le 8 oct. (croquis d'Eglantine)",
  "domaines": [
    "app.elsee.care",
    "www.elsee.care"
  ],
  "parcours": {
    "entrees": {
      "libelle": "Entrées",
      "couleur": "#1A1A1A"
    },
    "short_form": {
      "libelle": "Short form",
      "couleur": "#3BB0F0",
      "titre": {
        "colonne": 0,
        "ligne": -3.8
      }
    },
    "offre_directe": {
      "libelle": "Offre directe",
      "couleur": "#F2C200",
      "titre": {
        "colonne": 2.6,
        "ligne": 0.35
      }
    },
    "long_form": {
      "libelle": "Long form",
      "couleur": "#1A1A1A"
    },
    "complements": {
      "libelle": "Compléments alimentaires",
      "couleur": "#1DB954",
      "titre": {
        "colonne": -3.15,
        "ligne": 8.5
      }
    },
    "mail": {
      "libelle": "Mail",
      "couleur": "#1A1A1A"
    },
    "carte_cadeau_long_form": {
      "libelle": "Carte cadeau – long form",
      "couleur": "#1A1A1A"
    },
    "carte_cadeau_directe": {
      "libelle": "Carte cadeau – offre directe",
      "couleur": "#1A1A1A"
    },
    "carte_cadeau_mail": {
      "libelle": "Carte cadeau – mail",
      "couleur": "#1A1A1A"
    }
  },
  "etapes": [
    {
      "id": "signup_corpo",
      "chemin": "/signup-corpo",
      "domaine": "app.elsee.care",
      "parcours": "entrees",
      "position": {
        "colonne": -4,
        "ligne": 0
      },
      "libelle": "CORPO"
    },
    {
      "id": "remboursement_complements_alimentaires",
      "chemin": "/remboursement-complements-alimentaires",
      "domaine": "www.elsee.care",
      "parcours": "entrees",
      "position": {
        "colonne": -3,
        "ligne": 0
      }
    },
    {
      "id": "offres_remboursement_elsee",
      "chemin": "/offres-remboursement-elsee",
      "domaine": "www.elsee.care",
      "parcours": "entrees",
      "position": {
        "colonne": -2,
        "ligne": 0
      }
    },
    {
      "id": "obtenir_mon_offre",
      "chemin": "/obtenir-mon-offre",
      "domaine": "www.elsee.care",
      "parcours": "short_form",
      "position": {
        "colonne": 0,
        "ligne": -3
      },
      "libelle": "SITE",
      "nom": "obtenir-mon-offre · page 1"
    },
    {
      "id": "obtenir_mon_offre_2",
      "chemin": "/obtenir-mon-offre",
      "domaine": "www.elsee.care",
      "parcours": "short_form",
      "position": {
        "colonne": 0,
        "ligne": -2
      },
      "nom": "obtenir-mon-offre · page 2"
    },
    {
      "id": "obtenir_mon_offre_3",
      "chemin": "/obtenir-mon-offre",
      "domaine": "www.elsee.care",
      "parcours": "short_form",
      "position": {
        "colonne": 0,
        "ligne": -1
      },
      "nom": "obtenir-mon-offre · page 3"
    },
    {
      "id": "obtenir_mon_offre_4",
      "chemin": "/obtenir-mon-offre",
      "domaine": "www.elsee.care",
      "parcours": "short_form",
      "position": {
        "colonne": 0,
        "ligne": 0
      },
      "nom": "obtenir-mon-offre · page 4"
    },
    {
      "id": "signup",
      "chemin": "/signup",
      "domaine": "app.elsee.care",
      "parcours": "short_form",
      "position": {
        "colonne": 0,
        "ligne": 1
      }
    },
    {
      "id": "mon_offre_directe",
      "chemin": "/mon-offre",
      "domaine": "app.elsee.care",
      "parcours": "offre_directe",
      "position": {
        "colonne": 1.3,
        "ligne": 1
      }
    },
    {
      "id": "mon_panier_directe",
      "chemin": "/mon-panier",
      "domaine": "app.elsee.care",
      "parcours": "offre_directe",
      "position": {
        "colonne": 2.6,
        "ligne": 1
      }
    },
    {
      "id": "paiement_ok_directe",
      "chemin": "/bienvenue-chez-elsee",
      "domaine": "www.elsee.care",
      "parcours": "offre_directe",
      "position": {
        "colonne": 3.9,
        "ligne": 1
      }
    },
    {
      "id": "social_signup",
      "chemin": "/social_signup",
      "domaine": "app.elsee.care",
      "parcours": "entrees",
      "position": {
        "colonne": -2,
        "ligne": 2
      },
      "libelle": "SOCIAL"
    },
    {
      "id": "depenses_complements",
      "chemin": "/signup/depenses_complements",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 2
      }
    },
    {
      "id": "montant_complements",
      "chemin": "/signup/montant_complements",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 3
      }
    },
    {
      "id": "network_complements",
      "chemin": "/signup/network_complements",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 4
      }
    },
    {
      "id": "recap_marques",
      "chemin": "/signup/recap_marques",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 5
      }
    },
    {
      "id": "depenses_complements_step",
      "chemin": "/signup/depenses_complements_step",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 6
      }
    },
    {
      "id": "sante_mentale_seances",
      "chemin": "/signup/sante_mentale_seances",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 7
      }
    },
    {
      "id": "montant_sante_mentale",
      "chemin": "/signup/montant_sante_mentale",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 8
      }
    },
    {
      "id": "md_seances",
      "chemin": "/signup/md_seances",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 9
      }
    },
    {
      "id": "montant_medecine_douce",
      "chemin": "/signup/montant_medecine_douce",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 10
      }
    },
    {
      "id": "soins_seances",
      "chemin": "/signup/soins_seances",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 11
      }
    },
    {
      "id": "montant_soins",
      "chemin": "/signup/montant_soins",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 12
      }
    },
    {
      "id": "network_info",
      "chemin": "/signup/network_info",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 13
      }
    },
    {
      "id": "prete_a_changer",
      "chemin": "/signup/prete_a-changer",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 14
      }
    },
    {
      "id": "medecine_douce_step",
      "chemin": "/signup/medecine_douce_step",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 15
      }
    },
    {
      "id": "en_savoir_plus_sur_vous",
      "chemin": "/signup/en_savoir_plus_sur_vous",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 16
      }
    },
    {
      "id": "depenses_sports",
      "chemin": "/signup/depenses_sports",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 17
      }
    },
    {
      "id": "network_sport",
      "chemin": "/signup/network_sport",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 18
      }
    },
    {
      "id": "out_of_network_sport",
      "chemin": "/signup/out_of_network_sport",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 19
      }
    },
    {
      "id": "sport_step",
      "chemin": "/signup/sport_step",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 20
      }
    },
    {
      "id": "depenses_produit",
      "chemin": "/signup/depenses_produit",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 21
      }
    },
    {
      "id": "network_produit",
      "chemin": "/signup/network_produit",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 22
      }
    },
    {
      "id": "out_of_network_produit",
      "chemin": "/signup/out_of_network_produit",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 23
      }
    },
    {
      "id": "depenses_app",
      "chemin": "/signup/depenses_app",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 24
      }
    },
    {
      "id": "out_of_network_app",
      "chemin": "/signup/out_of_network_app",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 25
      }
    },
    {
      "id": "final_step",
      "chemin": "/signup/final_step",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 26
      }
    },
    {
      "id": "offre_en_preparation",
      "chemin": "/signup/offre_en_preparation",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 27
      }
    },
    {
      "id": "sante_mentale_step",
      "chemin": "/signup/sante_mentale_step",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 1,
        "ligne": 8
      }
    },
    {
      "id": "recap_remboursements",
      "chemin": "/signup/recap_remboursements",
      "domaine": "app.elsee.care",
      "parcours": "complements",
      "position": {
        "colonne": -2,
        "ligne": 6
      }
    },
    {
      "id": "bonus_abonnement",
      "chemin": "/signup/bonus-abonnement",
      "domaine": "app.elsee.care",
      "parcours": "complements",
      "position": {
        "colonne": -2,
        "ligne": 7
      }
    },
    {
      "id": "bilan",
      "chemin": "/signup/bilan",
      "domaine": "app.elsee.care",
      "parcours": "complements",
      "position": {
        "colonne": -2,
        "ligne": 8
      }
    },
    {
      "id": "offres",
      "chemin": "/offres",
      "domaine": "app.elsee.care",
      "parcours": "complements",
      "position": {
        "colonne": -2,
        "ligne": 9
      }
    },
    {
      "id": "mon_panier_complements",
      "chemin": "/mon-panier",
      "domaine": "app.elsee.care",
      "parcours": "complements",
      "position": {
        "colonne": -2,
        "ligne": 10
      }
    },
    {
      "id": "paiement_ok_complements",
      "chemin": "/bienvenue-chez-elsee",
      "domaine": "www.elsee.care",
      "parcours": "complements",
      "position": {
        "colonne": -2,
        "ligne": 11
      }
    },
    {
      "id": "mon_offre_long_form",
      "chemin": "/mon-offre",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 28
      }
    },
    {
      "id": "mon_panier_long_form",
      "chemin": "/mon-panier",
      "domaine": "app.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 30
      }
    },
    {
      "id": "paiement_ok_long_form",
      "chemin": "/bienvenue-chez-elsee",
      "domaine": "www.elsee.care",
      "parcours": "long_form",
      "position": {
        "colonne": 0,
        "ligne": 31
      }
    },
    {
      "id": "cartecadeau_long_form",
      "chemin": "/pricing/cartecadeau",
      "domaine": "app.elsee.care",
      "parcours": "carte_cadeau_long_form",
      "position": {
        "colonne": 1,
        "ligne": 29
      },
      "effacer_si_retour": true
    },
    {
      "id": "mon_panier_cc_long_form",
      "chemin": "/mon-panier",
      "domaine": "app.elsee.care",
      "parcours": "carte_cadeau_long_form",
      "position": {
        "colonne": 1,
        "ligne": 30
      }
    },
    {
      "id": "paiement_ok_cc_long_form",
      "chemin": "/bienvenue-chez-elsee",
      "domaine": "www.elsee.care",
      "parcours": "carte_cadeau_long_form",
      "position": {
        "colonne": 1,
        "ligne": 31
      }
    },
    {
      "id": "mon_bilan_elsee",
      "chemin": "/mon-bilan-elsee",
      "domaine": "www.elsee.care",
      "parcours": "mail",
      "position": {
        "colonne": 3,
        "ligne": 18
      },
      "libelle": "MAIL"
    },
    {
      "id": "mon_offre_mail",
      "chemin": "/mon-offre",
      "domaine": "app.elsee.care",
      "parcours": "mail",
      "position": {
        "colonne": 3,
        "ligne": 19
      },
      "repli": true,
      "fleche_entree": true
    },
    {
      "id": "mon_panier_mail",
      "chemin": "/mon-panier",
      "domaine": "app.elsee.care",
      "parcours": "mail",
      "position": {
        "colonne": 3,
        "ligne": 20
      },
      "repli": true,
      "fleche_entree": true
    },
    {
      "id": "paiement_ok_mail",
      "chemin": "/bienvenue-chez-elsee",
      "domaine": "www.elsee.care",
      "parcours": "mail",
      "position": {
        "colonne": 3,
        "ligne": 21
      },
      "repli": true,
      "fleche_entree": true
    },
    {
      "id": "cartecadeau_directe",
      "chemin": "/pricing/cartecadeau",
      "domaine": "app.elsee.care",
      "parcours": "carte_cadeau_directe",
      "position": {
        "colonne": 1.3,
        "ligne": 2
      },
      "effacer_si_retour": true
    },
    {
      "id": "mon_panier_cc_directe",
      "chemin": "/mon-panier",
      "domaine": "app.elsee.care",
      "parcours": "carte_cadeau_directe",
      "position": {
        "colonne": 2.6,
        "ligne": 2
      }
    },
    {
      "id": "paiement_ok_cc_directe",
      "chemin": "/bienvenue-chez-elsee",
      "domaine": "www.elsee.care",
      "parcours": "carte_cadeau_directe",
      "position": {
        "colonne": 3.9,
        "ligne": 2
      }
    },
    {
      "id": "cartecadeau_mail",
      "chemin": "/pricing/cartecadeau",
      "domaine": "app.elsee.care",
      "parcours": "carte_cadeau_mail",
      "position": {
        "colonne": 4.3,
        "ligne": 20
      },
      "effacer_si_retour": true,
      "repli": true,
      "fleche_entree": "droite"
    },
    {
      "id": "mon_panier_cc_mail",
      "chemin": "/mon-panier",
      "domaine": "app.elsee.care",
      "parcours": "carte_cadeau_mail",
      "position": {
        "colonne": 4.3,
        "ligne": 21
      }
    },
    {
      "id": "paiement_ok_cc_mail",
      "chemin": "/bienvenue-chez-elsee",
      "domaine": "www.elsee.care",
      "parcours": "carte_cadeau_mail",
      "position": {
        "colonne": 4.3,
        "ligne": 22
      }
    }
  ],
  "fleches": [
    {
      "de": "obtenir_mon_offre",
      "vers": "obtenir_mon_offre_2",
      "type": "normale"
    },
    {
      "de": "obtenir_mon_offre_2",
      "vers": "obtenir_mon_offre_3",
      "type": "normale"
    },
    {
      "de": "obtenir_mon_offre_3",
      "vers": "obtenir_mon_offre_4",
      "type": "normale"
    },
    {
      "de": "obtenir_mon_offre_4",
      "vers": "signup",
      "type": "normale",
      "mesurable": false,
      "raison": "Passage de www.elsee.care à app.elsee.care : GA4 perd l'identifiant (étape 1, section 6)."
    },
    {
      "de": "offres_remboursement_elsee",
      "vers": "signup",
      "type": "normale",
      "mesurable": false,
      "raison": "Passage de www.elsee.care à app.elsee.care : GA4 perd l'identifiant (étape 1, section 6)."
    },
    {
      "de": "remboursement_complements_alimentaires",
      "vers": "signup",
      "type": "normale",
      "mesurable": false,
      "raison": "Passage de www.elsee.care à app.elsee.care : GA4 perd l'identifiant (étape 1, section 6)."
    },
    {
      "de": "signup_corpo",
      "vers": "signup",
      "type": "normale"
    },
    {
      "de": "signup",
      "vers": "mon_offre_directe",
      "type": "normale"
    },
    {
      "de": "mon_offre_directe",
      "vers": "mon_panier_directe",
      "type": "normale"
    },
    {
      "de": "mon_panier_directe",
      "vers": "paiement_ok_directe",
      "type": "normale"
    },
    {
      "de": "signup",
      "vers": "depenses_complements",
      "type": "normale"
    },
    {
      "de": "social_signup",
      "vers": "depenses_complements",
      "type": "normale"
    },
    {
      "de": "depenses_complements",
      "vers": "montant_complements",
      "type": "oui"
    },
    {
      "de": "depenses_complements",
      "vers": "sante_mentale_seances",
      "type": "non"
    },
    {
      "de": "montant_complements",
      "vers": "network_complements",
      "type": "normale"
    },
    {
      "de": "network_complements",
      "vers": "recap_marques",
      "type": "normale"
    },
    {
      "de": "recap_marques",
      "vers": "depenses_complements_step",
      "type": "normale"
    },
    {
      "de": "recap_marques",
      "vers": "recap_remboursements",
      "type": "normale"
    },
    {
      "de": "depenses_complements_step",
      "vers": "sante_mentale_seances",
      "type": "normale"
    },
    {
      "de": "recap_remboursements",
      "vers": "bonus_abonnement",
      "type": "normale"
    },
    {
      "de": "bonus_abonnement",
      "vers": "bilan",
      "type": "normale"
    },
    {
      "de": "bilan",
      "vers": "offres",
      "type": "normale"
    },
    {
      "de": "offres",
      "vers": "mon_panier_complements",
      "type": "normale"
    },
    {
      "de": "mon_panier_complements",
      "vers": "paiement_ok_complements",
      "type": "normale"
    },
    {
      "de": "sante_mentale_seances",
      "vers": "montant_sante_mentale",
      "type": "oui"
    },
    {
      "de": "sante_mentale_seances",
      "vers": "sante_mentale_step",
      "type": "non"
    },
    {
      "de": "montant_sante_mentale",
      "vers": "md_seances",
      "type": "normale"
    },
    {
      "de": "sante_mentale_step",
      "vers": "md_seances",
      "type": "normale"
    },
    {
      "de": "md_seances",
      "vers": "montant_medecine_douce",
      "type": "oui"
    },
    {
      "de": "md_seances",
      "vers": "soins_seances",
      "type": "non"
    },
    {
      "de": "montant_medecine_douce",
      "vers": "soins_seances",
      "type": "normale"
    },
    {
      "de": "soins_seances",
      "vers": "montant_soins",
      "type": "oui"
    },
    {
      "de": "soins_seances",
      "vers": "medecine_douce_step",
      "type": "non"
    },
    {
      "de": "montant_soins",
      "vers": "network_info",
      "type": "normale"
    },
    {
      "de": "network_info",
      "vers": "prete_a_changer",
      "type": "normale"
    },
    {
      "de": "prete_a_changer",
      "vers": "medecine_douce_step",
      "type": "normale"
    },
    {
      "de": "medecine_douce_step",
      "vers": "en_savoir_plus_sur_vous",
      "type": "normale"
    },
    {
      "de": "medecine_douce_step",
      "vers": "depenses_sports",
      "type": "normale",
      "note": "Coordonnées déjà recueillies : en_savoir_plus_sur_vous n'est pas montrée."
    },
    {
      "de": "en_savoir_plus_sur_vous",
      "vers": "depenses_sports",
      "type": "normale"
    },
    {
      "de": "depenses_sports",
      "vers": "network_sport",
      "type": "oui"
    },
    {
      "de": "depenses_sports",
      "vers": "sport_step",
      "type": "non"
    },
    {
      "de": "network_sport",
      "vers": "out_of_network_sport",
      "type": "normale"
    },
    {
      "de": "out_of_network_sport",
      "vers": "sport_step",
      "type": "normale"
    },
    {
      "de": "sport_step",
      "vers": "depenses_produit",
      "type": "normale"
    },
    {
      "de": "depenses_produit",
      "vers": "network_produit",
      "type": "oui"
    },
    {
      "de": "depenses_produit",
      "vers": "depenses_app",
      "type": "non"
    },
    {
      "de": "network_produit",
      "vers": "out_of_network_produit",
      "type": "normale"
    },
    {
      "de": "out_of_network_produit",
      "vers": "depenses_app",
      "type": "normale"
    },
    {
      "de": "depenses_app",
      "vers": "out_of_network_app",
      "type": "oui"
    },
    {
      "de": "depenses_app",
      "vers": "final_step",
      "type": "non"
    },
    {
      "de": "out_of_network_app",
      "vers": "final_step",
      "type": "normale"
    },
    {
      "de": "final_step",
      "vers": "offre_en_preparation",
      "type": "normale"
    },
    {
      "de": "offre_en_preparation",
      "vers": "mon_offre_long_form",
      "type": "normale"
    },
    {
      "de": "mon_offre_long_form",
      "vers": "mon_panier_long_form",
      "type": "normale"
    },
    {
      "de": "mon_panier_long_form",
      "vers": "paiement_ok_long_form",
      "type": "normale"
    },
    {
      "de": "mon_offre_long_form",
      "vers": "cartecadeau_long_form",
      "type": "normale"
    },
    {
      "de": "cartecadeau_long_form",
      "vers": "mon_panier_cc_long_form",
      "type": "normale"
    },
    {
      "de": "mon_panier_cc_long_form",
      "vers": "paiement_ok_cc_long_form",
      "type": "normale"
    },
    {
      "de": "mon_bilan_elsee",
      "vers": "mon_offre_mail",
      "type": "normale",
      "mesurable": false,
      "raison": "Passage de www.elsee.care à app.elsee.care : GA4 perd l'identifiant (étape 1, section 6)."
    },
    {
      "de": "mon_offre_mail",
      "vers": "mon_panier_mail",
      "type": "normale"
    },
    {
      "de": "mon_panier_mail",
      "vers": "paiement_ok_mail",
      "type": "normale"
    },
    {
      "de": "mon_offre_directe",
      "vers": "cartecadeau_directe",
      "type": "normale"
    },
    {
      "de": "cartecadeau_directe",
      "vers": "mon_panier_cc_directe",
      "type": "normale"
    },
    {
      "de": "mon_panier_cc_directe",
      "vers": "paiement_ok_cc_directe",
      "type": "normale"
    },
    {
      "de": "mon_offre_mail",
      "vers": "cartecadeau_mail",
      "type": "normale"
    },
    {
      "de": "cartecadeau_mail",
      "vers": "mon_panier_cc_mail",
      "type": "normale"
    },
    {
      "de": "mon_panier_cc_mail",
      "vers": "paiement_ok_cc_mail",
      "type": "normale"
    }
  ],
  "pages_vues": {
    "formulaire": "app.elsee.care",
    "debut": [
      "signup_corpo",
      "signup",
      "social_signup"
    ],
    "offre": [
      "mon_offre_directe",
      "mon_offre_long_form",
      "offres",
      "mon_offre_mail"
    ],
    "position": {
      "colonne": 1.7,
      "ligne": 3.3
    }
  },
  "leads": {
    "provenance_interne": "app.elsee.care",
    "entrees": [
      {
        "etape": "signup_corpo",
        "coordonnees": "a_l_entree"
      },
      {
        "etape": "remboursement_complements_alimentaires",
        "coordonnees": "a_l_entree"
      },
      {
        "etape": "offres_remboursement_elsee",
        "coordonnees": "a_l_entree"
      },
      {
        "etape": "obtenir_mon_offre",
        "coordonnees": "a_l_entree"
      },
      {
        "etape": "signup",
        "provenance": "www.elsee.care",
        "coordonnees": "a_l_entree"
      },
      {
        "etape": "signup",
        "coordonnees": "plus_tard"
      },
      {
        "etape": "social_signup",
        "coordonnees": "plus_tard"
      }
    ],
    "moments": [
      {
        "id": "avant_depenses_complements",
        "libelle": "Avant depenses_complements",
        "detail": "Entrée par /obtenir-mon-offre, /offres-remboursement-elsee, /remboursement-complements-alimentaires (/signup ouverte depuis www.elsee.care) ou /signup-corpo. Compté à l’arrivée sur depenses_complements.",
        "page": "depenses_complements",
        "entree": "a_l_entree"
      },
      {
        "id": "popup_bilan",
        "libelle": "Pop-up avant bilan",
        "detail": "Entrée directe (/social_signup, ou /signup ouverte sans venir de www.elsee.care), chemin compléments : pop-up entre bonus-abonnement et bilan. Compté à l’arrivée sur bilan.",
        "page": "bilan",
        "apres": "bonus_abonnement",
        "entree": "plus_tard"
      },
      {
        "id": "en_savoir_plus_sur_vous",
        "libelle": "en_savoir_plus_sur_vous",
        "detail": "Entrée directe, long form. Compté à l’arrivée sur depenses_sports, la page suivante.",
        "page": "depenses_sports",
        "apres": "en_savoir_plus_sur_vous"
      }
    ]
  },
  "paiement": {
    "libelle": "paiement ok",
    "page": "www.elsee.care/bienvenue-chez-elsee",
    "pages": [
      {
        "page": "www.elsee.care/bienvenue-chez-elsee",
        "apres": [
          "app.elsee.care/mon-panier"
        ],
        "provenance": [
          "checkout.stripe.com"
        ]
      },
      {
        "page": "app.elsee.care/success",
        "apres": [
          "app.elsee.care/mon-panier",
          "www.elsee.care/bienvenue-chez-elsee"
        ],
        "provenance": [
          "checkout.stripe.com"
        ]
      }
    ],
    "reprise_si_provenance": [
      "checkout.stripe.com"
    ]
  },
  "sous_etapes": {
    "page": "www.elsee.care/obtenir-mon-offre",
    "evenement": "step_form",
    "parametre": "form_derniere_page",
    "etapes": [
      {
        "etape": "obtenir_mon_offre",
        "valeur": "/obtenir-mon-offre-1"
      },
      {
        "etape": "obtenir_mon_offre_2",
        "valeur": "/obtenir-mon-offre-2"
      },
      {
        "etape": "obtenir_mon_offre_3",
        "valeur": "/obtenir-mon-offre-3"
      },
      {
        "etape": "obtenir_mon_offre_4",
        "valeur": "/obtenir-mon-offre-4"
      }
    ]
  },
  "empreinte": "a0ec1fc979"
};
