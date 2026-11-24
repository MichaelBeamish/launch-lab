<#
.SYNOPSIS
  Builds Launch Lab's gameplay devices from stock tags with invader-edit (ADR 0005): the grenade pile gun and the
  overshield gun (task 9).

.DESCRIPTION
  Each device is a chain of three tags of our own, copied from stock:
    gun (a stock weapon copy) -> fires a pellet (copy of the stock frag grenade projectile, so it arcs, bounces and
    settles) -> when the pellet "detonates" it plays an effect (copy of the stock frag explosion effect, cut down to
    ONE part) -> that part creates a STOCK pickup where the pellet came to rest.
  Pile gun:   pistol copy        -> stock weapons\frag grenade\frag grenade.equipment  (chain-reacts: stock behaviour)
  Shield gun: plasma pistol copy -> stock powerups\over shield.equipment

  Every change from stock is listed in $Devices below and read back after writing. The outputs go to
  <tools>\tags\levels\launch_lab\<device>\ and are generated (git-ignored): this script is their source.
  No stock tag is written: the script ends by running tools\stock-baseline.ps1 and fails if it fails.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\devices.ps1
#>
$ErrorActionPreference = 'Stop'
$ConfigFile = Join-Path $PSScriptRoot 'local.config.ps1'
if (-not (Test-Path $ConfigFile)) { throw "Missing tools\local.config.ps1." }
. $ConfigFile
foreach ($k in 'ToolsRoot', 'InvaderEdit') { if (-not $LaunchLab -or -not $LaunchLab[$k]) { throw "tools\local.config.ps1 doesn't set `$LaunchLab.$k." } }
$Tags = Join-Path $LaunchLab.ToolsRoot 'tags'
$Ie = $LaunchLab.InvaderEdit
if (-not (Test-Path -LiteralPath $Ie)) { throw "invader-edit not found: $Ie" }

$PileDir = 'levels\launch_lab\pile_gun'
$ShieldDir = 'levels\launch_lab\shield_gun'

# Shared pellet changes: a frag grenade projectile with a muzzle speed (the stock frag has initial_velocity 0 because
# the throw supplies its speed). final_velocity stays 0 like the stock frag: a non-zero final speed is held constant
# (bullets, needles), and 8/8 made pellets bounce forever (task 9 playtest).
# The frag's per-surface reactions include a detonation_effect (e.g. rocket launcher "impact dirt/stone"): that was a
# small "rubble" pop when a pellet settled (task 9 playtest), so it is cleared on every surface. The bounce effects
# (default_effect) stay, so pellets still clink as they land.
$PelletClear = @{ Block = 'projectile_material_response'; Field = 'detonation_effect'; Empty = '.effect' }

# ---- The devices, as differences from stock (edit these) -----------------------------------------------
$Devices = @(
    # ---- Grenade pile gun ----
    @{  # Effect: one part, creating the stock frag grenade pickup. No damage, no sound, no particles.
        From = 'weapons\frag grenade\effects\explosion.effect'; To = "$PileDir\drop_grenade.effect"
        Erase = @('events[0].parts[1-6]', 'events[0].particles[*]')
        Set = [ordered]@{ 'events[0].parts[0].type' = 'weapons\frag grenade\frag grenade.equipment' }
    }
    @{  # Pellet
        From = 'weapons\frag grenade\frag grenade.projectile'; To = "$PileDir\pile_gun_pellet.projectile"
        Erase = @()
        Set = [ordered]@{ 'effect' = "$PileDir\drop_grenade.effect"; 'initial_velocity' = '8'; 'final_velocity' = '0' }
        ClearEach = $PelletClear
    }
    @{  # Gun: the stock pistol, firing pellets, with a big reserve so it doesn't run dry in MCC.
        From = 'weapons\pistol\pistol.weapon'; To = "$PileDir\pile_gun.weapon"
        Erase = @()
        Set = [ordered]@{
            'triggers[0].projectile'               = "$PileDir\pile_gun_pellet.projectile"
            'magazines[0].rounds_total_initial'    = '999'
            'magazines[0].rounds_reserved_maximum' = '999'
            # Owner asked for a thump, not the pistol shot. The grenade-throw whoosh (tried first) sounded like a live frag,
            # so: the stock melee impact thump (owner: "sounds great"). firing_effect accepts a sound directly.
            # Alternatives: sound\sfx\impulse\melee\melee_dirt.sound, melee_concrete.sound, melee_armor.sound.
            'triggers[0].firing_effects[0].firing_effect' = 'sound\sfx\impulse\melee\melee_rubber.sound'
        }
    }

    # ---- Overshield gun ----
    @{  # Effect: one part, creating the stock overshield pickup.
        From = 'weapons\frag grenade\effects\explosion.effect'; To = "$ShieldDir\drop_overshield.effect"
        Erase = @('events[0].parts[1-6]', 'events[0].particles[*]')
        Set = [ordered]@{ 'events[0].parts[0].type' = 'powerups\over shield.equipment' }
    }
    @{  # Pellet: the same arcing, settling pellet as the pile gun's, but it must not LOOK like a frag (owner: "the
        # plasma pistol also shoots a frag"). So it gets the overshield's own model (stock over shield.equipment uses
        # powerups\active camoflage\active camoflage.model, sic) and loses the frag's attachments (its blinking light).
        From = 'weapons\frag grenade\frag grenade.projectile'; To = "$ShieldDir\shield_gun_pellet.projectile"
        Erase = @('attachments[*]')
        Set = [ordered]@{
            'effect' = "$ShieldDir\drop_overshield.effect"; 'initial_velocity' = '8'; 'final_velocity' = '0'
            'model'  = 'powerups\active camoflage\active camoflage.model'
        }
        ClearEach = $PelletClear
    }
    @{  # Gun: the stock plasma pistol. Both triggers (normal and overcharged) fire the pellet. No battery drain (stock
        # ages 0.002 per shot and misfires from 0.9), so it never runs out in MCC. Stock firing sound kept.
        From = 'weapons\plasma pistol\plasma pistol.weapon'; To = "$ShieldDir\shield_gun.weapon"
        Erase = @()
        Set = [ordered]@{
            'triggers[0].projectile'              = "$ShieldDir\shield_gun_pellet.projectile"
            'triggers[1].projectile'              = "$ShieldDir\shield_gun_pellet.projectile"
            'triggers[0].age_generated_per_round' = '0'
            'triggers[1].age_generated_per_round' = '0'
        }
    }
)
# --------------------------------------------------------------------------------------------------------

