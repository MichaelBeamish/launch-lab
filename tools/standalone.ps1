<#
.SYNOPSIS
  Starts Standalone (halo_tag_test.exe) in a window, running tools\standalone\init.txt at startup.

.DESCRIPTION
  Copies the repo's init.txt into the mod tools folder (Standalone runs every line of init.txt in that folder as a
  console command at startup; c20: /h1/engine/arguments). The repo copy is the source of truth.

  Runs windowed because full screen is cropped on high-DPI displays (seen at 200% scaling, task 2).
  -vidmode is "useful for the H1A standalone build which cannot be configured in-game" (c20).

.PARAMETER Width
  Window width in pixels (default 1600).

.PARAMETER Height
  Window height in pixels (default 1000).
#>
param(
    [int]$Width = 1600,
    [int]$Height = 1000
)

$ErrorActionPreference = 'Stop'
$ConfigFile = Join-Path $PSScriptRoot 'local.config.ps1'
if (-not (Test-Path $ConfigFile)) {
    throw "Missing tools\local.config.ps1. Create it with: `$LaunchLab = @{ ToolsRoot = '<mod tools folder>'; GameRoot = '<MCC folder>' }"
}
. $ConfigFile
if (-not $LaunchLab -or -not $LaunchLab.ToolsRoot) { throw "tools\local.config.ps1 doesn't set `$LaunchLab.ToolsRoot." }

$exe = Join-Path $LaunchLab.ToolsRoot 'halo_tag_test.exe'
if (-not (Test-Path $exe)) { throw "Standalone not found: $exe (check ToolsRoot in tools\local.config.ps1)" }

$source = Join-Path $PSScriptRoot 'standalone\init.txt'
$target = Join-Path $LaunchLab.ToolsRoot 'init.txt'
# Keep a copy of an init.txt we didn't write, rather than silently replacing it.
if ((Test-Path -LiteralPath $target) -and
    (Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $source).Hash) {
    Copy-Item -LiteralPath $target -Destination "$target.bak" -Force
    Write-Host "Backed up the existing init.txt to init.txt.bak in the tools folder."
}
Copy-Item -LiteralPath $source -Destination $target -Force

# Working directory must be the tools folder: Standalone resolves tags\ and init.txt relative to it.
Start-Process -FilePath $exe -WorkingDirectory $LaunchLab.ToolsRoot -ArgumentList @('-windowed', '-vidmode', "$Width,$Height,60")
Write-Host "Started Standalone ${Width}x$Height windowed with tools\standalone\init.txt."
