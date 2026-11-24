<#
.SYNOPSIS
  Applies Launch Lab's scenario placements (spawn, vehicles, equipment, object names) with invader-edit (ADR 0004).

.DESCRIPTION
  The placement list below (spawns, vehicles, equipment, cutscene flags) is the source of truth. The script:
    1. syncs the repo into the tools folder (tools\sync.ps1 push; refuses if there is unpulled Sapien/Guerilla work),
    2. clears the placement blocks and writes them again from the list (so re-running never duplicates anything),
    3. reads every value back and compares it,
    4. runs Tool's check-map,
    5. pulls the scenario back into the repo (tools\sync.ps1 pull).
  Other scenario fields (type, skies, BSP reference) are left untouched.

  Units: positions in world units (1 WU = 10 ft, about 3 m); arena origin at the centre, floor at z = 0.
  Angles here are in DEGREES; invader-edit takes radians (and shows degrees), so they are converted.
  Layout reference (art\launch_lab_arena.py): the ramp runs y -12 -> 0 (x -3..3); the platform is y 8..16, 4 WU high.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\scenario.ps1
#>
$ErrorActionPreference = 'Stop'

# ---- Placements (edit these) ---------------------------------------------------------------------------
$Scenario = 'levels\launch_lab\launch_lab.scenario'

$PlayerStarts = @(
    @{ Position = @(0, -17, 0.5); Facing = 90 }            # behind the ramp, facing up it (+y)
)
$VehiclePalette = @('vehicles\warthog\warthog.vehicle')    # stock campaign Warthog (not mp_warthog)
$Vehicles = @(
    @{ Type = 0; Name = 'hog'; Position = @(0, -15, 0.5); Yaw = 90 }   # between the spawn and the ramp
)
$EquipmentPalette = @('weapons\frag grenade\frag grenade.equipment')
$Equipment = @(
    @{ Type = 0; Position = @(2, -17, 0.2) }
    @{ Type = 0; Position = @(3, -17, 0.2) }
    @{ Type = 0; Position = @(4, -17, 0.2) }
)
# Cutscene flags: named points that scripts target (damage_new, effect_new, object_teleport).
$CutsceneFlags = @(
    @{ Name = 'boom_flag'; Position = @(0, -15, 0.1) }     # on the floor under the Warthog's centre (task 8)
)
# --------------------------------------------------------------------------------------------------------

$ConfigFile = Join-Path $PSScriptRoot 'local.config.ps1'
if (-not (Test-Path $ConfigFile)) { throw "Missing tools\local.config.ps1." }
. $ConfigFile
foreach ($k in 'ToolsRoot', 'InvaderEdit') {
    if (-not $LaunchLab -or -not $LaunchLab[$k]) { throw "tools\local.config.ps1 doesn't set `$LaunchLab.$k." }
}
$Tags = Join-Path $LaunchLab.ToolsRoot 'tags'
$Ie = $LaunchLab.InvaderEdit
if (-not (Test-Path $Ie)) { throw "invader-edit not found: $Ie" }

function Invoke-Native([string]$exe, [string[]]$arguments) {
    # Windows PowerShell 5.1 turns stderr into ErrorRecords and, with 'Stop', aborts on them; keep the text instead.
    $ErrorActionPreference = 'Continue'
    $out = & $exe @arguments 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" }
    }
    return @{ Code = $LASTEXITCODE; Out = @($out) }
}

function Edit-Tag([string[]]$arguments, [switch]$NoSafeguards) {
    $a = @('-t', $Tags)
    if ($NoSafeguards) { $a += '-n' }
    $r = Invoke-Native $Ie ($a + $arguments + @($Scenario))
    if ($r.Code -ne 0 -or $r.Out.Count) { throw "invader-edit $($arguments -join ' ') failed (exit $($r.Code)): $($r.Out -join ' ')" }
}

function Get-TagValue([string]$key) {
    $r = Invoke-Native $Ie @('-t', $Tags, '-G', $key, $Scenario)
    if ($r.Code -ne 0) { throw "invader-edit -G $key failed: $($r.Out -join ' ')" }
    return ($r.Out -join ' ').Trim()
}

