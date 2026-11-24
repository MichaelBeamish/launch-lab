# Feasibility matrix

Each sandbox feature is classified by how it can be built without changing the engine.
**Confirmed** means the mechanism is documented (see the cited research notes). It does not mean that we have run it.
A row only moves to **Proven ✅** after a verified task, with the task number recorded.

Legend: **Confirmed** (documented) · **Likely** (strong indirect evidence) · **Unknown** (needs an experiment) ·
**Blocker** (not possible without engine changes or unacceptable risk) · **Proven ✅** (we've done it)

| Feature | Status | Mechanism (no engine changes) | How we'll prove it |
|---|---|---|---|
| Original-engine Warthog + grenade physics | **Proven ✅ (task 2)** | Stock `warthog` and grenade tags in H1A-EK; Standalone and MCC run the real engine. Frags visibly move the Warthog, the same in both | Task 2 (stock map); Task 3 repeats it in our arena |
| Launching a Warthog with stock grenades | **Proven ✅ (task 8), when stacked** | One frag only nudges it, and the throw rate prevents stacking by hand. **8 simultaneous stock frag explosions** (`effect_new` of the stock frag explosion at a flag, from script) launched it high, 2/2. The smallest count is unmeasured | Task 8 |
| Grenade piles that chain-react | **Proven ✅ (task 9)** | The pile gun's pellet (frag projectile copy) detonates into an effect whose one part creates a stock `frag grenade.equipment`. Piles form where you aim, and one thrown frag cascades the pile and launches the Warthog far (owner) | Task 9 |
| Small custom outdoor arena | **Proven ✅ (task 3)** | Blender script → JMS → `tool structure` → lightmaps → `build-cache-file`; sealed `+sky` box, zero errors. Placements via `invader-edit` (ADR 0004) | Task 3 |
| Unlimited grenades | **Likely** | Option A: `cheat_infinite_ammo` (covered grenades in Standalone, task 2; MCC, from a script, untested). Option B: continuous script that tops up through `player_add_equipment` / starting profile. Option C: many respawning grenade pickups (`object_create_anew`) | Task 4 compares options |
| Reset objects without reloading | **Confirmed** | `object_teleport` to cutscene flags, or `object_destroy` + `object_create_anew` | Task 5 |
| Trigger: object enters zone | **Confirmed** | `volume_test_object` against a named object, polled in a `continuous` script | Task 6 |
| Hoop detection | **Likely** | Two thin trigger volumes on each side of the hoop; a pass-through means "A then B within N ticks". The hoop is BSP geometry or scenery | Milestone 2+ |
| Scoring / success feedback | **Confirmed** | Globals for score; `cinematic_set_title` / `hud_set_objective_text` / sounds for feedback | Task 6 |
| Personal bests across sessions | **Unknown / likely blocker** | HSC has no file I/O. A best can last a session as a global; persistence probably needs saved checkpoints or isn't possible | Experiment later; may drop |
| Tracking height / distance | **Likely** | No coordinate readout. Approximate with `objects_distance_to_flag` sampled each tick, or stacked "altitude band" volumes | Milestone 2+ experiment |
| Dynamic spawning (vehicles/props) | **Confirmed, with limits** | Only **pre-placed, named** objects can be (re)created: no arbitrary new instances at runtime. Budget pools ahead of time (256 placed vehicles; 2048 runtime objects) | Milestone 3 |
| Overshield placement | **Proven ✅ (task 9)** | The overshield gun (plasma pistol copy) drops stock `powerups\over shield.equipment` wherever you shoot; it can be picked up (owner). The pellet sinks into the floor briefly before the pickup appears (cosmetic) | Task 9 |
| Teleport points | **Confirmed** | `object_teleport (player0) <flag>`, triggered by volumes or input tests | Milestone 3 |
| Player input for sandbox controls | **Likely** | `player_action_test_*` (grenade, action, jump…). There is no custom keybinding or menu UI; controls are contextual | Milestone 3 experiment |
| Skull-like modifiers | **Likely (partial)** | Cheat globals (`cheat_bottomless_clip`, `cheat_super_jump`, `cheat_jetpack`, `cheat_deathless_player`, `cheat_omnipotent`), `physics_set_gravity`. MCC's own skulls are menu options; **script control is unknown** | Milestone 3 experiment |
| Chain reactions | **Confirmed (singleplayer only)** | "Detonates explosives" works only in singleplayer, so we build a **singleplayer scenario** | Milestone 3/4 |
| Large world | **Proven ✅ (task 10)** at 1000 × 1000 × 1000 WU: no jitter at z 900, smooth frame rate, 3.94 MiB tags; draft lightmaps 8.8 min (one core). c20 vertex limit ±1500 WU. Earlier notes: | Tag space 64 MiB; BSP up to 131k surfaces; vehicles die below z ≈ −4950; precision drops far from the origin | Milestone 4 (keep near the origin) |
| Floating islands (static) | **Proven ✅ (task 10)** | Separate closed solids inside the sealed world, normals outward: build, render, collide and light. Tested at z 40 and z 900 | Task 10 |
| Floating ships / platforms | **Confirmed** | Static scenery or BSP geometry at height. Moving platforms need device machines (not researched) | Milestone 4 |
| Play in MCC as a custom map | **Proven ✅ (task 3)** | Built `classic`; **replacement method**: our map as `halo1\maps\a10.map`, MCC with anti-cheat off, played as *The Pillar of Autumn* (`tools/mcc-swap.ps1`). A menu entry of its own: not found; Steam Workshop route unexplored | Task 3 |
| Browser play (OpenCE) | **Unknown** | Requires an Xbox disc image; MCC-map support is experimental; the physics base is a pre-release Xbox build | Milestone 5 (local only) |
| Public browser hosting | **Blocker (legal risk)** | The decompiled engine is high-risk to host | Not planned |
| New mechanics (e.g., direct velocity control) | **Blocker without engine changes** | No `object_set_velocity`. Approximate with invisible `damage_new` impulses (Likely) | Only if needed |

## Biggest unknowns, in the order we'll test them
1. Can a script remove the mid-air fall death but keep the landing death? (Next batch)
2. Which unlimited-grenade method feels right without distorting stock behaviour? (Task 4)
3. How close is OpenCE physics to our MCC baseline? (Milestone 5)

Answered: the dev loop works end to end (tasks 2–3); custom SP maps play in MCC via the replacement method (task 3);
stacked stock frags launch a Warthog (task 8).
