<#
.SYNOPSIS
  Builds the Launch Lab level: geometry (Blender -> JMS), BSP, lightmaps and the .map, failing on any error.

.DESCRIPTION
  Steps, in order (run one with -Step, or all):
    jms        art\launch_lab_arena.py in headless Blender -> mod\data\levels\launch_lab\models\launch_lab.JMS
    structure  sync push, then: tool structure levels\launch_lab launch_lab
               (first run also creates tags\levels\launch_lab\launch_lab.scenario; then run sync pull)
    lightmaps  tool lightmaps levels\launch_lab\launch_lab launch_lab <quality> <stop>   (default 0 0.3: fast draft)
    scenario   tools\scenario.ps1: placements (needed before cache: scripts reference trigger volumes and flags)
    devices    tools\devices.ps1: gameplay device tags generated from stock (ADR 0005)
    cache      tool build-cache-file levels\launch_lab\launch_lab classic none  -> <tools>\maps\launch_lab.map
  Tool usage strings were read from the installed tool.exe (task 3).

  A step fails if the program exits non-zero, prints an error/exception/assert line, or Tool writes a .wrl file
  (its report of broken geometry). The full output of each step is saved to build-logs\ (git-ignored).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Step all
#>
param(
    [ValidateSet('jms', 'structure', 'lightmaps', 'devices', 'scenario', 'cache', 'all')][string]$Step = 'all',
    [ValidateSet('0', '1')][string]$LightmapQuality = '0',
    # Draft default 0.9 (task 11): stops refining much sooner than 0.3 (8.8 min for the 3 km world in task 10).
    # For a release-quality pass use -LightmapQuality 1 -LightmapStop 0.3 (slow; overnight).
    [string]$LightmapStop = '0.9',
    # Re-run structure + lightmaps even when the geometry is unchanged.
    [switch]$Rebuild
)

$ErrorActionPreference = 'Stop'
$ConfigFile = Join-Path $PSScriptRoot 'local.config.ps1'
if (-not (Test-Path $ConfigFile)) { throw "Missing tools\local.config.ps1." }
. $ConfigFile
foreach ($k in 'ToolsRoot', 'Blender') {
    if (-not $LaunchLab -or -not $LaunchLab[$k]) { throw "tools\local.config.ps1 doesn't set `$LaunchLab.$k." }
}

$Repo = Split-Path $PSScriptRoot -Parent
$Tool = Join-Path $LaunchLab.ToolsRoot 'tool.exe'
# A missing program must fail the build, not pass with a stale exit code.
foreach ($exe in $Tool, $LaunchLab.Blender) { if (-not (Test-Path -LiteralPath $exe)) { throw "Not found: $exe (check tools\local.config.ps1)" } }
$Jms = Join-Path $Repo 'mod\data\levels\launch_lab\models\launch_lab.JMS'
$WrlDir = Join-Path $LaunchLab.ToolsRoot 'data\levels\launch_lab'
$LogDir = Join-Path $Repo 'build-logs'
New-Item -ItemType Directory -Force $LogDir | Out-Null

# Lines that mean a step failed. Tool prints e.g. "### ERROR ..." / "EXCEPTION" / "assert"; Blender prints tracebacks.
$ErrorPattern = '(?i)(\berror\b|exception|\bassert|traceback|failed)'

