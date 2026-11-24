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
| `mod/` | *(task 3)* Our Halo content, mirroring the H1A-EK `data/` + `tags/` layout |
| `art/` | *(task 3)* Blender sources |
| `tools/local.config.ps1` | **Git-ignored.** Machine paths: mod tools folder (`ToolsRoot`) and MCC folder (`GameRoot`) |
| `tools/stock-baseline.ps1` | Hashes the stock physics tags and compares them with the baseline (ADR 0002); `-Record` rewrites it |
| `tools/stock-tag-hashes.json` | The baseline: SHA-256 of 8 stock tags + the tools build they were recorded on |
| `docs/research/toolchain-baseline.md` | Tool and game versions, confirmed tool facts, task 2 playtest |
| `tools/standalone.ps1` | Starts `halo_tag_test.exe` windowed (high-DPI fix), after copying `tools/standalone/init.txt` into the tools folder |
| `tools/standalone/init.txt` | Console commands Standalone runs at startup (source of truth; the copy in the tools folder is overwritten) |
| `tools/` (more) | *(task 3)* Sync/build helpers |

## Named scenario objects, flags and volumes
*(none yet: added from task 3)*

## To change X, edit Y
- **Change what Standalone does at startup** (level, cheats) → edit `tools/standalone/init.txt`, relaunch with `tools\standalone.ps1`.
- **Protect another stock tag** → add it to `$StockTags` in `tools/stock-baseline.ps1`, then re-record (owner's OK).
