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
| `art/launch_lab_arena.py` | **Arena geometry as code** (Blender script): sealed shell on one grid, `+sky` walls/ceiling, ramp, platform, UVs; exports the JMS |
| `mod/tags/levels/launch_lab/launch_lab.scenario` | Our scenario (committed): type singleplayer, sky `sky_timberland` (set in Guerilla), placements from `tools/scenario.ps1` |
| `mod/data/levels/launch_lab/models/launch_lab.JMS` | **Generated, git-ignored**: exported by the arena script |
| `tools/scenario.ps1` | **Placements as code** (ADR 0004): spawn, vehicles, equipment, cutscene flags, object names via `invader-edit`; read-back + `check-map` |
| `mod/data/levels/launch_lab/scripts/launch_lab.hsc` | Level HaloScript. Debug-only `dbg_` scripts: `(dbg_boom_1..8)` stacked stock frag explosions at `boom_flag`, `(dbg_hog_reset)` |
| `tools/build.ps1` | Build steps `jms`, `structure`, `lightmaps`, `cache` (or `all`); fails on error lines or a new `.wrl`; logs in `build-logs/` (ignored) |
| `tools/sync.ps1` | `push` repo → tools folder; `pull` the `.scenario` back after a GUI edit. Refuses to push over unpulled GUI work |
| `tools/devices.ps1` | **Gameplay devices from stock** (ADR 0005): pile gun (pistol → frag pellet → stock frag pickup) and shield gun (plasma pistol → orb pellet → stock overshield). Every change from stock listed and read back; outputs generated in the tools folder (git-ignored) |
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
| `hog` | Stock Warthog (`vehicles\warthog\warthog.vehicle`) | (0, −15, 0.5), yaw 90° (up the ramp) | `tools/scenario.ps1` |
| *(unnamed)* | Player start | (0, −17, 0.5), facing 90° | `tools/scenario.ps1` |
| *(unnamed)* ×3 | Frag grenade pickups | (2..4, −17, 0.2) | `tools/scenario.ps1` |
| `boom_flag` | Cutscene flag under the Warthog (task 8 debug explosions) | (0, −15, 0.1) | `tools/scenario.ps1` |

Arena layout (`art/launch_lab_arena.py`): 40 × 40 WU, ceiling 30 WU; ramp x −3..3, y −12 → 0, top 3 WU; platform x −5..5,
y 8..16, 4 WU high (not reachable by driving; the launch target).

## To change X, edit Y
- **Change a gun or what it drops** → edit `$Devices` in `tools/devices.ps1`, then `tools\build.ps1 -Step devices` (Standalone reads the new tags at load).
- **Change the starting loadout** → `$StartingProfile` in `tools/scenario.ps1`.
- **Move or add a spawn, vehicle or pickup** → edit the lists at the top of `tools/scenario.ps1`, run it, then load in Standalone.
- **Change the arena shape** → edit the layout constants in `art/launch_lab_arena.py`, then `tools\build.ps1 -Step all`.
- **Play our map in MCC** → `tools\build.ps1 -Step cache`, `tools\mcc-swap.ps1 install`, play *The Pillar of Autumn* (anti-cheat off), then `tools\mcc-swap.ps1 restore`.
- **Change what Standalone does at startup** (level, cheats) → edit `tools/standalone/init.txt`, relaunch with `tools\standalone.ps1`.
- **Protect another stock tag** → add it to `$StockTags` in `tools/stock-baseline.ps1`, then re-record (owner's OK).
