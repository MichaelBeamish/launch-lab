# Progress Log

Newest first. One entry per verified task or significant decision.

## 2026-11-23 — Task 2: toolchain smoke test (Warthog vs grenades on a stock map)
- **Built:**
  - `tools/stock-baseline.ps1`: hashes 8 stock physics tags; `tools/stock-tag-hashes.json` is the baseline.
  - `tools/standalone.ps1` + `tools/standalone/init.txt`: windowed launcher, added for the high-DPI crop.
  - Git-ignored `tools/local.config.ps1`.
  - `docs/research/toolchain-baseline.md` with versions, confirmed tool facts and the playtest.
- **Versions:** mod tools build 11722677 (Standalone 01.03.43.0000), MCC build 19905945.
- **Playtest:**
  - Standalone (b30, `cheat_spawn_warthog`, `cheat_infinite_ammo 1`): console ✅, Warthog spawn ✅. 5 single frags each
    moved the Warthog slightly ✅ (no lift-off seen). Infinite grenades ✅.
  - MCC (The Silent Cartographer, classic graphics, no cheats): the same small nudge per frag ✅.
  - No clips.
- **Criterion change (owner-approved):** "visibly launched" → "visibly moved, same in Standalone and MCC". Stacking
  grenades by hand isn't possible at the game's throw rate. The launch question is now **task 8** (scripted, stacked stock
  explosions); the MVP records it as an open risk.
- **Verified:** hash check PASS (8 tags); self-test cases pass/fail as expected; no stock files or local paths in git.
  Code review: 1 important and 5 small findings fixed and re-tested, 1 rejected. Security review done by hand (the skill
  needs a remote): no findings.
- **Learned:**
  - One stock frag only nudges a Warthog, identically in Standalone and MCC (first parity evidence).
  - `cheat_infinite_ammo` covers grenades in Standalone.
  - Full screen is cropped at 200% display scaling; windowed `-vidmode` fixes it.
  - Standalone logs to `reports\debug.txt` in the tools folder.
  - Right mouse button throws grenades.

## 2026-11-23 — Task 1: local repo + baseline commit; ADRs 0001–0003 accepted
- The owner accepted ADRs 0001–0003 as proposed.
- `git init` with `main` as the default branch, and no remote. The commit identity is set in this repo's local config
  (GitHub noreply address, as in the owner's earlier projects).
- One baseline commit of the kickoff docs, skills, `.gitignore` and PR template.
- **Verified:** `git status` is clean, `git log` shows one commit, and `git check-ignore` confirms the ignore patterns
  (see the task 1 checks in the commit's PR notes / session summary).

## 2026-11-23 — Kickoff: Milestone 0 (technical feasibility) drafted
- Reviewed the earlier projects' workflow (Ink Tank/`creature-world` and Commuting Through Time, read-only). Adapted the five
  skills to a Halo toolchain: tag builds and recorded playtests replace unit tests and the browser.
- Ran parallel research (mod tools/scripting, OpenCE/browser, legal) → `docs/research/`, feasibility matrix.
- Proposed ADRs:
  - 0001: H1A-EK singleplayer scenario for MCC.
  - 0002: MCC stock-tag physics baseline.
  - 0003: distribution posture.
- Drafted the vision, MVP, roadmap, architecture and backlog (tasks 1–7).
- **Verified:** documentation only. Nothing has been built or played yet. All capability claims are documented, not proven.
- **Learned:**
  - OpenCE is a decompiled *Xbox development build*. It needs an Xbox disc image and is AGPL-licensed, so it isn't a
    distribution path.
  - Explosion chaining works only in singleplayer.
  - HaloScript can't read coordinates or set velocities.
