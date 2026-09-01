# O.C. Flow

Diktieren statt tippen, in jeder App auf dem Mac. Taste gedrückt halten, sprechen, loslassen. Der aufgeräumte Text landet dort, wo gerade der Cursor steht: Mail, Slack, Word, Browser.

Alles läuft auf dem eigenen Rechner. Keine Cloud, kein Konto, keine Kosten. Die Spracherkennung kommt von macOS, das Aufräumen übernimmt Apples eingebautes Sprachmodell.

## Was du brauchst

- macOS 26 oder neuer
- Apple Intelligence eingeschaltet (Systemeinstellungen ▸ Apple Intelligence & Siri). Ohne läuft die App auch, räumt den Text aber nur nach festen Regeln auf.
- Einmalig die Entwickler-Werkzeuge von Apple. Falls `swift --version` im Terminal nichts findet:

```bash
xcode-select --install
```

## Installation

```bash
git clone https://github.com/yassinebb2005-oss/OC-Flow.git
cd OC-Flow
make install
```

`make install` baut die App, signiert sie und legt sie unter `/Applications/OC Flow.app` ab. Der erste Build dauert ein paar Minuten.

Danach zwei Berechtigungen erteilen, beide sind Pflicht:

| Berechtigung | Wo | Wofür |
|---|---|---|
| Bedienungshilfen | Systemeinstellungen ▸ Datenschutz & Sicherheit ▸ Bedienungshilfen | Die Sprechtaste erkennen und den Text einfügen |
| Mikrofon | Fragt die App beim ersten Diktat selbst | Aufnahme |

Nach dem Erteilen der Bedienungshilfen-Berechtigung die App einmal beenden und neu starten.

## Benutzen

**Rechte ⌥ gedrückt halten, sprechen, loslassen.** Das ist alles. Die Taste lässt sich in den Einstellungen ändern (rechte ⌥, fn oder rechte ⌘).

Unten am Bildschirm erscheint eine kleine Pille mit einer Linie, die auf deine Stimme reagiert. Der fertige Text landet im aktiven Textfeld.

Das Hauptfenster (Klick auf das O.C. in der Menüleiste) zeigt die letzten Aufnahmen und das Wörterbuch. Ins Wörterbuch gehören Namen und Fachbegriffe, die die Erkennung immer wieder falsch versteht, einmal eintragen, ab dann wird automatisch korrigiert.

## Was beim Aufräumen passiert

Das Diktat geht nach der Erkennung durch Apples Sprachmodell auf dem Gerät:

- Füllwörter fliegen raus (ähm, halt, quasi, sozusagen)
- Satzzeichen und Großschreibung werden gesetzt
- Selbstkorrekturen greifen: „Schick das Dienstag, ach nee, Mittwoch" wird zu „Schick das Mittwoch"
- Gesprochene Aufzählungen werden Listen
- Auseinandergerissene Komposita werden zusammengesetzt: „Kosten Voranschlag" wird zu „Kostenvoranschlag"

Antwortet das Modell nicht schnell genug, nimmt die App den Rohtext mit Regel-Aufräumen. Kein Diktat geht verloren.

## Wenn etwas hakt

**Die Sprechtaste reagiert nicht.** Meist fehlt die Bedienungshilfen-Berechtigung oder die App wurde danach nicht neu gestartet. Zeigt die Systemeinstellung den Schalter als an, obwohl nichts geht, hilft Zurücksetzen:

```bash
tccutil reset Accessibility com.oc-hairsystems.ocflow
```

Danach die Systemeinstellungen komplett beenden (⌘Q), neu öffnen und die Berechtigung neu erteilen. Wichtig: immer mit der Bundle-ID zurücksetzen, ein nacktes `tccutil reset Accessibility` löscht die Einträge sämtlicher Apps.

**„Apple Intelligence ist ausgeschaltet" im Menü.** Systemeinstellungen ▸ Apple Intelligence & Siri einschalten, kurz warten, bis das Modell geladen ist.

**Der Text landet in der falschen App.** Der Text geht immer an das Fenster mit dem Fokus. Erst ins Zielfeld klicken, dann diktieren.

## Für Entwickler

Swift 6, SwiftUI, keine externen Abhängigkeiten im Standardpfad. Die Erkennung läuft über `SpeechAnalyzer`/`SpeechTranscriber` (macOS 26), optional Parakeet v3 über FluidAudio. Das Aufräumen über das FoundationModels-Framework.

```
Sources/OCFlow/
├── Core/            Zustandsmaschine, Sprechtaste, Audio, Texteinfügung
├── Transcription/   Engine-Protokoll, Apple Speech, Parakeet
├── Formatting/      Regel-Aufräumen und LLM-Aufräumen
├── UI/              Hauptfenster, HUD, Einstellungen, Design-System
└── Support/         Settings, Berechtigungen, Logging
```

Die zwei Stellen, an denen am ehesten geschraubt wird, sind Protokolle: `TranscriptionEngine` (Erkennung austauschen) und `TextFormatter` (Aufräumen austauschen). Der Rest der App bleibt davon unberührt.

Weitere Make-Ziele: `make app` (nur bauen), `make run` (ohne Installation starten), `make clean`.
