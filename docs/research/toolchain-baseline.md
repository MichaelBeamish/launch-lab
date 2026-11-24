# Toolchain baseline

The versions and stock-tag hashes our "authentic physics" claim is measured against (ADR 0002). Recorded in task 2.
Install paths are machine-specific and live only in the git-ignored `tools/local.config.ps1`.

## Versions (recorded 2026-11-23)
| Component | Version | Source |
|---|---|---|
| Halo: CE Mod Tools – MCC (Steam app 1532190) | Steam build `11722677` | `appmanifest_1532190.acf` |
| Standalone (`halo_tag_test.exe`) | `halo1 pc 01.03.43.0000` | header line of the tools' `reports\debug.txt` |
| Halo: The Master Chief Collection (Steam app 976730) | Steam build `19905945` | `appmanifest_976730.acf` |
| Halo CE content | Anniversary add-on (DLC 1064221) plus a second Halo CE package (DLC 1080080). Name of the second one unconfirmed; it installs only into `halo1\` | `appmanifest_976730.acf`, installed folders |

After any Steam update to the tools or the game: re-run the mod tools' `(Extract).bat`, run `tools\stock-baseline.ps1`,
and record the new builds here. If the hash check fails after an official update, re-record only with the owner's OK
and note what changed.

## Stock tag hashes
Stored in [`tools/stock-tag-hashes.json`](../../tools/stock-tag-hashes.json) (SHA-256, paths relative to the tools' `tags\`):
- `vehicles\warthog\warthog.vehicle`, `warthog.physics`, `warthog.model_collision_geometry`
- `weapons\frag grenade\frag grenade.projectile`, `explosion.damage_effect`, `shock wave.damage_effect`,
  `effects\explosion.effect` (likely the detonation effect; not confirmed which effect the projectile uses)
- `globals\globals.globals`

The collision geometry and detonation effect were added after code review, with the owner's approval. The original six
hashes were checked unchanged before the 8-tag baseline was recorded.

Check: `powershell -ExecutionPolicy Bypass -File tools\stock-baseline.ps1` → `PASS` (exit 0), `FAIL` (exit 1), setup problem (exit 2).
Self-test (2026-11-23, re-run after code review): passes on the real tags and on untouched copies; fails on a copy
with one flipped byte (`CHANGED`), on a deleted copy (`MISSING`) and when a baseline tag is dropped from the script's list
(`NOT CHECKED`). It refuses `-Record` together with `-TagsRoot` (a test copy can't become the baseline), and reports a
config without `ToolsRoot` or a missing baseline as a setup problem (exit 2).

## Facts confirmed in the installed tools (2026-11-23)
- The extracted archive holds 13,525 files: `tags\` (11,538 files, 1.7 GB), `data\` (1,766 files, including 36 stock `.hsc`
  scripts) and `shaders\`.
- `halo_tag_test.exe` contains the commands `cheat_spawn_warthog` ("drops a warthog near player"), `cheat_all_vehicles`,
  `cheat_all_weapons`, `cheat_infinite_ammo`, `cheat_bottomless_clip`, `framerate_throttle`, `map_name`, `game_revert`.
- Stock levels that reference `vehicles\warthog\warthog`: `a30` (Halo) and `b30` (The Silent Cartographer).
  `levels\test\bloodgulch` uses `mp_warthog` and `rwarthog` instead.
- Launched with no `tags\`, Standalone quits immediately: `couldn't open scenario tag 'ui.scenario'` / `game_load() failed`
  (see `reports\debug.txt`). Fix: run `(Extract).bat`.

## Task 2 playtest

### Part A: Standalone, 2026-11-23 (tools build 11722677)
Launched with `tools\standalone.ps1` (windowed 1600x1000; `init.txt` ran `framerate_throttle 1`, `cheat_infinite_ammo 1`,
`map_name levels\b30\b30`, confirmed in `reports\debug.txt`).
- ✅ b30 loaded; the console (`~`) worked.
- ✅ `cheat_spawn_warthog` dropped a Warthog near the player.
- ⚠️ **Single grenades moved the Warthog only slightly.** 5 separate throws, one grenade each; each nudged it "as much as
  they normally do" (owner). Owner's first report said "warthog launched!"; it's unclear whether any throw lifted a wheel.
  No clip. No throw was seen lifting it off the ground.
- A burst retest (3–4 grenades at once) **wasn't possible by hand**: the game's throw rate stops grenades from being
  stacked. With the owner's approval, criterion 2 was reworded to "grenade explosions visibly move the Warthog, the same
  in Standalone and MCC" (✅ by the results above), and the launch question moved to **task 8** (scripted, stacked stock
  explosions).
- ✅ **With `cheat_infinite_ammo 1`, grenades didn't run out** (5 throws; owner: "seem to have infinite grenades").
  An early observation for task 4, in Standalone only. MCC has no console, so task 4 still has to test this from a script.
- Grenade key on the owner's machine: **right mouse button**. The menus are off-screen, so the bindings were found by trying keys.
- Which Warthog the cheat spawns (`warthog` or `mp_warthog`): not observed.

**Issues found:**
- Full screen on a 3840x2400 display at 200% scaling shows only the bottom-right of the picture; the menu and the
  top-left console are off-screen. Fix: run windowed with `-vidmode` (`tools\standalone.ps1`).
- Running the launcher through Claude Code's `!` prompt needs forward slashes (the shell strips backslashes).

### Part B: MCC, 2026-11-23 (MCC build 19905945)
- ✅ Played **The Silent Cartographer** (campaign, no cheats) in **classic graphics** (owner).
- ✅ **Grenades moved the Warthog the same small amount as in Standalone**: first evidence that Standalone and MCC
  match. Grenades ran out (no cheats in MCC).
- ⚠️ No launch off the ground observed. No clip.

### Finding
**Observed:** with stock physics, **one frag only nudges a Warthog** (Standalone and MCC alike).
**Hypothesis (unverified, tested in task 8):** a launch needs several explosions at nearly the same time, or a vehicle
that is already moving or tilted. Whatever the answer, ADR 0002 means we design around it (stacked or chained
explosions, ramps), not by tuning tags.
