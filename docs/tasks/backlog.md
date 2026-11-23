# Backlog

Ordered by table position. Task numbers are stable IDs (never renumbered), so new tasks get the next free number.
Status: `todo` · `planned` · `in-progress` · `done` · `dropped` (kept for the record, with the reason).
Before starting a task, run `/plan-task <n>`.

| # | Task | Milestone | Status |
|---|---|---|---|
| 1 | Local repo + baseline commit | 1 | done |
| 2 | Toolchain smoke test: Warthog launch on a stock map | 1 | todo |
| 3 | Minimal custom arena with one Warthog, playable in Standalone + MCC | 1 | todo |
| 4 | Endless grenades (compare 3 methods) | 1 | todo |
| 5 | Reset Warthog + player | 1 | todo |
| 6 | Landing-platform challenge + feedback | 2 | todo |
| 7 | CI: repo-hygiene guard + HSC lint | 2 | todo |

## 1. Local repo + baseline commit
`git init` in `launch-lab`, `main` as the default branch, add `.gitignore`, then commit the kickoff docs and skills **with the owner's
approval**. No remote yet. Creating the GitHub repo and protecting `main` is a later, separately approved step.
**Accept:** `git status` is clean; `git log` shows one commit; ignored patterns are verified with `git check-ignore`.

## 2. Toolchain smoke test (no custom content)
Owner buys *Halo: Combat Evolved Anniversary* on Steam (installs MCC with Halo CE; Campaign **and** Multiplayer) and
installs the free *Halo: CE Mod Tools – MCC*, then runs `(Extract).bat`. Load a stock
singleplayer level in `halo_tag_test.exe`, spawn a Warthog (`cheat_spawn_warthog`), and launch it with grenades. Then do the same
in MCC with a stock level. Record the install paths in the git-ignored local config, the versions and observations.
**Accept:**
- Standalone loads a level and the console works.
- A Warthog is visibly launched by grenade explosions in Standalone and in MCC.
- The tools version and MCC build are recorded in `docs/research/`.
- Hashes of the stock `warthog` vehicle/physics tags and the frag grenade tags are recorded as our authenticity baseline.

## 3. Minimal custom arena
Blender flat ground + ramp + platform → JMS → `tool structure` → lightmaps → scenario in Sapien with a player spawn,
a Warthog and grenade pickups → `build-cache-file`. Sources live in `mod/`, and a sync script copies them into H1A-EK.
**Accept:**
- The arena builds with zero errors.
- It loads in Standalone and in MCC (EAC off), where the owner can drive the Warthog and launch it with grenades.
- No stock files appear in `git status`.

## 4. Endless grenades
Try `cheat_infinite_ammo`, a scripted top-up and respawning pickups. Choose one with the owner (ADR if it's notable).
**Accept:**
- The player can throw at least 30 grenades in a row without running out.
- Grenade behaviour is otherwise unchanged (no stock tag edits).

## 5. Reset
Return the Warthog (upright, stopped) and the player to their start spots without reloading. The trigger could be a reset pad or an input test.
**Accept:** works 5× in a row, including when the Warthog is upside down or destroyed.

## 6. Landing-platform challenge
A trigger volume on the platform, plus a "came to rest" check (the Warthog stays in the volume for N ticks). Show a title, play a sound,
and increase a counter.
**Accept:**
- Fires on a real landing (3 attempts).
- Doesn't fire on a drive-through or a mid-air pass.

## 7. CI guard
A GitHub Actions workflow, created once the remote exists. It fails if stock or proprietary files (`.map`, stock tag paths outside `mod/tags/levels/launch_lab/`,
absolute local paths) are committed, and runs a small HSC lint (bracket balance; known-function allowlist), written in TypeScript with tests.
**Accept:** CI passes on clean branches and fails on a deliberately bad commit.
