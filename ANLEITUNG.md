# O.C. Flow installieren

Fünf Minuten, einmalig. Danach: Taste halten, sprechen, loslassen — der Text landet da, wo dein Cursor steht.

**Voraussetzung:** macOS 26 oder neuer. Prüfen unter  ▸ Über diesen Mac. Steht da eine kleinere Zahl, zuerst macOS aktualisieren.

## Schritt 1: Terminal öffnen

Cmd + Leertaste drücken, „Terminal" tippen, Enter.

## Schritt 2: Apples Entwickler-Werkzeuge holen

Diesen Befehl einfügen und Enter drücken:

```bash
xcode-select --install
```

Es öffnet sich ein Fenster, dort auf „Installieren" klicken und warten, bis es fertig ist (ein paar Minuten). Kommt stattdessen eine Meldung wie „already installed", ist alles gut — weiter zu Schritt 3.

## Schritt 3: App herunterladen und bauen

Diese vier Befehle nacheinander einfügen, nach jedem Enter drücken:

```bash
git clone https://github.com/yassinebb2005-oss/OC-Flow.git
```

```bash
cd OC-Flow
```

```bash
bash Tools/create-signing-cert.sh
```

```bash
make install
```

Der dritte Befehl legt ein Zertifikat auf deinem Mac an und fragt dabei nach deinem Passwort. Das ist kostenlos und sorgt dafür, dass du die Berechtigung aus Schritt 4 nur ein einziges Mal erteilen musst, auch nach künftigen Updates.

Der letzte Befehl arbeitet ein paar Minuten. Fragt der Schlüsselbund dabei, ob „codesign" den Schlüssel benutzen darf, auf **Immer erlauben** klicken. Am Ende startet O.C. Flow von selbst und oben in der Menüleiste erscheint ein kleines O.C.

## Schritt 4: Zwei Berechtigungen erteilen

1. Es öffnet sich eine Abfrage für die **Bedienungshilfen** — falls nicht: Systemeinstellungen ▸ Datenschutz & Sicherheit ▸ Bedienungshilfen. Dort **OC Flow** einschalten. Steht der Schalter dort schon auf an, weil du O.C. Flow früher einmal installiert hattest, dann gilt er für die alte Fassung und wirkt nicht. In dem Fall den Eintrag mit dem Minus-Knopf entfernen und die App neu starten, dann kommt die Abfrage wieder.
2. Die App **einmal beenden und neu starten**: auf das O.C. in der Menüleiste klicken ▸ „OC Flow beenden", dann im Ordner Programme wieder öffnen.
3. Jetzt in irgendein Textfeld klicken, die **rechte ⌥-Taste** gedrückt halten und einen Satz sagen. Beim ersten Mal fragt macOS nach dem **Mikrofon** — erlauben, dann klappt es ab dem zweiten Versuch.

## Sprechtaste umstellen

Voreingestellt ist die rechte ⌥-Taste. Viele nehmen lieber **fn**. Umstellen: im O.C.-Flow-Fenster oben rechts auf das **Zahnrad**, dann unter **Sprechtaste** auf „fn" klicken. Es greift sofort, kein Neustart nötig. Der gleiche Schalter sitzt auch im Menüleisten-Menü unter „Push-to-talk key".

fn bleibt dabei normal benutzbar, also fn + Pfeiltasten, fn + Entf und der Emoji-Picker.

## Apple Intelligence einschalten

Damit die App den Text aufräumt, also Füllwörter rauswirft, Kommas setzt und Versprecher korrigiert, muss **Apple Intelligence** an sein. Klick auf das O.C. in der Menüleiste und schau auf die Zeile **Automatisch aufräumen (KI auf dem Gerät)**.

So soll es aussehen, beide Zeilen angehakt und normal lesbar:

![Menüleisten-Menü mit aktivem Aufräumen](docs/menue-aufraeumen-an.png)

Ist die Zeile stattdessen grau und darunter steht „Apple Intelligence ist in den Systemeinstellungen ausgeschaltet", dann Systemeinstellungen ▸ Apple Intelligence & Siri einschalten und zurück im Menü **Automatisch aufräumen** anhaken.

Alles rechnet auf deinem Mac, nichts geht ins Internet.

**Wenn der Text lange braucht, lass das Aufräumen aus.** Das Modell belegt rund 3 GB Arbeitsspeicher. Ist der knapp, schiebt macOS es ständig raus und lädt es wieder, und dann wartest du pro Satz mehrere Sekunden. Auf einem Mac mit 8 GB ist das gemessen der Normalfall: mit Aufräumen 11 bis 23 Sekunden pro Satz, ohne Aufräumen 0,2 Sekunden. Auf einem Mac mit 16 GB haben wir es ausprobiert, dort kommt der Text ohne merkliche Wartezeit.

Deshalb der Test, der zählt: diktiere einen Satz und schau auf die Uhr. Ist der Text nach einer guten Sekunde da, lass **Automatisch aufräumen** an. Dauert es länger, hak es ab. Du verlierst dabei nur das Feinschliff-Aufräumen, Satzzeichen und die Wörterbuch-Korrekturen macht die App weiterhin. Wie viel Speicher dein Mac hat, steht unter Apfelmenü ▸ Über diesen Mac.

## Neue Version holen

Es gibt keine automatische Aktualisierung. Wenn Yassine sagt, es gibt was Neues, im Terminal:

```bash
cd ~/OC-Flow && git pull && make install
```

Ein bis zwei Minuten, danach läuft alles weiter wie vorher. Neu erlauben musst du nichts, dafür sorgt das Zertifikat aus Schritt 3.

**Falls du die App installiert hast, als es den Zertifikat-Schritt noch nicht gab:** dann reagiert die Sprechtaste nach dem Update nicht mehr, weil macOS die App als eine neue ansieht. Einmal nachholen, danach ist Ruhe:

```bash
cd ~/OC-Flow && bash Tools/create-signing-cert.sh && make install
```

Anschließend die Berechtigung ein letztes Mal erteilen: Systemeinstellungen ▸ Datenschutz & Sicherheit ▸ Bedienungshilfen. Steht **OC Flow** dort noch in der Liste, mit dem Minus-Knopf entfernen, dann die App beenden und aus dem Ordner Programme neu öffnen. Die Abfrage kommt wieder, dort erlauben.

## Fertig

Ab jetzt überall: Sprechtaste halten, sprechen, loslassen.

**Hakt etwas?** In der [README](README.md) steht unter „Wenn etwas hakt", was zu tun ist — oder frag Yassine.
