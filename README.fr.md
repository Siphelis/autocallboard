# 🎯 AutoCallboard

**Le Callboard ne vous fera plus jamais perdre votre temps.**

AutoCallboard relance le _Callboard_ pour vous, reconnaît la quête que
vous cherchez dès qu'elle apparaît, la sélectionne, et s'arrête pile au
bon moment.
À cela s'ajoutent une mémoire de toutes les quêtes déjà vues, des listes
de sélection sauvegardées et partagées entre tous vos personnages, un
mode "quête de l'instance en cours", le partage automatique en groupe,
et une intégration complète avec le système de builds du serveur. Le
tout dans une interface sobre et élégante, disponible en français,
anglais, allemand et espagnol.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table des matières

- [Pourquoi cette extension](#-pourquoi-cette-extension)
- [Fonctionnalités](#-fonctionnalités)
- [Installation](#-installation)
- [Démarrage rapide](#️-démarrage-rapide)
- [Anatomie du code](#-anatomie-du-code--comment-ça-fonctionne)
- [Commandes slash](#️-commandes-slash)
- [Langues](#-langues)
- [Compagnons optionnels](#-compagnons-optionnels)
- [Captures d'écran](#-captures-décran)
- [Contribuer](#-contribuer)
- [Licence et crédits](#-licence-et-crédits)

---

## 🔥 Pourquoi cette extension

Le Callboard propose trois quêtes aléatoires et vous oblige à relancer
à la main jusqu'à obtenir celle que vous voulez. C'est répétitif, ça
prend du temps. AutoCallboard fait ce travail à votre place.

## ✨ Fonctionnalités

- **Relance automatique intelligente** — cochez les quêtes voulues,
  cliquez sur démarrer, et l'extension sélectionne automatiquement la
  ou les quêtes choisies.
- **Mémoire persistante des quêtes** — chaque quête vue sur le tableau
  est enregistrée automatiquement (titre, type, récompenses) et triée
  par catégorie : donjon, raid, monde ouvert, métier.
- **Listes de sélection sauvegardées** — sauvegardez plusieurs
  sélections nommées, organisées en groupes façon tableau de bord,
  partagées entre tous vos personnages.
- **Mode "instance en cours"** — dans un donjon ou raid reconnu,
  relance uniquement pour la quête propre à cette instance.
- **Difficulté synchronisée (Hardmode)** — chaque liste peut cibler un
  palier de difficulté ; l'extension l'applique automatiquement dès que
  possible.
- **Partage de quête de groupe** — repartage automatiquement votre
  dernière quête acceptée, et peut auto-accepter les quêtes partagées
  par un autre AutoCallboard de votre groupe.
- **Suivi des dépenses d'or** — chaque relance coûte de l'or ; le
  panneau affiche la dépense totale, la dépense de la session en cours,
  et le coût de la dernière quête obtenue.
- **Intégration au système de builds du serveur** — consultez, changez
  et épinglez vos builds de talents depuis une petite barre "Echo" à 3
  emplacements, déplaçable et assignable à des raccourcis clavier.
- **Export / import texte** — copiez votre liste de quêtes apprises
  d'une installation à l'autre par simple copier-coller.
- **Changement de langue à chaud** — changez de langue depuis le
  panneau, et tous les textes visibles se mettent à jour instantanément,
  sans `/reload`.

## 📦 Installation

1. [**AutoCallboard**](https://github.com/Siphelis/autocallboard/releases/latest) — téléchargez la dernière version.
2. Décompressez le dossier `AutoCallboard` dans
   `Interface/AddOns/`.
3. Vérifiez dans l'écran de sélection des extensions que
   **AutoCallboard** est bien coché.
4. C'est tout — aucune dépendance n'est nécessaire pour son
   fonctionnement.

## 🕹️ Démarrage rapide

```
/acb           → affiche la version installée
/acb quests    → ouvre la fenêtre des quêtes connues
/acb roll      → démarre la relance
/acb stop      → arrête la relance
/acb help      → ouvre l'aide intégrée au jeu
```

1. Ouvrez la fenêtre des quêtes (`/acb quests`) et cochez celles que
   vous voulez chasser.
2. Approchez-vous du Callboard (ou laissez l'extension l'invoquer) et
   cliquez sur **Démarrer**.
3. L'extension relance pour vous, s'arrête dès qu'une quête cochée
   apparaît, et la sélectionne.
4. Terminez la quête, relancez à nouveau dès que vous voulez la
   suivante.

Toute l'aide contextuelle (raccourcis, astuces, coûts en or) est
disponible en jeu via `/acb help`.

## 🧠 Anatomie du code — comment ça fonctionne

AutoCallboard est découpé en modules à sens unique : chaque dossier a
un rôle clair, et tout communique via l'espace de noms partagé
`AutoCallboardRuntime` (abrégé `RT` dans le code).

### `Core/` — logique pure, sans état de jeu

| Fichier         | Rôle exact                                                                                                                                                                                                                                                                                                                                                                                                            |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Core.lua`      | Le cerveau sans effet de bord : valeurs par défaut des données sauvegardées, fusion/adoption d'un état sauvegardé (rétrocompatibilité), l'analyseur de la commande `/acb`, la classification heuristique des quêtes (mots-clés donjon/raid/métier/monde ouvert), la logique des listes et groupes sauvegardés (création, renommage, déplacement, limites), et le format d'export/import texte du catalogue de quêtes. |
| `State.lua`     | Le pont entre `Core` et la sauvegarde `AutoCallboardDB` : applique un nouvel état, incrémente un compteur de révision pour que l'interface ne se rafraîchisse qu'en cas de besoin, et suit l'or dépensé en relances.                                                                                                                                                                                                  |
| `Migration.lua` | La migration unique des anciennes sauvegardes _par personnage_ vers le profil de compte partagé — avec des boîtes de dialogue chaque fois qu'un import doit être fusionné, remplacé, conservé ou ignoré.                                                                                                                                                                                                              |
| `Util.lua`      | La boîte à outils partagée : affichage dans le chat, résolution des chemins de frames Blizzard (`"Frame.child.other"`), clics simulés qui coupent temporairement le son du jeu pour ne pas polluer l'ambiance, formatage de l'argent/du temps, et le petit système de journalisation de débogage.                                                                                                                     |

### `Automation/` — ce qui agit sur le jeu

| Fichier          | Rôle exact                                                                                                                                                                                                                                                                                 |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Callboard.lua`  | Détecte et invoque le Callboard : cible le PNJ, lance le sort d'invocation, lit les temps de recharge, reconnaît une session de tableau ouverte (interface, PNJ, ou fenêtre d'objectifs), la machine à états "tableau actif / en recharge".                                                |
| `Roll.lua`       | Le moteur de relance lui-même : une boucle d'évaluation sur les objectifs affichés à chaque tick, comparaison avec les quêtes désirées, gestion des pauses (aucun tableau ouvert, aucune quête voulue, une quête déjà sélectionnée et en cours), suivi de l'or dépensé pendant la session. |
| `Instance.lua`   | Calcule la quête cible automatique quand le mode "Instance en cours" est actif : détecte dans quel donjon/raid vous êtes et le fait correspondre à sa quête d'instance connue.                                                                                                             |
| `Difficulty.lua` | Lit et applique le palier de difficulté (Hardmode) via le service du serveur, en le synchronisant avec la difficulté demandée par la liste active.                                                                                                                                         |

### `Features/` — des extras qui ne dépendent de rien d'autre

| Fichier        | Rôle exact                                                                                                                                                                                                                                                             |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Share.lua`    | Repartage automatiquement votre dernière quête acceptée au groupe/raid (un protocole dédié de message d'extension), et auto-accepte une quête partagée par un autre AutoCallboard — jamais une partagée par un joueur normal, qui reste à accepter manuellement.       |
| `Builds.lua`   | Le pont vers le système de builds de talents du serveur (un protocole d'opcodes "echo"), une fenêtre de sélection de build, et la **barre Echo** : 3 emplacements en glisser-déposer, ancrables n'importe où, verrouillables, et assignables à des raccourcis clavier. |
| `Eternals.lua` | Un mini-utilitaire indépendant : convertit Cristal élémentaire → Éternel → objet final via un bouton sécurisé assignable à une touche, en détectant automatiquement chaque étape de la séquence.                                                                       |

### `Language/` et `Locales/` — le système multilingue

| Fichier                                                | Rôle exact                                                                                                                  |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| `Language/Locale.lua`                                  | Le registre des langues disponibles et le résolveur qui choisit la langue par défaut du client au premier lancement.        |
| `Language/Switcher.lua`                                | Le menu de sélection de langue et le rafraîchissement à chaud de **tous** les textes à l'écran, sans recharger l'interface. |
| `Locales/enUS.lua`, `frFR.lua`, `deDE.lua`, `esES.lua` | Les quatre traductions complètes de l'extension.                                                                            |

### `UI/` — tout ce que vous voyez

| Fichier            | Rôle exact                                                                                                                                                                          |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Skin.lua`         | Le système de thème (violet sur noir), et les fabriques réutilisables pour les fenêtres, boutons, lignes et cases à cocher qui donnent à toute l'extension son apparence cohérente. |
| `ControlFrame.lua` | Le petit panneau de contrôle (bouton Callboard, Démarrer/Arrêter, statut d'invocation) et le bouton de la minimap.                                                                  |
| `QuestWindow.lua`  | La fenêtre des quêtes connues : recherche, filtres par type, cases à cocher pour les quêtes désirées, et sélection directe d'une quête actuellement sur le tableau.                 |
| `Lists.lua`        | Le gestionnaire de listes et groupes sauvegardés, une disposition à deux volets façon tableau de bord avec glisser-déposer entre groupes et réordonnancement.                       |
| `QuestData.lua`    | La fenêtre d'export/import texte du catalogue de quêtes apprises.                                                                                                                   |
| `Help.lua`         | L'aide intégrée, disponible en jeu à tout moment.                                                                                                                                   |

### À la racine

| Fichier             | Rôle exact                                                                                                                                                                                                  |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AutoCallboard.lua` | Le point d'entrée : crée la boucle `OnUpdate` adaptative (elle ralentit automatiquement dès qu'il ne se passe rien), route chaque événement WoW écouté par l'extension, et interprète les commandes `/acb`. |
| `AutoCallboard.toc` | Le manifeste WoW : métadonnées, variables sauvegardées (`AutoCallboardDB`, `AutoCallboardQuestDB`, `AutoCallboardEternalsDB`), et ordre de chargement des fichiers.                                         |
| `Bindings.xml`      | Les 3 raccourcis assignables pour déclencher chaque emplacement de la barre Echo.                                                                                                                           |

## 🗣️ Commandes slash

Alias : `/acb` et `/autocallboard`.

| Commande                                                         | Effet                                                                                                                 |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `/acb` (ou `version` / `v`)                                      | Affiche la version installée de l'extension.                                                                          |
| `/acb run` (ou `call`)                                           | Ouvre le panneau et reprend le flux du tableau. L'invocation elle-même passe obligatoirement par le bouton Callboard. |
| `/acb help`                                                      | Ouvre l'aide intégrée.                                                                                                |
| `/acb show` / `hide`                                             | Affiche ou masque le panneau de contrôle.                                                                             |
| `/acb roll` (ou `autoroll`)                                      | Démarre la relance.                                                                                                   |
| `/acb stop`                                                      | Arrête la relance.                                                                                                    |
| `/acb quests` (ou `quest`)                                       | Ouvre la fenêtre des quêtes connues.                                                                                  |
| `/acb reroll [nom_frame]`                                        | Force une relance ponctuelle, ou change le nom de la frame de relance.                                                |
| `/acb objective <1-3>` (ou `obj` / `pick` / juste `1`, `2`, `3`) | Sélectionne directement l'un des 3 emplacements affichés.                                                             |
| `/acb reset`                                                     | Réinitialise les réglages en conservant les quêtes apprises.                                                          |
| `/acb name <texte>`                                              | Change le nom du PNJ ciblé utilisé pour l'invocation.                                                                 |
| `/acb id <spellID>`                                              | Change le sort d'invocation utilisé.                                                                                  |
| `/acb maxrolls <n>`                                              | Change le nombre maximum de relances avant abandon.                                                                   |
| `/acb accept on/off`                                             | Active/désactive l'acceptation automatique de la quête trouvée.                                                       |
| `/acb autoacceptquests on/off`                                   | Active/désactive l'auto-acceptation des quêtes partagées par un autre ACB.                                            |
| `/acb autoinstance on/off`                                       | Active/désactive le mode "quête de l'instance en cours".                                                              |
| `/acb minimap on/off`                                            | Affiche ou masque le bouton de la minimap.                                                                            |
| `/acb export` / `import`                                         | Ouvre la fenêtre d'export ou d'import du catalogue de quêtes.                                                         |

Le bouton **Callboard** invoque le Callboard ; le curseur de vitesse de
relance propose 4 préréglages (Turbo, Rapide, Normal, Sûr) directement
depuis le panneau.

## 🌍 Langues

Français, anglais, allemand et espagnol sont disponibles au complet. Le
sélecteur de langue dans le panneau change tout instantanément, y
compris les fenêtres déjà ouvertes.

## 📜 Licence et crédits

Auteur original : **Disarray** — fork maintenu par **Siphelis**.

## Licence

Ce projet est distribué sous une licence personnalisée (base MIT +
PolyForm Noncommercial pour les modifications) — voir [LICENSE](https://github.com/Siphelis/autocallboard/blob/main/LICENSE) pour les
détails.

---
