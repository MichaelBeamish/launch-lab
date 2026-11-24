<#
.SYNOPSIS
  Puts our built map into MCC in place of a stock singleplayer map, or restores the stock map (task 3).

.DESCRIPTION
  c20 documents only a replacement method for playing a custom singleplayer map in MCC: the custom .map takes the
  file name of a stock map of the same type, and MCC (launched with anti-cheat disabled) loads it for that level.
  Maps in subfolders of maps\ are not loaded, so the backup goes outside the game folder.

  install: backs up <MCC>\halo1\maps\<Slot>.map (once, with its SHA-256), then copies <tools>\maps\launch_lab.map over it.
  restore: copies the backup back and verifies its SHA-256 against the recorded one.
  status:  shows which map is in the slot.
  Steam's "Verify integrity of game files" also restores stock maps.

.PARAMETER Slot
  Stock map to replace. Default a10 (The Pillar of Autumn, the first campaign level).
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('install', 'restore', 'status')][string]$Action,
    [ValidatePattern('^[a-d][0-9]{2}$')][string]$Slot = 'a10'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'local.config.ps1')
foreach ($k in 'ToolsRoot', 'GameRoot') { if (-not $LaunchLab[$k]) { throw "tools\local.config.ps1 doesn't set `$LaunchLab.$k." } }

$Target = Join-Path $LaunchLab.GameRoot "halo1\maps\$Slot.map"
$Ours = Join-Path $LaunchLab.ToolsRoot 'maps\launch_lab.map'
$BackupDir = Join-Path $env:LOCALAPPDATA 'LaunchLabTools\mcc-stock-maps'
$Backup = Join-Path $BackupDir "$Slot.map"
$BackupHash = "$Backup.sha256"

function Get-Sha($p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
# Every H1 cache file stores its own map name at offset 0x20 (32 bytes): "a10" for stock a10.map, "launch_lab" for
# ours (checked on both in task 3). A file is treated as stock only if that name equals the slot name.
function Get-MapName($p) {
    $fs = [IO.File]::OpenRead($p)
    try { $b = New-Object byte[] 64; [void]$fs.Read($b, 0, 64) } finally { $fs.Close() }
    return [Text.Encoding]::ASCII.GetString($b, 0x20, 32).TrimEnd([char]0)
}
if (-not (Test-Path $Target)) { throw "Stock map not found: $Target" }

switch ($Action) {
    'status' {
        $name = Get-MapName $Target
        $state = if ($name -eq 'launch_lab') { 'OURS (launch_lab)' }
                 elseif ($name -eq $Slot) { if ((Test-Path $BackupHash) -and (Get-Sha $Target) -eq (Get-Content $BackupHash)) { 'STOCK (matches backup)' } else { 'STOCK (no current backup)' } }
                 else { "unknown (map name '$name')" }
        Write-Host "$Slot.map: $state"
    }
    'install' {
        if (-not (Test-Path $Ours)) { throw "Build the map first: $Ours not found (tools\build.ps1 -Step cache)." }
        if ((Get-MapName $Ours) -ne 'launch_lab') { throw "$Ours doesn't look like our map." }
        $name = Get-MapName $Target
        if ($name -eq $Slot) {
            # Genuine stock map in the slot: back it up, also when Steam has updated it since the last backup.
            if (-not (Test-Path $Backup) -or (Get-Sha $Target) -ne (Get-Content $BackupHash -ErrorAction SilentlyContinue)) {
                New-Item -ItemType Directory -Force $BackupDir | Out-Null
                Copy-Item -LiteralPath $Target -Destination $Backup -Force
                if ((Get-Sha $Backup) -ne (Get-Sha $Target)) { throw "Backup copy doesn't match the stock map." }
                Set-Content -LiteralPath $BackupHash -Value (Get-Sha $Backup) -Encoding ascii
                Write-Host "Backed up stock $Slot.map to $Backup"
            }
        } elseif ($name -eq 'launch_lab') {
            if (-not (Test-Path $Backup)) { throw "$Slot.map is ours but there is no stock backup: restore it with Steam's 'Verify integrity of game files' first." }
        } else {
            throw "$Slot.map has map name '$name', neither stock '$Slot' nor ours: not touching it. Use Steam's 'Verify integrity of game files'."
        }
        Copy-Item -LiteralPath $Ours -Destination $Target -Force
        if ((Get-Sha $Target) -ne (Get-Sha $Ours)) { throw "Copy failed: $Slot.map doesn't match launch_lab.map." }
        Write-Host "Installed launch_lab.map as $Slot.map. Restore afterwards: tools\mcc-swap.ps1 restore" -ForegroundColor Green
    }
    'restore' {
        if (-not (Test-Path $Backup)) { throw "No backup at $Backup. Use Steam's 'Verify integrity of game files' instead." }
        if ((Get-Sha $Backup) -ne (Get-Content $BackupHash)) { throw "The backup's hash doesn't match the recorded one; not restoring. Use Steam's verify instead." }
        if ((Get-MapName $Backup) -ne $Slot) { throw "The backup's map name isn't '$Slot'; not restoring. Use Steam's verify instead." }
        Copy-Item -LiteralPath $Backup -Destination $Target -Force
        if ((Get-Sha $Target) -ne (Get-Content $BackupHash)) { throw "Restore copy failed verification." }
        Write-Host "Restored stock $Slot.map (SHA-256 and map name verified)." -ForegroundColor Green
    }
}
