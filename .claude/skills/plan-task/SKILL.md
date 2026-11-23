---
name: plan-task
description: Turn a Launch Lab backlog task into a short implementation spec and get the owner's approval before any tags, scripts, geometry or code are written. Use when starting a task, e.g. "/plan-task 1".
---

# Plan a task

1. Read `CLAUDE.md`, `docs/tasks/backlog.md`, `docs/architecture/overview.md`, the relevant ADRs in
   `docs/decisions/`, and any research note the task depends on (`docs/research/`).
2. Identify the task (by number from the argument, or the first `todo` task). Confirm the tasks it depends on are
   `done`. If it depends on an **unknown** in `docs/research/feasibility-matrix.md`, say so; the task may need to
   start as an experiment.
3. Inspect what the task touches. Start from `docs/architecture/code-map.md`, then **confirm every file, tag path,
   script function and tool command by reading it in the repo, the installed mod tools, or a cited reference
   (c20.reclaimers.net, Microsoft Learn)**. Never rely on memory. HaloScript functions differ between Halo CE versions,
   so name the source that confirms each one exists in the H1A (MCC) toolset. Mark anything new as *new*.
4. Write the spec **in chat** (don't create a file) with:
   - **Goal**: one sentence.
   - **Files**: source files (`data/…`: `.hsc` scripts, `.jms`/`.blend` geometry) and tag files (`tags/…`) to create
     or modify, plus any repo tooling. Say which are **ours** (committed) and which are **stock** (Microsoft's, never
     committed).
   - **Approach**: 3–8 bullets. Name the editor for each step (Blender, Tool, Guerilla, Sapien) and explain any
     engine concept the owner hasn't met yet.
   - **Acceptance criteria**: copied from the backlog and made concrete and observable, e.g. "Warthog leaves the
     ground after 4 grenades and lands on its wheels or roof", not "physics works".
   - **Verification**: the automated checks (CLAUDE.md → Commands), the build step (`tool` output with zero
     errors) and the **playtest script**: numbered steps the owner can follow in the game, with what they should see.
   - **Authenticity check**: does the task change any stock physics, vehicle, projectile or damage tag? If so,
     flag it. Changes like that need an ADR (see the "authentic physics" rule in CLAUDE.md).
   - **Risk / size**: S/M/L, and what could go wrong.
   - **Open questions / decisions**: anything that needs the owner, such as new software, deviations from an ADR or legal questions.
5. Keep it short. **Stop and ask for approval.** Don't write anything else.
6. On approval, set the task's status to `planned` in the backlog.
