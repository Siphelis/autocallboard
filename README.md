# 🎯 AutoCallboard

**The Callboard will never waste your time again.**

AutoCallboard rerolls the _Callboard_ for you, recognizes the quest you're looking for the
moment it appears, selects it, and picks the search back up once the quest is done. It also
remembers every quest it has seen, saves your selections as collections shared by all your
characters, records and replays your routes with a guiding arrow, lets players share those
routes, and gives you a quick bar for your echo builds. All wrapped in a sleek, understated
interface, available in English, French, German, or Spanish.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table of Contents

- [Why this addon](#-why-this-addon)
- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Quick start](#-quick-start)
- [The main panel](#-the-main-panel)
- [Quests and collections](#-quests-and-collections)
- [Rolling](#-rolling)
- [Routes](#-routes)
- [Echo builds](#-echo-builds)
- [Extras](#-extras)
- [Settings](#-settings)
- [Good to know](#-good-to-know)
- [Languages](#-languages)
- [License & credits](#-license--credits)

---

## 🔥 Why this addon

The Callboard offers three random quests and makes you reroll by hand until you land the one
you want. It's repetitive, and it takes time. With AutoCallboard you tick the quests you want
and it does the rerolling for you.

## ✨ Features

- **Smart auto-reroll** — tick the quests you want and click Start: the addon rerolls until
  one shows up, selects it, accepts it if you like, and resumes once the quest is done.
- **Known quests** — every quest seen on the board is remembered (title, type, rewards) so
  you can search it, filter it and tick it.
- **Collections** — save named sets of quests, sort them into groups, and load one in a
  single click. They are shared by all your characters, and each can carry a difficulty.
- **"Current instance" mode** — inside a dungeon or raid, roll only for that instance's quest.
- **Routes** — record your runs (NPCs, dialogues, quests, checkpoints), replay them with a
  guiding arrow, once or on a loop, and share them with other players through a library.
- **Travel button** — jump to a checkpoint near the zone of your quest.
- **Group quest sharing** — the **Share** button shares the last quest you accepted with your
  party or raid.
- **Echo builds** — switch builds from a window, or from a movable 3-slot quick bar with
  key bindings.
- **Eternals assistant** — converts your crystals while you do the Eternals quests.
- **Gold counters** — see what your rerolls cost: total, session, current search, last quest.
- **Update notice** — a button tells you when a newer version is out.
- **Export / import** — copy your known quests from one install to another.
- **Your look** — arrow style and which buttons the main bar shows; the windows follow the
  skin, colors, scale and opacity chosen in [EbonAPI](https://github.com/Siphelis/EbonAPI).
- **Four languages** — English, French, German, Spanish, switched live without `/reload`.

## 📋 Requirements

| | |
|---|---|
| **Game** | World of Warcraft 3.3.5a on the **Ebonhold** server |
| **Integration** | ProjectEbonhold, included with the Ebonhold client |
| **Required addon** | [**EbonAPI**](https://github.com/Siphelis/EbonAPI) **2.1 or newer**, shared by the Ebonhold addons; AutoCallboard does not load without it |

## 📦 Installation

1. Download the latest version from the
   [Releases page](https://github.com/Siphelis/autocallboard/releases/latest).
2. Unzip the `AutoCallboard` folder into `Interface/AddOns/`. Install
   [**EbonAPI**](https://github.com/Siphelis/EbonAPI) the same way if it is
   not there yet.
3. Restart the game and check on the AddOns selection screen that **AutoCallboard** and
   [**EbonAPI**](https://github.com/Siphelis/EbonAPI) are both ticked.
4. The AutoCallboard panel appears on screen. A minimap button gives you quick access to it.

## 🚀 Quick start

1. Click **Quests**, then tick the quests you want to get.
2. Click **Callboard**: it summons a Callboard if you have the spell from the shop, then
   targets and opens it for you. Next to a fixed Objectives Board instead? Click the board
   once so AutoCallboard can read its content.
3. Click **Start**. AutoCallboard rerolls until one of your quests shows up, then stops
   rerolling and selects it. It accepts it too, unless you turned that option off.
4. Do the quest. Once you hand it in, the search resumes on its own as soon as a board is
   open, until you click **Stop**.

On a fresh install the list of known quests is still empty: see [Known quests](#known-quests)
to fill it.

The line under the buttons tells you what is going on: Callboard active or on cooldown,
rerolls made, search paused, quest selected.

## 🧭 The main panel

| Control | What it does |
|---|---|
| **Lists** | Opens your collections. |
| **Builds** | Opens your echo builds. |
| **Callboard** | Summons the Callboard and opens it. Greyed out while your character is indoors. |
| **Start / Stop** | Starts or stops the search. |
| **Share** | Shares your last accepted quest with your party or raid. Greyed out until you accept a quest. |
| **Quests** | Unfolds the known quests window under the panel. The button then reads **Hide**. |
| Gear, **?**, **×** (top right) | Settings, the in-game help, close. |
| **Update available** | Only appears when a newer version has been spotted. Opens the download page. |
| **Travel: …** | Appears under the panel when a checkpoint matches your quest. See [Extras](#-extras). |

Drag the panel to move it, or Shift-drag any of its buttons. The minimap button shows or
hides the panel (left-click), opens the settings (right-click) and can be dragged around the
minimap. The help opens with **?**, in the EbonAPI window.

## 📂 Quests and collections

### Known quests

**Quests** opens the list of every quest AutoCallboard has seen on a board. The list is empty
on a fresh install and grows as boards show you quests.

- Tick a quest to look for it. Hover it to see its type, objective, rewards (XP and Soul Ash
  per difficulty) and how many times it came up.
- **Search** filters by name, objective, type or reward. The type boxes (Open World, Dungeon,
  Raid, Profession, Other) narrow the list further.
- **Show all** keeps every known quest in the list even while a collection is loaded. Without
  it, the list only shows the quests of the loaded collection.
- **Right-click** a quest to file it into a collection, or to start a new collection with it.
- **Export** shows your known quests as text to copy. Paste that text into **Import** on
  another install to add them there.
- To fill the list quickly, click **Start** with nothing ticked: AutoCallboard asks you to
  confirm, then rerolls only to learn quests, without stopping on any.

### Collections

A collection is a named set of ticked quests. **Lists** opens them.

- Click a collection to load it: its quests get ticked. Click it again to unload it, which
  clears the ticks. **(No selection)** clears them too. Collections cannot be switched while
  the search is running.
- The **+** at the top right of the list (or of an open group) saves your current ticks there
  as a new collection. The **+** at the top left of the window creates a group.
- Right-click a collection to move it, set its difficulty, update it with your current
  ticks, rename it or delete it. Drag it to reorder it or drop it in another group.
- Groups sort your collections. A folded group shows as a band: click it to open it, and use
  **>>** to fold it again. Up to 10 groups, and up to 50 collections in each group and in the
  base list.
- A collection can carry a difficulty (Normal, HC1 to HC5). It is applied when you load the
  collection, as long as you are in a rest area (an inn or a capital) and out of combat.

Collections are shared by all your characters. The ticked quests and the loaded collection
belong to each character.

### Current instance

**Auto Current Instance**: inside a dungeon or raid, **Start** ignores the ticked quests and
rolls only for that instance's quest. Not every dungeon or raid has a Callboard quest; if
none matches, AutoCallboard keeps rerolling until it reaches its limit or you stop it.

## ⚡ Rolling

Every reroll costs gold. When you click **Start**, AutoCallboard:

1. rerolls the board, always waiting for the server's answer before the next reroll;
2. compares the three quests with the ones you ticked (or with the instance's quest);
3. on a match, stops rerolling, selects the quest and closes the board;
4. stays paused while the quest is in progress, then resumes when you hand it in or abandon it.

Only one board objective can be active at a time. If a wanted quest shows up while another
objective is already active, AutoCallboard does not replace it: it pauses until you hand in or
abandon the objective in progress.

An abandoned quest is left out of the search until you accept another one of your selected
quests, or until you enter or leave a dungeon or raid. The search stops by itself after 50
rerolls without a match, or when you can no longer afford a reroll.

| Option | What it does |
|---|---|
| **Automatically accept selected quests** *(on)* | Accepts the Callboard quest as soon as it matches one you ticked. |
| **Auto Current Instance** *(off)* | See [Current instance](#current-instance). |
| **Roll without the board** *(off)* | Keeps rerolling and picking quests with no board open, anywhere in the world. Each reroll still costs gold, and the server may refuse it at any time. |
| **Roll speed** | How quickly rerolls follow one another. Four presets: Turbo, Fast, Normal, Safe. |

You find these options in the settings, on the **General** tab.

## 📍 Routes

A route is a run you recorded: the NPCs you talked to, the dialogue choices you made, the
quests you took or handed in, the checkpoints you used, and where each step happened. When
you replay it, AutoCallboard repeats the recorded interactions as you reach them, except
accepting a quest offered by a player, and an arrow shows where to go next. Moving your
character is still up to you.

The **Routes** button opens the routes window. It is not on the main bar by default: add it
in the settings, on the **Main bar** tab. The window has **●** (record), **▶** (play),
**⏭** (skip), **↻** (auto restart), the **My routes** and **Library** buttons, and **_**,
which shrinks it to a single line that stays above everything, world map included.

### Recording

Click **●**, then play as usual: talk to NPCs, take and hand in quests, use checkpoints. When
your run is over, click **■**: name the route and choose one of the eight categories
(Leveling, Dailies, Reputations, Professions, Chains and access, Class, World events,
Achievements and collections). A route holds up to 400 steps, and you can keep up to 50 in
each category.

### Playing

Click a route in **My routes** to load it (click it again to unload it), then click **▶** to
start from the beginning, or click any line of the route to start from there. **⏭** skips the
block in progress. A route of the other faction refuses to start. A quest offered by a player
(a share, an escort) is never accepted for you: accept it yourself; the route waits while the
offer is on screen, then goes on. Playback stops by itself at the end of the route, if a
checkpoint is not unlocked for your character, or if a step cannot be played through. Turn
**↻** on to have the route start again from its first block instead of stopping at the end, and
click it again to turn it off. A route made only of checkpoints does not start again.

Right-click a route to load or unload it, change its category, share it, add your current
recording to it (**Append**) or replace it (**Overwrite**), set its **Starting difficulty**,
rename it or delete it. Right-click a line to delete it, or to point the arrow at it.

### The arrow

The arrow points to the next recorded spot and shows the distance and the expected action.
When it cannot aim (the spot is on another continent, you are inside an instance, or your
position cannot be read) it says so instead of pointing, and it tells you when you have
arrived. Move it by dragging. Choose its look with **Browse styles** (ten styles), and its
size and text size, in the settings on the **Appearance** tab.

### Sharing

Right-click a route and choose **Share**: it appears in the **Library** of the other
AutoCallboard players, sorted by category. Open a category, then click a route to get it. A
greyed route cannot be downloaded right now, because nobody who has it is online. A route you
get is shared in turn; choose **Stop sharing** if you would rather not. If you edit a shared
route, the new version is published again, while players who already took it keep their own
copy. Routes of the other faction can be kept, edited and shared, but not played. Sharing
happens in the background.

## 🔄 Echo builds

The **Builds** button opens the echo builds of your character, as stored by the server. Click
a build to activate it. Builds cannot be switched in combat.

**Echo quick bar** (settings, **General** tab) adds a small bar of three slots. Drag a build
from the Builds window onto a slot. Right-click a slot to clear it, or drag one slot onto
another to swap them. **Bar layout** switches the bar between horizontal and vertical. The dot
at the bar's top-left corner locks it: a locked bar cannot be moved or changed, but its slots
still work. Each slot can have its own key binding, in the World of Warcraft key bindings
menu, under AutoCallboard.

## 🧰 Extras

- **Quest travel button** *(on)* — when your quest belongs to a zone, a **Travel** button
  appears under the panel and teleports you to an unlocked checkpoint in or near that zone.
  **Travel automatically** *(off)* does it as soon as a new quest is selected, without asking.
  It never fires in combat or while dead, and only uses checkpoints you have unlocked.
- **Eternals assistance** *(on)* — when you accept an Eternal quest (Water, Fire, Earth, Air
  or Shadow) with 10 matching crystals in your bags, a small button appears and converts them
  in two steps. Click it or press its key (Ctrl+W by default). Right-click it to close it.
- **Gold counters** — AutoCallboard counts what your rerolls cost: total, session, current
  search and last quest obtained. Pick the counters and where they show in the settings, on
  the **Gold** tab. This feature is still in development and some counters may be off.
- **Show character speed** *(off)* — shows your actual speed under the buttons, as a
  percentage of normal running speed. It counts your mount and every active effect, and reads
  0% when you stand still.
- **Update notice** — when a player with a newer version is spotted, the
  **Update available** button shows up on the panel. Nothing is written in your chat.

## 🔧 Settings

Click the gear on the panel, or right-click the minimap button: the settings open in the
EbonAPI window, on the **AutoCallboard** tab.

| Tab | What you find |
|---|---|
| **General** | The options above: Auto Current Instance, Echo quick bar, Bar layout, Minimap Button, Quest travel button, Travel automatically, Roll without the board, Automatically accept selected quests, Eternals assistance, Show character speed and Roll speed. |
| **Appearance** | Arrow size, text size and style. |
| **Main bar** | Choose which buttons the main bar shows and in which order. By default: Lists, Builds, Callboard, Start, Share and Quests. You can also add Routes, Export, Import, Auto Current Instance, Eternals assistance, Help and Settings. Each character has its own bar. |
| **Gold** | Which gold counters to show, and whether to show them in the main bar. |
| **Help** | The in-game help, in five parts: About, Callboard, Routes, Builds and Settings. The **?** button opens it directly. |

Every change applies at once. The **Appearance**, **Main bar** and **Gold** tabs have a
**Defaults** button that puts them back to their original values. Skin, colors, scale, opacity
and position locking are set on the **Appearance** tab of EbonAPI: AutoCallboard's windows
follow them, like those of every addon that uses EbonAPI. A new skin applies when the interface
reloads.

## 💡 Good to know

- **Known quests, collections, routes and the look are shared by all your characters.** The
  ticked quests, the loaded collection, the main bar, the quick bar, the loaded route and its
  auto restart belong to each character.
- **The Callboard button is greyed out indoors**, because the board cannot be summoned there.
- **If you used an older version**, the lists saved per character move to your account when
  each character logs in, and lists from the old AutoCallboardPresets addon are picked up
  too. If all ten groups are already in use, AutoCallboard asks what to keep.

## 🌍 Languages

English, French, German, and Spanish ship complete. AutoCallboard follows the language of
your game, and you can change it on the **General** tab of EbonAPI: everything
switches instantly, including windows that are already open. The language is shared with the
other Ebonhold addons that use [EbonAPI](https://github.com/Siphelis/EbonAPI).

## 📜 License & credits

Original author: **Disarray** — fork maintained by **Siphelis**.

## License

This project is licensed under a custom license (MIT base + PolyForm Noncommercial for modifications) — see [LICENSE](https://github.com/Siphelis/autocallboard/blob/main/LICENSE) for details.

---
