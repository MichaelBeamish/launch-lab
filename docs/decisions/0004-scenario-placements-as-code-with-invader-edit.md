# 0004 — Scenario placements as code with invader-edit; Sapien is for viewing

- **Status:** Accepted (2026-11-23, by the owner)
- **Date:** 2026-11-23

## Context
Placing objects in Sapien proved too hard for the owner (no middle mouse button; c20 documents the scenario data but
not Sapien's GUI steps). Claude can't operate GUI apps here. Invader's `invader-edit` (0.55.0, GPLv3, a community tool c20 recommends)
edits tag fields from the command line. In the task 3 experiment, run on a **copy** of our H1A-made scenario:
- it read every field correctly and wrote a spawn, a vehicle palette entry, the Warthog `hog` and 3 frag pickups;
- Tool's `check-map` printed exactly the same 21 warning lines (all about stock effects) for the copy and the untouched original;
- Standalone loaded it with no errors, and the owner confirmed every placement in game;
- the stock tag hash check passed.

Syntax learned: `block[i].field`; points are comma-separated; angles are *set* in radians and *shown* in degrees;
`object_names` is guarded and needs `-n` (no safeguards).

## Decision
- Placements live in a committed script, `tools/scenario.ps1`, as a readable list, applied to `launch_lab.scenario` with `invader-edit`.
- Invader is installed outside the repo and the tools folder. Its path goes in `tools/local.config.ps1`. It is never committed or redistributed.
- After every scenario change: `tool check-map`, the stock hash check, and a Standalone load. Every written value is read back and compared.
- `-n` is used only from that script, only for `object_names`.
- Sapien and Guerilla remain available for viewing and for edits Invader can't do. A GUI edit must be pulled into the repo (`tools\sync.ps1 pull`) and reconciled with the script.

## Consequences
- ➕ Placements are reviewable, diffable and repeatable, like the geometry (`art/launch_lab_arena.py`). No mouse skill is needed.
- ➖ A dependency on a community tool keeping up with MCC tag formats. Placement is by numbers, not by eye (checked in Standalone).
- ➖ Running with `-n` bypasses Invader's safeguards. This is mitigated by read-back checks and `check-map`.
- Alternatives: the owner uses Sapien with a USB mouse (still possible); a hand-written tag writer (too risky).
- Revisit if a tools update breaks Invader compatibility, or if a later task needs visual placement (e.g. Milestone 4 world building).

## Addendum (2026-11-24, task 11)
At world scale, placements are no longer only hand-written lists: the world generator (`art/launch_lab_arena.py`)
writes `world_layout.json` (vehicles, trees and rocks with exact surface heights, landing zones, flags), and
`tools/scenario.ps1` applies it alongside the hand-made items. Writes are batched (one `invader-edit` call per element)
and generated blocks are read back by sample (first, last, every 25th). Limit learned: 256 trigger volumes per scenario.
