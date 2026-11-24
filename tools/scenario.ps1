<#
.SYNOPSIS
  Applies Launch Lab's scenario placements with invader-edit (ADR 0004): hand-made items listed below, plus the world
  (trees, rocks, a vehicle per level, landing zones, level flags) from the generator's world_layout.json (task 11).

.DESCRIPTION
  The lists below (starting profile, spawns, vehicles, equipment, scenery, trigger volumes, cutscene flags) are the source of truth: each run
  clears and rewrites those blocks, so edits to them in Sapien/Guerilla are overwritten. The script:
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
$VehiclePalette = @(
    'vehicles\warthog\warthog.vehicle'    # 0: stock campaign Warthog (not mp_warthog)
)
$Vehicles = @(
    @{ Type = 0; Name = 'hog'; Position = @(0, -15, 0.5); Yaw = 90 }   # between the spawn and the ramp
)
$EquipmentPalette = @('weapons\frag grenade\frag grenade.equipment')
$Equipment = @(
    @{ Type = 0; Position = @(2, -17, 0.2) }
    @{ Type = 0; Position = @(3, -17, 0.2) }
    @{ Type = 0; Position = @(4, -17, 0.2) }
)
# What the player spawns with. Mirrors the stock b30 profile's form (name, health/shield 1.0, 4 frags).
$StartingProfile = [ordered]@{
    'name'                                 = 'player0_starting_profile'
    'starting_health_modifier'             = '1'
    'starting_shield_modifier'             = '1'
    'primary_weapon'                       = 'levels\launch_lab\pile_gun\pile_gun.weapon'   # built by tools\devices.ps1 (task 9)
    'primary_rounds_loaded'                = '12'
    'primary_rounds_reserved'              = '999'
    'secondary_weapon'                     = 'levels\launch_lab\shield_gun\shield_gun.weapon'   # overshield gun (task 9)
    'starting_fragmentation_grenade_count' = '4'
}

# ---- The world (generated): read from the layout art\launch_lab_arena.py writes ------------------------------------
# Trees, rocks, a vehicle per level, landing zones (fall guard + checkpoints) and level flags all come from
# mod\data\levels\launch_lab\world_layout.json (generated, git-ignored), so placements always match the geometry.
$LayoutFile = Join-Path (Split-Path $PSScriptRoot -Parent) 'mod\data\levels\launch_lab\world_layout.json'
if (-not (Test-Path $LayoutFile)) { throw "Missing ${LayoutFile}: run 'tools\build.ps1 -Step jms' first (the world generator writes it)." }
$Layout = Get-Content $LayoutFile -Raw | ConvertFrom-Json

# Stock scenery by the short names the generator uses.
$SceneryKinds = [ordered]@{
    'fern'               = 'scenery\plants\plant fern\plant fern.scenery'
    'broadleaf'          = 'scenery\plants\plant_broadleaf_tall\plant_broadleaf_tall.scenery'
    'yellowbig'          = 'scenery\plants\plant_yellowbig\plant_yellowbig.scenery'
    'boulder'            = 'scenery\rocks\boulder\boulder.scenery'
    'tree_leafy'         = 'scenery\trees\tree_leafy\tree_leafy.scenery'
    'tree_dense'         = 'scenery\trees\tree_leafydense_doublewide\tree_leafydense_doublewide.scenery'
    'trunk'              = 'scenery\trees\tree_leafy_fallentrunk_short\tree_leafy_fallentrunk_short.scenery'
    'pine'               = 'levels\test\timberland\scenery\mp_tree_pine_tall\mp_tree_pine_tall.scenery'
    'boulder_moss'       = 'levels\test\timberland\scenery\mp_boulder_moss_small\mp_boulder_moss_small.scenery'
    'boulder_moss_large' = 'scenery\rocks\boulder_moss_large\boulder_moss_large.scenery'
    'boulder_granite'    = 'levels\test\timberland\scenery\mp_boulder_granite_medium\mp_boulder_granite_medium.scenery'
    # Island themes (task 11): crash sites and landing-pad beacons
    'wreck_pelican'      = 'scenery\vehicles\pelican_crashed\pelican_crashed.scenery'
    'wreck_dropship'     = 'scenery\vehicles\c_dropship_crashed\c_dropship_crashed.scenery'
    'wreck_banshee'      = 'scenery\debris\banshee_crashed\banshee_crashed.scenery'
    'wreck_lifepod'      = 'scenery\vehicles\lifepod_crashed\lifepod_crashed.scenery'
    'beacon'             = 'scenery\landing beacon\landing beacon.scenery'
}
$SceneryPalette = @($SceneryKinds.Values)
$SceneryIndex = @{}; $n = 0; foreach ($k in $SceneryKinds.Keys) { $SceneryIndex[$k] = $n; $n++ }
$Scenery = @($Layout.scatter | ForEach-Object { @{ Type = $SceneryIndex[$_.kind]; Position = @($_.position) } })

