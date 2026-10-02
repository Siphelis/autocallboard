# 🎯 AutoCallboard

**Le Callboard ne vous fera plus jamais perdre votre temps.**

AutoCallboard relance le _Callboard_ pour vous, reconnaît la quête que vous cherchez dès
qu'elle apparaît, la sélectionne, puis reprend la recherche une fois la quête terminée. Il
mémorise aussi toutes les quêtes déjà vues, enregistre vos sélections sous forme de
collections communes à tous vos personnages, enregistre et rejoue vos routes avec une flèche
de guidage, permet aux joueurs de se les partager, et vous offre une barre d'accès rapide à
vos builds d'échos. Le tout dans une interface sobre et élégante, disponible en français,
anglais, allemand et espagnol.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table des matières

- [Pourquoi cet addon](#-pourquoi-cet-addon)
- [Fonctionnalités](#-fonctionnalités)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Démarrage rapide](#-démarrage-rapide)
- [Le panneau principal](#-le-panneau-principal)
- [Quêtes et collections](#-quêtes-et-collections)
- [Les relances](#-les-relances)
- [Les routes](#-les-routes)
- [Les builds](#-les-builds)
- [Les extras](#-les-extras)
- [Réglages](#-réglages)
- [À savoir](#-à-savoir)
- [Langues](#-langues)
- [Licence et crédits](#-licence-et-crédits)

---

## 🔥 Pourquoi cet addon

Le Callboard propose trois quêtes aléatoires et vous oblige à relancer à la main jusqu'à
obtenir celle que vous voulez. C'est répétitif, et ça prend du temps. Avec AutoCallboard, vous
cochez les quêtes voulues et il se charge des relances.

## ✨ Fonctionnalités

- **Relance automatique intelligente** — cochez les quêtes voulues et cliquez sur Démarrer :
  l'addon relance jusqu'à ce que l'une d'elles apparaisse, la sélectionne, l'accepte si vous
  le souhaitez, et reprend une fois la quête terminée.
- **Quêtes connues** — chaque quête vue sur le tableau est mémorisée (titre, type,
  récompenses) pour que vous puissiez la rechercher, la filtrer et la cocher.
- **Collections** — enregistrez des sélections de quêtes nommées, rangez-les en groupes et
  chargez-en une en un clic. Elles sont communes à tous vos personnages, et chacune peut
  porter une difficulté.
- **Mode « instance actuelle »** — dans un donjon ou un raid, relance uniquement pour la
  quête de cette instance.
- **Routes** — enregistrez vos trajets (PNJ, dialogues, quêtes, checkpoints), rejouez-les avec
  une flèche de guidage, une fois ou en boucle, et partagez-les avec les autres joueurs grâce à
  une bibliothèque.
- **Bouton de voyage** — rejoignez un checkpoint proche de la zone de votre quête.
- **Partage de quêtes en groupe** — le bouton **Partager** partage votre dernière quête acceptée
  avec votre groupe ou votre raid.
- **Builds d'échos** — changez de build depuis une fenêtre, ou depuis une barre d'accès rapide
  déplaçable à 3 emplacements, avec raccourcis clavier.
- **Assistance Eternals** — convertit vos cristaux pendant les quêtes des Eternals.
- **Compteurs d'or** — voyez ce que coûtent vos relances : total, session, recherche en
  cours, dernière quête.
- **Avis de mise à jour** — un bouton vous prévient lorsqu'une nouvelle version existe.
- **Export / import** — copiez vos quêtes connues d'une installation à l'autre.
- **Votre apparence** — style de flèche et boutons affichés dans la barre principale ; les
  fenêtres suivent le skin, les couleurs, l'échelle et l'opacité choisis dans
  [EbonAPI](https://github.com/Siphelis/EbonAPI).
- **Quatre langues** — français, anglais, allemand, espagnol, changées à chaud sans `/reload`.

## 📋 Prérequis

| | |
|---|---|
| **Jeu** | World of Warcraft 3.3.5a sur le serveur **Ebonhold** |
| **Intégration** | ProjectEbonhold, fourni avec le client Ebonhold |
| **Addon requis** | [**EbonAPI**](https://github.com/Siphelis/EbonAPI) **2.1 ou plus récent**, commun aux addons Ebonhold ; AutoCallboard ne se charge pas sans lui |

## 📦 Installation

1. Téléchargez la dernière version depuis la
   [page des versions](https://github.com/Siphelis/autocallboard/releases/latest).
2. Décompressez le dossier `AutoCallboard` dans `Interface/AddOns/`. Installez
   [**EbonAPI**](https://github.com/Siphelis/EbonAPI) de la même façon s'il
   n'y est pas encore.
3. Redémarrez le jeu et vérifiez dans l'écran de sélection des addons que **AutoCallboard** et
   [**EbonAPI**](https://github.com/Siphelis/EbonAPI) sont bien cochés.
4. Le panneau AutoCallboard apparaît à l'écran. Un bouton sur la minicarte y donne un accès
   rapide.

## 🚀 Démarrage rapide

1. Cliquez sur **Quêtes**, puis cochez les quêtes que vous souhaitez obtenir.
2. Cliquez sur **Callboard** : il invoque un Callboard si vous disposez du sort de la
   boutique, puis le cible et l'ouvre pour vous. Vous êtes plutôt près d'un Objectives Board
   fixe ? Cliquez une première fois dessus pour qu'AutoCallboard puisse lire son contenu.
3. Cliquez sur **Démarrer**. AutoCallboard relance jusqu'à ce qu'une de vos quêtes apparaisse,
   puis cesse de relancer et la sélectionne. Il l'accepte aussi, sauf si vous avez désactivé
   cette option.
4. Faites la quête. Dès que vous l'avez rendue, la recherche reprend d'elle-même à partir du
   moment où un tableau est ouvert, jusqu'à ce que vous cliquiez sur **Arrêter**.

Sur une installation neuve, la liste des quêtes connues est encore vide : voyez
[Quêtes connues](#quêtes-connues) pour la remplir.

La ligne sous les boutons vous indique ce qui se passe : Callboard actif ou en recharge,
relances effectuées, recherche en pause, quête sélectionnée.

## 🧭 Le panneau principal

| Élément | Rôle |
|---|---|
| **Listes** | Ouvre vos collections. |
| **Builds** | Ouvre vos builds d'échos. |
| **Callboard** | Invoque le Callboard et l'ouvre. Grisé lorsque votre personnage est en intérieur. |
| **Démarrer / Arrêter** | Lance ou arrête la recherche. |
| **Partager** | Partage votre dernière quête acceptée avec votre groupe ou votre raid. Grisé tant que vous n'avez accepté aucune quête. |
| **Quêtes** | Déploie la fenêtre des quêtes connues sous le panneau. Le bouton devient alors **Masquer**. |
| Engrenage, **?**, **×** (en haut à droite) | Réglages, aide intégrée, fermeture. |
| **Mise à jour disponible** | N'apparaît que lorsqu'une version plus récente a été repérée. Ouvre la page de téléchargement. |
| **Voyage : …** | Apparaît sous le panneau lorsqu'un checkpoint correspond à votre quête. Voir [Les extras](#-les-extras). |

Faites glisser le panneau pour le déplacer, ou faites glisser l'un de ses boutons en
maintenant Maj. Le bouton de la minicarte affiche ou masque le panneau (clic gauche), ouvre
les réglages (clic droit) et peut être déplacé autour de la minicarte. L'aide s'ouvre avec **?**,
dans la fenêtre d'EbonAPI.

## 📂 Quêtes et collections

### Quêtes connues

**Quêtes** ouvre la liste de toutes les quêtes qu'AutoCallboard a vues sur un tableau. Elle
est vide à l'installation et s'enrichit à mesure que les tableaux vous montrent des quêtes.

- Cochez une quête pour la chercher. Survolez-la pour voir son type, son objectif, ses
  récompenses (XP et Soul Ash par difficulté) et le nombre de fois où elle est sortie.
- **Rechercher** filtre par nom, objectif, type ou récompense. Les cases de type (Monde
  ouvert, Donjon, Raid, Métier, Autre) affinent encore la liste.
- **Tout afficher** garde toutes les quêtes connues dans la liste même lorsqu'une collection est
  chargée. Sans cela, la liste n'affiche que les quêtes de la collection chargée.
- Faites un **clic droit** sur une quête pour la ranger dans une collection, ou pour créer une
  nouvelle collection à partir d'elle.
- **Exporter** affiche vos quêtes connues sous forme de texte à copier. Collez ce texte dans
  **Importer** sur une autre installation pour les y ajouter.
- Pour remplir la liste rapidement, cliquez sur **Démarrer** sans rien cocher : AutoCallboard
  vous demande confirmation, puis relance uniquement pour apprendre des quêtes, sans jamais
  s'arrêter sur l'une d'elles.

### Collections

Une collection est un ensemble nommé de quêtes cochées. **Listes** les ouvre.

- Cliquez sur une collection pour la charger : ses quêtes sont cochées. Cliquez à nouveau
  dessus pour la décharger, ce qui décoche tout. **(Aucune sélection)** décoche aussi tout.
  On ne peut pas changer de collection pendant que la recherche tourne.
- Le **+** en haut à droite de la liste (ou d'un groupe ouvert) y enregistre vos quêtes
  cochées comme nouvelle collection. Le **+** en haut à gauche de la fenêtre crée un groupe.
- Faites un clic droit sur une collection pour la déplacer, fixer sa difficulté, la mettre à
  jour avec vos quêtes cochées, la renommer ou la supprimer. Faites-la glisser pour la
  réordonner ou la déposer dans un autre groupe.
- Les groupes rangent vos collections. Un groupe replié apparaît sous forme de bandeau :
  cliquez dessus pour l'ouvrir, et utilisez **>>** pour le replier. Jusqu'à 10 groupes, et
  jusqu'à 50 collections dans chaque groupe et dans la liste de base.
- Une collection peut porter une difficulté (Normal, HC1 à HC5). Elle est appliquée au
  chargement de la collection, à condition d'être dans une zone de repos (une auberge ou une
  capitale) et hors combat.

Les collections sont communes à tous vos personnages. Les quêtes cochées et la collection
chargée sont propres à chaque personnage.

### Instance actuelle

**Instance actuelle auto** : dans un donjon ou un raid, **Démarrer** ignore les quêtes
cochées et relance uniquement pour la quête de cette instance. Tous les donjons et raids n'ont
pas de quête Callboard ; si aucune ne correspond, AutoCallboard continue de relancer jusqu'à
atteindre sa limite ou jusqu'à ce que vous l'arrêtiez.

## ⚡ Les relances

Chaque relance coûte de l'or. Lorsque vous cliquez sur **Démarrer**, AutoCallboard :

1. relance le tableau, en attendant toujours la réponse du serveur avant la relance suivante ;
2. compare les trois quêtes proposées à celles que vous avez cochées (ou à la quête de
   l'instance) ;
3. en cas de correspondance, cesse de relancer, sélectionne la quête et ferme le tableau ;
4. reste en pause pendant que la quête est en cours, puis reprend lorsque vous la rendez ou
   l'abandonnez.

Un seul objectif du tableau peut être actif à la fois. Si une quête voulue apparaît alors qu'un
autre objectif est déjà actif, AutoCallboard ne le remplace pas : il se met en pause jusqu'à ce
que vous rendiez ou abandonniez l'objectif en cours.

Une quête abandonnée est écartée de la recherche jusqu'à ce que vous acceptiez une autre de vos
quêtes sélectionnées, ou que vous entriez dans un donjon ou un raid ou en sortiez. La recherche
s'arrête d'elle-même après 50 relances sans correspondance, ou lorsque vous n'avez plus assez
d'or pour relancer.

| Option | Rôle |
|---|---|
| **Accepter automatiquement les quêtes sélectionnées** *(activée)* | Accepte la quête du Callboard dès qu'elle correspond à l'une de celles que vous avez cochées. |
| **Instance actuelle auto** *(désactivée)* | Voir [Instance actuelle](#instance-actuelle). |
| **Relancer sans le tableau** *(désactivée)* | Continue de relancer et de choisir les quêtes sans tableau ouvert, partout dans le monde. Chaque relance coûte toujours de l'or, et le serveur peut la refuser à tout moment. |
| **Vitesse de roll** | La cadence des relances. Quatre préréglages : Turbo, Rapide, Normale, Sûre. |

Ces options se trouvent dans les réglages, onglet **Général**.

## 📍 Les routes

Une route est un trajet que vous avez enregistré : les PNJ auxquels vous avez parlé, les choix
faits dans leurs dialogues, les quêtes prises ou rendues, les checkpoints utilisés et l'endroit
de chaque étape. Lorsque vous la rejouez, AutoCallboard refait les interactions enregistrées
au moment où vous les atteignez, sauf l'acceptation d'une quête proposée par un joueur, et une
flèche indique où aller ensuite. Déplacer votre personnage reste à votre charge.

Le bouton **Routes** ouvre la fenêtre des routes. Il n'est pas dans la barre principale par
défaut : ajoutez-le dans les réglages, onglet **Barre principale**. La fenêtre comporte **●**
(enregistrer), **▶** (lire), **⏭** (passer), **↻** (relance automatique), les boutons
**Mes routes** et **Bibliothèque**, et **_**, qui la réduit à une seule ligne restant au-dessus
de tout, carte du monde comprise.

### Enregistrer

Cliquez sur **●**, puis jouez normalement : parlez aux PNJ, prenez et rendez des quêtes,
utilisez des checkpoints. Lorsque votre trajet est terminé, cliquez sur **■** : nommez la route
et choisissez l'une des huit catégories (Montée en niveau, Journalières, Réputations, Métiers,
Chaînes et accès, Classe, Événements mondiaux, Hauts faits et collection). Une route contient
jusqu'à 400 étapes, et vous pouvez en garder jusqu'à 50 par catégorie.

### Lire

Cliquez sur une route dans **Mes routes** pour la charger (cliquez à nouveau pour la
décharger), puis sur **▶** pour la démarrer depuis le début, ou cliquez sur n'importe quelle
ligne de la route pour partir de là. **⏭** ignore le bloc en cours. Une route de la
faction opposée refuse de démarrer. Une quête proposée par un joueur (partage, escorte) n'est
jamais acceptée à votre place : acceptez-la vous-même, la route vous attend tant que l'offre est
affichée, puis continue. La lecture s'arrête d'elle-même à la fin de la route, si un checkpoint
n'est pas débloqué pour votre personnage, ou si une étape ne peut pas être jouée jusqu'au bout.
Allumez **↻** pour que la route reparte de son premier bloc au lieu de s'arrêter à la fin, et
cliquez à nouveau pour l'éteindre. Une route faite uniquement de checkpoints ne repart pas.

Faites un clic droit sur une route pour la charger ou la décharger, changer sa catégorie, la
partager, lui ajouter votre enregistrement actuel (**Ajouter à la suite**) ou la remplacer
(**Écraser**), fixer sa **Difficulté de départ**, la renommer ou la supprimer. Faites un clic
droit sur une ligne pour la supprimer, ou pour y pointer la flèche.

### La flèche

La flèche indique le prochain endroit enregistré et affiche la distance et l'action attendue.
Lorsqu'elle ne peut pas viser (l'endroit est sur un autre continent, vous êtes dans une
instance, ou votre position est illisible), elle l'indique au lieu de pointer, et elle vous
signale votre arrivée. Déplacez-la en la faisant glisser. Choisissez son apparence avec **Voir
les styles** (dix styles), ainsi que sa taille et celle de son texte, dans les réglages,
onglet **Apparence**.

### Partager

Faites un clic droit sur une route et choisissez **Partager** : elle apparaît dans la
**Bibliothèque** des autres joueurs d'AutoCallboard, classée par catégorie. Ouvrez une catégorie,
puis cliquez sur une route pour la récupérer. Une route grisée n'est pas téléchargeable pour
l'instant, car aucun joueur qui la possède n'est connecté. Une route récupérée est partagée à
son tour ; choisissez **Ne plus partager** si vous préférez l'éviter. Si vous modifiez une
route partagée, sa nouvelle version est republiée, tandis que les joueurs qui l'avaient déjà
récupérée gardent leur propre copie. Les routes de l'autre faction peuvent être gardées,
modifiées et partagées, mais pas jouées. Le partage se fait en arrière-plan.

## 🔄 Les builds

Le bouton **Builds** ouvre les builds d'échos de votre personnage, tels que le serveur les
enregistre. Cliquez sur un build pour l'activer. On ne peut pas changer de build en combat.

**Accès rapide échos** (réglages, onglet **Général**) ajoute une petite barre de trois
emplacements. Faites glisser un build depuis la fenêtre Builds vers un emplacement. Faites un
clic droit sur un emplacement pour le vider, ou faites glisser un emplacement sur un autre
pour les échanger. **Sens de la barre** bascule la barre entre horizontal et vertical. Le
point dans le coin supérieur gauche de la barre la verrouille : une barre verrouillée ne peut
plus être déplacée ni modifiée, mais ses emplacements restent utilisables. Chaque emplacement
peut avoir son propre raccourci clavier, dans le menu des raccourcis de World of Warcraft,
sous AutoCallboard.

## 🧰 Les extras

- **Bouton de voyage** *(activé)* — lorsque votre quête appartient à une zone, un bouton
  **Voyage** apparaît sous le panneau et vous téléporte vers un checkpoint débloqué dans cette
  zone ou près d'elle. **Voyage automatique** *(désactivé)* le fait dès qu'une nouvelle quête
  est sélectionnée, sans rien demander. Il ne se déclenche jamais en combat ou lorsque vous
  êtes mort, et n'utilise que des checkpoints que vous avez débloqués.
- **Assistance Eternals** *(activée)* — lorsque vous acceptez une quête d'Eternal (Eau, Feu,
  Terre, Air ou Ombre) avec 10 cristaux correspondants dans vos sacs, un petit bouton apparaît
  et les convertit en deux étapes. Cliquez dessus ou appuyez sur sa touche (Ctrl+W par
  défaut). Faites un clic droit dessus pour le fermer.
- **Compteurs d'or** — AutoCallboard compte ce que coûtent vos relances : total, session,
  recherche en cours et dernière quête obtenue. Choisissez les compteurs et leur emplacement
  dans les réglages, onglet **Or**. Cette fonctionnalité est encore en cours de développement
  et certains compteurs peuvent être inexacts.
- **Afficher la vitesse du personnage** *(désactivé)* — affiche votre vitesse réelle sous les
  boutons, en pourcentage de la vitesse de course normale. Elle tient compte de votre monture
  et de tous les effets actifs, et indique 0 % lorsque vous êtes immobile.
- **Avis de mise à jour** — lorsqu'un joueur disposant d'une version plus récente est repéré,
  le bouton **Mise à jour disponible** s'affiche sur le panneau. Rien n'est écrit dans votre
  discussion.

## 🔧 Réglages

Cliquez sur l'engrenage du panneau, ou faites un clic droit sur le bouton de la minicarte :
les réglages s'ouvrent dans la fenêtre d'EbonAPI, onglet **AutoCallboard**.

| Onglet | Contenu |
|---|---|
| **Général** | Les options ci-dessus : Instance actuelle auto, Accès rapide échos, Sens de la barre, Bouton minicarte, Bouton de voyage, Voyage automatique, Relancer sans le tableau, Accepter automatiquement les quêtes sélectionnées, Assistance Eternals, Afficher la vitesse du personnage et Vitesse de roll. |
| **Apparence** | Taille, texte et style de la flèche. |
| **Barre principale** | Choisissez les boutons affichés dans la barre principale et leur ordre. Par défaut : Listes, Builds, Callboard, Démarrer, Partager et Quêtes. Vous pouvez aussi ajouter Routes, Exporter, Importer, Instance actuelle auto, Assistance Eternals, Aide et Réglages. Chaque personnage a sa propre barre. |
| **Or** | Les compteurs d'or à afficher, et s'il faut les afficher dans la barre principale. |
| **Aide** | L'aide intégrée, en cinq parties : À propos, Callboard, Routes, Builds et Réglages. Le bouton **?** l'ouvre directement. |

Chaque changement s'applique tout de suite. Les onglets **Apparence**, **Barre principale** et
**Or** ont un bouton **Par défaut** qui les remet à leurs valeurs d'origine. Le skin, les
couleurs, l'échelle, l'opacité et le verrouillage des positions se règlent dans l'onglet
**Apparence** d'EbonAPI : les fenêtres d'AutoCallboard les suivent, comme celles de tous les
addons qui utilisent EbonAPI. Un nouveau skin s'applique au rechargement de l'interface.

## 💡 À savoir

- **Les quêtes connues, les collections, les routes et l'apparence sont communes à tous vos
  personnages.** Les quêtes cochées, la collection chargée, la barre principale, la barre
  d'accès rapide, la route chargée et sa relance automatique sont propres à chaque personnage.
- **Le bouton Callboard est grisé en intérieur**, car le tableau ne peut pas y être invoqué.
- **Si vous utilisiez une ancienne version**, les listes enregistrées par personnage passent
  sur votre compte à la connexion de chaque personnage, et les listes de l'ancien addon
  AutoCallboardPresets sont reprises elles aussi. Si les dix groupes sont déjà utilisés,
  AutoCallboard vous demande ce qu'il faut garder.

## 🌍 Langues

Le français, l'anglais, l'allemand et l'espagnol sont disponibles au complet. AutoCallboard
suit la langue de votre jeu, et vous pouvez la changer dans l'onglet **Général** d'EbonAPI :
tout change instantanément, y compris les fenêtres déjà ouvertes. La langue est commune aux
autres addons Ebonhold qui utilisent [EbonAPI](https://github.com/Siphelis/EbonAPI).

## 📜 Licence et crédits

Auteur original : **Disarray** — fork maintenu par **Siphelis**.

## Licence

Ce projet est distribué sous une licence personnalisée reposant sur MIT et PolyForm Noncommercial pour les modifications. Consultez le fichier [LICENSE](https://github.com/Siphelis/autocallboard/blob/main/LICENSE) pour connaître les conditions complètes.

---
