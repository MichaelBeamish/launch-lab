# 0006 — Distribute to MCC owners through the Steam Workshop (Excession) only

- **Status:** Accepted (2026-11-24, by the owner)
- **Date:** 2026-11-24
- **Refines:** ADR 0003 (distribute to MCC owners only; the repo holds only our own work)

## Context
The owner wants people who own the game to be able to play Launch Lab. A built `.map` packs the game's own tag
data. The MCC EULA allows distributing *Mods* but not *Modded Versions*, while the EULA FAQ says "we do plan to
facilitate an ecosystem for mods within Steam Workshop, you are free to share your mods as you see fit". Microsoft
ships **Excession** (the MCC Mod Uploader) to publish MCC mods, Halo CE campaign maps included, to the Steam Workshop;
subscribers get the map in MCC's own Campaigns menu (anti-cheat disabled). See `docs/research/sharing-and-workshop.md`.

## Decision
- **The Steam Workshop, uploaded with Excession, is the only download channel.** No `.map` files on GitHub (neither
  committed nor attached to releases) or other hosts.
- **Non-commercial**, nothing that looks official (no logos; "Halo" only descriptively), stock MCC retail assets only.
- **The Game Content Usage Rules notice** goes in the Workshop description and the README.
- The owner uploads from their Steam account, after reviewing the terms; Claude prepares the package, the guide and
  click-by-click Excession steps.
- **GitHub hosts the source and the player guide** (`docs/PLAY.md`), not the game files.

## Consequences
- ➕ The sanctioned channel; one-click subscribe; its own menu entry (no stock-file swap for players).
- ➕ Clear legal posture: Microsoft's own tool and storefront for exactly this.
- ➖ Players must launch MCC with anti-cheat disabled (mods are never loaded otherwise) and own MCC on **Steam**.
- ➖ MCC updates may require a rebuild and re-upload (the stock-tag hash check will flag changed stock tags).
- Revisit if Microsoft changes the mod terms, or the owner wants another channel.
