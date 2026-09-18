# Installation per Claude Code

Wer Claude Code auf dem Mac hat, kann sich O.C. Flow einrichten lassen, statt die Befehle selbst einzutippen. Den Text unten komplett kopieren, in Claude Code einfügen, Enter.

Danach bleiben trotzdem drei Handgriffe am Menschen hängen: zwei Passwort-Fenster wegklicken und die Berechtigungen erteilen. Claude Code sagt jeweils Bescheid, wann es soweit ist.

---

Installiere mir bitte O.C. Flow auf diesem Mac, eine Diktier-App. Antworte auf Deutsch und
erkläre alles in Alltagssprache, ich bin kein Entwickler. Zeig mir keine Fehlermeldungen im
Rohzustand, sondern sag mir in einem Satz, was los ist und was ich tun soll.

Quelle: https://github.com/yassinebb2005-oss/OC-Flow

Geh so vor und halte die Reihenfolge ein:

1. Prüf mit `sw_vers`, ob macOS 26 oder neuer läuft. Ist es älter, brich ab und sag mir, dass
   die App erst ab macOS 26 läuft und ich zuerst aktualisieren muss.

2. Prüf mit `xcode-select -p`, ob Apples Entwickler-Werkzeuge da sind. Fehlen sie, starte
   `xcode-select --install` und sag mir, dass ich im Fenster auf „Installieren" klicken und
   dir Bescheid geben soll, wenn es fertig ist. Warte dann auf mich.

3. Lösch einen eventuell vorhandenen Ordner `~/OC-Flow` und klon das Repo frisch dorthin.

4. Sag mir, dass jetzt ein Passwort-Fenster aufgeht, und führ dann
   `bash Tools/create-signing-cert.sh` aus. Das legt ein kostenloses Zertifikat an, damit ich
   die Berechtigung aus Schritt 7 nur ein einziges Mal erteilen muss. Fragt das Skript im
   Terminal nach einem Passwort, sag mir das, ich tippe es selbst ein.

5. Sag mir, dass der Schlüsselbund gleich fragt, ob „codesign" den Schlüssel benutzen darf,
   und dass ich dort auf „Immer erlauben" klicken soll. Führ dann `make install` aus. Das
   dauert ein paar Minuten.

6. Lies mit `sysctl -n hw.memsize` den Arbeitsspeicher aus. Sind es 8 GB oder weniger, sag
   mir deutlich: Ich soll im Menüleisten-Menü „Automatisch aufräumen (KI auf dem Gerät)"
   ausschalten, sonst warte ich pro Satz über zehn Sekunden auf meinen Text. Sind es mehr,
   sag mir, dass ich es anlassen kann.

7. Zum Schluss erklär mir, was ich jetzt selbst tun muss, in genau dieser Reihenfolge:
   - In den Systemeinstellungen unter Datenschutz & Sicherheit ▸ Bedienungshilfen den Eintrag
     „OC Flow" einschalten. Öffne mir diese Seite mit
     `open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"`.
   - Die App einmal beenden (O.C. in der Menüleiste ▸ „OC Flow beenden") und aus dem Ordner
     Programme neu öffnen.
   - In ein Textfeld klicken, die rechte ⌥-Taste halten, einen Satz sagen, loslassen. Beim
     ersten Mal fragt macOS nach dem Mikrofon, das erlauben.

Diese drei Dinge kannst du nicht für mich tun, ich muss sie selbst klicken. Sag mir am Ende
klar, dass der Rest bei mir liegt, und bleib erreichbar, falls etwas nicht klappt.
