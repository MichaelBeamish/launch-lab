# World-scale experiment (task 10)

**Question:** can we build the Sky Islands world at full scale: floating islands, stock plants and rocks, water, and a
sky box as high as precision allows? And what do builds cost at that size?

**Setup (2026-11-23, tools build 11722677):**
- `art/launch_lab_arena.py`: a sky box of 1000 × 1000 WU (±500) and 1000 WU tall, on a 50 WU grid.
- Two floating islands, closed rock frustums with grass tops: one at z 40 and one at z 900.
- A 10 × 10 WU sunken pool with the stock `b30` water shader (render-only, `water!`).
- Stock plants (fern, broadleaf tall, yellow big) and a boulder on the low island, placed by `tools/scenario.ps1`.
- Debug teleports `(dbg_tp_ground)`, `(dbg_tp_island_low)` and `(dbg_tp_island_top)` (`object_teleport (player0) <flag>`;
  `player0` is defined in the stock `data\global_scripts.hsc`).

## Results
| Check | Result |
|---|---|
| Geometry seal check (script) | ✅ after one fix: the 50 WU grid's x = 0 line ran through the ramp, leaving 6 open edges until the ramp was split on the grid |
| `tool structure` | ✅ 3 s, **no warnings**: 1360 surfaces, 6 material groups (islands and water included), 1 cluster |
| `tool lightmaps` (quality 0, stop 0.3) | ✅ **530 s (8.8 min)**, single CPU core, no errors |
| `build-cache-file` | ✅ the map is 64.3 MB; tag space 3.94 of 64 MiB |
| Placements | ✅ 47 values read back; `check-map` OK |
| Stock hashes | ✅ PASS |
| Playtest: scale | ✅ "it's massive, I love how high it is" |
| Playtest: teleports, standing on both islands | ✅ |
| Playtest: plants and boulder render on the island | ✅ |
| Playtest: pool renders as water | ✅ (owner doesn't love the square pool, see below) |
| Playtest: precision at z 900 | ✅ no jitter or flicker |
| Playtest: frame rate | ✅ smooth |

## Conclusions
- **Floating islands work:** separate closed solids with outward normals build, render, collide and light. c20's
  "floating cluster invisible" warning did not apply.
- **Full scale is fine:** 1000 WU tall stays precise and smooth, and tag space is barely touched.
- **Lighting is the slow step:** about 9 min at draft quality, on one core. It's needed only when the geometry changes;
  placements, devices and scripts don't need it.
- **Design feedback (owner):**
  - The islands look "a little boxy": more natural shapes wanted.
  - Pools: a few natural pools on islands, with sloping edges you can walk out of.
  - A Banshee at the bottom for testing.
  - Falling: remove the mid-air death and keep the impact death.
