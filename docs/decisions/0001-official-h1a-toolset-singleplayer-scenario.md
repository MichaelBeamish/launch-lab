# 0001 — Build Launch Lab as an H1A-EK singleplayer scenario for MCC

- **Status:** Accepted (2026-11-23, by the owner)
- **Date:** 2026-11-23

## Context
The owner's top requirement is authentic Halo CE physics. Only the original engine provides that. The candidates were the official
MCC mod tools (H1A-EK), the 2004 HEK for Custom Edition, and OpenCE (a decompiled Xbox build). See
`docs/research/mod-tools-and-scripting.md` and `browser-opence.md`. Explosion chaining works only in singleplayer, and
singleplayer scenarios support vehicles and scripts.

## Decision
- Author with **H1A-EK** (Tool, Guerilla, Sapien, Standalone) and target **MCC on Steam** as the release platform.
- The map is a **singleplayer scenario**.
- Use Standalone (`halo_tag_test.exe`) for the inner dev loop, and treat a built map in MCC as the final verification.

## Consequences
- ➕ It is official and supported: it has the highest limits (64 MiB tag space, 1024 scripts) and a debug console. It is legally the cleanest option.
- ➕ It uses the real engine and stock tags, so the physics are authentic by construction.
- ➖ Windows-only GUI tools that need the game installed. CI can't build or run the map.
- ➖ No multiplayer: a singleplayer scenario can't be played in MP.
- ➖ Browser play becomes a separate, uncertain experiment.
- Alternatives:
  - HEK/Custom Edition: older, lower limits, less legally clear today.
  - OpenCE as the primary target: needs an Xbox disc, and carries legal risk.
- Revisit if MCC custom singleplayer maps turn out to be unplayable (task 3).
