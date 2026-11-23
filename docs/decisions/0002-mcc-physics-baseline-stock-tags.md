# 0002 — The physics reference is stock MCC Halo CE, with stock tags unmodified

- **Status:** Accepted (2026-11-23, by the owner)
- **Date:** 2026-11-23

## Context
"Original Halo CE physics" can mean any of several releases:
- the 2001 Xbox release, whose engine also patched some tags in memory;
- the 2003 PC release;
- Custom Edition;
- MCC, which has hundreds of fixes and possibly updated tags;
- OpenCE, a pre-release Xbox build.

Every physics value is an editable tag, so "authentic" has to be defined to be testable.

## Decision
- The **reference baseline is Halo CE as shipped in MCC**, running stock tags.
- We never edit stock physics-relevant tags (`vehicle`, `physics`, `projectile`, `damage_effect`, `globals`).
- Task 2 records SHA-256 hashes of the stock tags we rely on. `/verify-task` re-checks them.
- Any deliberate tuning lives in **copies** under `tags\levels\launch_lab\tuned\`. It must be opt-in, labelled in game, and recorded in its own ADR.

## Consequences
- ➕ "Authentic" becomes a checkable property (hashes), not a feeling.
- ➕ The baseline is the version players can actually buy and run.
- ➖ MCC may differ slightly from the 2001 original. We accept that and document it.
- ➖ Gameplay ideas that need different physics must be built around the physics, not by tuning it.
- Revisit if the owner wants a "classic Xbox" comparison mode, or if Milestone 5 shows large differences in OpenCE.
