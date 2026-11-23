# Feasibility matrix

Each sandbox feature is classified by how it can be built without changing the engine.
**Confirmed** means the mechanism is documented (see the cited research notes). It does not mean that we have run it.
A row only moves to **Proven ✅** after a verified task, with the task number recorded.

Legend: **Confirmed** (documented) · **Likely** (strong indirect evidence) · **Unknown** (needs an experiment) ·
**Blocker** (not possible without engine changes or unacceptable risk) · **Proven ✅** (we've done it)

| Feature | Status | Mechanism (no engine changes) | How we'll prove it |
|---|---|---|---|
| Original-engine Warthog + grenade physics | **Confirmed** | Stock `warthog` and grenade tags in H1A-EK; Standalone and MCC run the real engine | Task 2 (stock map), Task 3 (our arena) |
| Small custom outdoor arena | **Confirmed** | Blender → JMS → `tool structure` → lightmaps → `build-cache-file` | Task 3 |
| Unlimited grenades | **Likely** | Option A: `cheat_infinite_ammo` (grenade coverage unknown). Option B: continuous script that tops up through `player_add_equipment` / starting profile. Option C: many respawning grenade pickups (`object_create_anew`) | Task 4 compares options |
| Reset objects without reloading | **Confirmed** | `object_teleport` to cutscene flags, or `object_destroy` + `object_create_anew` | Task 5 |
| Trigger: object enters zone | **Confirmed** | `volume_test_object` against a named object, polled in a `continuous` script | Task 6 |
| Hoop detection | **Likely** | Two thin trigger volumes on each side of the hoop; a pass-through means "A then B within N ticks". The hoop is BSP geometry or scenery | Milestone 2+ |
| Scoring / success feedback | **Confirmed** | Globals for score; `cinematic_set_title` / `hud_set_objective_text` / sounds for feedback | Task 6 |
| Personal bests across sessions | **Unknown / likely blocker** | HSC has no file I/O. A best can last a session as a global; persistence probably needs saved checkpoints or isn't possible | Experiment later; may drop |
| Tracking height / distance | **Likely** | No coordinate readout. Approximate with `objects_distance_to_flag` sampled each tick, or stacked "altitude band" volumes | Milestone 2+ experiment |
| Dynamic spawning (vehicles/props) | **Confirmed, with limits** | Only **pre-placed, named** objects can be (re)created: no arbitrary new instances at runtime. Budget pools ahead of time (256 placed vehicles; 2048 runtime objects) | Milestone 3 |
| Overshield placement | **Likely** | Pre-placed overshield equipment respawned with `object_create_anew`, or `object_set_shield` above 1.0 directly on the player. "Wherever desired" only means at fixed spots, or teleporting a pool item to the player | Milestone 3 |
| Teleport points | **Confirmed** | `object_teleport (player0) <flag>`, triggered by volumes or input tests | Milestone 3 |
| Player input for sandbox controls | **Likely** | `player_action_test_*` (grenade, action, jump…). There is no custom keybinding or menu UI; controls are contextual | Milestone 3 experiment |
| Skull-like modifiers | **Likely (partial)** | Cheat globals (`cheat_bottomless_clip`, `cheat_super_jump`, `cheat_jetpack`, `cheat_deathless_player`, `cheat_omnipotent`), `physics_set_gravity`. MCC's own skulls are menu options; **script control is unknown** | Milestone 3 experiment |
| Chain reactions | **Confirmed (singleplayer only)** | "Detonates explosives" works only in singleplayer, so we build a **singleplayer scenario** | Milestone 3/4 |
| Large world | **Confirmed, with care** | Tag space 64 MiB; BSP up to 131k surfaces; vehicles die below z ≈ −4950; precision drops far from the origin | Milestone 4 (keep near the origin) |
| Floating ships / platforms | **Confirmed** | Static scenery or BSP geometry at height. Moving platforms need device machines (not researched) | Milestone 4 |
| Play in MCC as a custom map | **Likely** | Build with `remastered`/`classic`, launch with EAC off, map in `maps\` (not a subfolder). How the menu lists it is unverified | Task 3 |
| Browser play (OpenCE) | **Unknown** | Requires an Xbox disc image; MCC-map support is experimental; the physics base is a pre-release Xbox build | Milestone 5 (local only) |
| Public browser hosting | **Blocker (legal risk)** | The decompiled engine is high-risk to host | Not planned |
| New mechanics (e.g., direct velocity control) | **Blocker without engine changes** | No `object_set_velocity`. Approximate with invisible `damage_new` impulses (Likely) | Only if needed |

## Biggest unknowns, in the order we'll test them
1. Does the dev loop (Standalone → MCC custom map) work on the owner's machine? (Tasks 2–3)
2. Which unlimited-grenade method feels right without distorting stock behaviour? (Task 4)
3. Do MCC custom singleplayer maps appear and play correctly from the menu? (Task 3)
4. How close is OpenCE physics to our MCC baseline? (Milestone 5)
