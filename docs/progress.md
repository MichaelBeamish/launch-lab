# Progress Log

Newest first. One entry per verified task or significant decision.

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
