# tarpowershell

Persönliche Sammlung wiederverwendbarer PowerShell-Befehle von TarJae.
Jeder Befehl liegt in einem eigenen Unterordner.

## Befehle

| Befehl | Zweck |
| --- | --- |
| [`cdf`](tarpowershell-cdf/) | Einen der letzten zehn besuchten Ordner anhand seines vollständigen Pfads auswählen – unabhängig vom aktuellen Standort. |

## Lokal laden

Windows PowerShell 5.1 oder PowerShell 7 unter Windows mit `Out-GridView`:

```powershell
. 'D:\Projekte\tarpowershell\tarpowershell-cdf\cdf.ps1'
cdf
```

Der Punkt vor dem Skriptpfad ist wichtig (Dot-Sourcing): So wechselt `cdf`
den Ordner deiner aktuellen PowerShell-Sitzung. Beim nächsten Prompt wird der
aktuelle Dateisystemordner automatisch lokal gespeichert. Auch relative
Ordnerwechsel werden dadurch als vollständige Pfade erfasst.

## Dauerhaft verfügbar machen

Einmal dein Profil öffnen:

```powershell
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
notepad $PROFILE
```

Diese Zeile im Profil ergänzen und speichern:

```powershell
. 'D:\Projekte\tarpowershell\tarpowershell-cdf\cdf.ps1'
```

Danach eine neue PowerShell öffnen oder `. $PROFILE` ausführen. Nun genügt `cdf`.
Windows PowerShell und PowerShell 7 haben separate Profile.
Eine eventuell vorhandene ältere `cdf`-Definition durch diese Ladezeile ersetzen.

### Update von der ersten Version

Die Ladezeile bleibt gleich. Nach einem Update `. $PROFILE` ausführen oder
PowerShell neu öffnen. Die neue Ordnerliste baut sich ab jetzt auf; alte
relative Befehle aus PSReadLine werden nicht übernommen, weil ihr ursprünglicher
Ausgangsordner unbekannt ist.

## Struktur

```text
tarpowershell/
├── README.md
├── tests/
│   └── Test-Cdf.ps1
└── tarpowershell-cdf/
    ├── README.md
    └── cdf.ps1
```

Weitere Befehle als eigene `tarpowershell-<name>/`-Ordner hinzufügen
und in der Tabelle dokumentieren.

## Tests

Ohne zusätzliche Testpakete, im Repository-Stamm:

```powershell
powershell -NoProfile -File .\tests\Test-Cdf.ps1
pwsh -NoProfile -File .\tests\Test-Cdf.ps1
```

Die Tests verwenden ausschließlich temporäre Testordner und einen isolierten
Datenspeicher; sie ersetzen das Auswahlfenster.
Die tatsächliche grafische Bedienung muss interaktiv getestet werden.

## Datenschutz

Nur Quellcode und Dokumentation gehören in dieses öffentliche Repository.
Persönlicher PowerShell-Verlauf, Profile, Zugangsdaten und lokale Laufdaten
werden nicht mitgeliefert. `cdf` speichert bis zu 100 eindeutige vollständige
Ordnerpfade ausschließlich lokal unter
`%LOCALAPPDATA%\tarpowershell\cdf\folders.json`. Es liest keinen PSReadLine-Verlauf
mehr und führt gespeicherte Inhalte niemals als Code aus.
