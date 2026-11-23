# Launch Lab

A physics stunt playground: a custom singleplayer map for *Halo: Combat Evolved* in *Halo: The Master Chief Collection*,
built with the official Halo CE mod tools. Launch Warthogs with endless grenades, chain explosions, and tackle stunt
challenges, all on the original engine's physics.

**Status:** planning (Milestone 0). Nothing is playable yet. See [`docs/product/roadmap.md`](docs/product/roadmap.md).

## How it's built
- **Engine:** Halo CE in MCC, unmodified. Stock physics tags are used as shipped ([ADR 0002](docs/decisions/0002-mcc-physics-baseline-stock-tags.md)).
- **Tools:** H1A-EK (Tool, Guerilla, Sapien, Standalone), Blender, HaloScript.
- **Process:** spec-first tasks, ADRs, recorded playtests. See [`CLAUDE.md`](CLAUDE.md) and [`docs/`](docs/).

## Requirements to play (once released)
A legitimate copy of *Halo: The Master Chief Collection* on Steam, launched with anti-cheat disabled. This repository
contains **no game files**: only original scripts, geometry sources, tags and documentation.

## Legal
Launch Lab is a non-commercial fan project. It is not affiliated with or endorsed by Microsoft, Halo Studios or Bungie.
Halo is a trademark of the Microsoft group of companies. Game content is used under Microsoft's
[Game Content Usage Rules](https://www.xbox.com/en-US/developers/rules).
