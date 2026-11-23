# Launch Lab — Project Instructions

A physics stunt playground built as a custom **singleplayer map for Halo: Combat Evolved (MCC)** with Microsoft's
official mod tools (H1A-EK). Warthogs, endless grenades, chain reactions, challenges. The original engine's physics
are non-negotiable.

> **Status: Milestone 1 starting.** ADRs 0001–0003 are *Accepted*. Task 1 (repo + baseline commit) is done; nothing is built yet. Task #2 is next.

The owner is an experienced Vue/TypeScript developer returning to engineering, and **new to Halo modding**.
Their earlier projects with Claude are The Ink Tank (`creature-world`) and Commuting Through Time. Launch Lab uses the same
way of working. **Never modify those repositories.**

## Mentoring (owner preference)
- When something important is implemented, explain the engine concept and the *why* in a few bullets, at the end of the summary.
- Translate Halo concepts into frontend terms where it helps:
  - tags are like typed asset/config files;
  - the scenario is like the component tree;
  - HaloScript is a 30 Hz polling loop.
- Label these points **"Worth knowing"** and add them to `docs/learning-notes.md`.
- Skip trivial details.

## Read first
- `docs/product/vision.md`, `docs/product/mvp.md`, `docs/product/roadmap.md`
- `docs/architecture/overview.md` (pipeline, boundaries, repo layout) and `docs/architecture/code-map.md`
- `docs/research/feasibility-matrix.md` (what's confirmed, likely or unknown) and the other research notes
- `docs/tasks/backlog.md`, `docs/decisions/`

## Working rules
1. **Plan before building.** Every task gets a `/plan-task` spec approved by the owner first.
2. **One task at a time.** Small, independently verifiable increments. No drive-by features or refactors.
3. **Ask before major decisions.** New software, architecture changes, deviations from an ADR or legal questions: discuss first, then `/adr`.
4. **Verify before done.** Gameplay is verified only by a recorded playtest (`docs/testing/playtest.md`).
   **Never claim a gameplay feature works because the script looks right.**
5. **No commits without the owner's explicit approval. Nothing is pushed without it. Only the owner merges.**
   Never install software, and never touch other repositories, without approval.
6. **Keep docs current:** progress, backlog, feasibility matrix, code map and README on every task.
7. **Verify before you reference.** Every HaloScript function, tag field and Tool command must be confirmed in the installed
   tools, the extracted stock scripts or a cited source (c20, Microsoft Learn), never from memory. Functions differ between
   Halo CE versions; we target **H1A (MCC)**.
8. **Prefer simple.** Use stock assets and plain scripts. Add no abstractions until a second use exists.
9. **Stop at each gate.** Don't roll from planning into implementation, or from one task into the next.
10. **Report honestly.** Report failures with their output, name skipped steps, and say "unverified" when something hasn't been played.

## Halo-specific rules
- **Authentic physics (ADR 0002):** never edit stock `vehicle`, `physics`, `projectile`, `damage_effect` or `globals` tags.
  Tuned variants are copies under `mod/tags/levels/launch_lab/tuned/`, need an ADR, and are labelled in game.
- **Repo holds only our work (ADR 0003):** never commit stock tags, extracted data, `.map` files, tool binaries, OpenCE code
  or game data. Check `git status` after every sync.
- **Source of truth is the repo.** Our files live in `mod/` and are synced into the H1A-EK folder. Never leave the only copy
  inside the tools folder.
- **GUI steps (Sapien, Guerilla, the game itself) are done by the owner.** Claude writes exact step-by-step instructions,
  then waits for the result.
- **Machine-specific paths** (Steam and H1A-EK install folder) go only in the git-ignored `tools/local.config.ps1`.
- **Budgets:** 2048 runtime objects; 256 placed vehicles; 64 MiB tag space; scripts tick at 30 Hz. Keep the world near the origin.
- **Naming and legal:** "Halo" is used only descriptively. No logos. Nothing commercial.

## Task lifecycle and Git workflow
**Plan → Review → Implement → Verify → Checkpoint**, one branch per task:
1. `/plan-task n` → owner approves.
2. `/implement-task n` → branch `task/<n>-<slug>` from an up-to-date `main`.
3. `/verify-task n` → build, playtest, review.
4. `/checkpoint` → one approval covers commit + push + PR. Before a remote exists, it covers the local commit only.
5. CI is green → share the link.
6. **The owner merges.**
7. After the merge: switch to `main`, run `git pull --ff-only`, and delete the branch.

Never commit directly to `main`. Never amend pushed commits, force-push or skip hooks unless the owner asks.
Once the GitHub repo exists (with the owner's OK), protect `main` with a ruleset: PRs only, CI green, no force-push, squash merges.

## Multi-agent use
- Use subagents for **parallel, read-only research** (e.g. engine, tools, legal, browser) and independent review.
  They report findings; the lead integrates them.
- Never have two agents edit the same files. Implementation happens in the main session.
- Prefer sequential work when tasks depend on each other. The goal is better software, not agent activity.

## Stack
H1A-EK (Tool, Guerilla, Sapien, `halo_tag_test.exe`) · Halo CE in MCC (Steam) · Blender 4.x + Halo Asset Blender
Development Toolset (JMS export) · HaloScript (`.hsc`) · PowerShell for local helper scripts · TypeScript (strict) +
Vitest for CI-side tooling (from task 7) · Git + GitHub.

## Commands
*(Filled in by tasks 2, 3 and 7 as each command is proven.)*

| Command | Purpose | Added by |
|---|---|---|
| `tools\sync.ps1` | Copy `mod\` into the H1A-EK folder | task 3 |
| `tool structure levels\launch_lab launch_lab` | Build the BSP from JMS | task 3 |
| `tool build-cache-file levels\launch_lab\launch_lab classic` | Build the map (compiles scripts); see c20 for the flags | task 3 |
| `halo_tag_test.exe` → `map_name levels\launch_lab\launch_lab` | Fast dev playtest | task 3 |
| CI guard + HSC lint | Repo hygiene and script sanity | task 7 |

Before a task is done: every command added so far must pass, and the task's playtest must be recorded.
