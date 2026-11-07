function Get-TarCdfHistoryPath {
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        throw 'cdf: LOCALAPPDATA ist nicht gesetzt.'
    }
    Join-Path $env:LOCALAPPDATA 'tarpowershell\cdf\folders.json'
}

function Get-TarCdfFolderHistory {
    $file = Get-TarCdfHistoryPath
    if (Test-Path -LiteralPath $file) {
        # Invalid JSON is reported, not silently overwritten.
        $items = Get-Content -LiteralPath $file -Raw -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop
        foreach ($item in $items) {
            if ($item -is [string] -and $item -match '^(?:[a-zA-Z]:\\|\\\\[^\\]+\\[^\\]+)') {
                $item
            }
        }
    }
}

function Save-TarCdfCurrentFolder {
    $location = Get-Location
    if ($location.Provider.Name -ne 'FileSystem') { return }
    $path = $location.ProviderPath
    if ($global:TarCdfState.LastPath -eq $path) { return }

    $file = Get-TarCdfHistoryPath
    $folders = @(Get-TarCdfFolderHistory | Where-Object { $_ -ne $path }) + @($path)
    $folders = @($folders | Select-Object -Last 100)
    $directory = Split-Path -Parent $file
    [void][System.IO.Directory]::CreateDirectory($directory)
    $temporary = Join-Path $directory ([guid]::NewGuid().ToString() + '.tmp')
    try {
        ConvertTo-Json -InputObject $folders |
            Set-Content -LiteralPath $temporary -Encoding UTF8 -ErrorAction Stop
        Move-Item -LiteralPath $temporary -Destination $file -Force -ErrorAction Stop
        $global:TarCdfState.LastPath = $path
    } finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
        }
    }
}

function cdf {
    <#
    .SYNOPSIS
    Waehlt einen der letzten zehn besuchten Ordner anhand vollstaendiger Pfade.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command Out-GridView -ErrorAction SilentlyContinue)) {
        throw 'Out-GridView fehlt. cdf benoetigt PowerShell unter Windows mit grafischer Oberflaeche.'
    }
    Save-TarCdfCurrentFolder
    $folders = @(Get-TarCdfFolderHistory | Where-Object {
        Test-Path -LiteralPath $_ -PathType Container
    } | Select-Object -Last 10)
    if ($folders.Count -eq 0) {
        Write-Warning 'Noch keine erreichbaren Ordner gespeichert.'
        return
    }
    $selection = $folders | ForEach-Object { [pscustomobject]@{ Ordner = $_ } } |
        Out-GridView -Title 'cdf: Letzte Ordner (vollstaendige Pfade)' -OutputMode Single
    if ($null -ne $selection) {
        Set-Location -LiteralPath $selection.Ordner -ErrorAction Stop
        Save-TarCdfCurrentFolder
    }
}

# Wrap the existing prompt once. Do not replace cd/Set-Location or read command history.
if (-not (Get-Variable -Name TarCdfState -Scope Global -ErrorAction SilentlyContinue)) {
    $global:TarCdfState = @{
        OriginalPrompt = (Get-Command prompt -CommandType Function -ErrorAction Stop).ScriptBlock
        LastPath = $null
        WarningShown = $false
    }
    function global:prompt {
        $savedExitCode = $global:LASTEXITCODE
        try {
            & $global:TarCdfState.OriginalPrompt
        } finally {
            try {
                Save-TarCdfCurrentFolder
            } catch {
                if (-not $global:TarCdfState.WarningShown) {
                    Write-Warning "cdf: Ordnerliste konnte nicht gespeichert werden: $_"
                    $global:TarCdfState.WarningShown = $true
                }
            }
            $global:LASTEXITCODE = $savedExitCode
        }
    }
}
