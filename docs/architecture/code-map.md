# Code map

Where things are, and "to change X, edit Y". Update this map in the same change whenever a file, script, named object or
tuning global is added, renamed or removed. A drift check will come with the CI tooling (task 7).

## Files
| Path | What it is |
|---|---|
| `CLAUDE.md` | Project rules for Claude |
| `.claude/skills/*/SKILL.md` | Workflow skills: plan-task, implement-task, verify-task, checkpoint, adr |
| `docs/product/` | Vision, MVP, roadmap |
| `docs/architecture/overview.md` | Pipeline, boundaries, repo layout |
| `docs/research/` | Feasibility research and matrix |
| `docs/testing/playtest.md` | Manual playtest protocol |
| `docs/decisions/` | ADRs |
| `art/launch_lab_arena.py` | **The world generator** (Blender script): terrain (hills, mesas), the 10-level climb (`LEVELS`: height, layout, hop, theme), natural islands, bridges with landing notches, island themes, the summit castle; plans placements; writes the JMS, `world_layout.json` and `world.hsc` |
| `mod/data/levels/launch_lab/models/launch_lab.JMS` | **Generated, git-ignored**: the geometry |
| `mod/data/levels/launch_lab/world_layout.json` | **Generated, git-ignored**: levels, islands, vehicles, trees and rocks (with exact heights), landing zones, level flags; read by `tools/scenario.ps1` |
| `mod/data/levels/launch_lab/scripts/world.hsc` | **Generated, git-ignored**: fall guard (all landing zones), automatic checkpoints per level, flashlight-key checkpoint, `(dbg_tp_level_N)` teleports |
| `mod/data/levels/launch_lab/scripts/launch_lab.hsc` | Hand-written HaloScript: `unlimited_ammo` (sets `cheat_infinite_ammo`, also in MCC) |
| `mod/data/levels/launch_lab/scripts/debug.hsc` | **Debug-only** scripts, left out of release builds: `(dbg_boom_1..8)`, `(dbg_hog_reset)`, `(dbg_tp_ground)` |
| `mod/tags/levels/launch_lab/launch_lab.scenario` | Our scenario (committed): type singleplayer, sky `sky_timberland` (set in Guerilla), placements from `tools/scenario.ps1` |
| `tools/scenario.ps1` | **Placements as code** (ADR 0004): hand-made items (spawn, `hog`, frags, starting profile, debug flags) plus the generated world from `world_layout.json`; batched `invader-edit` writes, sampled read-back, `check-map` |
| `tools/build.ps1` | `-Release`: better lighting, no debug scripts, dated map + SHA-256 in `%LOCALAPPDATA%\LaunchLabTools\release\` (`-FinalLighting`: slow quality 1, overnight only). Logs are written live. Steps `jms`, `devices`, `structure`, `lightmaps`, `scenario`, `cache` (or `all`). Skips structure + lightmaps when the geometry is unchanged (`-Rebuild` forces); draft lightmaps by default (`-LightmapQuality 1 -LightmapStop 0.3` for release); fails on error lines or a new `.wrl`; logs in `build-logs/` (ignored) |
| `tools/sync.ps1` | `push` repo → tools folder; `pull` the `.scenario` back after a GUI edit. Refuses to push over unpulled GUI work (hash-based) |
| `tools/devices.ps1` | **Gameplay devices from stock** (ADR 0005): pile gun (pistol → frag pellet → stock frag pickup) and shield gun (plasma pistol → orb pellet → stock overshield). Every change from stock listed and read back; outputs generated in the tools folder (git-ignored) |
| `ci/` | **CI** (task 7): `src/guard.ts` (repo hygiene), `src/hsc-lint.ts` (HaloScript lint), `src/cli.ts` (runs both over `git ls-files`), `test/` (Vitest, incl. deliberately bad cases), `hsc-functions.json` (confirmed engine functions) |
| `.github/workflows/ci.yml` | GitHub Actions: runs the CI on every push to `main` and every pull request |
| `tools/package-mod.ps1` | Builds the Excession mod folder (`Documents\Launch Lab Workshop\LaunchLab\`: `maps\launch_lab.map` from the newest release, SHA-256 checked; `images\`) outside the repo (ADR 0006) |
| `docs/PLAY.md` | Player guide: what to buy, what to install, subscribe, launch, troubleshooting |
| `docs/release/workshop-upload.md` | Owner runbook: Excession set-up, the mod form, local test, upload, Workshop description |
| `tools/mcc-swap.ps1` | `install` / `restore` / `status`: plays our map in MCC in place of a stock SP map (`a10`), with a SHA-256-checked backup |
| `tools/local.config.ps1` | **Git-ignored.** Machine paths: mod tools folder (`ToolsRoot`) and MCC folder (`GameRoot`) |
| `tools/stock-baseline.ps1` | Hashes the stock physics tags and compares them with the baseline (ADR 0002); `-Record` rewrites it |
| `tools/stock-tag-hashes.json` | The baseline: SHA-256 of 8 stock tags + the tools build they were recorded on |
| `docs/research/toolchain-baseline.md` | Tool and game versions, confirmed tool facts, task 2 playtest |
| `tools/standalone.ps1` | Starts `halo_tag_test.exe` windowed (high-DPI fix), after copying `tools/standalone/init.txt` into the tools folder |
| `tools/standalone/init.txt` | Console commands Standalone runs at startup (source of truth; the copy in the tools folder is overwritten) |

## Named scenario objects, flags and volumes
| Name | What | Where (WU) | Defined in |
|---|---|---|---|
| `hog` | Stock Warthog on the ground | (0, −15, 0.5) | `tools/scenario.ps1` |
| *(unnamed)* | Player start; 3 frag pickups | (0, −17, 0.5); (2..4, −17, 0.2) | `tools/scenario.ps1` |
| `boom_flag`, `ground_flag` | Debug flags: stacked explosions (task 8), teleport back to the spawn | (0, −15, 0.1), (0, −17, 0.5) | `tools/scenario.ps1` |
| `level_N_flag` | Debug teleport target per level (a free spot on the main island) | generated | `world_layout.json` |
| `level_N_zone_K` | Landing zone over each island; also that level's checkpoint zone | generated | `world_layout.json` |
| `ground_zone`, `hill_I_J` | Landing zones: flat ground, and tilted zones over hilly ground | generated | `world_layout.json` |
| `level_N_bridge_zone_K`, `level_N_castle_zone_K`, `level_N_K_structure_zone_T` | Landing zones over bridges, castle parts, theme structures | generated | `world_layout.json` |

The world (`art/launch_lab_arena.py`): 1000 × 1000 × 1000 WU sky box; 10 levels from z 20 to the castle summit at z 620;
hops 30, 45, 65, 90, then 115 WU; one Warthog per group of connected islands. Limit: 256 trigger volumes per scenario
(the generator stops at 240).

## To change X, edit Y
- **Change a gun or what it drops** → edit `$Devices` in `tools/devices.ps1`, then `tools\build.ps1 -Step devices` (Standalone reads the new tags at load).
- **Change the starting loadout** → `$StartingProfile` in `tools/scenario.ps1`.
- **Move or add a hand-made spawn, vehicle or pickup** → the lists at the top of `tools/scenario.ps1`, then `tools\build.ps1 -Step all`.
- **Change the climb** (heights, hops, cluster/solo, themes) → the `LEVELS` table in `art/launch_lab_arena.py`, then `tools\build.ps1 -Step all`.
- **Change the terrain** → `HILLS` / `MESAS` in `art/launch_lab_arena.py`. **An island's look or a theme** → `natural_island` / `build_theme`.
- **Change what grows where** → `SCATTER_ISLAND` / `SCATTER_GROUND` and `plan_placements` (generator); stock paths in `$SceneryKinds` (`tools/scenario.ps1`).
- **Play our map in MCC** → `tools\build.ps1 -Step cache`, `tools\mcc-swap.ps1 install`, play *The Pillar of Autumn* (anti-cheat off), then `tools\mcc-swap.ps1 restore`.
- **Change what Standalone does at startup** (level, cheats) → edit `tools/standalone/init.txt`, relaunch with `tools\standalone.ps1`.
- **Use a new HaloScript function** → confirm it with `tool script-doc <name>`, then add it to `ci/hsc-functions.json` (CI rejects unconfirmed calls).
- **Protect another stock tag** → add it to `$StockTags` in `tools/stock-baseline.ps1`, then re-record (owner's OK).
