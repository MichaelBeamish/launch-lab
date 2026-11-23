# Research: Halo CE mod tools, HaloScript, limits and physics

Researched 2026-11-23 from current web sources. Each claim below is **CONFIRMED** (cited), **LIKELY**, or **UNKNOWN**.
Re-check a source before relying on it in a spec: the tools are updated, and wiki pages change.

## 1. The official toolset: H1A-EK ("Halo: CE Mod Tools – MCC")
- **CONFIRMED.** The kit is distributed through Steam as *Halo: CE Mod Tools – MCC* (app 1532190). It is listed in the Steam
  Library under **Tools**. [MS Learn overview](https://learn.microsoft.com/en-us/halo-master-chief-collection/general/overview-tools)
- **Ownership: the sources conflict.** Microsoft says the H1 tools are "available to anyone, regardless of which titles
  they own". c20 says you need MCC plus the matching content, and that the Windows Store version is unsupported
  ([c20 mod tools](https://c20.reclaimers.net/general/mod-tools/)). Either way, **playing** the result needs MCC on Steam.
- **CONFIRMED.** After installing (and after every tools update), run `(Extract).bat`. It unpacks the stock `tags` and `data`
  (including every singleplayer `.hsc` script).
- **CONFIRMED.** The kit has four parts ([c20 H1A-EK](https://c20.reclaimers.net/h1/h1-ek/)):
  - **Tool**: a command-line program that imports source files and builds maps.
  - **Guerilla**: the tag editor.
  - **Sapien**: the level editor, used to place objects, volumes and flags and to run scripts.
  - **Standalone** (`halo_tag_test.exe`): the game engine running loose tags, with a full debug console.
- **CONFIRMED.** Standalone ([c20](https://c20.reclaimers.net/h1/h1-ek/h1-standalone-build/)):
  - `map_name levels\a30\a30` loads a level; startup commands can go in `init.txt`.
  - It includes a debug camera and cheats such as `cheat_spawn_warthog` and `cheat_all_vehicles`.
  - There is no networking. Use `framerate_throttle 1` to stop the sound from breaking up.
  - **Do final testing in MCC with a built map.**
- **CONFIRMED.** Build pipeline ([c20 Tool](https://c20.reclaimers.net/h1/h1-ek/h1-tool/)):
  1. `tool structure <data-dir> <bsp-name>` converts JMS geometry into a `.scenario_structure_bsp`.
  2. `tool lightmaps <scenario> <bsp> <0|1> <threshold>` bakes the lighting.
  3. `tool build-cache-file <scenario> <classic|remastered>` builds the `.map`. It recompiles the scripts from `.hsc` source.

  `check-map` validates a scenario.
- **CONFIRMED.** Directory layout:
  - Sources go in `data\levels\<name>\models\*.jms` and `data\levels\<name>\scripts\*.hsc`.
  - Tags go in `tags\levels\<name>\*.scenario` and `*.scenario_structure_bsp`.
- **CONFIRMED.** Geometry can be authored in Blender 4.0+ with the
  [Halo Asset Blender Development Toolset](https://github.com/general-101/halo-asset-blender-development-toolset),
  which exports JMS. 3ds Max may also work (LIKELY), but we don't need it.
- **CONFIRMED.** To play custom maps, launch MCC with **Easy Anti-Cheat disabled**. Steam Workshop integration exists.
  **LIKELY:** a singleplayer custom map appears as a campaign entry. We will verify this in Milestone 1.
- **CONFIRMED.** Maps inside subfolders of `maps\` are not loaded ([c20 maps](https://c20.reclaimers.net/h1/maps/)).
- **Older ecosystem (CONFIRMED):** Custom Edition + HEK (2004). c20 now recommends authoring with H1A-EK and using
  [Invader](https://c20.reclaimers.net/h1/) to build maps for other targets, such as the CE format.

## 2. HaloScript (HSC): what we can do without engine changes
Source: [c20 scripting](https://c20.reclaimers.net/h1/scripting/) unless noted. All CONFIRMED unless marked.

| Need | Mechanism |
|---|---|
| Script lifecycle | `startup`, `dormant` (+`wake`), `continuous` (every tick), `static` functions; `sleep` / `sleep_until`. **30 ticks = 1 s.** |
| Spawn / respawn | `object_create`, `object_create_anew`, `object_destroy`, `…_containing` variants (objects must be pre-placed and named in Sapien) |
| Reset position | `object_teleport <object> <cutscene_flag>` |
| Triggers | `volume_test_object`, `volume_test_objects`, `volume_test_objects_all` |
| Height / distance | `objects_distance_to_flag`, `objects_distance_to_object`. **No function returns raw coordinates.** |
| Grenades / equipment | `player_add_equipment <unit> <starting_profile> <bool>`, `unit_get_total_grenade_count`. `cheat_infinite_ammo` global (whether it covers grenades is **UNKNOWN**) |
| Shields | `object_set_shield`, `unit_set_current_vitality`, `unit_get_shield`. Placing overshield powerups: pre-placed equipment + `object_create_anew` (LIKELY) |
| Input | `player_action_test_grenade_trigger`, `…_action`, `…_jump`, `player_action_test_reset` |
| Feedback | `hud_set_objective_text`, `display_scenario_help`, `cinematic_set_title`, `sound_impulse_start`, `print` (debug) |
| Explosions / force | `effect_new`, `damage_new <damage> <flag>`, `damage_object`. **There is no `object_set_velocity`.** Force comes from damage (LIKELY workaround) |
| Modifiers | Cheat globals: `cheat_infinite_ammo`, `cheat_bottomless_clip`, `cheat_deathless_player`, `cheat_omnipotent`, `cheat_super_jump`, `cheat_jetpack`. `physics_set_gravity`. **Scripted skulls: UNKNOWN**. MCC skulls are menu options |
| State | Globals: boolean, real, short, long, string (32 chars) |

**H1A script limits** ([c20 limits](https://c20.reclaimers.net/h1/scripting/limits/)):

| Limit | H1A |
|---|---|
| Scripts | 1024 |
| Globals | 512 |
| Syntax nodes | 32767 |
| Source files | 16 |
| Size per source file | 1 MB |

- Running threads are capped at 256.
- Release builds don't catch stack overflows.
- H1A changed some functions: `print` no longer formats its argument, and `game_speed` was replaced.

## 3. Engine limits (CONFIRMED)
- **Tag space and map size:**
  - Tag space is 64 MiB in MCC (23 MiB in CE/PC).
  - A map can be up to 2 GiB in MCC.
  - A map holds at most 65535 tags.
  - Sources: [c20 maps](https://c20.reclaimers.net/h1/maps/), [scenario](https://c20.reclaimers.net/h1/tags/scenario/).
- **Scenario (H1A):**
  - 256 entries per object palette.
  - 256 placed vehicles.
  - Up to 65535 placed scenery objects.
  - Up to 65534 trigger volumes.
  - 640 object names.
  - 512 cutscene flags.
- **Runtime:** [game state](https://c20.reclaimers.net/h1/engine/game-state/)
  - **2048 objects.**
  - 256 effects.
  - 1024 particles.
  - 256 AI.
  - H1A did not raise these limits. **Chain reactions and spawning must budget against them.**
- **BSP and world:** [BSP](https://c20.reclaimers.net/h1/tags/scenario_structure_bsp/), [physics engine](https://c20.reclaimers.net/h1/engine/physics-engine/)
  - Up to 131k collision surfaces.
  - Vehicles are killed below about z = −4950.
  - Objects can move beyond 5000 units horizontally.
  - Precision far from the origin probably degrades (LIKELY).
- **Singleplayer vs multiplayer:** a singleplayer scenario loads with `map_name` and can't be played in multiplayer. Explosion chaining
  ("detonates explosives") **works only in singleplayer**. → **Launch Lab should be a singleplayer scenario.**

## 4. Physics: what "authentic" means here
- **CONFIRMED.** H1 has its own physics engine, not Havok. Behaviour comes from tags:
  - `physics`: mass points, friction (about 0.23 on the Warthog), and antigravity.
  - `damage_effect`: "instantaneous acceleration" with min/max radius falloff, scaled by each object's acceleration scale.
  - [c20 physics](https://c20.reclaimers.net/h1/tags/physics/), [damage_effect](https://c20.reclaimers.net/h1/tags/damage_effect/)
- Everything above is editable in Guerilla. **Authentic = stock tags, unmodified.** Tuned variants must be copies, kept
  apart and clearly labelled.
- **CONFIRMED.** MCC fixed "hundreds of bugs" ([c20 H1](https://c20.reclaimers.net/h1/)), and stock tags may have been
  changed in MCC updates (MS Learn). The original Xbox also applied some balance edits in memory ([c20 engine](https://c20.reclaimers.net/h1/engine/)).
- **UNKNOWN.** Whether MCC's H1 vehicle and explosion physics match the 2001 Xbox and 2003 PC releases exactly. H1 runs at a 30 Hz tick
  (LIKELY in MCC too). The documented 60 Hz change covered later games. We pick MCC as our **reference baseline**
  (see ADR 0002) and treat the other releases as comparisons.