# A Warthog per connected group of islands (owner; no turrets since the stage A playtest). Palette: 0 Warthog.
$Vehicles += @($Layout.vehicles | ForEach-Object {
    @{ Type = $(if ($_.kind -eq 'warthog') { 0 } else { throw "Unknown vehicle kind '$($_.kind)' in the layout" }); Name = ''; Position = @($_.position); Yaw = [double]$_.yaw } })

# Trigger volumes: every landing zone (fall guard; the island ones are also the checkpoints). Stock convention (a10):
# type rotational, forward (1,0,0), up (0,0,1), starting corner = low corner, ending corner offset = size.
# Tilted zones (hills) carry their own forward/up axes; the rest are axis-aligned. Limit: 256 per scenario (Tool).
$TriggerVolumes = @($Layout.landing_zones | ForEach-Object {
    @{ Name = $_.name; Corner = @($_.corner); Size = @($_.size)
       Forward = $(if ($_.forward) { @($_.forward) } else { @(1, 0, 0) }); Up = $(if ($_.up) { @($_.up) } else { @(0, 0, 1) }) } })

# Cutscene flags: hand-made debug points, plus one per level (for the debug teleports in the generated world.hsc).
$CutsceneFlags = @(
    @{ Name = 'boom_flag'; Position = @(0, -15, 0.1) }        # on the floor under the Warthog's centre (task 8)
    @{ Name = 'ground_flag'; Position = @(0, -17, 0.5) }      # the spawn spot: debug teleport back (task 10)
) + @($Layout.flags | ForEach-Object { @{ Name = $_.name; Position = @($_.position) } })

# Read-back: every hand-made value, and for generated blocks a sample (first, last, every 25th) to keep runs short.
function Test-Sampled([int]$i, [int]$count) { ($i -eq 0) -or ($i -eq $count - 1) -or ($i % 25 -eq 0) }
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
# Plain decimals only: [string] of a tiny double gives scientific notation (1.01E-06), which invader-edit misreads
# (it read back -4.98: found by the read-back check in task 11). Invariant culture: always a '.' decimal point.
function Format-Point($p) { ($p | ForEach-Object { ([double]$_).ToString('0.######', [Globalization.CultureInfo]::InvariantCulture) }) -join ',' }

# Expected read-back values, checked at the end: key -> value.
$Expect = [ordered]@{}

# The starting profile references device tags generated by tools\devices.ps1; check they exist before editing.
foreach ($v in $StartingProfile.Values) {
    if ($v -match '\.weapon$' -and -not (Test-Path -LiteralPath (Join-Path $Tags $v))) {
        throw "Missing $v in the tools folder: run 'tools\build.ps1 -Step devices' first."
    }
}

# 1. Sync the repo into the tools folder (guards unpulled GUI work).
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') push
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync push" -ForegroundColor Red; exit 1 }

