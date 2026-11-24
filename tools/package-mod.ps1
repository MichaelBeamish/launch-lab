<#
.SYNOPSIS
  Assembles the Launch Lab mod folder for Excession (the MCC Mod Uploader) from the latest release map (task 20, ADR 0006).

.DESCRIPTION
  Excession's layout (learn.microsoft.com, Excession > Setup > Folder structure): mods live in a ROOT folder; each mod is
  a folder directly inside it ("not below the 1st level"); its .map files go in a "maps" subfolder; images (PNG) must be
  inside the mod folder (we use "images"). Excession itself writes ModInfo.json and the campaign\<scenario>.json files
  when you create the mod in its UI, and it writes MCC's ModManifest.txt from the root folders you configure.

  This script:
    - creates <Root>\LaunchLab\maps and \images (default root: Documents\Launch Lab Workshop, outside the repo:
      the .map packs game data and is never committed, ADR 0003/0006),
    - copies the newest release map (tools\build.ps1 -Release) in as maps\launch_lab.map, checking its SHA-256,
    - copies PNG images from -Images if given (thumbnail.png, large.png, loading.png),
    - never touches ModInfo.json or the campaign\ folder Excession manages, so re-running only updates the map/images.

.PARAMETER Root
  The Excession root folder. Default: <Documents>\Launch Lab Workshop

.PARAMETER Images
  A folder with thumbnail.png, large.png and loading.png (screenshots), copied into the mod's images folder.
#>
param(
    [string]$Root = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Launch Lab Workshop'),
    [string]$Images
)
$ErrorActionPreference = 'Stop'

$Mod = Join-Path $Root 'LaunchLab'
$Maps = Join-Path $Mod 'maps'
$ImageDir = Join-Path $Mod 'images'
foreach ($d in $Maps, $ImageDir) { New-Item -ItemType Directory -Force $d | Out-Null }

# The newest release map and its recorded SHA-256 (written by tools\build.ps1 -Release).
$ReleaseDir = Join-Path $env:LOCALAPPDATA 'LaunchLabTools\release'
$map = Get-ChildItem $ReleaseDir -Filter 'launch_lab_*.map' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $map) { throw "No release map in ${ReleaseDir}: run 'tools\build.ps1 -Step all -Release' first." }
$want = (Get-Content "$($map.FullName).sha256" -ErrorAction Stop).Trim()
$got = (Get-FileHash -LiteralPath $map.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
if ($got -ne $want) { throw "Release map $($map.Name) doesn't match its recorded SHA-256." }
$target = Join-Path $Maps 'launch_lab.map'
Copy-Item -LiteralPath $map.FullName -Destination $target -Force
if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $want) { throw "Copy failed verification." }
Write-Host "Map: $($map.Name) -> $target (SHA-256 $want)" -ForegroundColor Green

if ($Images) {
    foreach ($n in 'thumbnail.png', 'large.png', 'loading.png') {
        $src = Join-Path $Images $n
        if (-not (Test-Path $src)) { throw "Missing $src (Excession needs PNG images: thumbnail, large, loading screen)." }
        Copy-Item -LiteralPath $src -Destination (Join-Path $ImageDir $n) -Force
        Write-Host "Image: $n" -ForegroundColor Green
    }
}
$have = @(Get-ChildItem $ImageDir -Filter *.png | ForEach-Object Name)
Write-Host "Mod folder: $Mod  (images: $(if ($have) { $have -join ', ' } else { 'none yet' }))"
Write-Host "Excession: root folder = $Root ; mod folder = $Mod ; Scenario File Name = levels/launch_lab/launch_lab"