function Invoke-Step($name, $exe, [string[]]$arguments, $workDir) {
    Write-Host "== $name" -ForegroundColor Cyan
    Write-Host "   $([IO.Path]::GetFileName($exe)) $($arguments -join ' ')"
    $log = Join-Path $LogDir "$name.log"
    $started = Get-Date
    Push-Location $workDir
    # With 'Stop', Windows PowerShell 5.1 aborts on a program's first stderr line (Tool prints warnings there).
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    try {
        # Windows PowerShell wraps a program's stderr lines as ErrorRecords ("RemoteException"); keep only their text,
        # so the error check below sees what the program printed, not the wrapper.
        $output = & $exe @arguments 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" }
        }
        $code = $LASTEXITCODE
    } finally {
        Pop-Location
        $ErrorActionPreference = 'Stop'
    }
    $output | Set-Content -LiteralPath $log -Encoding utf8
    $errors = @($output | Where-Object { $_ -match $ErrorPattern })
    # Structure errors land next to the JMS; lightmap errors land in the tools root (seen in task 3).
    $wrlAfter = @(@(Get-ChildItem $WrlDir -Recurse -Filter *.wrl -ErrorAction SilentlyContinue) +
            @(Get-ChildItem $LaunchLab.ToolsRoot -Filter '*launch_lab*.wrl' -ErrorAction SilentlyContinue) |
            Where-Object { $_.LastWriteTime -ge $started } | ForEach-Object FullName)
    $output | Select-Object -Last 15 | ForEach-Object { Write-Host "   | $_" }
    if ($code -ne 0 -or $errors.Count -or $wrlAfter.Count) {
        Write-Host "FAIL: $name (exit $code, $($errors.Count) error line(s), $($wrlAfter.Count) new .wrl). Full log: build-logs\$name.log" -ForegroundColor Red
        $errors | Select-Object -First 10 | ForEach-Object { Write-Host "   ! $_" -ForegroundColor Red }
        $wrlAfter | ForEach-Object { Write-Host "   wrl: $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "OK: $name (exit $code). Log: build-logs\$name.log" -ForegroundColor Green
}

# devices first: the scenario references the device tags (starting weapons), and every later step loads it.
# scenario before cache: scripts reference placements (trigger volumes, flags), so they must exist when the map compiles.
$steps = if ($Step -eq 'all') { 'jms', 'devices', 'structure', 'lightmaps', 'scenario', 'cache' } else { @($Step) }

# Lighting is the slow step and is only needed when the geometry changes. Remember which JMS was last built and lit;
# in a full build, skip structure + lightmaps when the JMS is unchanged and its lit BSP is still in the tools folder.
$GeometryState = Join-Path $LogDir 'geometry-state.json'
$Bsp = Join-Path $LaunchLab.ToolsRoot 'tags\levels\launch_lab\launch_lab.scenario_structure_bsp'
function Get-JmsHash { if (Test-Path $Jms) { (Get-FileHash -LiteralPath $Jms).Hash } else { '' } }
function Get-LitHash { if (Test-Path $GeometryState) { (Get-Content $GeometryState -Raw | ConvertFrom-Json).litJms } else { '' } }
$skipGeometry = $false

foreach ($s in $steps) {
    if ($Step -eq 'all' -and $s -eq 'structure') {
        $skipGeometry = (-not $Rebuild) -and (Test-Path $Bsp) -and ((Get-JmsHash) -ne '') -and ((Get-JmsHash) -eq (Get-LitHash))
        if ($skipGeometry) { Write-Host "== structure + lightmaps: SKIPPED (geometry unchanged since the last lit build; -Rebuild to force)" -ForegroundColor Yellow }
    }
    if ($skipGeometry -and $s -in 'structure', 'lightmaps') { continue }
    switch ($s) {
        'jms' {
            New-Item -ItemType Directory -Force (Split-Path $Jms) | Out-Null
            Invoke-Step 'jms' $LaunchLab.Blender @('--background', '--python', (Join-Path $Repo 'art\launch_lab_arena.py'), '--', $Jms) $Repo
        }
        'structure' {
            & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') push
            if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync push" -ForegroundColor Red; exit 1 }
            Invoke-Step 'structure' $Tool @('structure', 'levels\launch_lab', 'launch_lab') $LaunchLab.ToolsRoot
            # Re-importing the BSP clears its lightmaps: forget the lit state until lightmaps runs again.
            Remove-Item -LiteralPath $GeometryState -ErrorAction SilentlyContinue
            # On a first import Tool creates the scenario in the tools folder; bring it into the repo straight away.
            # (Re-importing doesn't modify an existing scenario: seen in task 3, scenario unchanged after rebuilds.)
            if (-not (Test-Path (Join-Path $Repo 'mod\tags\levels\launch_lab\launch_lab.scenario'))) {
                & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') pull
                if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync pull" -ForegroundColor Red; exit 1 }
            }
        }
        'lightmaps' {
            Invoke-Step 'lightmaps' $Tool @('lightmaps', 'levels\launch_lab\launch_lab', 'launch_lab', $LightmapQuality, $LightmapStop) $LaunchLab.ToolsRoot
            # Record which geometry is now built and lit (structure always runs before lightmaps).
            [IO.File]::WriteAllText($GeometryState, (@{ litJms = (Get-JmsHash); quality = $LightmapQuality; stop = $LightmapStop } | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
        }
        'devices' {
            # Gameplay device tags generated from stock (ADR 0005); git-ignored, rebuilt here.
            Invoke-Step 'devices' 'powershell.exe' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'devices.ps1')) $Repo
        }
        'scenario' {
            Invoke-Step 'scenario' 'powershell.exe' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'scenario.ps1')) $Repo
        }
        'cache' {
            # Push scripts and tags first: when structure is skipped, nothing else has synced them.
            & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') push
            if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync push" -ForegroundColor Red; exit 1 }
            Invoke-Step 'cache' $Tool @('build-cache-file', 'levels\launch_lab\launch_lab', 'classic', 'none') $LaunchLab.ToolsRoot
        }
    }
}
Write-Host "Build finished: $($steps -join ', ')." -ForegroundColor Green