# Back up the tools-folder scenario: if any later step fails, it is restored, so a failed run never leaves a
# half-written scenario behind (which a later "sync pull" could copy into the repo).
$ToolsScenario = Join-Path $Tags $Scenario
$Backup = "$ToolsScenario.before-scenario-ps1"
Copy-Item -LiteralPath $ToolsScenario -Destination $Backup -Force
$succeeded = $false
try {

# This script owns object_names, but only builds names for vehicles. Refuse if other placement blocks are in use
# (their name indices would dangle); extend the script first if a task needs them.
foreach ($b in 'bipeds', 'weapons', 'machines', 'controls', 'light_fixtures', 'sound_scenery') {
    $r = Invoke-Native $Ie @('-t', $Tags, '-C', $b, $Scenario)
    if ($r.Code -ne 0) { throw "invader-edit -C $b failed: $($r.Out -join ' ')" }
    if ([int]($r.Out -join '') -gt 0) { throw "The scenario has $($r.Out -join '') $b placement(s); tools\scenario.ps1 only manages the starting profile, spawns, vehicles, equipment, scenery, trigger volumes and cutscene flags. Extend it before running." }
}

# 2. Clear placement blocks. Instances first, then palettes and names (instances point at them by index).
Clear-Block 'equipment'; Clear-Block 'vehicles'; Clear-Block 'player_starting_locations'; Clear-Block 'cutscene_flags'
Clear-Block 'player_starting_profile'; Clear-Block 'scenery'; Clear-Block 'scenery_palette'; Clear-Block 'trigger_volumes'
Clear-Block 'equipment_palette'; Clear-Block 'vehicle_palette'
Clear-Block 'object_names' -NoSafeguards   # guarded by invader-edit; -n only here (ADR 0004)

# Object names, collected from the placements in order.
$Names = @($Vehicles | Where-Object { $_.Name } | ForEach-Object { $_.Name })   # generated vehicles are unnamed
if ($Names.Count) {
    Edit-Tag @('-I', 'object_names', "$($Names.Count)", 'end') -NoSafeguards
    for ($i = 0; $i -lt $Names.Count; $i++) {
        Edit-Tag @('-S', "object_names[$i].name", $Names[$i]) -NoSafeguards
        $Expect["object_names[$i].name"] = $Names[$i]
    }
}

if ($StartingProfile.Count) {
    Edit-Tag @('-I', 'player_starting_profile', '1', 'end')
    foreach ($k in $StartingProfile.Keys) {
        Edit-Tag @('-S', "player_starting_profile[0].$k", $StartingProfile[$k])
        $v = $StartingProfile[$k]
        $Expect["player_starting_profile[0].$k"] = if ($v -match '^-?[0-9.]+$') { ,@([double]$v) } else { $v }
    }
}

if ($TriggerVolumes.Count) { Edit-Tag @('-I', 'trigger_volumes', "$($TriggerVolumes.Count)", 'end') }
for ($i = 0; $i -lt $TriggerVolumes.Count; $i++) {
    $v = $TriggerVolumes[$i]
    # One invader-edit call per element (all its fields), not one per field: hundreds of zones (task 11).
    Edit-Tag @('-S', "trigger_volumes[$i].type", 'rotational', '-S', "trigger_volumes[$i].name", $v.Name,
               '-S', "trigger_volumes[$i].rotation_vector_forward", (Format-Point $v.Forward),
               '-S', "trigger_volumes[$i].rotation_vector_up", (Format-Point $v.Up),
               '-S', "trigger_volumes[$i].starting_corner", (Format-Point $v.Corner),
               '-S', "trigger_volumes[$i].ending_corner_offset", (Format-Point $v.Size))
    if (Test-Sampled $i $TriggerVolumes.Count) {
        $Expect["trigger_volumes[$i].name"] = $v.Name
        $Expect["trigger_volumes[$i].starting_corner"] = $v.Corner
        $Expect["trigger_volumes[$i].ending_corner_offset"] = $v.Size
    }
}

if ($CutsceneFlags.Count) { Edit-Tag @('-I', 'cutscene_flags', "$($CutsceneFlags.Count)", 'end') }
for ($i = 0; $i -lt $CutsceneFlags.Count; $i++) {
    $f = $CutsceneFlags[$i]
    Edit-Tag @('-S', "cutscene_flags[$i].name", $f.Name, '-S', "cutscene_flags[$i].position", (Format-Point $f.Position))
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

foreach ($p in @(@{ Block = 'vehicle_palette'; Items = $VehiclePalette }, @{ Block = 'equipment_palette'; Items = $EquipmentPalette }, @{ Block = 'scenery_palette'; Items = $SceneryPalette })) {
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
    $set = @('-S', "vehicles[$i].type", "$($v.Type)", '-S', "vehicles[$i].position", (Format-Point $v.Position),
             '-S', "vehicles[$i].rotation", "$($v.Yaw * $Rad),0,0")
    if ($v.Name) {
        $nameIndex = [array]::IndexOf($Names, $v.Name)
        $set += @('-S', "vehicles[$i].name", "$nameIndex")
        $Expect["vehicles[$i].name"] = "$nameIndex"
    }
    Edit-Tag $set
    $Expect["vehicles[$i].type"] = "$($v.Type)"
    $Expect["vehicles[$i].position"] = $v.Position
    $Expect["vehicles[$i].rotation"] = @($v.Yaw, 0, 0)
}

if ($Scenery.Count) { Edit-Tag @('-I', 'scenery', "$($Scenery.Count)", 'end') }
for ($i = 0; $i -lt $Scenery.Count; $i++) {
    $e = $Scenery[$i]
    Edit-Tag @('-S', "scenery[$i].type", "$($e.Type)", '-S', "scenery[$i].position", (Format-Point $e.Position))
    if (Test-Sampled $i $Scenery.Count) {
        $Expect["scenery[$i].type"] = "$($e.Type)"
        $Expect["scenery[$i].position"] = $e.Position
    }
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
# "failed to load" / "invalid element count" too: in task 11 check-map couldn't load the scenario (397 trigger volumes,
# limit 256) and this filter, matching only error/exception/assert, still reported OK.
$errs = @($r.Out | Where-Object { $_ -match '(?i)\berror\b|exception|\bassert|failed to load|invalid element count|FAILED' })
if ($r.Code -ne 0 -or $errs.Count) {
    $errs | ForEach-Object { Write-Host "  ! $_" }; throw "tool check-map failed (exit $($r.Code))."
}
$warns = @($r.Out | Where-Object { $_ -match '^###' }).Count
Write-Host "tool check-map: OK (exit 0, $warns warning line(s); stock-effect warnings are expected)." -ForegroundColor Green

$succeeded = $true
} catch {
    Write-Host "FAIL: $_" -ForegroundColor Red
} finally {
    if (-not $succeeded) {
        Copy-Item -LiteralPath $Backup -Destination $ToolsScenario -Force
        Write-Host "Restored the tools-folder scenario to its state before this run." -ForegroundColor Yellow
    }
    Remove-Item -LiteralPath $Backup -Force -ErrorAction SilentlyContinue
}
if (-not $succeeded) { exit 1 }

# 5. Bring the result back into the repo.
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync.ps1') pull
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: sync pull" -ForegroundColor Red; exit 1 }
Write-Host "Scenario placements applied." -ForegroundColor Green
