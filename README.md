# 🎯 AutoCallboard

**The Callboard will never waste your time again.**

AutoCallboard rerolls the _Callboard_ for you, recognizes the quest you're
looking for the moment it appears, selects it, and stops right on cue.
Add to that a memory of every quest you've ever seen, saved selection lists shared across your characters, a "current dungeon quest" mode, automatic party sharing, and full integration with the server's build system. All wrapped in a sleek, understated interface, available in
English, French, German, or Spanish.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table of Contents

- [Why this addon](#-why-this-addon)
- [Features](#-features)
- [Installation](#-installation)
- [Quick start](#️-quick-start)
- [Code anatomy](#-code-anatomy--how-it-works)
- [Slash commands](#️-slash-commands)
- [Languages](#-languages)
- [Optional companions](#-optional-companions)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)
- [License & credits](#-license--credits)

---

## 🔥 Why this addon

The Callboard offers three random quests and makes you reroll by hand
until you land the one you want. It's repetitive, it takes time.
AutoCallboard does that work for you.

## ✨ Features

- **Smart auto-reroll** — tick the quests you want, hit start, and the
  addon automatically selects the chosen quest(s).
- **Persistent quest memory** — every quest seen on the board gets
  recorded automatically (title, type, rewards) and sorted by category:
  dungeon, raid, open world, profession.
- **Saved selection lists** — save multiple named selections, organized
  into dashboard-style groups, shared across all your characters.
- **"Current instance" mode** — inside a recognized dungeon or raid, only
  reroll for that instance's own quest.
- **Synced difficulty (Hardmode)** — each list can target a difficulty
  tier; the addon applies it automatically whenever it can.
- **Group quest sharing** — automatically re-shares your last accepted
  quest, and can auto-accept quests shared by another AutoCallboard in
  your group.
- **Gold spend tracking** — every reroll costs gold; the panel shows
  total spend, current session spend, and the cost of the last quest
  obtained.
- **Server build integration** — check, switch, and pin your talent
  builds from a small 3-slot "Echo" bar, movable and bindable to
  keyboard shortcuts.
- **Text export / import** — copy your learned quest list from one
  install to another with a simple copy-paste.
- **Live multilingual switching** — change language from the panel, and
  every visible text updates instantly, no /reload needed.

## 📦 Installation

1. [**AutoCallboard**](https://github.com/Siphelis/autocallboard/releases/latest) — download the latest version.
2. Unzip the `AutoCallboard` folder into
   `Interface/AddOns/`.
3. Check the AddOns selection screen to make sure **AutoCallboard** is
   ticked.
4. That's it — no dependency is required for it to work.

## 🕹️ Quick start

```
/acb           → shows the installed version
/acb quests    → opens the known quests window
/acb roll      → starts rerolling
/acb stop      → stops rerolling
/acb help      → opens the built-in in-game help
```

1. Open the quest window (`/acb quests`) and tick the ones you want to
   hunt.
2. Approach the Callboard (or let the addon summon it) and click
   **Start**.
3. The addon rerolls for you, stops the moment a ticked quest shows up,
   and selects it.
4. Finish the quest, reroll again whenever you want the next one.

All contextual help (shortcuts, tips, gold costs) is available in-game
via `/acb help`.

## 🧠 Code anatomy — how it works

AutoCallboard is split into one-way modules: each folder has one clear
job, and everything communicates through the shared namespace
`AutoCallboardRuntime` (abbreviated `RT` in the code).

### `Core/` — pure logic, no game state

| File | Exact role |
| --- | --- |
| `Core.lua` | The side-effect-free brain: saved-data defaults, merging/adopting a saved state (backward compatibility), the `/acb` command parser, heuristic quest classification (dungeon/raid/profession/open-world keywords), saved-list and group logic (create, rename, move, limits), and the text export/import format for the quest catalog. |
| `State.lua` | The bridge between `Core` and the `AutoCallboardDB` save: applies a new state, bumps a revision counter so the UI only refreshes when needed, and tracks gold spent on rerolls. |
| `Migration.lua` | The one-time migration of old *per-character* saves into the shared account profile — with dialogs whenever an import needs to be merged, replaced, kept, or discarded. |
| `Util.lua` | The shared toolbox: chat printing, resolving Blizzard frame paths (`"Frame.child.other"`), simulated clicks that temporarily mute the game's sound so they don't pollute the ambiance, money/time formatting, and the small debug-log system. |

### `Automation/` — what acts on the game

| File | Exact role |
| --- | --- |
| `Callboard.lua` | Detects and summons the Callboard: targets the NPC, casts the summon spell, reads cooldowns, recognizes an open board session (UI, NPC, or objectives window), the "board active / on cooldown" state machine. |
| `Roll.lua` | The reroll engine itself: an evaluation loop over the displayed objectives on every tick, matching against desired quests, handling pauses (no board open, no wanted quest, a quest already selected and in progress), tracking gold spent during the session. |
| `Instance.lua` | Computes the automatic target quest when "Current instance" mode is on: detects which dungeon/raid you're in and matches it to its known instance quest. |
| `Difficulty.lua` | Reads and applies the difficulty tier (Hardmode) via the server's service, syncing it with the difficulty requested by the active list. |

### `Features/` — extras that depend on nothing else

| File | Exact role |
| --- | --- |
| `Share.lua` | Automatically shares your last accepted quest to party/raid (a dedicated addon-message protocol), and auto-accepts a quest shared by another AutoCallboard — never one shared by a regular player, which stays for you to accept by hand. |
| `Builds.lua` | The bridge to the server's talent build system (an "echo" opcode protocol), a build-selection window, and the **Echo bar**: 3 drag-and-drop slots, anchorable anywhere, lockable, and bindable to keyboard shortcuts. |
| `Eternals.lua` | An independent mini-utility: converts Elemental Crystal → Eternal → final item through a secure, key-bound button, auto-detecting each step of the sequence. |

### `Language/` and `Locales/` — the multilingual system

| File | Exact role |
| --- | --- |
| `Language/Locale.lua` | The registry of available languages and the resolver that picks the client's default language on first launch. |
| `Language/Switcher.lua` | The language-selection menu and the live refresh of **every** on-screen text, without reloading the UI. |
| `Locales/enUS.lua`, `frFR.lua`, `deDE.lua`, `esES.lua` | The addon's four complete translations. |

### `UI/` — everything you see

| File | Exact role |
| --- | --- |
| `Skin.lua` | The theme system (purple on black), and the reusable factories for windows, buttons, rows, and checkboxes that give the whole addon its consistent look. |
| `ControlFrame.lua` | The small control panel (Callboard button, Start/Stop, summon status) and the minimap button. |
| `QuestWindow.lua` | The known-quests window: search, type filters, checkboxes for desired quests, and directly selecting a quest currently on the board. |
| `Lists.lua` | The saved-lists and groups manager, a two-pane dashboard-style layout with drag-and-drop between groups and reordering. |
| `QuestData.lua` | The text export/import window for the learned quest catalog. |
| `Help.lua` | The built-in help, available in-game at any time. |

### At the root

| File | Exact role |
| --- | --- |
| `AutoCallboard.lua` | The entry point: creates the adaptive `OnUpdate` loop (it slows itself down automatically once nothing's happening), routes every WoW event the addon listens to, and interprets `/acb` commands. |
| `AutoCallboard.toc` | The WoW manifest: metadata, saved variables (`AutoCallboardDB`, `AutoCallboardQuestDB`, `AutoCallboardEternalsDB`), and file load order. |
| `Bindings.xml` | The 3 assignable keybindings for triggering each Echo bar slot. |

## 🗣️ Slash commands

Aliases: `/acb` and `/autocallboard`.

| Command | Effect |
| --- | --- |
| `/acb` (or `version` / `v`) | Prints the installed addon version. |
| `/acb run` (or `call`) | Opens the panel and resumes the board flow. Summoning itself must be done with the Callboard button. |
| `/acb help` | Opens the built-in help. |
| `/acb show` / `hide` | Shows or hides the control panel. |
| `/acb roll` (or `autoroll`) | Starts rerolling. |
| `/acb stop` | Stops rerolling. |
| `/acb quests` (or `quest`) | Opens the known quests window. |
| `/acb reroll [frame_name]` | Forces a one-off reroll, or changes the reroll frame's name. |
| `/acb objective <1-3>` (or `obj` / `pick` / just `1`, `2`, `3`) | Directly selects one of the 3 displayed slots. |
| `/acb reset` | Resets settings while keeping learned quests. |
| `/acb name <text>` | Changes the targeted NPC name used for summoning. |
| `/acb id <spellID>` | Changes the summon spell used. |
| `/acb maxrolls <n>` | Changes the maximum number of rerolls before giving up. |
| `/acb accept on/off` | Toggles auto-accepting the quest that was found. |
| `/acb autoacceptquests on/off` | Toggles auto-accepting quests shared by another ACB. |
| `/acb autoinstance on/off` | Toggles "current instance quest" mode. |
| `/acb minimap on/off` | Shows or hides the minimap button. |
| `/acb export` / `import` | Opens the export or import window for the quest catalog. |

The **Callboard** button summons the Callboard; the reroll speed slider
offers 4 presets (Turbo, Fast, Normal, Safe) right from the panel.

## 🌍 Languages

English, French, German, and Spanish ship complete. The language picker
in the panel switches everything instantly, including windows that are
already open.

## 📜 License & credits

Original author: **Disarray** — fork maintained by **Siphelis**.

## License

This project is licensed under a custom license (MIT base + PolyForm Noncommercial for modifications) — see [LICENSE](https://github.com/Siphelis/autocallboard/blob/main/LICENSE) for details.

---
