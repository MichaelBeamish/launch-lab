<#
.SYNOPSIS
  Checks that the stock physics-relevant tags Launch Lab relies on are unmodified (ADR 0002).

.DESCRIPTION
  Hashes (SHA-256) a fixed list of stock H1A-EK tags and compares them with tools\stock-tag-hashes.json.
  Run without arguments to check; run with -Record to (re)write the baseline (only when the owner agrees,
  e.g. after a mod tools update that legitimately changed stock tags, recorded in docs/research/toolchain-baseline.md).

  The tags are read, never written. Only paths and hashes are stored, no game content (ADR 0003).

.PARAMETER Record
  Write the baseline instead of checking against it.

.PARAMETER TagsRoot
  Override the tags folder (default: <ToolsRoot>\tags from tools\local.config.ps1). Used to self-test the check
  against copies. Can't be combined with -Record, so a test copy can never become the baseline.

.EXAMPLE
  powershell -File tools\stock-baseline.ps1
  Exit code 0 = all tags match; 1 = a tag is changed or missing; 2 = setup problem.
#>
param(
    [switch]$Record,
    [string]$TagsRoot
)

$ErrorActionPreference = 'Stop'

# Exit codes are a contract: 1 means a stock tag differs, so any unexpected error must be a setup problem (2).
trap {
    Write-Host "Setup problem: $_" -ForegroundColor Red
    exit 2
}

if ($Record -and $TagsRoot) {
    Write-Host "-Record can't be combined with -TagsRoot: the baseline must come from the real stock tags." -ForegroundColor Red
    exit 2
}

# Stock tags whose values define the physics we treat as authentic. Relative to the tags folder.
$StockTags = @(
    'vehicles\warthog\warthog.vehicle'
    'vehicles\warthog\warthog.physics'
    'vehicles\warthog\warthog.model_collision_geometry'
    'weapons\frag grenade\frag grenade.projectile'
    'weapons\frag grenade\explosion.damage_effect'
    'weapons\frag grenade\shock wave.damage_effect'
    'weapons\frag grenade\effects\explosion.effect'
    'globals\globals.globals'
)

$BaselineFile = Join-Path $PSScriptRoot 'stock-tag-hashes.json'
$ConfigFile = Join-Path $PSScriptRoot 'local.config.ps1'

$ToolsBuildId = $null
if (-not $TagsRoot) {
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Missing tools\local.config.ps1. Create it with:" -ForegroundColor Red
        Write-Host '  $LaunchLab = @{ ToolsRoot = ''<mod tools folder>''; GameRoot = ''<MCC folder>'' }'
        exit 2
    }
    . $ConfigFile
    if (-not $LaunchLab -or -not $LaunchLab.ToolsRoot) {
        Write-Host "tools\local.config.ps1 doesn't set `$LaunchLab.ToolsRoot." -ForegroundColor Red
        exit 2
    }
    $TagsRoot = Join-Path $LaunchLab.ToolsRoot 'tags'
    # Steam's manifest for the mod tools (app 1532190) sits two folders above the install folder.
    $Manifest = Join-Path $LaunchLab.ToolsRoot '..\..\appmanifest_1532190.acf'
    if (Test-Path $Manifest) {
        $m = Select-String -Path $Manifest -Pattern '"buildid"\s+"(\d+)"' | Select-Object -First 1
        if ($m) { $ToolsBuildId = $m.Matches[0].Groups[1].Value }
    }
}
if (-not (Test-Path $TagsRoot)) {
    Write-Host "Tags folder not found: $TagsRoot (did you run the mod tools' (Extract).bat?)" -ForegroundColor Red
    exit 2
}

$Current = [ordered]@{}
foreach ($tag in $StockTags) {
    $path = Join-Path $TagsRoot $tag
    if (Test-Path -LiteralPath $path) {
        $Current[$tag] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    } else {
        $Current[$tag] = $null
    }
}

if ($Record) {
    $missing = @($Current.Keys | Where-Object { -not $Current[$_] })
    if ($missing.Count) {
        Write-Host "Cannot record: missing tags: $($missing -join ', ')" -ForegroundColor Red
        exit 1
    }
    $data = [ordered]@{
        recorded     = (Get-Date -Format 'yyyy-MM-dd')
        toolsBuildId = $ToolsBuildId
        algorithm    = 'SHA256'
        tags         = $Current
    }
    # UTF-8 without BOM, LF line endings, so the file diffs cleanly.
    $json = ($data | ConvertTo-Json -Depth 3) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($BaselineFile, $json + "`n", (New-Object Text.UTF8Encoding $false))
    Write-Host "Recorded $($Current.Count) stock tag hashes to tools\stock-tag-hashes.json (tools build $ToolsBuildId)." -ForegroundColor Green
    exit 0
}

if (-not (Test-Path $BaselineFile)) {
    Write-Host "No baseline yet: run with -Record first." -ForegroundColor Red
    exit 2
}
$Baseline = Get-Content $BaselineFile -Raw | ConvertFrom-Json

if ($ToolsBuildId -and $Baseline.toolsBuildId -and $ToolsBuildId -ne $Baseline.toolsBuildId) {
    Write-Host "Note: mod tools build is $ToolsBuildId; the baseline was recorded on $($Baseline.toolsBuildId). A tools update may change stock tags." -ForegroundColor Yellow
}

$failures = 0
foreach ($tag in $StockTags) {
    $expected = $Baseline.tags.$tag
    $actual = $Current[$tag]
    if (-not $expected) {
        Write-Host "  NOT IN BASELINE  $tag" -ForegroundColor Red; $failures++
    } elseif (-not $actual) {
        Write-Host "  MISSING          $tag" -ForegroundColor Red; $failures++
    } elseif ($actual -ne $expected) {
        Write-Host "  CHANGED          $tag" -ForegroundColor Red; $failures++
    } else {
        Write-Host "  ok               $tag"
    }
}
# A tag in the baseline that the list no longer checks would silently lose its protection.
foreach ($tag in $Baseline.tags.PSObject.Properties.Name) {
    if ($StockTags -notcontains $tag) {
        Write-Host "  NOT CHECKED      $tag (in the baseline but missing from `$StockTags)" -ForegroundColor Red; $failures++
    }
}

if ($failures) {
    Write-Host "FAIL: $failures stock tag(s) differ from the baseline. Stock physics may have changed (ADR 0002)." -ForegroundColor Red
    exit 1
}
Write-Host "PASS: all $($StockTags.Count) stock tags match the baseline." -ForegroundColor Green
exit 0
