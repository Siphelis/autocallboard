# 🎯 AutoCallboard

**Das Callboard verschwendet nie wieder deine Zeit.**

AutoCallboard würfelt das _Callboard_ für dich neu aus, erkennt die
gesuchte Quest in dem Moment, in dem sie erscheint, wählt sie aus und
stoppt genau im richtigen Moment.
Dazu kommen ein Gedächtnis für jede jemals gesehene Quest, gespeicherte
Auswahllisten, die zwischen all deinen Charakteren geteilt werden, ein
"aktuelle Instanz"-Modus, automatisches Teilen in der Gruppe und volle
Integration in das Build-System des Servers. Das alles in einer
schlanken, dezenten Oberfläche, verfügbar auf Deutsch, Englisch,
Französisch und Spanisch.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Inhaltsverzeichnis

- [Warum dieses Addon](#-warum-dieses-addon)
- [Funktionen](#-funktionen)
- [Installation](#-installation)
- [Schnellstart](#️-schnellstart)
- [Code-Aufbau](#-code-aufbau--wie-es-funktioniert)
- [Slash-Befehle](#️-slash-befehle)
- [Sprachen](#-sprachen)
- [Optionale Begleit-Tools](#-optionale-begleit-tools)
- [Screenshots](#-screenshots)
- [Mitwirken](#-mitwirken)
- [Lizenz & Danksagung](#-lizenz--danksagung)

---

## 🔥 Warum dieses Addon

Das Callboard bietet drei zufällige Quests an und zwingt dich, so lange
manuell neu zu würfeln, bis du die gewünschte bekommst. Das ist
repetitiv und kostet Zeit. AutoCallboard übernimmt diese Arbeit für
dich.

## ✨ Funktionen

- **Intelligentes Auto-Reroll** — hake die gewünschten Quests ab,
  klicke auf Start, und das Addon wählt automatisch die gewählte(n)
  Quest(en) aus.
- **Persistentes Quest-Gedächtnis** — jede auf dem Board gesehene
  Quest wird automatisch erfasst (Titel, Typ, Belohnungen) und nach
  Kategorie sortiert: Instanz, Raid, offene Welt, Beruf.
- **Gespeicherte Auswahllisten** — speichere mehrere benannte
  Auswahllisten, organisiert in Dashboard-artigen Gruppen, geteilt
  zwischen all deinen Charakteren.
- **"Aktuelle Instanz"-Modus** — in einer erkannten Instanz oder
  einem Raid wird nur nach der zugehörigen Instanz-Quest neu
  gewürfelt.
- **Synchronisierter Schwierigkeitsgrad (Hardmode)** — jede Liste
  kann eine Schwierigkeitsstufe festlegen; das Addon wendet sie
  automatisch an, sobald möglich.
- **Gruppenweites Quest-Teilen** — teilt automatisch deine zuletzt
  angenommene Quest erneut und kann Quests, die von einem anderen
  AutoCallboard in deiner Gruppe geteilt wurden, automatisch annehmen.
- **Goldausgaben-Tracking** — jeder Reroll kostet Gold; das Panel
  zeigt die Gesamtausgaben, die Ausgaben der aktuellen Sitzung und die
  Kosten der zuletzt erhaltenen Quest.
- **Integration in das Build-System des Servers** — prüfe, wechsle
  und pinne deine Talent-Builds über eine kleine 3-Slot-"Echo"-Leiste,
  verschiebbar und mit Tastenkürzeln belegbar.
- **Text-Export/-Import** — kopiere deine erlernte Quest-Liste mit
  einfachem Copy-Paste von einer Installation zur anderen.
- **Live-Sprachumschaltung** — wechsle die Sprache direkt im Panel,
  und jeder sichtbare Text aktualisiert sich sofort, ohne `/reload`.

## 📦 Installation

1. [LINKS] — lade die neueste Version herunter.
2. Entpacke den Ordner `AutoCallboard` nach
   `Interface/AddOns/`.
3. Prüfe im AddOn-Auswahlbildschirm, dass **AutoCallboard**
   angehakt ist.
4. Das war's — es wird keine Abhängigkeit benötigt.

## 🕹️ Schnellstart

```
/acb           → öffnet (oder startet direkt) das Kontrollpanel
/acb quests    → öffnet das Fenster der bekannten Quests
/acb roll      → startet das Rerollen
/acb stop      → stoppt das Rerollen
/acb help      → öffnet die integrierte Hilfe im Spiel
```

1. Öffne das Quest-Fenster (`/acb quests`) und hake die Quests ab, die
   du suchen möchtest.
2. Nähere dich dem Callboard (oder lasse es vom Addon herbeirufen) und
   klicke auf **Start**.
3. Das Addon würfelt für dich neu, stoppt in dem Moment, in dem eine
   abgehakte Quest erscheint, und wählt sie aus.
4. Schließe die Quest ab und würfle erneut, sobald du die nächste
   möchtest.

Die gesamte Kontexthilfe (Tastenkürzel, Tipps, Goldkosten) ist im Spiel
über `/acb help` verfügbar.

## 🧠 Code-Aufbau — wie es funktioniert

AutoCallboard ist in Einwegmodule aufgeteilt: Jeder Ordner hat eine
klare Aufgabe, und alles kommuniziert über den gemeinsamen Namespace
`AutoCallboardRuntime` (im Code abgekürzt als `RT`).

### `Core/` — reine Logik, kein Spielzustand

| Datei | Genaue Rolle |
| --- | --- |
| `Core.lua` | Das nebenwirkungsfreie Gehirn: Standardwerte der gespeicherten Daten, Zusammenführen/Übernehmen eines gespeicherten Zustands (Abwärtskompatibilität), der `/acb`-Befehlsparser, die heuristische Quest-Klassifizierung (Schlüsselwörter für Instanz/Raid/Beruf/offene Welt), die Logik für gespeicherte Listen und Gruppen (Erstellen, Umbenennen, Verschieben, Limits) und das Text-Export-/Importformat für den Quest-Katalog. |
| `State.lua` | Die Brücke zwischen `Core` und dem `AutoCallboardDB`-Speicherstand: wendet einen neuen Zustand an, erhöht einen Revisionszähler, damit sich die Oberfläche nur bei Bedarf aktualisiert, und verfolgt das für Rerolls ausgegebene Gold. |
| `Migration.lua` | Die einmalige Migration alter, *charakterbezogener* Speicherstände in das gemeinsame Account-Profil — mit Dialogen, wann immer ein Import zusammengeführt, ersetzt, behalten oder verworfen werden muss. |
| `Util.lua` | Der gemeinsame Werkzeugkasten: Chat-Ausgaben, Auflösen von Blizzard-Frame-Pfaden (`"Frame.child.other"`), simulierte Klicks, die vorübergehend den Spielsound stummschalten, damit sie die Atmosphäre nicht stören, Geld-/Zeitformatierung und das kleine Debug-Log-System. |

### `Automation/` — was auf das Spiel einwirkt

| Datei | Genaue Rolle |
| --- | --- |
| `Callboard.lua` | Erkennt und ruft das Callboard herbei: zielt auf den NPC, wirkt den Beschwörungszauber, liest Abklingzeiten aus, erkennt eine offene Board-Sitzung (UI, NPC oder Zielfenster), die Zustandsmaschine "Board aktiv / in Abklingzeit". |
| `Roll.lua` | Die eigentliche Reroll-Engine: eine Auswertungsschleife über die angezeigten Ziele bei jedem Tick, Abgleich mit den gewünschten Quests, Behandlung von Pausen (kein Board offen, keine gewünschte Quest, eine Quest bereits ausgewählt und in Bearbeitung), Verfolgung des während der Sitzung ausgegebenen Golds. |
| `Instance.lua` | Berechnet die automatische Zielquest, wenn der Modus "Aktuelle Instanz" aktiv ist: erkennt, in welcher Instanz/welchem Raid du dich befindest, und ordnet sie der bekannten Instanz-Quest zu. |
| `Difficulty.lua` | Liest und wendet die Schwierigkeitsstufe (Hardmode) über den Serverdienst an und synchronisiert sie mit der von der aktiven Liste angeforderten Schwierigkeit. |

### `Features/` — Extras, die von nichts anderem abhängen

| Datei | Genaue Rolle |
| --- | --- |
| `Share.lua` | Teilt automatisch deine zuletzt angenommene Quest mit Gruppe/Raid (über ein eigenes Addon-Nachrichtenprotokoll) und nimmt automatisch eine Quest an, die von einem anderen AutoCallboard geteilt wurde — niemals eine, die von einem normalen Spieler geteilt wurde; diese bleibt zur manuellen Annahme bestehen. |
| `Builds.lua` | Die Brücke zum Talent-Build-System des Servers (ein "Echo"-Opcode-Protokoll), ein Build-Auswahlfenster und die **Echo-Leiste**: 3 Drag-and-Drop-Slots, überall verankerbar, sperrbar und mit Tastenkürzeln belegbar. |
| `Eternals.lua` | Ein eigenständiges Mini-Werkzeug: wandelt Elementarkristall → Ewiges → Enditem über einen gesicherten, tastenbelegbaren Button um und erkennt automatisch jeden Schritt der Sequenz. |

### `Language/` und `Locales/` — das Mehrsprachensystem

| Datei | Genaue Rolle |
| --- | --- |
| `Language/Locale.lua` | Das Verzeichnis der verfügbaren Sprachen und der Resolver, der beim ersten Start die Standardsprache des Clients auswählt. |
| `Language/Switcher.lua` | Das Sprachauswahlmenü und die Live-Aktualisierung **jedes** Textes auf dem Bildschirm, ohne die Oberfläche neu zu laden. |
| `Locales/enUS.lua`, `frFR.lua`, `deDE.lua`, `esES.lua` | Die vier vollständigen Übersetzungen des Addons. |

### `UI/` — alles, was du siehst

| Datei | Genaue Rolle |
| --- | --- |
| `Skin.lua` | Das Themensystem (lila auf schwarz) und die wiederverwendbaren Fabriken für Fenster, Buttons, Zeilen und Checkboxen, die dem gesamten Addon sein einheitliches Aussehen geben. |
| `ControlFrame.lua` | Das kleine Kontrollpanel (Callboard-Button, Start/Stopp, Beschwörungsstatus) und der Minimap-Button. |
| `QuestWindow.lua` | Das Fenster der bekannten Quests: Suche, Typfilter, Checkboxen für gewünschte Quests und direkte Auswahl einer aktuell auf dem Board befindlichen Quest. |
| `Lists.lua` | Der Verwalter für gespeicherte Listen und Gruppen, ein zweigeteiltes Dashboard-Layout mit Drag-and-Drop zwischen Gruppen und Neuanordnung. |
| `QuestData.lua` | Das Text-Export-/Importfenster für den erlernten Quest-Katalog. |
| `Help.lua` | Die integrierte Hilfe, jederzeit im Spiel verfügbar. |

### Im Wurzelverzeichnis

| Datei | Genaue Rolle |
| --- | --- |
| `AutoCallboard.lua` | Der Einstiegspunkt: erstellt die adaptive `OnUpdate`-Schleife (sie verlangsamt sich automatisch, sobald nichts passiert), leitet jedes vom Addon abonnierte WoW-Ereignis weiter und interpretiert `/acb`-Befehle. |
| `AutoCallboard.toc` | Das WoW-Manifest: Metadaten, gespeicherte Variablen (`AutoCallboardDB`, `AutoCallboardQuestDB`, `AutoCallboardEternalsDB`) und die Ladereihenfolge der Dateien. |
| `Bindings.xml` | Die 3 zuweisbaren Tastenkürzel zum Auslösen jedes Echo-Leisten-Slots. |

## 🗣️ Slash-Befehle

Aliase: `/acb` und `/autocallboard`.

| Befehl | Effekt |
| --- | --- |
| `/acb` (oder `run` / `call`) | Öffnet das Panel und startet in einem Schritt das Rerollen. |
| `/acb help` | Öffnet die integrierte Hilfe. |
| `/acb show` / `hide` | Zeigt oder versteckt das Kontrollpanel. |
| `/acb roll` (oder `autoroll`) | Startet das Rerollen. |
| `/acb stop` | Stoppt das Rerollen. |
| `/acb quests` (oder `quest`) | Öffnet das Fenster der bekannten Quests. |
| `/acb reroll [frame_name]` | Erzwingt einen einmaligen Reroll oder ändert den Namen des Reroll-Frames. |
| `/acb objective <1-3>` (oder `obj` / `pick` / einfach `1`, `2`, `3`) | Wählt direkt einen der 3 angezeigten Slots aus. |
| `/acb reset` | Setzt die Einstellungen zurück, behält aber die erlernten Quests. |
| `/acb name <Text>` | Ändert den für die Beschwörung verwendeten NPC-Namen. |
| `/acb id <spellID>` | Ändert den verwendeten Beschwörungszauber. |
| `/acb maxrolls <n>` | Ändert die maximale Anzahl an Rerolls, bevor aufgegeben wird. |
| `/acb accept on/off` | Schaltet die automatische Annahme der gefundenen Quest um. |
| `/acb autoacceptquests on/off` | Schaltet die automatische Annahme von Quests um, die von einem anderen ACB geteilt wurden. |
| `/acb autoinstance on/off` | Schaltet den Modus "aktuelle Instanz-Quest" um. |
| `/acb minimap on/off` | Zeigt oder versteckt den Minimap-Button. |
| `/acb export` / `import` | Öffnet das Export- oder Importfenster für den Quest-Katalog. |

Der **Callboard**-Button beschwört oder öffnet das nächstgelegene
Board; der Reroll-Geschwindigkeitsregler bietet 4 Voreinstellungen
(Turbo, Schnell, Normal, Sicher) direkt im Panel.

## 🌍 Sprachen

Deutsch, Englisch, Französisch und Spanisch sind vollständig verfügbar.
Die Sprachauswahl im Panel ändert sofort alles, auch bereits geöffnete
Fenster.

## 📜 Lizenz & Danksagung

Ursprünglicher Autor: **Disarray** — Fork gepflegt von **Siphelis**.

## Lizenz

Dieses Projekt steht unter einer angepassten Lizenz (MIT-Basis +
PolyForm Noncommercial für die Änderungen) — siehe [LICENSE](https://github.com/Siphelis/autocallboard/blob/main/LICENSE) für
Details.

---
