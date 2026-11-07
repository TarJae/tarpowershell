# cdf – Besuchte Ordner direkt auswählen

```powershell
. 'D:\Projekte\tarpowershell\tarpowershell-cdf\cdf.ps1'
cdf
```

Eintrag im Fenster auswählen und mit **OK** bestätigen oder doppelklicken.
Abbrechen lässt den aktuellen Ordner unverändert.

## Vollständige Pfade statt relativer Verlaufseinträge

Nach dem Laden erfasst `cdf` den aktuellen Dateisystemordner beim Anzeigen
des nächsten PowerShell-Prompts. Der vorhandene Prompt wird dabei einmalig
umschlossen und weiterhin aufgerufen. `cd`, `Set-Location` und deren Aliase
werden nicht verändert. Eine spätere komplette Neudefinition von `prompt`
(z. B. durch ein Theme) kann die Erfassung deaktivieren; deshalb die Ladezeile
nach der Prompt-/Theme-Initialisierung ins Profil setzen.

Beispiel:

```powershell
cd 'D:\Persoenlich'
cd '.\Diogenes und Ich'
# Sobald der nächste Prompt erscheint, ist der vollständige Pfad gespeichert.
cd 'C:\Users'
cdf
# D:\Persoenlich\Diogenes und Ich direkt auswählen – kein Zwischenstopp nötig.
```

## Verhalten und Grenzen

- Eine eigene Liste ersetzt den PSReadLine-Befehlsverlauf; PSReadLine ist nicht
  mehr erforderlich. Alte relative Einträge werden nicht übernommen.
- Bis zu 100 eindeutige vollständige Pfade werden lokal gespeichert unter
  `%LOCALAPPDATA%\tarpowershell\cdf\folders.json`.
- Die Auswahl zeigt die letzten zehn noch vorhandenen Ordner, ältester zuerst.
  Der aktuelle Ordner kann ebenfalls enthalten sein. Erneute Besuche rücken
  einen Ordner ans Ende; wiederholte Prompts am selben Ort ändern nichts.
- Auch Ordner mit Leerzeichen, Umlauten und eckigen Klammern funktionieren.
- Erfasst werden tatsächlich erreichte Dateisystemorte beim Prompt und bei
  `cdf`. Zwischenstopps innerhalb eines Skripts oder einer einzigen Befehlszeile
  ohne Prompt werden nicht erfasst. Registry- und andere Provider entfallen.
- Verschwundene Ordner werden nicht angeboten. Wird ein Ordner erst nach dem
  Öffnen der Auswahl gelöscht, kann der Wechsel weiterhin einen Fehler melden.
- Netzlaufwerke und UNC-Pfade können bei der Erreichbarkeitsprüfung warten.
- Mehrere PowerShell-Fenster teilen dieselbe Datei. Gleichzeitige Schreibvorgänge
  werden nicht zusammengeführt; dabei kann ein gerade gespeicherter Besuch
  verloren gehen. Pro Schreibvorgang wird eine temporäre Datei umbenannt.
- Fehler beim Speichern verhindern nicht den bisherigen Prompt; pro Sitzung
  erscheint höchstens eine entsprechende Warnung. Ungültiges JSON wird nicht
  automatisch überschrieben. `cdf` selbst meldet Speicherfehler ausdrücklich.
- Erneutes Laden installiert keinen zweiten Prompt-Wrapper.
- Benötigt Windows mit grafischer Sitzung und `Out-GridView`.
- Keine Ausführung gespeicherter Pfade als Code, keine Datenübertragung.

## Aktualisieren und zurücksetzen

Die bisherige Ladezeile im Profil bleibt unverändert. Nach einem Update:

```powershell
. $PROFILE
```

Die zuverlässige Ordnerliste baut sich erst mit künftigen Besuchen auf.
Persönliche Pfade gehören nicht ins Git-Repository.

Zum Leeren der Liste (oder nach einer beschädigten JSON-Datei) die lokale
Datei löschen und eine neue PowerShell-Sitzung starten:

```powershell
Remove-Item -LiteralPath "$env:LOCALAPPDATA\tarpowershell\cdf\folders.json" -ErrorAction SilentlyContinue
```

Installation ins PowerShell-Profil: siehe [zentrale README](../README.md).
