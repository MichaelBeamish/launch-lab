# Backlog

Ordered by table position. Task numbers are stable IDs (never renumbered), so new tasks get the next free number.
Status: `todo` · `planned` · `in-progress` · `done` · `dropped` (kept for the record, with the reason).
Before starting a task, run `/plan-task <n>`.

| # | Task | Milestone | Status |
|---|---|---|---|
| 1 | Local repo + baseline commit | 1 | done |
| 2 | Toolchain smoke test: Warthog vs grenades on a stock map | 1 | done |
| 3 | Minimal custom arena with one Warthog, playable in Standalone + MCC | 1 | done |
| 8 | Launch experiment: stacked stock frag explosions | 1 | done |
| 9 | Grenade pile gun + overshield gun (devices from stock tags) | 1 | done |
| 10 | World-scale experiment: floating island, pool, plants, height limits | 4 | done |
| 11 | Sky Islands world: the MVP (terrain, 10 levels, themes, castle, checkpoints) | 4 | done |
| 12 | One device gun (two fire modes) + a real weapon | 3 | dropped |
| 13 | Checkpoints when reaching a new level | 3 | done |
| 14 | Enemies on islands; enemy-flown Banshees | 4 | dropped |
| 15 | Slow flying ships you can walk on (device machines) | 4 | dropped |
| 16 | A big stationary ship (our own geometry) | 4 | dropped |
| 4 | Endless grenades (compare 3 methods) | 1 | done |
| 5 | Reset Warthog + player | 1 | dropped |
| 6 | Landing-platform challenge + feedback | 2 | dropped |
| 7 | CI: repo-hygiene guard + HSC lint | 2 | todo |

**Scope decision (owner, 2026-11-24): the MVP is the Sky Islands world as it stands** ("no need for portals or any of
that other stuff, let's keep this the MVP as is"). Resolved by other means or dropped:
- **4 done by other means:** unlimited grenades by script (`(set cheat_infinite_ammo on)`, task 11), plus the pile gun
  (task 9). MCC confirmation is part of task 11's MCC playtest.
- **5 dropped:** checkpoints replace resets (die → back to your last level or flashlight save).
- **6 dropped:** the climb itself is the challenge (automatic checkpoints per level).
- **13 done** in task 11. **12, 14, 15, 16 dropped**, along with Stage B (portals, waterfalls, a level-number HUD,
  ground bases): see `docs/product/map-design.md`.
- **7 (CI)** stays for later: it needs a GitHub remote first.

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
- Grenade explosions visibly move the Warthog, the same way in Standalone and in MCC. *(Reworded 2026-11-23 with the
  owner's approval. The original "visibly launched" wasn't testable by hand: the throw rate prevents stacking grenades,
  and one frag only nudges a Warthog. The launch question moved to task 8.)*
- The tools version and MCC build are recorded in `docs/research/`.
- Hashes of the stock `warthog` vehicle/physics tags and the frag grenade tags are recorded as our authenticity baseline.

## 3. Minimal custom arena
Blender flat ground + ramp + platform → JMS → `tool structure` → lightmaps → scenario in Sapien with a player spawn,
a Warthog and grenade pickups → `build-cache-file`. Sources live in `mod/`, and a sync script copies them into H1A-EK.
**Accept:**
- The arena builds with zero errors.
- It loads in Standalone and in MCC (EAC off), where the owner can drive the Warthog and launch it with grenades.
- No stock files appear in `git status`.

## 8. Launch experiment: stacked stock frag explosions
Comes after task 3 (needs our arena, for cutscene flags). Task 2 showed that one stock frag only nudges a Warthog, and
the throw rate prevents stacking grenades by hand. A script sets off N stock frag explosions together beside the parked
Warthog with `damage_new "weapons\frag grenade\explosion" <flag>` (the form used by stock `a10` scripts, e.g.
`(damage_new "levels\a10\devices\shield charge\zapper" tutorial_zapper_flag)`), for N = 1, 2, 3, 4…, triggered from
the console in Standalone. No stock tag changes (ADR 0002).
**Accept:**
- For each N tested, 3 attempts are recorded: did the Warthog leave the ground or flip, and roughly how high.
  *(Adaptive search with the owner's approval, 2026-11-23: start at N = 4, then go down (2, 3) or up (6, 8).)*
- The smallest N that gives a visible launch is found, or "none up to N = 8" is recorded.
- The stock-tag hash check still passes.
- The result is written into the MVP: keep "launch with grenades" as is, or revise it with the owner.

## 9. Grenade pile gun (owner's idea, 2026-11-23)
A gun the player spawns with. Each shot drops a **stock** frag grenade pickup where it hits, without exploding. Stock data
says pickups are `destroyed_by_explosions` (0.4–0.8 s delay) and the frag explosion `detonates_explosives`, so piles should
chain-react. A trigger can't fire equipment ("equipment tags cannot be referenced here"), so the chain is: gun (copy of the
stock pistol) → pellet (copy of the pistol bullet, no damage) → impact effect (ours) whose one part creates the stock
`frag grenade.equipment`. The tags are built as code from stock with `invader-edit` (ADR 0005).
*Extended by the owner:* a second gun (plasma pistol copy) that drops stock overshields the same way.
**Accept:**
- You spawn with the gun; shots leave grenade pickups on the floor.
- The second gun's shots become overshield pickups you can collect.
- One thrown grenade sets off a pile, which cascades.
- The stock hash check passes; `check-map` and the cache build are clean.

## 10. World-scale experiment
Prove the Sky Islands building blocks before building the world (see `docs/product/map-design.md`): a floating island,
stock plants and a boulder on it, a stock water pool, a much bigger and taller sky box, and how build and lightmap times
grow. Planned in chat with the owner.

## 11–16. Sky Islands and later features
From the owner's map vision (`docs/product/map-design.md`). Each is planned when it comes up.
- **12:** the two devices merged into one gun (plasma pistol: normal shot = grenades, charged = overshields), freeing a
  slot for a real weapon (players carry two weapons: *likely*, to be confirmed).
- **13:** checkpoints on reaching a level (`game_save`-style; to be researched).
- **14:** enemies (AI encounters) on some islands, and Banshees flown by enemies.
- **15:** walkable slow ships as device machines (our own model and animation).
- **16:** a big stationary ship built as our own geometry.

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
