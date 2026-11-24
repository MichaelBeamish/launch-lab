# Progress Log

Newest first. One entry per verified task or significant decision.

## 2026-11-24 — Task 11: the Sky Islands world (the MVP)
- **Built:**
  - `art/launch_lab_arena.py` is now the **world generator**:
    - terrain with hills and mesas;
    - a 10-level climb (hops 30 → 115 WU, then growing rises, owner-tuned);
    - natural islands (smooth noise, rounded undersides, smooth shading) and bridges with landing notches;
    - island themes (ruins and watchtower, crash sites, landing pads with beacons, rock spires, groves, a pool);
    - a Forerunner-style castle on a big summit at z 620.
  - It writes the geometry, `world_layout.json` and `world.hsc`, and `scenario.ps1` applies the layout.
  - **Scripts:** a fall guard (no mid-air fall death; you die at the ground), automatic checkpoints per level, a
    flashlight-key checkpoint, unlimited ammo by script, per-level debug teleports.
  - **Builds:** placements before the map; skip unchanged geometry (6 s vs minutes); quick draft lighting.
  - **Removed:** the ramp and platform, vines, turrets, the test Banshee.
- **Problems found and fixed:**
  - The `c10 moss` shader is alpha-tested (see-through patches).
  - Bridge ends intersected islands ("z buffered triangles", fixed with landing notches).
  - The pool water reached into rock ("clipped to no leaves").
  - Trigger volumes are **limited to 256** (Tool refused 397; tilted zones on hills fixed it; the research note was wrong).
  - Scientific-notation numbers were misread by invader-edit (caught by read-back).
  - `check-map` "OK" while Tool failed to load the scenario (filter tightened).
  - The engine stores a fall death while damage is blocked (zones must end just above surfaces).
  - The non-solid `tree_gnarled_doublewide`.
- **Playtests (owner):** several rounds in Standalone ("it looks awesome"), then MCC: everything works, including
  unlimited ammo (by script), the guns, checkpoints and the fall guard.
- **Verified:** full builds clean (no BSP warnings, 11,410 surfaces, 6.4 MiB tags), `check-map` OK, scripts compile,
  stock hashes PASS. Code review: 6 important and 4 small findings fixed (Warthog in wrecks, zones on columns and spires,
  teleports into structures, the island overlap check, trees under low islands, flat plazas for wrecks); the hop
  accuracy (±5 WU) noted.
- **Scope (owner):** the MVP is this world as it stands; portals, waterfalls, a level HUD, ground bases, enemies and
  ships are not planned. Browser play stays local-only (ADR 0003).

## 2026-11-23 — Task 10: world-scale experiment; Sky Islands design
- **Design:**
  - `docs/product/map-design.md` records the owner's vision (massive floating islands, a climb that gets cooler as you
    go, bridges, pools, waterfalls, tanks and turrets on islands, later enemies and ships) and c20's world limits.
  - Roadmap Milestone 4 is now "Sky Islands"; backlog tasks 11–16 added.
- **Built:**
  - The arena became a 1000 × 1000 × 1000 WU sky box (50 WU grid).
  - Two floating islands (z 40 and z 900), a water pool, stock plants and a boulder (`scenario.ps1` now manages scenery).
  - Debug teleports.
  - The arena script now orients each closed shape on its own (the shell faces inwards, islands outwards) and seal-checks each one.
- **Results** (`docs/research/world-scale.md`):
  - Structure 3 s with no warnings; draft lightmaps **8.8 min** on one core; tag space 3.94 MiB.
  - Playtest: massive, teleports work, islands solid; plants, boulder and water render; no jitter at z 900; smooth frame rate.
- **Owner feedback for next:** natural-looking islands, a few natural walk-out pools, a test Banshee, no mid-air fall
  death (keep the impact death), and faster iteration than re-lighting every build.
- **Verified:** builds, `check-map`, stock hashes PASS; owner playtest. Code review skipped: geometry and data-list
  changes, checked by the script's own seal check and the builds.

## 2026-11-23 — Task 9: grenade pile gun and overshield gun (ADR 0005)
- **Built:** `tools/devices.ps1` generates two devices from stock tags with `invader-edit`:
  - **Pile gun:** stock pistol copy → frag-projectile pellet (muzzle speed 8, final 0; per-surface detonation effects
    cleared) → effect whose one part creates a stock frag grenade pickup. The firing sound is the stock melee thump.
  - **Shield gun:** stock plasma pistol copy (both triggers, no battery drain) → pellet with the overshield orb model →
    effect creating a stock overshield.
  - The starting profile gives both guns plus 4 frags. Build order: devices before structure.