function Clear-Block([string]$block, [switch]$NoSafeguards) {
    $r = Invoke-Native $Ie @('-t', $Tags, '-C', $block, $Scenario)
    if ($r.Code -ne 0) { throw "invader-edit -C $block failed: $($r.Out -join ' ')" }
    if ([int]($r.Out -join '') -gt 0) { Edit-Tag @('-E', "$block[*]") -NoSafeguards:$NoSafeguards }
}

$Rad = [math]::PI / 180
function Format-Point($p) { ($p | ForEach-Object { [string]([double]$_) }) -join ',' }

# Expected read-back values, checked at the end: key -> value.
$Expect = [ordered]@{}

# 1. Sync the repo into the tools folder (guards unpulled GUI work).
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') push
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync push" -ForegroundColor Red; exit 1 }

# Back up the tools-folder scenario: if any later step fails, it is restored, so a failed run never leaves a
# half-written scenario behind (which a later "sync pull" could copy into the repo).
$ToolsScenario = Join-Path $Tags $Scenario
$Backup = "$ToolsScenario.before-scenario-ps1"
Copy-Item -LiteralPath $ToolsScenario -Destination $Backup -Force
$ok = $false
try {

# This script owns object_names, but only builds names for vehicles. Refuse if other placement blocks are in use
# (their name indices would dangle); extend the script first if a task needs them.
foreach ($b in 'scenery', 'bipeds', 'weapons', 'machines', 'controls', 'light_fixtures', 'sound_scenery') {
    $r = Invoke-Native $Ie @('-t', $Tags, '-C', $b, $Scenario)
    if ($r.Code -ne 0) { throw "invader-edit -C $b failed: $($r.Out -join ' ')" }
    if ([int]($r.Out -join '') -gt 0) { throw "The scenario has $($r.Out -join '') $b placement(s); tools\scenario.ps1 only manages spawns, vehicles and equipment. Extend it before running." }
}

# 2. Clear placement blocks. Instances first, then palettes and names (instances point at them by index).
Clear-Block 'equipment'; Clear-Block 'vehicles'; Clear-Block 'player_starting_locations'; Clear-Block 'cutscene_flags'
Clear-Block 'equipment_palette'; Clear-Block 'vehicle_palette'
Clear-Block 'object_names' -NoSafeguards   # guarded by invader-edit; -n only here (ADR 0004)

# Object names, collected from the placements in order.
$Names = @($Vehicles | Where-Object { $_.Name } | ForEach-Object { $_.Name })
if ($Names.Count) {
    Edit-Tag @('-I', 'object_names', "$($Names.Count)", 'end') -NoSafeguards
    for ($i = 0; $i -lt $Names.Count; $i++) {
        Edit-Tag @('-S', "object_names[$i].name", $Names[$i]) -NoSafeguards
        $Expect["object_names[$i].name"] = $Names[$i]
    }
}

if ($CutsceneFlags.Count) { Edit-Tag @('-I', 'cutscene_flags', "$($CutsceneFlags.Count)", 'end') }
for ($i = 0; $i -lt $CutsceneFlags.Count; $i++) {
    $f = $CutsceneFlags[$i]
    Edit-Tag @('-S', "cutscene_flags[$i].name", $f.Name)
    Edit-Tag @('-S', "cutscene_flags[$i].position", (Format-Point $f.Position))
    $Expect["cutscene_flags[$i].name"] = $f.Name
    $Expect["cutscene_flags[$i].position"] = $f.Position
}

if ($PlayerStarts.Count) { Edit-Tag @('-I', 'player_starting_locations', "$($PlayerStarts.Count)", 'end') }
for ($i = 0; $i -lt $PlayerStarts.Count; $i++) {
    $s = $PlayerStarts[$i]
    Edit-Tag @('-S', "player_starting_locations[$i].position", (Format-Point $s.Position))
    Edit-Tag @('-S', "player_starting_locations[$i].facing", [string]($s.Facing * $Rad))
    $Expect["player_starting_locations[$i].position"] = $s.Position
    $Expect["player_starting_locations[$i].facing"] = @($s.Facing)
}

foreach ($p in @(@{ Block = 'vehicle_palette'; Items = $VehiclePalette }, @{ Block = 'equipment_palette'; Items = $EquipmentPalette })) {
    if (-not $p.Items.Count) { continue }
    Edit-Tag @('-I', $p.Block, "$($p.Items.Count)", 'end')
    for ($i = 0; $i -lt $p.Items.Count; $i++) {
        Edit-Tag @('-S', "$($p.Block)[$i].name", $p.Items[$i])
        $Expect["$($p.Block)[$i].name"] = $p.Items[$i]
    }
}

if ($Vehicles.Count) { Edit-Tag @('-I', 'vehicles', "$($Vehicles.Count)", 'end') }
for ($i = 0; $i -lt $Vehicles.Count; $i++) {
    $v = $Vehicles[$i]
    Edit-Tag @('-S', "vehicles[$i].type", "$($v.Type)")
    if ($v.Name) {
        $nameIndex = [array]::IndexOf($Names, $v.Name)
        Edit-Tag @('-S', "vehicles[$i].name", "$nameIndex")
        $Expect["vehicles[$i].name"] = "$nameIndex"
    }
    Edit-Tag @('-S', "vehicles[$i].position", (Format-Point $v.Position))
    Edit-Tag @('-S', "vehicles[$i].rotation", "$($v.Yaw * $Rad),0,0")
    $Expect["vehicles[$i].type"] = "$($v.Type)"
    $Expect["vehicles[$i].position"] = $v.Position
    $Expect["vehicles[$i].rotation"] = @($v.Yaw, 0, 0)
}

if ($Equipment.Count) { Edit-Tag @('-I', 'equipment', "$($Equipment.Count)", 'end') }
for ($i = 0; $i -lt $Equipment.Count; $i++) {
    $e = $Equipment[$i]
    Edit-Tag @('-S', "equipment[$i].type", "$($e.Type)")
    Edit-Tag @('-S', "equipment[$i].position", (Format-Point $e.Position))
    $Expect["equipment[$i].type"] = "$($e.Type)"
    $Expect["equipment[$i].position"] = $e.Position
}

# 3. Read back and compare (numbers within 0.001; invader-edit prints degrees for angles).
$bad = 0
foreach ($k in $Expect.Keys) {
    $want = $Expect[$k]
    $got = Get-TagValue $k
    if ($want -is [array]) {
        $g = @($got -split ',' | ForEach-Object { [double]$_ })
        $ok = $g.Count -eq $want.Count
        for ($j = 0; $ok -and $j -lt $want.Count; $j++) { $ok = [math]::Abs($g[$j] - [double]$want[$j]) -lt 0.001 }
    } else {
        $ok = $got -eq $want
    }
    if (-not $ok) { Write-Host "  MISMATCH $k : want $($want -join ',') got $got" -ForegroundColor Red; $bad++ }
}
if ($bad) { throw "$bad value(s) didn't read back as written." }
Write-Host "Read back $($Expect.Count) values: all match." -ForegroundColor Green

# 4. Tool's own validation.
Push-Location $LaunchLab.ToolsRoot
try { $r = Invoke-Native (Join-Path $LaunchLab.ToolsRoot 'tool.exe') @('check-map', ($Scenario -replace '\.scenario$', '')) }
finally { Pop-Location }
$errs = @($r.Out | Where-Object { $_ -match '(?i)\berror\b|exception|\bassert' })
if ($r.Code -ne 0 -or $errs.Count) {
    $errs | ForEach-Object { Write-Host "  ! $_" }; throw "tool check-map failed (exit $($r.Code))."
}
$warns = @($r.Out | Where-Object { $_ -match '^###' }).Count
Write-Host "tool check-map: OK (exit 0, $warns warning line(s); stock-effect warnings are expected)." -ForegroundColor Green

$ok = $true
} catch {
    Write-Host "FAIL: $_" -ForegroundColor Red
} finally {
    if (-not $ok) {
        Copy-Item -LiteralPath $Backup -Destination $ToolsScenario -Force
        Write-Host "Restored the tools-folder scenario to its state before this run." -ForegroundColor Yellow
    }
    Remove-Item -LiteralPath $Backup -Force -ErrorAction SilentlyContinue
}
if (-not $ok) { exit 1 }

# 5. Bring the result back into the repo.
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') pull
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync pull" -ForegroundColor Red; exit 1 }
Write-Host "Scenario placements applied." -ForegroundColor Green
