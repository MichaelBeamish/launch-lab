# Launch experiment: stacked stock frag explosions (task 8)

**Question (MVP risk from task 2):** one stock frag only nudges a Warthog, and the throw rate stops a player from stacking
grenades. Can stock frag explosions launch a Warthog at all if they go off together?

**Setup (2026-11-23, Standalone, tools build 11722677):**
- `boom_flag` sits on the floor under the Warthog's centre, at (0, −15, 0.1).
- `(dbg_boom_N)` sets off stock frag explosions at the flag N times in one script call, so in the same tick.
- The Warthog is reset between attempts with `(dbg_hog_reset)` (`object_create_anew hog`).
- No stock tags are changed; the hash check passes.

**Console:** script calls need brackets: `(dbg_boom_4)` works.

## Correction: each blast counted twice
The first `dbg_boom_1` called `effect_new "weapons\frag grenade\effects\explosion"` **and**
`damage_new "weapons\frag grenade\explosion"`. Inspecting the stock tags afterwards showed that the effect's part 0 *is*
`explosion.damage_effect` (with sound, shock wave, particles, decal and lights as parts 1–6), and that a thrown frag
detonates through this same effect. So **each `dbg_boom` unit was 2 frag explosions' damage**, and the "N = 4" runs below
were really **8 stacked stock frag explosions**. The script was fixed to `effect_new` only (one real frag per unit).

## Results
| Script call (old) | Real frag explosions | Attempt | Left ground | Flipped | Height | Destroyed | Notes (owner) |
|---|---|---|---|---|---|---|---|
| `dbg_boom_4` | **8** | 1 | ✅ | ✅ (one backflip) | well above its own height | no | "flying up and back" |
| `dbg_boom_4` | **8** | 2 | ✅ | not noted | **hit the arena ceiling (30 WU)** | no | "all the way to the ceiling", landed beside the owner |

- **8 simultaneous stock frag explosions launch the Warthog: 2 of 2 attempts** (the plan asked for 3; the owner judged
  the result clear).
- The Warthog survived both times. The owner notes it is damage-resistant in H1.
- The *smallest* number that launches is not known: fewer than 8 was never tested. The answer to the MVP question is
  known: **yes**.

## Conclusions
- **Stock frag physics can launch a Warthog spectacularly** when about 8 explosions coincide (fewer is untested). The MVP's "launch with
  grenades" is achievable without tuning, but only through **stacking**, which needs a script or a level device rather
  than hand-throwing.
- **The 30 WU ceiling is too low:** an 8-frag launch reached it. The invisible `+sky` ceiling caps launches and hides
  the true height.
- **Grenade piles chain-react in stock data:** `frag grenade.equipment` (a grenade pickup lying in the world) has
  `item_flags: destroyed_by_explosions`, a `detonation_delay` of 0.4–0.8 s and the frag explosion as its
  `detonation_effect`. The frag's `explosion.damage_effect` has `detonates_explosives`. So a pile of grenade pickups
  should cascade when one goes off, which is the basis for the next task (the owner's grenade pile gun).
