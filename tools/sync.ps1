<#
.SYNOPSIS
  Syncs our level files between the repo (mod\) and the mod tools folder. Touches only levels\launch_lab\.

.DESCRIPTION
  push: repo -> tools. Copies mod\data\levels\launch_lab\ and mod\tags\levels\launch_lab\ into the tools folder,
        so Tool, Sapien and Standalone see them.
  pull: tools -> repo. Copies the .scenario back after Sapien or Guerilla saved it (they save inside the tools folder).

  The repo is the source of truth, but Sapien edits happen in the tools folder, so the rule is:
  after saving in Sapien/Guerilla, run "pull" before anything else. "push" refuses to overwrite a tools-folder
  scenario that differs from both the repo and the last synced version (tools\.sync-state.json, by SHA-256),
  i.e. unpulled GUI work, unless -Force is given.

  Generated files (JMS, BSP, .map) are never copied back: they are rebuilt by tools\build.ps1.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\sync.ps1 push
  powershell -ExecutionPolicy Bypass -File tools\sync.ps1 pull
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('push', 'pull')][string]$Direction,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ConfigFile = Join-Path $PSScriptRoot 'local.config.ps1'
if (-not (Test-Path $ConfigFile)) { throw "Missing tools\local.config.ps1 (see tools\stock-baseline.ps1 for the format)." }
. $ConfigFile
if (-not $LaunchLab -or -not $LaunchLab.ToolsRoot) { throw "tools\local.config.ps1 doesn't set `$LaunchLab.ToolsRoot." }

$Repo = Split-Path $PSScriptRoot -Parent
$Level = 'levels\launch_lab'
$RepoData = Join-Path $Repo "mod\data\$Level"
$RepoTags = Join-Path $Repo "mod\tags\$Level"
$ToolsData = Join-Path $LaunchLab.ToolsRoot "data\$Level"
$ToolsTags = Join-Path $LaunchLab.ToolsRoot "tags\$Level"

# Hand-authored tags we keep in the repo (generated tags such as the BSP stay in the tools folder only).
$AuthoredTagPatterns = @('*.scenario')

function Copy-Tree($from, $to, [string[]]$patterns) {
    if (-not (Test-Path $from)) { return 0 }
    $n = 0
    foreach ($pattern in $patterns) {
        foreach ($f in Get-ChildItem -LiteralPath $from -Recurse -File -Filter $pattern) {
            $rel = $f.FullName.Substring($from.Length).TrimStart('\')
            $dest = Join-Path $to $rel
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
            Write-Host "  $rel"
            $n++
        }
    }
    return $n
}

# Hash of each authored tag as of the last push/pull (git-ignored). The push guard compares hashes, not timestamps:
# a git checkout or branch switch changes file times, and must never let a push overwrite unpulled GUI work.
$StateFile = Join-Path $PSScriptRoot '.sync-state.json'
$State = @{}
if (Test-Path $StateFile) {
    (Get-Content $StateFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $State[$_.Name] = $_.Value }
}
function Get-Sha($p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }
function Save-State {
    $o = [ordered]@{}
    foreach ($k in ($State.Keys | Sort-Object)) { $o[$k] = $State[$k] }
    [IO.File]::WriteAllText($StateFile, ($o | ConvertTo-Json) + "`n", (New-Object Text.UTF8Encoding $false))
}
function Get-AuthoredTags($root) {
    foreach ($pattern in $AuthoredTagPatterns) {
        Get-ChildItem -LiteralPath $root -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue
    }
}

if ($Direction -eq 'push') {
    # Refuse if a tools-folder tag differs from the repo AND from what we last synced: that is unpulled GUI work.
    foreach ($t in Get-AuthoredTags $ToolsTags) {
        $rel = $t.FullName.Substring($ToolsTags.Length).TrimStart('\')
        $r = Join-Path $RepoTags $rel
        $toolsHash = Get-Sha $t.FullName
        $differs = -not (Test-Path $r) -or $toolsHash -ne (Get-Sha $r)
        if ($differs -and $State[$rel] -ne $toolsHash -and -not $Force) {
            Write-Host "REFUSED: $rel in the tools folder has changes the repo doesn't have (unpulled Sapien/Guerilla work?)." -ForegroundColor Red
            Write-Host "Run 'tools\sync.ps1 pull' first, or 'push -Force' to discard the tools-folder version."
            exit 1
        }
    }
    Write-Host "push data -> $ToolsData"
    $d = Copy-Tree $RepoData $ToolsData @('*')
    Write-Host "push tags -> $ToolsTags"
    $t = Copy-Tree $RepoTags $ToolsTags $AuthoredTagPatterns
    foreach ($f in Get-AuthoredTags $RepoTags) { $State[$f.FullName.Substring($RepoTags.Length).TrimStart('\')] = Get-Sha $f.FullName }
    Save-State
    # Files removed or renamed in the repo stay in the tools folder (and would still be built): report them.
    if (Test-Path $ToolsData) {
        foreach ($f in Get-ChildItem -LiteralPath $ToolsData -Recurse -File) {
            $rel = $f.FullName.Substring($ToolsData.Length).TrimStart('\')
            if (-not (Test-Path (Join-Path $RepoData $rel))) {
                Write-Host "  WARNING: data\$Level\$rel is in the tools folder but not in the repo (stale? delete it if so)." -ForegroundColor Yellow
            }
        }
    }
    Write-Host "Pushed $d data file(s), $t tag file(s)." -ForegroundColor Green
} else {
    Write-Host "pull tags <- $ToolsTags"
    $t = Copy-Tree $ToolsTags $RepoTags $AuthoredTagPatterns
    foreach ($f in Get-AuthoredTags $RepoTags) { $State[$f.FullName.Substring($RepoTags.Length).TrimStart('\')] = Get-Sha $f.FullName }
    Save-State
    Write-Host "Pulled $t tag file(s). Check 'git status'." -ForegroundColor Green
}
