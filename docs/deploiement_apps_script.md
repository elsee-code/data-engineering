# Mettre la page en ligne (Apps Script)

Pour Eglantine, avec le compte **hello@elsee.care** (propriétaire du projet
Google Cloud `ga4-chemin-form`). Aucune installation : tout se fait dans le
navigateur, par copier-coller de quatre fichiers. Compter 15 minutes.

La page tourne avec les droits de hello@elsee.care : c'est ce compte qui
interroge BigQuery. Les personnes qui ouvrent la page ne voient que des totaux.
Seuls les comptes @elsee.care peuvent l'ouvrir.

## Les quatre fichiers

Ils sont dans le dépôt GitHub, branche `main`, dossier `apps-script/` :

| Fichier du dépôt | Nom dans Apps Script |
|---|---|
| [`appsscript.json`](https://github.com/elsee-code/data-engineering/blob/main/apps-script/appsscript.json) | `appsscript.json` (le manifeste) |
| [`Code.gs`](https://github.com/elsee-code/data-engineering/blob/main/apps-script/Code.gs) | `Code.gs` |
| [`Graphe.gs`](https://github.com/elsee-code/data-engineering/blob/main/apps-script/Graphe.gs) | `Graphe.gs` |
| [`Page.html`](https://github.com/elsee-code/data-engineering/blob/main/apps-script/Page.html) | `Page.html` |

Pour copier un fichier depuis GitHub : ouvrir le lien, puis cliquer sur l'icône
« Copier le contenu brut » (*Copy raw file*, deux carrés superposés) en haut à
droite du contenu.

## 1. Créer le projet

1. Se connecter à Google avec **hello@elsee.care**, puis ouvrir
   <https://script.google.com>.
2. Cliquer sur **Nouveau projet**.
3. En haut à gauche, cliquer sur « Projet sans titre » et le renommer
   **Tunnel d'inscription Elsee**.
4. Dans la colonne de gauche, ouvrir **Paramètres du projet** (roue dentée) et
   cocher **Afficher le fichier manifeste « appsscript.json » dans l'éditeur**.
   Vérifier aussi que le fuseau horaire est **(GMT+01:00) Paris**. Revenir à
   l'**Éditeur** (icône `< >`).

## 2. Coller les fichiers

1. **`appsscript.json`** : le sélectionner dans la liste des fichiers, tout
   effacer, coller le contenu du fichier du dépôt.
2. **`Code.gs`** : même chose (effacer la fonction `myFunction` proposée).
3. **`Graphe.gs`** : cliquer sur **+** à côté de « Fichiers », choisir
   **Script**, le nommer `Graphe` (Apps Script ajoute `.gs`), coller.
4. **`Page.html`** : **+**, choisir **HTML**, le nommer `Page`, tout effacer,
   coller.
5. Enregistrer (icône disquette, ou Ctrl+S / Cmd+S).

Dans la colonne de gauche, la rubrique **Services** doit maintenant afficher
**BigQuery**. Sinon : **Services** → **+** → **BigQuery API** → **Ajouter**.

## 3. Vérifier l'installation

1. Dans la liste des fichiers, cliquer sur **Code.gs** : le bouton
   **Exécuter** et la liste des fonctions n'apparaissent en haut de l'éditeur
   que lorsqu'un fichier `.gs` est ouvert (pas `Page.html` ni
   `appsscript.json`).
2. Dans la liste des fonctions, à droite de **Exécuter** et **Déboguer**,
   choisir **testerInstallation**, puis cliquer sur **Exécuter**.
3. La première fois, Google demande une autorisation : **Examiner les
   autorisations** → choisir hello@elsee.care → si un écran « Google n'a pas
   validé cette application » s'affiche, cliquer sur **Paramètres avancés**
   puis **Accéder à** *(nom du projet)* **(non sécurisé)** → **Autoriser**.
   (C'est votre propre script : l'avertissement est normal.)
4. Le **journal d'exécution** doit se terminer par **« Installation
   correcte. »**, avec les dates des données disponibles et le nombre de
   personnes sur `/signup`. En cas d'erreur, copier le message et me
   l'envoyer.

## 4. Déploiement de test

1. **Déployer** (bouton bleu en haut à droite) → **Tester les déploiements**.
2. Type : **Application Web**. Copier l'**URL** (elle se termine par `/dev`) et
   l'ouvrir dans un nouvel onglet.
3. La page s'affiche avec le schéma de la période « 7 jours ». Cette adresse
   ne fonctionne que pour les personnes qui peuvent modifier le script : c'est
   l'étape de vérification. Me dire ce qui ne va pas avant de publier.

## 5. Publier

1. **Déployer** → **Nouveau déploiement**.
2. Roue dentée à côté de « Sélectionner le type » → **Application Web**.
3. Description : `Version 1`.
4. **Exécuter en tant que** : **Moi (hello@elsee.care)**.
5. **Qui a accès** : l'option réservée au domaine **elsee.care** (« Tous les
   utilisateurs de elsee.care »).
6. **Déployer**, puis copier l'**URL de l'application Web** (elle se termine
   par `/exec`). C'est l'adresse à partager avec l'équipe.

## 6. Installer les alertes

Une vérification tourne chaque jour entre 15 h et 16 h (heure de Paris) et
écrit à **hello@elsee.care** seulement en cas de gros problème :

- aucune nouvelle journée GA4 depuis plus de 2 jours (un retard d'un jour,
  qui arrive parfois, ne déclenche rien) ;
- le calcul du tunnel échoue (fonction BigQuery disparue ou en erreur) ;
- aucune personne sur les étapes du tunnel alors que GA4 a des données
  (adresses du formulaire changées, par exemple).

Tant qu'un même problème dure, il n'est rappelé que tous les 3 jours.

1. Ouvrir **Code.gs**, choisir la fonction **installerDeclencheur** dans la
   liste des fonctions, puis **Exécuter**. Google demande de nouvelles autorisations (envoyer des e-mails,
   s'exécuter à heure fixe) : les accepter comme à l'étape 3.
2. Le journal d'exécution confirme : « Vérification installée : chaque jour
   entre 15 h et 16 h… ». La rubrique **Déclencheurs** (icône réveil, colonne de
   gauche) montre une ligne `verifierChaqueJour`.
3. Facultatif : lancer **testerAlerte** pour recevoir un e-mail d'essai, et
   **verifierChaqueJour** pour faire la vérification tout de suite (le journal
   affiche « Vérification : tout va bien. »).

Relancer **installerDeclencheur** ne crée pas de doublon.

## Mettre à jour la page plus tard

Quand un fichier change dans le dépôt (par exemple `Graphe.gs` après l'ajout
d'une étape) :

1. Remplacer le contenu du fichier dans l'éditeur Apps Script, enregistrer.
   Si `Code.gs` a changé et que de nouvelles autorisations sont nécessaires,
   lancer une fois **testerInstallation** pour les accepter.
2. **Déployer** → **Gérer les déploiements** → sélectionner le déploiement →
   crayon (**Modifier**) → Version : **Nouvelle version** → **Déployer**.
   L'adresse `/exec` ne change pas.

Les résultats sont gardés en cache quelques heures : une modification de
`Graphe.gs` vide ce cache automatiquement.

## Dépannage

| Message | Cause et solution |
|---|---|
| « Page réservée aux comptes @elsee.care. » | Le navigateur est connecté avec un autre compte Google : se connecter avec son compte @elsee.care. |
| « BigQuery is not defined » | Le service BigQuery n'est pas ajouté : étape 2, rubrique **Services**. |
| « Access Denied » ou « Permission denied » | Le compte qui a déployé n'a pas accès au projet `ga4-chemin-form` : déployer avec hello@elsee.care. |
| « Not found: … elsee_funnel.agregats » | La fonction BigQuery a disparu : la recréer avec `sql/calcul/creer_fonction.sql` (voir `config/README.md`). |
| « Les données d'hier ne sont pas encore arrivées » | Normal le matin : GA4 envoie la journée de la veille dans la matinée. |
| Alerte « Aucune nouvelle donnée GA4 depuis le … » | L'export GA4 vers BigQuery est arrêté : dans GA4, Administration → rubrique des liaisons de produits (*Product links*) → BigQuery : vérifier que la liaison et l'export quotidien sont actifs. |
| Alerte « Le calcul du tunnel … échoue » | Recréer la fonction avec `sql/calcul/creer_fonction.sql` (voir `config/README.md`), ou me transmettre le message. |
| Alerte « Aucune personne comptée sur les étapes du tunnel » | Les adresses des pages du formulaire ont sans doute changé : les reporter dans `config/graphe.json`, puis suivre `config/README.md`. |
