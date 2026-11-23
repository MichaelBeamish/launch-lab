# Launch Lab — Vision

**Working title.** A physics stunt playground built as a custom map for the original Halo: Combat Evolved engine.

## What it is
Something like Garry's Mod meets a giant stunt park, running on Halo CE's real physics. Players drive Warthogs,
throw an endless supply of frag and plasma grenades, and chain explosions to send vehicles, props and themselves
flying. The fun comes from the physics and the player's ingenuity. Story and combat don't matter here.

The **original Halo CE game feel is non-negotiable.** The point is to play with *that* physics: the Warthog's
floaty bounce, grenade knockback and quirky collisions. A "Halo-like" imitation on a modern physics engine
misses the point.

## Who it's for
- **The owner:** a nostalgia passion project and a showcase of disciplined, specification-driven engineering.
- **Halo CE players** (who own the game) who like experimenting, stunts and speedrun-style trick discovery.
- **Portfolio reviewers:** they'll see a real modding toolchain, research-led decisions and reproducible
  verification, even where they can't play the game.

## Experience pillars
1. **Authentic physics first.** We use stock engine behaviour and stock vehicle, projectile and damage tags. Any deliberate tuning
   is visible, optional and recorded in an ADR.
2. **Fast experiment loop.** Try → fail → reset → try again in seconds. Resets beat reloads.
3. **Discovery.** Hidden destinations, ridiculous launches and challenges that reward creativity over aim.
4. **Clear feedback.** The game says when you succeed (titles, sounds, score) and lets you chase a personal best.

## Long-term feature ideas (not commitments)
- **Playground:** Warthogs and other vehicles, unlimited grenades, overshields placed anywhere, movable props,
  chain reactions, a per-object or whole-area reset, skull-like modifiers.
- **World:** a large outdoor map with hills, valleys, cliffs and ramps; floating platforms; parked or floating capital
  ships; towers, landing pads and hoops; hidden spots that only creative launches can reach.
- **Challenges:** a Warthog through a giant hoop, landing on platforms, objects into targets, height and distance
  records, and events triggered when objects enter zones.
- **Sandbox controls:** spawn and reset objects, grenade refills, overshield placement, teleport points, restarting a
  challenge, toggling modifiers.

## What it is NOT
- Not a Halo campaign recreation, story mod or conventional shooter.
- Not a reimplementation of Halo physics in another engine (no Rapier, Cannon or PhysX substitutes).
- Not a vehicle for distributing Microsoft's game files. Players use their own legitimately obtained copy.
- Not a commercial product. No monetisation of any kind.
- Not a browser game **first**. The browser is a goal only if it keeps the physics authentic and the legal exposure acceptable
  (see `docs/research/`).
