# Architecture overview

*Status: accepted (ADRs 0001–0003 accepted by the owner on 2026-11-23).*

## The big idea
**We don't write a physics engine or a game; we write *content* for one.** Launch Lab is a Halo CE **singleplayer
scenario** built with Microsoft's official H1A-EK tools. The engine (MCC's Halo CE, or the Standalone test build) provides all
physics, rendering and input. Our work has four parts:

1. **World geometry**: the map's terrain and structures, modelled in Blender and exported as JMS.
2. **Scenario**: what's placed in the world. Vehicles, scenery, grenade pickups, trigger volumes and cutscene flags,
   all placed in Sapien.
3. **Scripts**: HaloScript (`.hsc`), a Lisp-like language for the game rules. It covers resets, triggers, scoring and grenade refills.
4. **Tooling and docs**: small scripts for syncing and building, CI guards, the playtest protocol and research.

The key frontend-to-Halo translation: geometry is the **static layout**, the scenario is the **component tree**
(instances with names), and HaloScript is the **event loop** (polling every 1/30 s instead of event listeners).

## Pipeline
```
 Blender (.blend)  ──export──▶  data\levels\launch_lab\models\*.jms
                                      │ tool structure / lightmaps
                                      ▼
 tools\scenario.ps1 (placements as code, invader-edit; ADR 0004)  ──▶  tags\levels\launch_lab\launch_lab.scenario
 Guerilla / Sapien (sky, viewing) ──saves──▶  same .scenario (then tools\sync.ps1 pull)   (+ .scenario_structure_bsp from Tool)
 VS Code (.hsc)  ──────────▶   data\levels\launch_lab\scripts\*.hsc
                                      │ tool build-cache-file (compiles scripts, packs stock + our tags)
                                      ▼
                              launch_lab.map  ──▶  MCC (EAC off)      ← release target and final verification
           loose tags  ───────────────────────▶  halo_tag_test.exe   ← fast inner dev loop
                                                  (OpenCE: Milestone 5 experiment only)
```

## Boundaries
| Boundary | Rule |
|---|---|
| **Stock vs ours** | Stock tags/data (Microsoft's) are **read-only** and **never committed**. Our files live in the repo under `mod/` and are synced into the H1A-EK folder by a script. |
| **Authentic physics** | We don't edit stock physics-relevant tags (`vehicle`, `physics`, `projectile`, `damage_effect`, `globals`). Any tuned variant is a **copy** under `tags\levels\launch_lab\tuned\…`, opt-in, labelled, and recorded in an ADR. |
| **Scripts** | One concern per `.hsc` file (e.g. `grenades.hsc`, `resets.hsc`, `challenges.hsc`), up to 16 files. Tuning values are globals at the top of each file, prefixed `cfg_` (e.g. `cfg_reset_delay_ticks`). |
| **Engine** | No engine modifications, injected DLLs or runtime memory hacks (Chimera, OpenSauce etc.) in the core map. Anything that needs them is out of scope unless an ADR says otherwise. |
| **Browser** | OpenCE is an *external* runtime we may test against locally. We never vendor, fork, host or redistribute it. |

## Repository layout (planned; created as tasks need it)
```
launch-lab/
  CLAUDE.md, README.md, .gitignore
  .claude/skills/            plan-task, implement-task, verify-task, checkpoint, adr
  .github/                   PR template; CI workflow (task 7)
  docs/product/              vision, mvp, roadmap
  docs/architecture/         overview (this), code-map
  docs/tasks/backlog.md      ordered task list
  docs/decisions/            ADRs
  docs/research/             feasibility research + matrix
  docs/testing/playtest.md   manual playtest protocol
  docs/progress.md, docs/learning-notes.md
  mod/                       ★ our Halo content, mirroring the H1A-EK layout
    data/levels/launch_lab/models/    .jms exports
    data/levels/launch_lab/scripts/   .hsc scripts
    tags/levels/launch_lab/           our .scenario, BSP and (later) any tuned copies
  art/                       Blender sources (.blend)
  tools/                     sync/build helpers (PowerShell), CI guards
```
The H1A-EK install path is machine-specific. It goes in a git-ignored `tools/local.config.ps1`, never in committed files.

## What gets verified, and how
| Layer | Automated (CI, no game needed) | Local build | Manual (owner plays) |
|---|---|---|---|
| Repo hygiene | No stock or proprietary files; no local paths | – | – |
| Scripts | Bracket balance; function names checked against an allowlist from the c20 reference (later) | `tool build-cache-file` compiles them | Behaviour |
| Geometry/scenario | – | `tool structure`, `lightmaps`, `check-map` clean | Collision, layout, feel |
| Physics | – | – | Playtest protocol, repeated attempts, clips |