function Invoke-Native([string[]]$arguments) {
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    $out = & $Ie @arguments 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" }
    }
    return @{ Code = $LASTEXITCODE; Out = @($out) }
}
function Edit-Tag([string]$tag, [string[]]$arguments) {
    $r = Invoke-Native (@('-t', $Tags) + $arguments + @($tag))
    if ($r.Code -ne 0 -or $r.Out.Count) { throw "invader-edit $($arguments -join ' ') $tag failed (exit $($r.Code)): $($r.Out -join ' ')" }
}
function Get-TagValue([string]$tag, [string]$key) {
    $r = Invoke-Native @('-t', $Tags, '-G', $key, $tag)
    if ($r.Code -ne 0) { throw "invader-edit -G $key $tag failed: $($r.Out -join ' ')" }
    return ($r.Out -join ' ').Trim()
}

foreach ($dir in $PileDir, $ShieldDir) { New-Item -ItemType Directory -Force (Join-Path $Tags $dir) | Out-Null }
$bad = 0
foreach ($d in $Devices) {
    Write-Host "== $($d.To)  (from $($d.From))"
    $expect = [ordered]@{}
    foreach ($k in $d.Set.Keys) { $expect[$k] = $d.Set[$k] }
    # Fresh copy from stock every run, so the result depends only on stock + the listed changes.
    $firstKey = [string]($d.Set.Keys | Select-Object -First 1)
    Edit-Tag $d.From @('-O', $d.To, '-S', $firstKey, $d.Set[$firstKey])
    foreach ($e in $d.Erase) { Edit-Tag $d.To @('-E', $e) }
    foreach ($k in $d.Set.Keys) { Edit-Tag $d.To @('-S', $k, $d.Set[$k]) }
    if ($d.ClearEach) {
        # Clear one reference field in every element of a block. '""' passes an empty value: Windows PowerShell 5.1
        # drops a plain '' argument. invader-edit shows a cleared reference as ".<class>", e.g. ".effect".
        $r = Invoke-Native @('-t', $Tags, '-C', $d.ClearEach.Block, $d.To)
        if ($r.Code -ne 0) { throw "invader-edit -C $($d.ClearEach.Block) $($d.To) failed: $($r.Out -join ' ')" }
        $n = [int]($r.Out -join '')
        for ($i = 0; $i -lt $n; $i++) {
            $key = "$($d.ClearEach.Block)[$i].$($d.ClearEach.Field)"
            Edit-Tag $d.To @('-S', $key, '""')
            $expect[$key] = $d.ClearEach.Empty
        }
        Write-Host "   cleared $($d.ClearEach.Field) on $n $($d.ClearEach.Block) element(s)"
    }
    $shown = 0
    foreach ($k in $expect.Keys) {
        $want = $expect[$k]; $got = Get-TagValue $d.To $k
        $num = 0.0
        $match = if ($want -match '^-?[0-9.]+$') { [double]::TryParse($got, [ref]$num) -and [math]::Abs($num - [double]$want) -lt 0.001 } else { $got -eq $want }
        if (-not $match) { Write-Host "   MISMATCH $k : want $want got $got" -ForegroundColor Red; $bad++ }
        elseif ($d.Set.Contains($k)) { Write-Host ("   {0,-40} = {1}" -f $k, $got) }
        else { $shown++ }
    }
    if ($shown) { Write-Host "   ($shown cleared reference(s) read back as $($d.ClearEach.Empty))" }
}
if ($bad) { Write-Host "FAIL: $bad value(s) didn't read back." -ForegroundColor Red; exit 1 }
# Enforce the promise in the header: devices are copies, the stock tags stay untouched (ADR 0002/0005).
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'stock-baseline.ps1')
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: stock tag hash check after building devices." -ForegroundColor Red; exit 1 }
Write-Host "Device tags built: tags\$PileDir, tags\$ShieldDir." -ForegroundColor Green