- **Playtest (Standalone), each problem fixed in turn:**
  - Pellets first bounced forever (final velocity 8 is held constant) → fixed.
  - A rubble pop on settling (inherited surface detonation effects) → fixed.
  - The throw sound sounded like a live frag → changed to a thump ("sounds great").
  - Piles form where you aim; **one thrown frag cascades the pile and launches the Warthog "super far"**.
  - Overshields drop and can be picked up. The orb sinks into the floor briefly (cosmetic, kept).
  - The plasma pistol keeps its stock look and sound (owner's choice).
- **Verified:** fresh full build OK; `check-map` OK; stock hashes PASS (also enforced at the end of `devices.ps1`).
  Code review: 10 findings (5 important) fixed and re-tested, including a fresh-machine build-order bug.
  Also fixed: a `scenario.ps1` success-flag bug that let a failed read-back exit 0.
- **Not verified:** MCC play of the guns (Standalone only so far).

## 2026-11-23 — Task 8: stacked stock frag explosions launch the Warthog; lighter process
- **Built:**
  - Our first HaloScript, `launch_lab.hsc`: debug `dbg_boom_N` and `dbg_hog_reset`. Every function was confirmed with
    `tool script-doc`.
  - `boom_flag` (cutscene flags now managed by `tools/scenario.ps1`).
- **Playtest (Standalone):**
  - Console script calls need brackets.
  - 2/2 launches: a backflip; then one hit the 30 WU ceiling. The Warthog survived both.
- **Correction (found by inspecting stock tags):** the frag explosion `.effect` already contains the damage, so the first
  script (effect + damage) counted each blast twice. **The launches were 8 stacked stock frags, not 4.** Fixed to
  `effect_new` only. The smallest launching count is unmeasured; the owner judged the answer clear enough.
- **Found for task 9:** grenade pickups are `destroyed_by_explosions`; the frag explosion `detonates_explosives`. A weapon
  trigger can't fire equipment, but an effect part can create it.
- **Process (owner):** a lighter process from now on, recorded in CLAUDE.md and the plan/verify skills: short plans for
  small tasks, code review only for significant tooling changes, docs only when they change, related tasks may share a branch.
- **Verified:** script compile (cache build OK), `check-map` OK, stock hashes PASS. Code review skipped: small script and
  data-list change, reviewed by hand.

## 2026-11-23 — Task 3: minimal custom arena (Standalone + MCC); ADR 0004 accepted
- **Installed (owner-approved):**
  - Blender 4.5.10 LTS (winget, installer hash verified).
  - Halo Asset Blender Development Toolset master-432, lite build (MIT; inspected: plain Python).
  - Invader 0.55.0 (GPLv3; SHA-256 verified against GitHub). Local only, outside the repo.
- **Built:**
  - `art/launch_lab_arena.py`: the arena as code. A 40 × 40 WU sealed `+sky` box, ramp (top 3 WU) and platform
    (4 WU high), stock tutorial shaders, UVs.
  - `tools/build.ps1`: geometry → `structure` → `lightmaps` (draft) → `build-cache-file classic none`.
  - `tools/scenario.ps1`: placements as code (spawn, Warthog `hog`, 3 frags) via `invader-edit`, with read-back and `check-map`.
  - `tools/sync.ps1`: repo ↔ tools folder, with a hash-based guard for unpulled GUI work.
  - `tools/mcc-swap.ps1`: plays our map in MCC as `a10.map`; backup and restore verified by hash and header map name.
  - The scenario: sky set by the owner in Guerilla.
- **Experiment:** Sapien was too hard to use without a mouse. `invader-edit` on a scenario copy produced identical
  `check-map` output and loaded in Standalone → **ADR 0004**.
- **Build:** zero errors, no `.wrl`; the map uses 3.59 of 64 MiB tag space. Expected warnings: no ambient sound, no level scripts yet.
- **Playtest:**
  - Standalone: spawn ✅, ramp 3/3 ✅, frag moves the Warthog ✅, invisible edge wall ✅, nothing odd ✅.
  - MCC (*The Pillar of Autumn* slot, anti-cheat off, classic graphics): arena loads ✅, pickups give grenades ✅,
    "everything works" ✅. Stock `a10.map` restored and verified.
  - No clips.
- **Unverified:**
  - The platform is walkable: it can't be reached by driving, since it's the launch target (task 8).
  - The remastered toggle.
  - The starting loadout (no grenades at spawn, it seems; task 4).
- **Verified:** stock hashes PASS after every step; git has only our files; the scenario has no local paths.
  Code review: 7 important and 3 small findings, all fixed and re-tested with their failure cases. Security review done by hand: no findings.
- **Learned:**
  - A missing UV map makes the lightmapper fail ("degenerate triangle [or triangle with bad uvs]").
  - Lightmap error `.wrl` files land in the tools root.
  - PowerShell 5.1 turns Tool's stderr warnings into fatal errors under `Stop`.
  - invader-edit: comma-separated points; angles set in radians, shown in degrees; `object_names` needs `-n`.
  - MCC plays custom SP maps only by taking a stock map's file name (as far as c20 documents).

## 2026-11-23 — Task 2: toolchain smoke test (Warthog vs grenades on a stock map)
- **Built:**
  - `tools/stock-baseline.ps1`: hashes 8 stock physics tags; `tools/stock-tag-hashes.json` is the baseline.
  - `tools/standalone.ps1` + `tools/standalone/init.txt`: windowed launcher, added for the high-DPI crop.
  - Git-ignored `tools/local.config.ps1`.
  - `docs/research/toolchain-baseline.md` with versions, confirmed tool facts and the playtest.
- **Versions:** mod tools build 11722677 (Standalone 01.03.43.0000), MCC build 19905945.
- **Playtest:**
  - Standalone (b30, `cheat_spawn_warthog`, `cheat_infinite_ammo 1`): console ✅, Warthog spawn ✅. 5 single frags each
    moved the Warthog slightly ✅ (no lift-off seen). Infinite grenades ✅.
  - MCC (The Silent Cartographer, classic graphics, no cheats): the same small nudge per frag ✅.
  - No clips.
- **Criterion change (owner-approved):** "visibly launched" → "visibly moved, same in Standalone and MCC". Stacking
  grenades by hand isn't possible at the game's throw rate. The launch question is now **task 8** (scripted, stacked stock
  explosions); the MVP records it as an open risk.
- **Verified:** hash check PASS (8 tags); self-test cases pass/fail as expected; no stock files or local paths in git.
  Code review: 1 important and 5 small findings fixed and re-tested, 1 rejected. Security review done by hand (the skill
  needs a remote): no findings.
- **Learned:**
  - One stock frag only nudges a Warthog, identically in Standalone and MCC (first parity evidence).
  - `cheat_infinite_ammo` covers grenades in Standalone.
  - Full screen is cropped at 200% display scaling; windowed `-vidmode` fixes it.
  - Standalone logs to `reports\debug.txt` in the tools folder.
  - Right mouse button throws grenades.

## 2026-11-23 — Task 1: local repo + baseline commit; ADRs 0001–0003 accepted
- The owner accepted ADRs 0001–0003 as proposed.
- `git init` with `main` as the default branch, and no remote. The commit identity is set in this repo's local config
  (GitHub noreply address, as in the owner's earlier projects).
- One baseline commit of the kickoff docs, skills, `.gitignore` and PR template.
- **Verified:** `git status` is clean, `git log` shows one commit, and `git check-ignore` confirms the ignore patterns
  (see the task 1 checks in the commit's PR notes / session summary).

## 2026-11-23 — Kickoff: Milestone 0 (technical feasibility) drafted
- Reviewed the earlier projects' workflow (Ink Tank/`creature-world` and Commuting Through Time, read-only). Adapted the five
  skills to a Halo toolchain: tag builds and recorded playtests replace unit tests and the browser.
- Ran parallel research (mod tools/scripting, OpenCE/browser, legal) → `docs/research/`, feasibility matrix.
- Proposed ADRs:
  - 0001: H1A-EK singleplayer scenario for MCC.
  - 0002: MCC stock-tag physics baseline.
  - 0003: distribution posture.
- Drafted the vision, MVP, roadmap, architecture and backlog (tasks 1–7).
- **Verified:** documentation only. Nothing has been built or played yet. All capability claims are documented, not proven.
- **Learned:**
  - OpenCE is a decompiled *Xbox development build*. It needs an Xbox disc image and is AGPL-licensed, so it isn't a
    distribution path.
  - Explosion chaining works only in singleplayer.
  - HaloScript can't read coordinates or set velocities.
