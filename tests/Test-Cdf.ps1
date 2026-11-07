$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\tarpowershell-cdf\cdf.ps1')

function Assert-True($Condition, $Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message"
}

$originalLocation = Get-Location
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('tarpowershell-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
$script:historyFile = Join-Path $temp 'synthetic-history.txt'
$script:cancel = $false
$script:shown = @()

# Test doubles: no real history and no interactive UI.
function Get-PSReadLineOption {
    [pscustomobject]@{ HistorySavePath = $script:historyFile }
}
function Out-GridView {
    param([Parameter(ValueFromPipeline)]$InputObject, $Title, $OutputMode)
    begin { $items = @() }
    process { $items += $InputObject }
    end {
        $script:shown = $items
        if (-not $script:cancel) { $items | Select-Object -Last 1 }
    }
}

try {
    $target = Join-Path $temp 'folder [literal] with spaces'
    New-Item -ItemType Directory -Path $target | Out-Null
    Set-Content -LiteralPath $script:historyFile -Value @(
        'Get-Date'
        "cd '$target'"
        'cd $HOME'
        'cd $(throw "must never execute")'
        'cd .; throw "must never execute"'
        'cd . | Write-Output'
        'cd -Path .'
        'cd . > unwanted.txt'
    )
    cdf
    Assert-True ($script:shown.Count -eq 1) 'Unsupported expressions and compound commands excluded'
    Assert-True ((Get-Location).Path -eq $target) 'Quoted path with spaces and brackets selected literally'

    $lines = @(1..12 | ForEach-Object { "cd 'folder$_'" })
    $lines += "Set-Location `"$target`""
    Set-Content -LiteralPath $script:historyFile -Value $lines
    cdf
    Assert-True ($script:shown.Count -eq 10) 'Exactly the last ten supported entries shown'
    Assert-True ($script:shown[0].Ordner -eq 'folder4') 'Oldest entries removed in chronological order'
    Assert-True ((Get-Location).Path -eq $target) 'Double-quoted Set-Location path supported'

    $script:cancel = $true
    Set-Location -LiteralPath $temp
    cdf
    Assert-True ((Get-Location).Path -eq $temp) 'Cancel leaves location unchanged'
    $script:cancel = $false

    Set-Content -LiteralPath $script:historyFile -Value "sl 'folder [literal] with spaces'"
    cdf
    Assert-True ((Get-Location).Path -eq $target) 'Relative path resolved from current directory'

    Set-Content -LiteralPath $script:historyFile -Value @('Get-Date', 'cd $HOME')
    $script:shown = @()
    cdf -WarningAction SilentlyContinue
    Assert-True ($script:shown.Count -eq 0) 'Empty supported history does not open window'

    Remove-Item -LiteralPath $script:historyFile
    cdf -WarningAction SilentlyContinue
    Assert-True ((Get-Location).Path -eq $target) 'Missing history leaves location unchanged'

    Set-Content -LiteralPath $script:historyFile -Value "chdir '$temp\missing'"
    $failed = $false
    try { cdf } catch { $failed = $true }
    Assert-True $failed 'Missing target produces an error'
    Write-Host 'All cdf tests passed.'
} finally {
    Set-Location -LiteralPath $originalLocation.Path
    Remove-Item -LiteralPath $temp -Recurse -Force
}
