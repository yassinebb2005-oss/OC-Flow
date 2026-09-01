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

Diese drei Befehle nacheinander einfügen, nach jedem Enter drücken:

```bash
git clone https://github.com/yassinebb2005-oss/OC-Flow.git
```

```bash
cd OC-Flow
```

```bash
make install
```

Der letzte Befehl arbeitet ein paar Minuten. Am Ende startet O.C. Flow von selbst und oben in der Menüleiste erscheint ein kleines O.C.

## Schritt 4: Zwei Berechtigungen erteilen

1. Es öffnet sich eine Abfrage für die **Bedienungshilfen** — falls nicht: Systemeinstellungen ▸ Datenschutz & Sicherheit ▸ Bedienungshilfen. Dort **OC Flow** einschalten.
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

## Fertig

Ab jetzt überall: Sprechtaste halten, sprechen, loslassen.

**Hakt etwas?** In der [README](README.md) steht unter „Wenn etwas hakt", was zu tun ist — oder frag Yassine.
