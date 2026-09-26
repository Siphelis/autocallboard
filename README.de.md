# 🎯 AutoCallboard

**Das Callboard verschwendet nie wieder Ihre Zeit.**

AutoCallboard würfelt das _Callboard_ für Sie neu, erkennt die gesuchte Quest in dem Moment,
in dem sie erscheint, wählt sie aus und nimmt die Suche wieder auf, sobald die Quest erledigt
ist. Außerdem merkt es sich jede gesehene Quest, speichert Ihre Auswahlen als Sammlungen, die
für alle Ihre Charaktere gelten, zeichnet Ihre Routen auf und spielt sie mit einem Leitpfeil
wieder ab, lässt Spieler diese Routen teilen und bietet Ihnen eine Schnellleiste für Ihre
Echo-Builds. Das alles in einer schlanken, dezenten Oberfläche, verfügbar auf Deutsch,
Englisch, Französisch und Spanisch.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Inhaltsverzeichnis

- [Warum dieses Addon](#-warum-dieses-addon)
- [Funktionen](#-funktionen)
- [Voraussetzungen](#-voraussetzungen)
- [Installation](#-installation)
- [Schnellstart](#-schnellstart)
- [Das Hauptpanel](#-das-hauptpanel)
- [Quests und Sammlungen](#-quests-und-sammlungen)
- [Das Würfeln](#-das-würfeln)
- [Routen](#-routen)
- [Builds](#-builds)
- [Extras](#-extras)
- [Einstellungen](#-einstellungen)
- [Gut zu wissen](#-gut-zu-wissen)
- [Sprachen](#-sprachen)
- [Lizenz & Danksagung](#-lizenz--danksagung)

---

## 🔥 Warum dieses Addon

Das Callboard bietet drei zufällige Quests an und zwingt Sie, so lange von Hand neu zu würfeln,
bis Sie die gewünschte bekommen. Das ist eintönig und kostet Zeit. Mit AutoCallboard haken Sie
die Quests an, die Sie wollen, und es übernimmt das Würfeln.

## ✨ Funktionen

- **Intelligentes Auto-Reroll** — haken Sie die gewünschten Quests an und klicken Sie auf
  Start: Das Addon würfelt, bis eine davon erscheint, wählt sie aus, nimmt sie auf Wunsch an
  und macht weiter, sobald die Quest erledigt ist.
- **Bekannte Quests** — jede auf dem Brett gesehene Quest wird gemerkt (Titel, Typ,
  Belohnungen), damit Sie sie suchen, filtern und anhaken können.
- **Sammlungen** — speichern Sie benannte Quest-Auswahlen, ordnen Sie sie in Gruppen und laden
  Sie eine mit einem Klick. Sie gelten für alle Ihre Charaktere, und jede kann eine
  Schwierigkeit tragen.
- **Modus „aktuelle Instanz“** — in einem Dungeon oder Schlachtzug wird nur nach der Quest
  dieser Instanz gewürfelt.
- **Routen** — zeichnen Sie Ihre Wege auf (NPCs, Dialoge, Quests, Checkpoints), spielen Sie
  sie mit einem Leitpfeil ab und teilen Sie sie über eine Bibliothek mit anderen Spielern.
- **Reiseknopf** — reisen Sie zu einem Checkpoint in der Nähe des Gebiets Ihrer Quest.
- **Quests in der Gruppe teilen** — jede angenommene Quest wird mit Ihrer Gruppe oder Ihrem
  Schlachtzug geteilt, und über AutoCallboard geteilte Quests lassen sich automatisch annehmen.
- **Echo-Builds** — wechseln Sie Builds über ein Fenster oder über eine verschiebbare
  Schnellleiste mit 3 Plätzen und Tastenkürzeln.
- **Eternals-Hilfe** — wandelt Ihre Kristalle um, während Sie die Eternals-Quests machen.
- **Goldzähler** — sehen Sie, was Ihre Neuwürfe kosten: Gesamt, Sitzung, laufende Suche, letzte
  Quest.
- **Update-Hinweis** — ein Knopf zeigt Ihnen, wenn eine neuere Version erschienen ist.
- **Export / Import** — kopieren Sie Ihre bekannten Quests von einer Installation auf eine
  andere.
- **Ihr Aussehen** — Farben, Größe, Deckkraft, Pfeilstil und die Knöpfe der Hauptleiste.
- **Vier Sprachen** — Deutsch, Englisch, Französisch, Spanisch, live umschaltbar ohne `/reload`.

## 📋 Voraussetzungen

| | |
|---|---|
| **Spiel** | World of Warcraft 3.3.5a auf dem Server **Ebonhold** |
| **Integration** | ProjectEbonhold, im Ebonhold-Client enthalten |
| **Erforderliches Addon** | [**EbonAPI**](https://github.com/Siphelis/EbonAPI/releases/latest), gemeinsam für die Ebonhold-Addons; AutoCallboard wird ohne es nicht geladen |

## 📦 Installation

1. Laden Sie die neueste Version von der
   [Releases-Seite](https://github.com/Siphelis/autocallboard/releases/latest) herunter.
2. Entpacken Sie den Ordner `AutoCallboard` nach `Interface/AddOns/`. Installieren Sie
   [**EbonAPI**](https://github.com/Siphelis/EbonAPI/releases/latest) auf dieselbe Weise, falls
   es noch fehlt.
3. Starten Sie das Spiel neu und prüfen Sie im AddOn-Auswahlbildschirm, dass **AutoCallboard**
   und **EbonAPI** beide angehakt sind.
4. Das AutoCallboard-Panel erscheint auf dem Bildschirm. Ein Minikarten-Knopf bietet
   schnellen Zugriff darauf.

## 🚀 Schnellstart

1. Klicken Sie auf **Quests** und haken Sie die Quests an, die Sie erhalten möchten.
2. Klicken Sie auf **Callboard**: Es beschwört ein Callboard, sofern Sie den Zauber aus dem
   Shop besitzen, und zielt es dann an und öffnet es für Sie. Stehen Sie stattdessen bei einem
   festen Objectives Board? Klicken Sie es einmal an, damit AutoCallboard seinen Inhalt lesen
   kann.
3. Klicken Sie auf **Start**. AutoCallboard würfelt, bis eine Ihrer Quests erscheint, hört
   dann auf zu würfeln und wählt sie aus. Es nimmt sie auch an, sofern Sie diese Option nicht
   ausgeschaltet haben.
4. Erledigen Sie die Quest. Sobald Sie sie abgegeben haben, setzt sich die Suche von selbst
   fort, sobald ein Brett geöffnet ist, bis Sie auf **Stopp** klicken.

Nach einer Neuinstallation ist die Liste der bekannten Quests noch leer: Wie Sie sie füllen,
steht unter [Bekannte Quests](#bekannte-quests).

Die Zeile unter den Knöpfen zeigt Ihnen, was gerade passiert: Callboard aktiv oder in
Abklingzeit, bisherige Neuwürfe, Suche pausiert, Quest ausgewählt.

## 🧭 Das Hauptpanel

| Element | Aufgabe |
|---|---|
| **Listen** | Öffnet Ihre Sammlungen. |
| **Builds** | Öffnet Ihre Echo-Builds. |
| **Callboard** | Beschwört das Callboard und öffnet es. Ausgegraut, solange sich Ihr Charakter in einem Gebäude befindet. |
| **Start / Stopp** | Startet oder beendet die Suche. |
| **Teilen** | Teilt Ihre zuletzt angenommene Quest noch einmal mit Ihrer Gruppe oder Ihrem Schlachtzug. Ausgegraut, bis Sie eine Quest angenommen haben. |
| **Quests** | Klappt das Fenster der bekannten Quests unter dem Panel auf. Der Knopf heißt dann **Ausblenden**. |
| Zahnrad, **?**, **×** (oben rechts) | Einstellungen, integrierte Hilfe, Schließen. |
| **Update verfügbar** | Erscheint nur, wenn eine neuere Version entdeckt wurde. Öffnet die Download-Seite. |
| **Reise: …** | Erscheint unter dem Panel, wenn ein Checkpoint zu Ihrer Quest passt. Siehe [Extras](#-extras). |

Ziehen Sie das Panel, um es zu verschieben, oder ziehen Sie einen seiner Knöpfe bei gedrückter
Umschalttaste. Der Minikarten-Knopf blendet das Panel ein oder aus (Linksklick), öffnet die
Einstellungen (Rechtsklick) und lässt sich um die Minikarte herum ziehen. Die Hilfe hat fünf
Reiter und öffnet sich mit **?**.

## 📂 Quests und Sammlungen

### Bekannte Quests

**Quests** öffnet die Liste aller Quests, die AutoCallboard auf einem Brett gesehen hat. Sie
ist nach einer Neuinstallation leer und wächst, während Ihnen die Bretter Quests zeigen.

- Haken Sie eine Quest an, um nach ihr zu suchen. Fahren Sie darüber, um ihren Typ, ihr Ziel,
  ihre Belohnungen (EP und Soul Ash je Schwierigkeit) und die Zahl ihrer Auftritte zu sehen.
- **Suche** filtert nach Name, Ziel, Typ oder Belohnung. Die Typ-Kästchen (Offene Welt,
  Dungeon, Schlachtzug, Beruf, Sonstige) grenzen die Liste weiter ein.
- **Alle zeigen** behält alle bekannten Quests in der Liste, auch wenn gerade eine Sammlung
  geladen ist. Ohne diese Option zeigt die Liste nur die Quests der geladenen Sammlung.
- Klicken Sie eine Quest mit **rechts** an, um sie in eine Sammlung einzuordnen oder um eine
  neue Sammlung mit ihr zu beginnen.
- **Exportieren** zeigt Ihre bekannten Quests als Text zum Kopieren. Fügen Sie diesen Text
  unter **Importieren** in einer anderen Installation ein, um sie dort hinzuzufügen.
- Um die Liste schnell zu füllen, klicken Sie auf **Start**, ohne etwas anzuhaken:
  AutoCallboard bittet um Bestätigung und würfelt dann nur, um Quests kennenzulernen, ohne bei
  einer davon anzuhalten.

### Sammlungen

Eine Sammlung ist eine benannte Gruppe angehakter Quests. **Listen** öffnet sie.

- Klicken Sie auf eine Sammlung, um sie zu laden: Ihre Quests werden angehakt. Klicken Sie
  erneut darauf, um sie zu entladen, wodurch alle Haken verschwinden. **(Keine Auswahl)**
  entfernt ebenfalls alle Haken. Während die Suche läuft, lässt sich die Sammlung nicht
  wechseln.
- Das **+** oben rechts an der Liste (oder an einer geöffneten Gruppe) speichert Ihre
  angehakten Quests dort als neue Sammlung. Das **+** oben links im Fenster legt eine Gruppe an.
- Klicken Sie eine Sammlung mit rechts an, um sie zu verschieben, ihre Schwierigkeit
  festzulegen, sie mit Ihren angehakten Quests zu aktualisieren, sie umzubenennen oder zu
  löschen. Ziehen Sie sie, um sie neu zu ordnen oder in einer anderen Gruppe abzulegen.
- Gruppen ordnen Ihre Sammlungen. Eine zugeklappte Gruppe erscheint als Band: Klicken Sie
  darauf, um sie aufzuklappen, und klappen Sie sie mit **>>** wieder zu. Bis zu 10 Gruppen und
  bis zu 50 Sammlungen in jeder Gruppe und in der Basisliste.
- Eine Sammlung kann eine Schwierigkeit tragen (Normal, HC1 bis HC5). Sie wird beim Laden der
  Sammlung angewendet, solange Sie sich in einer Ruhezone (Gasthaus oder Hauptstadt) befinden
  und nicht im Kampf sind.

Sammlungen gelten für alle Ihre Charaktere. Die angehakten Quests und die geladene Sammlung
gehören zum jeweiligen Charakter.

### Aktuelle Instanz

**Auto aktuelle Instanz**: In einem Dungeon oder Schlachtzug ignoriert **Start** die
angehakten Quests und würfelt nur nach der Quest dieser Instanz. Nicht jeder Dungeon und
Schlachtzug hat eine Callboard-Quest; passt keine, würfelt AutoCallboard weiter, bis es sein
Limit erreicht oder Sie es anhalten.

## ⚡ Das Würfeln

Jeder Neuwurf kostet Gold. Wenn Sie auf **Start** klicken, geht AutoCallboard so vor:

1. Es würfelt das Brett neu und wartet dabei vor jedem weiteren Neuwurf stets auf die Antwort
   des Servers.
2. Es vergleicht die drei angebotenen Quests mit den angehakten (oder mit der Quest der
   Instanz).
3. Bei einem Treffer hört es auf zu würfeln, wählt die Quest aus und schließt das Brett.
4. Es bleibt pausiert, solange die Quest läuft, und macht weiter, wenn Sie sie abgeben oder
   aufgeben.

Eine aufgegebene Quest bleibt aus der Suche draußen, bis Sie eine andere Ihrer ausgewählten
Quests annehmen. Die Suche endet von selbst nach 50 Neuwürfen ohne Treffer oder wenn Sie sich
keinen Neuwurf mehr leisten können.

| Option | Aufgabe |
|---|---|
| **Ausgewählte Quests automatisch annehmen** *(an)* | Nimmt die Callboard-Quest an, sobald sie einer der angehakten Quests entspricht. |
| **Quests automatisch annehmen** *(aus)* | Nimmt Quests an, die Mitglieder Ihrer Gruppe oder Ihres Schlachtzugs über AutoCallboard teilen. Von anderen Spielern geteilte Quests müssen Sie selbst annehmen. |
| **Auto aktuelle Instanz** *(aus)* | Siehe [Aktuelle Instanz](#aktuelle-instanz). |
| **Ohne Board neu würfeln** *(aus)* | Würfelt weiter und wählt Quests, ohne dass ein Brett geöffnet ist, überall in der Welt. Jeder Neuwurf kostet weiterhin Gold, und der Server kann ihn jederzeit ablehnen. |
| **Roll-Geschwindigkeit** | Wie schnell die Neuwürfe aufeinander folgen. Vier Voreinstellungen: Turbo, Schnell, Normal, Sicher. |

Diese Optionen finden Sie in den Einstellungen auf dem Reiter **Allgemein**.

## 📍 Routen

Eine Route ist ein von Ihnen aufgezeichneter Weg: die NPCs, mit denen Sie gesprochen haben,
Ihre Entscheidungen in deren Dialogen, die angenommenen oder abgegebenen Quests, die genutzten
Checkpoints und der Ort jedes Schritts. Wenn Sie sie abspielen, wiederholt AutoCallboard die
aufgezeichneten Interaktionen, sobald Sie sie erreichen, und ein Pfeil zeigt, wohin es als
Nächstes geht. Ihren Charakter zu bewegen bleibt Ihre Sache.

Der Knopf **Routen** öffnet das Routenfenster. Er ist ab Werk nicht auf der Hauptleiste: Fügen
Sie ihn in den Einstellungen auf dem Reiter **Hauptleiste** hinzu. Das Fenster hat **●**
(aufnehmen), **▶** (abspielen), **⏭** (überspringen), die Knöpfe **Meine Routen** und
**Bibliothek** sowie **_**, das es auf eine einzige Zeile verkleinert, die über allem bleibt,
Weltkarte eingeschlossen.

### Aufnehmen

Klicken Sie auf **●** und spielen Sie dann ganz normal: Sprechen Sie mit NPCs, nehmen Sie
Quests an und geben Sie sie ab, nutzen Sie Checkpoints. Ist Ihr Weg zu Ende, klicken Sie auf
**■**: Geben Sie der Route einen Namen und wählen Sie eine der acht Kategorien (Stufenaufstieg,
Tägliche Quests, Ruf, Berufe, Questreihen und Zugänge, Klasse, Weltereignisse, Erfolge und
Sammlungen). Eine Route umfasst bis zu 400 Schritte, und Sie können bis zu 50 pro Kategorie
behalten.

### Abspielen

Klicken Sie unter **Meine Routen** auf eine Route, um sie zu laden (erneut klicken zum
Entladen), und dann auf **▶**, um von vorn zu beginnen, oder klicken Sie auf eine beliebige
Zeile der Route, um dort einzusteigen. **⏭** überspringt den laufenden Block. Eine Route der
gegnerischen Fraktion startet nicht. Die Wiedergabe hält von selbst an, wenn ein Checkpoint für
Ihren Charakter nicht freigeschaltet ist oder wenn ein Schritt nicht zu Ende gespielt werden
kann.

Klicken Sie eine Route mit rechts an, um sie zu laden oder zu entladen, ihre Kategorie zu
ändern, sie zu teilen, Ihre aktuelle Aufnahme anzuhängen (**Anhängen**) oder sie zu ersetzen
(**Überschreiben**), ihre Startschwierigkeit festzulegen, sie umzubenennen oder zu löschen.
Klicken Sie eine Zeile mit rechts an, um sie zu löschen oder den Pfeil auf sie zu richten.

### Der Pfeil

Der Pfeil zeigt zum nächsten aufgezeichneten Ort und gibt die Entfernung und die erwartete
Aktion an. Kann er nicht zielen (der Ort liegt auf einem anderen Kontinent, Sie sind in einer
Instanz oder Ihre Position ist nicht lesbar), sagt er das, statt zu zeigen, und er meldet
Ihnen Ihre Ankunft. Verschieben Sie ihn durch Ziehen. Sein Aussehen wählen Sie mit **Stile
ansehen** (zehn Stile), seine Größe und die Textgröße in den Einstellungen auf dem Reiter
**Aussehen**.

### Teilen

Klicken Sie eine Route mit rechts an und wählen Sie **Teilen**: Sie erscheint, nach Kategorie
sortiert, in der **Bibliothek** der anderen AutoCallboard-Spieler. Öffnen Sie eine
Kategorie und klicken Sie dann auf eine Route, um sie zu holen. Eine ausgegraute Route lässt sich im Moment nicht
herunterladen, weil kein Spieler, der sie besitzt, online ist. Eine geholte Route wird ihrerseits
geteilt; wählen Sie **Nicht mehr teilen**, wenn Sie das nicht möchten. Bearbeiten Sie eine
geteilte Route, wird die neue Version erneut veröffentlicht, während Spieler, die sie schon
geholt haben, ihre eigene Kopie behalten. Routen der anderen Fraktion lassen sich behalten,
bearbeiten und teilen, aber nicht abspielen. Das Teilen läuft im Hintergrund.

## 🔄 Builds

Der Knopf **Builds** öffnet die Echo-Builds Ihres Charakters, so wie der Server sie speichert.
Klicken Sie auf einen Build, um ihn zu aktivieren. Im Kampf lassen sich Builds nicht wechseln.

**Echo-Schnellleiste** (Einstellungen, Reiter **Allgemein**) fügt eine kleine Leiste mit drei
Plätzen hinzu. Ziehen Sie einen Build aus dem Builds-Fenster auf einen Platz. Klicken Sie
einen Platz mit rechts an, um ihn zu leeren, oder ziehen Sie einen Platz auf einen anderen, um
sie zu tauschen. **Ausrichtung** schaltet die Leiste zwischen waagerecht und senkrecht um. Der
Punkt in der linken oberen Ecke der Leiste sperrt sie: Eine gesperrte Leiste lässt sich weder
verschieben noch ändern, aber ihre Plätze funktionieren weiter. Jeder Platz kann ein eigenes
Tastenkürzel haben, im Tastenbelegungsmenü von World of Warcraft unter AutoCallboard.

## 🧰 Extras

- **Reiseschaltfläche** *(an)* — gehört Ihre Quest zu einem Gebiet, erscheint unter dem Panel ein
  Knopf **Reise**, der Sie zu einem freigeschalteten Checkpoint in oder nahe diesem Gebiet
  teleportiert. **Automatisch reisen** *(aus)* tut das, sobald eine neue Quest ausgewählt wird,
  ohne nachzufragen. Es greift nie im Kampf oder wenn Sie tot sind und nutzt nur Checkpoints,
  die Sie freigeschaltet haben.
- **Eternals-Hilfe** *(an)* — nehmen Sie eine Eternal-Quest (Wasser, Feuer, Erde, Luft oder
  Schatten) an und haben 10 passende Kristalle in den Taschen, erscheint ein kleiner Knopf, der
  sie in zwei Schritten umwandelt. Klicken Sie ihn an oder drücken Sie seine Taste (standardmäßig
  Strg+W). Mit einem Rechtsklick schließen Sie ihn.
- **Goldzähler** — AutoCallboard zählt, was Ihre Neuwürfe kosten: Gesamt, Sitzung, laufende
  Suche und zuletzt erhaltene Quest. Welche Zähler wo erscheinen, legen Sie in den
  Einstellungen auf dem Reiter **Gold** fest. Diese Funktion ist noch in Entwicklung, und
  manche Zähler können ungenau sein.
- **Geschwindigkeit des Charakters anzeigen** *(aus)* — zeigt Ihre tatsächliche Geschwindigkeit
  unter den Knöpfen, als Prozentsatz der normalen Laufgeschwindigkeit. Reittier und alle aktiven
  Effekte sind eingerechnet, und im Stand steht dort 0 %.
- **Update-Hinweis** — wird ein Spieler mit einer neueren Version entdeckt, erscheint eine
  Nachricht in Ihrem Chat, und der Knopf **Update verfügbar** taucht auf dem Panel auf.
- **EbonInvite** — nutzen Sie auch EbonInvite, kann es AutoCallboard bitten, für den von ihm
  gewählten Dungeon oder Schlachtzug zu würfeln.

## 🔧 Einstellungen

Klicken Sie auf das Zahnrad am Panel oder mit rechts auf den Minikarten-Knopf.

| Reiter | Inhalt |
|---|---|
| **Allgemein** | Die Optionen oben: Auto aktuelle Instanz, Echo-Schnellleiste, Quests automatisch annehmen, Minikarten-Schaltfläche, Reiseschaltfläche, Automatisch reisen, Ohne Board neu würfeln, Ausgewählte Quests automatisch annehmen, Eternals-Hilfe, Geschwindigkeit des Charakters anzeigen, Roll-Geschwindigkeit und Sprache. |
| **Aussehen** | Farben Hintergrund und Akzent, Oberflächengröße, Hintergrunddeckkraft, Größe, Text und Stil des Pfeils sowie **Fensterpositionen sperren**. |
| **Hauptleiste** | Wählen Sie, welche Knöpfe die Hauptleiste zeigt und in welcher Reihenfolge. Ab Werk: Listen, Builds, Callboard, Start, Teilen und Quests. Hinzufügen lassen sich außerdem Routen, Exportieren, Importieren, Auto aktuelle Instanz, Eternals-Hilfe, Hilfe und Einstellungen. Jeder Charakter hat seine eigene Leiste. |
| **Gold** | Welche Goldzähler angezeigt werden und ob sie in der Hauptleiste erscheinen. |

Änderungen auf dem Reiter **Allgemein** gelten sofort. Änderungen auf den Reitern **Aussehen**,
**Hauptleiste** und **Gold** gelten erst nach einem Klick auf **Anwenden**; **Standard** setzt
diese drei Reiter auf ihre ursprünglichen Werte zurück.

## 💡 Gut zu wissen

- **Bekannte Quests, Sammlungen, Routen und das Aussehen gelten für alle Ihre Charaktere.**
  Die angehakten Quests, die geladene Sammlung, die Hauptleiste, die Schnellleiste und die
  geladene Route gehören zum jeweiligen Charakter.
- **Der Knopf Callboard ist in Gebäuden ausgegraut**, weil sich das Brett dort nicht
  beschwören lässt.
- **Wenn Sie eine ältere Version genutzt haben**, wechseln die pro Charakter gespeicherten
  Listen beim Anmelden jedes Charakters auf Ihren Account, und die Listen des alten Addons
  AutoCallboardPresets werden ebenfalls übernommen. Sind alle zehn Gruppen schon belegt, fragt
  AutoCallboard, was behalten werden soll.

## 🌍 Sprachen

Deutsch, Englisch, Französisch und Spanisch sind vollständig enthalten. AutoCallboard folgt
der Sprache Ihres Spiels, und Sie können sie über den Sprachknopf in den Einstellungen ändern:
Alles wechselt sofort, auch bereits geöffnete Fenster. Die Sprache gilt gemeinsam für die
anderen Ebonhold-Addons, die EbonAPI nutzen.

## 📜 Lizenz & Danksagung

Ursprünglicher Autor: **Disarray** — Fork gepflegt von **Siphelis**.

## Lizenz

Dieses Projekt steht unter einer angepassten Lizenz, die auf MIT und für Änderungen auf PolyForm Noncommercial beruht. Die vollständigen Bedingungen finden Sie in der Datei [LICENSE](https://github.com/Siphelis/autocallboard/blob/main/LICENSE).

---
