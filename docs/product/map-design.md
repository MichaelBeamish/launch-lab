# Map design: Sky Islands

*Status: design direction agreed with the owner, 2026-11-23. The features are ideas until a task proves them (see the
feasibility matrix). Engine facts below were checked in the installed stock tags unless marked **unverified**.*

## The idea, in the owner's words
> "It'd be cool if the area was massive. Lots of places to explore. Imagine Avatar with floating rock islands with trees
> on top, all at different levels, some as high as the game engine will let us go. Each island should have stuff on it…
> something interactive or cool. Maybe a couple of islands are linked by a bridge, or by stairs. Maybe some have pools of
> water. Another might have a waterfall coming off of it. I kinda want this to be like the climbing game where the guy in
> the barrel uses the pickaxe to climb up to the top [*Getting Over It*]. Each area is different and it gets cooler as
> you go."

**In one line:** a massive vertical playground of floating rock islands, climbed with launches, piles and vehicles. Each
level up is different, and the view and the rewards get better the higher you get.

## Look
A **mix** of outdoor ring-world terrain (grass, rock, cliffs) and Forerunner-style structures (clean metal and stone
platforms, bridges, stairs), all with stock textures. Open sky, with the sealed sky box as high as the engine allows.

## Structure: a climb, not a flat map
- **The ground (level 0):** the base. The spawn and the "garage": Warthogs and the test Banshee (owner: "put one at the
  bottom for dev and testing purposes"). The first launch pads and grenade-pile spots are here.
- **Islands at rising heights:** each one reachable from below by a creative launch (a pile, a launch pad, a ramp jump),
  a bridge or stairs. Higher means harder to reach.
- **Each island has something:** a tank (Scorpion), a turret (Covenant gun turret), a pool, a waterfall, a launch
  cannon, a challenge. "Something interactive or cool." **No Banshees on the islands** (owner), so flying isn't a shortcut.
- **Links:** a few islands joined by bridges or stairs, making small connected clusters.
- **The summit:** the highest island, as high as the engine allows, with a reward (a view of the whole world and a
  "you made it" moment).
- **Distance and height** are read by eye (marker lines, level numbers): the engine can't report coordinates.

## Zones the owner chose (from the first map discussion)
Launch Range (distance lines), Platform Islands (landing challenges) and Hoop Canyon (hoops and goal frames), placed on or
between the levels of the climb.

## More ideas to explore (proposed, not yet chosen)
- **Launch cannons:** pads that fire you to the next island (stacked stock explosions, task 8), as rewards.
- **Gravity-lift island:** stock Covenant grav-lift visuals plus a scripted push.
- **Gaps** between islands that need a Warthog launch to cross.
- **Scorpion bowling:** knock vehicles off an island's edge.
- **Shield surfing:** survive grenade-jumping across a chain of piles with overshields.
- **Checkpoints** when you reach a new level (owner's idea), so a fall costs progress but not everything.

## Later (backlog, owner: "maybe this and the enemies are backlog items for now")
- **Enemies on some islands**, and some islands with Banshees already flown by enemies that you must take down.
- **A real weapon** for fighting. Halo CE players carry two weapons (**likely**, not yet confirmed in the data), so the plan
  is to **merge both devices into one gun** (the plasma pistol has two fire modes: normal shot = grenades, charged
  shot = overshields), which frees a slot for a real weapon.
- **Slow flying ships you can walk on:** these would be device machines (stock levels use them for lifts and platforms),
  with a model and animation of our own.
- **A big stationary ship:** no stock capital ship model exists, so it would be built as our own geometry.

## What the engine gives us (checked in stock tags)
| Need | Stock content |
|---|---|
| Plants and rocks for islands | `scenery\plants\…` (fern, broadleaf, yellow), `scenery\rocks\…` (boulder, a50 large rock). **Trees: not found yet** |
| Water pools | `shader_transparent_water`: `levels\b30\shaders\water`, `levels\a30\shaders\river_fronta`, `levels\c10\shaders\swamp_a_water` |
| Waterfall | **unverified** (transparent shaders and particles; no stock waterfall found yet) |
| Tank, turret, vehicles | `vehicles\scorpion`, `vehicles\c gun turret`, `vehicles\wraith`, `vehicles\ghost`, `vehicles\rwarthog`, `vehicles\banshee`, `vehicles\warthog` |
| Moving platforms | `device_machine` lifts and platforms (e.g. `levels\c20\devices\platform`, `levels\b40\devices\b40_towerlift`) |
| Ships | `vehicles\pelican`, `vehicles\c_dropship` (flown along recorded paths in the campaign). No capital ship |

## World limits (c20, 2026-11-23)
| Limit | Value | Source |
|---|---|---|
| Vertex bounds | **±1500 WU on each axis** (±150,000 JMS units) | c20 BSP troubleshooting |
| Precision | artefacts "starting at approximately 1,000 world units" from the origin | c20 renderer |
| Camera | can't leave a 10,000 WU cube centred on the origin | c20 renderer |
| Low floor | vehicles can't go below about −4,950 WU; other vehicle types rest on a hard floor at **−256 WU** | c20 physics, BSP |
| BSP | ≤131,072 surfaces; ≤16k triangles per cluster ("Couldn't allocate subcluster"); split with portals | c20 BSP |

**So "as high as the engine allows"** means about **1000 WU (≈3 km)** above the ground before precision suffers, with the
ground kept above −256 WU and the world within about ±1000 WU horizontally. That's a ~3 km cube: massive.

**Floating islands:** c20 says a BSP may be "one or multiple completely sealed volumes", which suggests a solid floating
island is allowed (its faces must face *outwards*, into the air). But c20 also warns that a floating *cluster* "not
touching any level geometry" can render invisible. **Unverified: task 10 tests it.**

**Water:** `shader_transparent_water` for lakes and pools; `shader_transparent_chicago(_extended)` for rivers and
waterfalls. Water surfaces may have open edges (render-only).

## Task 10 results (see `docs/research/world-scale.md`)
Floating islands, stock plants and rocks, water and full height (1000 WU) all work, smoothly. Owner feedback:
- **Islands should look natural**, not boxy: irregular rock outlines, uneven grass tops, jagged tapering undersides.
- **Pools:** only a few, on islands, natural, with **sloping edges you can walk out of** (not the square test pool).
- **A Banshee at the bottom** for testing.
- **Falling:** no mid-air death; keep the impact death (stock `globals` can't be edited per ADR 0002, so by script).

## Unknowns proved by task 10
1. Can a **floating island** (a closed shape inside the sealed world) be built, collided with and lit?
2. **How high and wide** can the world go before precision, lightmap time or BSP limits bite?
3. Do stock **plants, rocks and water** work on our geometry?
4. Does a large world stay **playable** (load time, frame rate)?

## Budgets to design within
2048 objects alive at once (grenade piles count!), 256 placed vehicles, 64 MiB tag space, one BSP for now. Keep the world
centred near the origin. Lightmap time grows with size, so we use draft quality while building.

## Sky Islands stage A: owner playtest notes (2026-11-24) — NOT YET IMPLEMENTED
What worked: the hills ("look awesome"), checkpoints (automatic and the flashlight key), the castle summit ("love the
last castle island"). Requested changes, with measurements and proposals:

1. **Hop distances.** "Height isn't necessarily what is hard; what's difficult is distance." The owner climbed to about
   level 8 and then couldn't launch between islands. Measured hops (horizontal, edge to edge) in stage A:
   L2 53, L3 35, L4 72, L5 76, L6 124, L7 113, **L8 155**, L9 168, L10 243, L11 157, L12 284, L13 200 WU.
   - Early gaps should be what the mid levels have now; the mid levels have the biggest gaps there should be.
   - Proposal: horizontal hops start small and grow to a **cap** at mid height, then stay at the cap while the
     **rises** (vertical gaps) keep growing instead. Cap: about the L6–L7 hops (~115–125 WU), which the owner managed.
2. **Fewer islands and a lower summit.** The summit can sit at two thirds of its current height (930 → about 620 WU);
   fewer islands overall. That also helps performance (fewer solids, trees and vehicles).
3. **More diversity on the islands in between** (the castle sets the bar). Theme ideas to choose from: ruins (broken
   walls, columns), a crashed Pelican or dropship, a watchtower, a beacon garden, a dense grove, rock spires, a pool,
   a small fort or bunker, a landing pad.
4. **Vehicles: Warthogs only, one per connected group** (a cluster of bridged islands = one group; a solo island = its
   own group). No Covenant turrets ("ditch the shades"). Open question: the two castle tower turrets.
5. **Non-solid trees:** `tree_gnarled_doublewide` has no collision model in stock (`collision_model` is empty), so it
   is decoration only. Drop it from the scatter lists.
6. **Lag with 24+ frags at once.** Likely causes: every frag explosion spawns stock particles, lights, decals and
   damage (we can't change stock effects: ADR 0002); the whole 3 km world is one render cluster, so everything is
   drawn every frame (an open world with a sky sees most of it anyway, so portals help little); 322 scenery items;
   Standalone may be slower than MCC (unverified). Options: test the same pile in MCC first; fewer islands and
   scenery; fewer trees far from the climb.

**Owner decisions (2026-11-24):**
- **10 levels**; the summit at about 620 WU. Hops start at ~20–30 WU and grow to a **cap of ~115 WU** by about
  level 5; after that only the rises grow.
- **Themes for the in-between islands: all four**, mixed through the climb: ruins and towers (generator-built,
  like the castle), crash sites (stock wrecks), groves and spires, pools and landing pads (stock beacons).
- **Remove the castle tower turrets**: Warthogs only, one per connected group, one at the castle gate.
- **Lag: trim scenery now** (fewer islands and fewer far-away trees), then retest in Standalone.
- Drop `tree_gnarled_doublewide` (no collision).

## MVP scope (owner, 2026-11-24)
"No need for portals or any of that other stuff; let's keep this the MVP as is." The MVP is the round 3 world:
terrain with hills and mesas, 10 levels (hops 30 → 115 WU, then rising gaps), themed islands, the summit castle, a
Warthog per group, automatic and flashlight checkpoints, the fall guard, the pile gun and the overshield gun, and
unlimited ammo (also in MCC, by script). **Not planned:** portals, waterfalls, a level-number HUD, ground bases,
enemies, flying ships, the big ship. Browser play stays a local-only experiment (ADR 0003); sharing is as an MCC
custom map, with a video and write-up.
