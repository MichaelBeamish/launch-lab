# Launch Lab

A physics stunt playground: a custom singleplayer map for *Halo: Combat Evolved* in *Halo: The Master Chief Collection*,
built with the official Halo CE mod tools. Launch Warthogs with endless grenades, chain explosions, and tackle stunt
challenges, all on the original engine's physics.

**Status:** MVP done: the Sky Islands world, a 10-level climb of floating islands up to a castle, plays in MCC. See [`docs/product/roadmap.md`](docs/product/roadmap.md).

## How it's built
- **Engine:** Halo CE in MCC, unmodified. Stock physics tags are used as shipped ([ADR 0002](docs/decisions/0002-mcc-physics-baseline-stock-tags.md)).
- **Tools:** H1A-EK (Tool, Guerilla, Sapien, Standalone), Blender, HaloScript.
- **Process:** spec-first tasks, ADRs, recorded playtests. See [`CLAUDE.md`](CLAUDE.md) and [`docs/`](docs/).

## Play it
**[How to play Launch Lab →](docs/PLAY.md)**: you need *Halo: Combat Evolved Anniversary* on Steam (a few dollars; it
installs inside *Halo: The Master Chief Collection*), with the Halo CE Campaign **and** Multiplayer parts installed.
Launch Lab will be on the **Steam Workshop** (link coming): subscribe, start MCC with "Anti-Cheat Disabled (Mods and
Limited Services)", then Campaigns → Halo: CE → Launch Lab. This repository contains **no game files**: only original
scripts, the world generator, tags and documentation ([ADR 0006](docs/decisions/0006-distribution-via-steam-workshop.md)).

## Legal
Launch Lab is a non-commercial fan project. It is not affiliated with or endorsed by Microsoft, Halo Studios or Bungie.
Halo is a trademark of the Microsoft group of companies. Game content is used under Microsoft's
[Game Content Usage Rules](https://www.xbox.com/en-US/developers/rules).

*Halo: The Master Chief Collection © Microsoft Corporation. Launch Lab was created under Microsoft's "Game Content Usage
Rules" using assets from Halo: The Master Chief Collection, and it is not endorsed by or affiliated with Microsoft.*
