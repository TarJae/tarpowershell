# cdf – Ordner aus dem Verlauf auswählen

```powershell
. 'D:\Projekte\tarpowershell\tarpowershell-cdf\cdf.ps1'
cdf
```

Eintrag im Fenster auswählen und mit **OK** bestätigen oder doppelklicken.
Abbrechen lässt den aktuellen Ordner unverändert.

## Verhalten und Grenzen

- Quelle ist die gespeicherte PSReadLine-Historie, auch aus früheren Sitzungen.
  Noch nicht gespeicherte Befehle erscheinen gegebenenfalls erst später.
- Angezeigt werden die letzten zehn unterstützten Ordnerwechsel in
  chronologischer Reihenfolge. Doppelte Einträge bleiben erhalten.
- Unterstützt: `cd`, `chdir`, `sl`, `Set-Location` mit genau einem einfachen
  Pfadargument, auch in einfachen oder doppelten Anführungszeichen.
- Beispiele: `cd D:\Projekte`, `cd 'D:\Meine Projekte'`, `cd ..`.
- Relative Pfade wie `..` werden vom **jetzigen** Ordner aus aufgelöst.
  Der damalige Ausgangsordner lässt sich aus dem Befehlsverlauf nicht zuverlässig
  rekonstruieren. Dies ist keine Liste nachweislich besuchter Ordner: Auch
  fehlgeschlagene Befehle können im Verlauf stehen.
- Variablen wie `$HOME`, Ausdrücke, zusätzliche Parameter, mehrere Befehle
  pro Zeile und mehrzeilige Befehle werden nicht unterstützt.
- Nicht mehr vorhandene Zielordner melden beim Wechsel einen Fehler.
- Benötigt Windows mit grafischer Sitzung, `Out-GridView` und PSReadLine.
- Keine Ausführung von Verlaufstext mittels `Invoke-Expression`.

Installation ins PowerShell-Profil: siehe [zentrale README](../README.md).
