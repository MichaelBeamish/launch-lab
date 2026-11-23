# MVP: "First Warthog launch" + "First challenge" (Milestones 1–2)

## The MVP in one sentence
**A small custom arena, played in MCC's original Halo CE engine, where I launch a stock Warthog with endless grenades,
try to land it on a raised platform, get told when I succeed, and reset in one action to try again.**

## In
1. **Arena:** one small outdoor BSP, roughly 100 × 100 m. It has flat ground, one ramp, one raised landing platform, a skybox
   (stock) and baked lighting. The arena is ours; the textures may be stock shaders.
2. **Warthog:** one stock Warthog, placed and named, using **unmodified stock tags**.
3. **Endless grenades:** frag (and ideally plasma) grenades are always available. The method is chosen in task 4.
4. **Reset:** a fast way to put the Warthog (and the player) back at the start without reloading the map.
5. **Challenge:** when the Warthog comes to rest on the platform volume, a title shows "Landed!" and a counter goes up.
6. **Playable in MCC** as a custom singleplayer map, *and* in Standalone for development.

## Out (later milestones)
- The large world, floating ships, hoops and hidden areas (M4).
- Object spawning menus, overshield placement, teleports and modifiers (M3).
- Persistent personal bests (may not be possible; see the feasibility matrix).
- Custom models, textures, sounds or HUD (we use stock assets unless a task needs our own).
- Browser play (M5) and the public release (M6).

## Success criteria
- The owner plays it in MCC and can launch the Warthog using only grenades, **repeatably** (at least 3 of 5 attempts
  achieve a visible launch).
- The reset works 5 times in a row without reloading or breaking state.
- The landing challenge fires on a real landing and **doesn't** fire on a drive-by or mid-air pass (both checked).
- The stock physics tags are byte-identical to the extracted originals. This is checked by hash.
- Each step has a playtest record in `docs/progress.md`.
