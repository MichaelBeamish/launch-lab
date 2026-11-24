# Learning notes

The owner's review document. Each entry covers what it is, how we use it, and an interview one-liner.

## Halo engine concepts

### Tags
- **What:** every asset and setting in Halo CE is a *tag*: a typed binary file (`.vehicle`, `.physics`, `.damage_effect`,
  `.scenario`…) edited in Guerilla. A built `.map` is a packed cache of all the tags the scenario references.
- **Here:** we use stock tags as-is, for authentic physics, and author only our own scenario, BSP and scripts.
- **One-liner:** "Halo CE is data-driven; gameplay is tag configuration plus a scripting layer. So 'authentic physics'
  became a checkable property: hashes of unmodified stock tags."

### Scenario and BSP
- **What:** the BSP (`.scenario_structure_bsp`) is the static level geometry and collision, compiled from JMS. The *scenario* is
  everything placed in that world: spawns, vehicles, scenery, trigger volumes, cutscene flags and scripts.
- **Frontend analogy:** the BSP is the static layout; the scenario is a component tree of named instances.

### HaloScript
- **What:** a small Lisp-like language that the engine runs at 30 ticks per second. `continuous` scripts run every tick;
  `sleep_until` polls a condition. There are no events or callbacks.
- **Limits that shape our design:** no coordinate readout, no velocity setter, no file I/O. Objects can only be (re)created
  if they were pre-placed and named.
- **One-liner:** "I designed the challenge logic as polled state machines over trigger volumes, because the scripting layer
  has no event system."

### Standalone vs a built map (task 2)
- **What:** `halo_tag_test.exe` ("Standalone") runs the engine straight from loose tag files in the mod tools' `tags\` folder,
  with a debug console (`~`) and cheats. MCC only plays *built* `.map` files: Tool packs every tag a scenario needs into one cache file.
- **Frontend analogy:** Standalone is the dev server serving source files with devtools open; the `.map` is the production
  bundle. "Works in dev" isn't "works in prod", so every gameplay task ends with an MCC check.
- **Why the Steam "Play" button closed instantly:** Standalone first loads `levels\ui\ui` from `tags\`, which only exists
  after `(Extract).bat`. Its log is `reports\debug.txt` in the tools folder: read it first when something closes silently.

### Authenticity as a hash check (task 2)
- **What:** physics values live in tags (`.vehicle`, `.physics`, `.projectile`, `.damage_effect`, `globals`). If those
  files are byte-identical to stock, the physics are stock. `tools/stock-baseline.ps1` hashes them and compares.
- **Frontend analogy:** a lockfile integrity hash (`package-lock.json`'s `integrity` field) for the engine's tuning data.
- **One-liner:** "I turned 'authentic Halo physics' from a feeling into a CI-style check: SHA-256 hashes of the stock
  physics tags, re-verified on every task."

### Stock physics set the design limits (task 2)
- **What:** one stock frag only nudges a Warthog, in Standalone and MCC alike, and the throw rate stops a player from stacking
  grenades. With tuning ruled out (ADR 0002), stunts must come from *combining* stock forces: several explosions, ramps, momentum.
- **Scripted force:** stock campaign scripts fire damage from script, e.g. `(damage_new "levels\a10\devices\shield charge\zapper"
  tutorial_zapper_flag)`: a stock damage effect, set off at a cutscene flag. Task 8 uses this to stack stock frag explosions.
- **Frontend analogy:** like a design system you may not fork: you compose the existing components instead of restyling them.

### Guard the guard (task 2 review)
- The important review finding wasn't about physics. `-Record` combined with `-TagsRoot` could have overwritten the baseline
  with a test copy, silently disabling the check. Tools that enforce a rule need their own failure modes tested: the self-test
  now covers a changed tag, a missing tag, a tag dropped from the list, and the refused option combination.

### The level pipeline, end to end (task 3)
- **What:** Blender script → JMS (text geometry) → `tool structure` (BSP: collision + render geometry; first run also
  creates the `.scenario`) → `tool lightmaps` (bakes lighting into the BSP) → placements → `tool build-cache-file` (`.map`).
- **Sealed world:** the BSP is one closed, inward-facing shell. Every edge must border exactly two faces, so all faces
  are cut on one shared grid (no T-junctions). `+sky` faces are invisible but solid: the "outdoors" is a sealed box.
- **UVs matter even for plain surfaces:** the lightmapper failed with "degenerate triangle [or triangle with bad uvs]"
  until every face got texture coordinates. Tool writes the broken triangles to a `.wrl` file.
- **Frontend analogy:** JMS is source, `tool structure` is the compiler, lightmaps are a build-time asset step, and
  the `.map` is the production bundle. The scenario is the component tree; `tools/scenario.ps1` renders it from data.

### Placements as code (task 3, ADR 0004)
- **What:** `invader-edit` sets tag fields from the command line (`block[i].field`). `tools/scenario.ps1` clears and
  rewrites the placement blocks from a list, reads every value back, and runs `check-map`, so the same input gives a
  byte-identical scenario.
- **Gotchas found:** points are comma-separated; angles are *set* in radians but *shown* in degrees; `object_names` is
  guarded (`-n`).
- **One-liner:** "When the GUI editor was the bottleneck, I proved a CLI tag editor round-trips our tags against the
  official compiler, then moved placements into reviewed, re-runnable code."

### Playing a custom singleplayer map in MCC (task 3)
- c20 only documents a replacement method: our `.map` takes a stock map's file name (`a10.map`), and MCC with anti-cheat
  disabled loads it as *The Pillar of Autumn*. `tools/mcc-swap.ps1` backs up and restores the stock file, with hashes.

### Effects are bundles, and scripts are 30 Hz batches (task 8)
- **An effect is a bundle of parts:** damage, sound, light, particles, decals, even objects. The frag's
  `explosion.effect` *includes* its `explosion.damage_effect`, so `effect_new` alone is a complete grenade blast. Adding
  `damage_new` too counted it twice: check what a tag contains before combining it.
- **Same-tick stacking:** calls inside one script invocation land in the same 1/30 s tick, so N calls = N simultaneous
  blasts. Force from simultaneous explosions adds up; one frag nudges a Warthog, eight launch it to the ceiling.
- **Frontend analogy:** an effect is like a component that renders its children (sound, particles, damage); and a static
  script is a function you call from devtools (the console), with brackets: `(dbg_boom_4)`.

### Devices: how a gun can "shoot" an item (task 9, ADR 0005)
- **A weapon trigger only fires projectiles** ("equipment tags cannot be referenced here"). So the chain is gun →
  projectile → its detonation **effect** → an effect part that **creates an object** (here a stock grenade or overshield
  pickup). Stock effects already do this (the Flood bursting into body parts).
- **Projectile speed:** `initial_velocity`/`final_velocity`. A non-zero final speed is *held* (bullets, needles), so a
  grenade-like pellet needs final = 0 and only an initial muzzle speed, or it bounces forever.
- **Projectiles react per surface** (`projectile_material_response`): the inherited frag responses played a rubble pop
  on settling until their `detonation_effect` was cleared.
- **Frontend analogy:** like extending a design-system component through its props (model, effect, sound) without
  forking its internals: every force on screen is still the stock grenade and its stock explosion.
