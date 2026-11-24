<#
.SYNOPSIS
  Builds the Launch Lab level: geometry (Blender -> JMS), BSP, lightmaps and the .map, failing on any error.

.DESCRIPTION
  Steps, in order (run one with -Step, or all):
    jms        art\launch_lab_arena.py in headless Blender -> mod\data\levels\launch_lab\models\launch_lab.JMS
    structure  sync push, then: tool structure levels\launch_lab launch_lab
               (first run also creates tags\levels\launch_lab\launch_lab.scenario; then run sync pull)
    lightmaps  tool lightmaps levels\launch_lab\launch_lab launch_lab <quality> <stop>   (default 0 0.3: fast draft)
    cache      tool build-cache-file levels\launch_lab\launch_lab classic none  -> <tools>\maps\launch_lab.map
  Tool usage strings were read from the installed tool.exe (task 3).

  A step fails if the program exits non-zero, prints an error/exception/assert line, or Tool writes a .wrl file
  (its report of broken geometry). The full output of each step is saved to build-logs\ (git-ignored).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Step all
#>
param(
    [ValidateSet('jms', 'structure', 'lightmaps', 'cache', 'all')][string]$Step = 'all',
    [ValidateSet('0', '1')][string]$LightmapQuality = '0',
    [string]$LightmapStop = '0.3'
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

$steps = if ($Step -eq 'all') { 'jms', 'structure', 'lightmaps', 'cache' } else { @($Step) }
foreach ($s in $steps) {
    switch ($s) {
        'jms' {
            New-Item -ItemType Directory -Force (Split-Path $Jms) | Out-Null
            Invoke-Step 'jms' $LaunchLab.Blender @('--background', '--python', (Join-Path $Repo 'art\launch_lab_arena.py'), '--', $Jms) $Repo
        }
        'structure' {
            & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') push
            if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync push" -ForegroundColor Red; exit 1 }
            Invoke-Step 'structure' $Tool @('structure', 'levels\launch_lab', 'launch_lab') $LaunchLab.ToolsRoot
            # On a first import Tool creates the scenario in the tools folder; bring it into the repo straight away.
            # (Re-importing doesn't modify an existing scenario: seen in task 3, scenario unchanged after rebuilds.)
            if (-not (Test-Path (Join-Path $Repo 'mod\tags\levels\launch_lab\launch_lab.scenario'))) {
                & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') pull
                if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync pull" -ForegroundColor Red; exit 1 }
            }
        }
        'lightmaps' {
            Invoke-Step 'lightmaps' $Tool @('lightmaps', 'levels\launch_lab\launch_lab', 'launch_lab', $LightmapQuality, $LightmapStop) $LaunchLab.ToolsRoot
        }
        'cache' {
            Invoke-Step 'cache' $Tool @('build-cache-file', 'levels\launch_lab\launch_lab', 'classic', 'none') $LaunchLab.ToolsRoot
        }
    }
}
Write-Host "Build finished: $($steps -join ', ')." -ForegroundColor Green
