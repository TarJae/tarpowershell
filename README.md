# tarpowershell

Persönliche Sammlung wiederverwendbarer PowerShell-Befehle von TarJae.
Jeder Befehl liegt in einem eigenen Unterordner.

## Befehle

| Befehl | Zweck |
| --- | --- |
| [`cdf`](tarpowershell-cdf/) | Einen der letzten zehn einfachen Ordnerwechsel aus dem gespeicherten Verlauf im Auswahlfenster auswählen. |

## Lokal laden

Windows PowerShell 5.1 oder PowerShell 7 unter Windows mit `Out-GridView` und PSReadLine:

```powershell
. 'D:\Projekte\tarpowershell\tarpowershell-cdf\cdf.ps1'
cdf
```

Der Punkt vor dem Skriptpfad ist wichtig (Dot-Sourcing): So wechselt `cdf`
den Ordner deiner aktuellen PowerShell-Sitzung.

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

Die Tests verwenden einen künstlichen Verlauf und ersetzen das Auswahlfenster.
Die tatsächliche grafische Bedienung muss interaktiv getestet werden.

## Datenschutz

Nur Quellcode und Dokumentation gehören in dieses öffentliche Repository.
Persönlicher PowerShell-Verlauf, Profile, Zugangsdaten und lokale Laufdaten
werden nicht mitgeliefert. `cdf` liest den Verlauf ausschließlich lokal und
führt dessen Inhalte niemals als Code aus.
