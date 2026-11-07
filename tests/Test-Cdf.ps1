$ErrorActionPreference = 'Stop'
function Assert-True($Condition, $Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message"
}

$originalLocation = Get-Location
$originalLocalAppData = $env:LOCALAPPDATA
$originalPrompt = (Get-Command prompt).ScriptBlock
$originalState = Get-Variable TarCdfState -Scope Global -ErrorAction SilentlyContinue
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('tarpowershell-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
$script:cancel = $false
$script:shown = @()
$script:choose = $null
$source = Join-Path $PSScriptRoot '..\tarpowershell-cdf\cdf.ps1'

function Out-GridView {
    param([Parameter(ValueFromPipeline)]$InputObject, $Title, $OutputMode)
    begin { $items = @() }
    process { $items += $InputObject }
    end {
        $script:shown = $items
        if (-not $script:cancel) {
            $items | Where-Object Ordner -EQ $script:choose | Select-Object -First 1
        }
    }
}

try {
    $env:LOCALAPPDATA = $temp
    Remove-Variable TarCdfState -Scope Global -ErrorAction SilentlyContinue
    function global:prompt { 'original prompt> ' }
    . $source
    Assert-True (-not (Test-Path -LiteralPath (Get-TarCdfHistoryPath))) 'Loading alone does not write personal folders'
    $global:LASTEXITCODE = 37
    $output = prompt
    Assert-True ($output -eq 'original prompt> ') 'Existing prompt output preserved'
    Assert-True ($global:LASTEXITCODE -eq 37) 'Native exit code preserved'
    Assert-True (Test-Path -LiteralPath (Get-TarCdfHistoryPath)) 'Prompt creates local folder storage'
    Assert-True ((Get-TarCdfHistoryPath).StartsWith($temp)) 'Test data stays outside repository'

    $parent = Join-Path $temp 'Persoenlich'
    $target = Join-Path $parent 'Diogenes und Ich [test]'
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Set-Location -LiteralPath $parent
    $null = prompt
    Set-Location -LiteralPath '.\Diogenes und Ich [test]'
    $null = prompt
    Assert-True (@(Get-TarCdfFolderHistory) -contains $target) 'Relative visit saved as an absolute literal path'

    Set-Location -LiteralPath $temp
    $null = prompt
    $script:choose = $target
    cdf
    Assert-True ((Get-Location).ProviderPath -eq $target) 'cdf reaches target from a different parent'
    Assert-True (@(Get-TarCdfFolderHistory)[-1] -eq $target) 'cdf selection becomes most recent visit'

    $before = @(Get-TarCdfFolderHistory).Count
    $null = prompt
    $null = prompt
    Assert-True (@(Get-TarCdfFolderHistory).Count -eq $before) 'Repeated prompts do not duplicate folders'

    $script:cancel = $true
    cdf
    Assert-True ((Get-Location).ProviderPath -eq $target) 'Cancel leaves location unchanged'
    $script:cancel = $false

    foreach ($index in 1..12) {
        $folder = Join-Path $temp "folder$index"
        New-Item -ItemType Directory -Path $folder | Out-Null
        Set-Location -LiteralPath $folder
        $null = prompt
    }
    $script:cancel = $true
    cdf
    Assert-True ($script:shown.Count -eq 10) 'Only ten recent unique existing folders shown'
    Assert-True ($script:shown[0].Ordner -eq (Join-Path $temp 'folder3')) 'Selection ordered oldest to newest'

    $last = (Get-TarCdfFolderHistory | Select-Object -Last 1)
    Remove-Item -LiteralPath (Join-Path $temp 'folder3') -Force
    cdf
    Assert-True (@($script:shown.Ordner) -notcontains (Join-Path $temp 'folder3')) 'Deleted folders not offered'

    $wrappedPrompt = (Get-Command prompt).Definition
    . $source
    Assert-True ((Get-Command prompt).Definition -eq $wrappedPrompt) 'Reload does not wrap prompt twice'
    Assert-True ((prompt) -eq 'original prompt> ') 'Original prompt still works after reload'

    Push-Location HKCU:\
    try {
        $null = prompt
        Assert-True ((Get-TarCdfFolderHistory | Select-Object -Last 1) -eq $last) 'Registry locations not recorded'
    } finally { Pop-Location }

    # Emulate a fresh session: reset only the in-memory location cache.
    $global:TarCdfState.LastPath = $null
    Assert-True (@(Get-TarCdfFolderHistory) -contains $target) 'Folder history survives session cache reset'

    $file = Get-TarCdfHistoryPath
    Set-Content -LiteralPath $file -Value '[".\\relative", "D:relative", "\\rootrelative"]'
    Assert-True (@(Get-TarCdfFolderHistory).Count -eq 0) 'Relative stored entries are rejected'

    Set-Content -LiteralPath $file -Value 'invalid json'
    $global:TarCdfState.LastPath = $null
    $output = prompt 3>$null
    Assert-True ($output -eq 'original prompt> ') 'Storage error does not break prompt'
    Assert-True ((Get-Content -LiteralPath $file -Raw).Trim() -eq 'invalid json') 'Corrupt storage is not overwritten'

    Write-Host 'All cdf tests passed.'
} finally {
    Set-Location -LiteralPath $originalLocation.Path
    $env:LOCALAPPDATA = $originalLocalAppData
    Set-Item Function:\global:prompt -Value $originalPrompt
    Remove-Variable TarCdfState -Scope Global -ErrorAction SilentlyContinue
    if ($null -ne $originalState) { $global:TarCdfState = $originalState.Value }
    Remove-Item -LiteralPath $temp -Recurse -Force
}
