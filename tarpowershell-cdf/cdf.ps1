function cdf {
    <#
    .SYNOPSIS
    Waehlt einen der letzten zehn einfachen Ordnerwechsel aus dem PSReadLine-Verlauf.
    .DESCRIPTION
    Relative Pfade beziehen sich auf den aktuellen Ordner. Verlauf wird niemals
    als Code ausgefuehrt. Variablen, Parameter und zusammengesetzte Befehle werden
    absichtlich nicht unterstuetzt.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command Out-GridView -ErrorAction SilentlyContinue)) {
        throw 'Out-GridView fehlt. cdf benoetigt PowerShell unter Windows mit grafischer Oberflaeche.'
    }
    if (-not (Get-Command Get-PSReadLineOption -ErrorAction SilentlyContinue)) {
        throw 'PSReadLine fehlt. Bitte zuerst Import-Module PSReadLine ausfuehren.'
    }

    $historyPath = (Get-PSReadLineOption).HistorySavePath
    if (-not (Test-Path -LiteralPath $historyPath -PathType Leaf)) {
        Write-Warning 'Noch kein gespeicherter PSReadLine-Verlauf vorhanden.'
        return
    }

    $entries = @(foreach ($line in (Get-Content -LiteralPath $historyPath -ErrorAction Stop)) {
        if ($line -notmatch '^\s*(cd|chdir|sl|Set-Location)\s+') { continue }
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $line, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0 -or $ast.EndBlock.Statements.Count -ne 1) { continue }
        $pipeline = $ast.EndBlock.Statements[0]
        if ($pipeline -isnot [System.Management.Automation.Language.PipelineAst] -or
            $pipeline.PipelineElements.Count -ne 1) { continue }
        $command = $pipeline.PipelineElements[0]
        if ($command -isnot [System.Management.Automation.Language.CommandAst] -or
            $command.CommandElements.Count -ne 2 -or $command.Redirections.Count -ne 0 -or
            $command.GetCommandName() -notin @('cd', 'chdir', 'sl', 'Set-Location')) { continue }
        $argument = $command.CommandElements[1]
        if ($argument -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            $path = $argument.Value
        } elseif ($argument -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -and
                  $argument.NestedExpressions.Count -eq 0) {
            $path = $argument.Value
        } else { continue }
        if ([string]::IsNullOrWhiteSpace($path) -or $path.StartsWith('-')) { continue }
        [pscustomobject]@{ Ordner = $path; Befehl = $line }
    })

    if ($entries.Count -eq 0) {
        Write-Warning 'Keine unterstuetzten Ordnerwechsel im gespeicherten Verlauf gefunden.'
        return
    }
    $selection = $entries | Select-Object -Last 10 |
        Out-GridView -Title 'cdf: Ordner waehlen (relative Pfade ab aktuellem Ordner)' -OutputMode Single
    if ($null -ne $selection) {
        Set-Location -LiteralPath $selection.Ordner -ErrorAction Stop
    }
}
