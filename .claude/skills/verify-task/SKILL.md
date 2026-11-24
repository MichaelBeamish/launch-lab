---
name: verify-task
description: Verify an implemented Launch Lab task against its acceptance criteria (automated checks, a clean tool build, and a recorded owner playtest), then update the backlog and progress log. Use after /implement-task, before /checkpoint.
---

# Verify a task

1. Confirm you are on the task or fix branch (`task/<n>-…` / `fix/<n>-…`), not `main`.
2. Run every automated check in `CLAUDE.md` → Commands. Report the output of any that fail.
3. **Build check:** run the task's `tool` build commands and confirm they finish with zero errors. Record any
   warnings and what they mean. Save the relevant output lines as evidence.
4. **Playtest.** Gameplay can't be verified automatically. Give the owner the task's numbered playtest script
   (from the spec, plus the standard checks in `docs/testing/playtest.md`) and **wait for their results**.
   - Each criterion gets ✅ / ❌ with evidence: the owner's observation, a screenshot or clip, or a console output line.
   - **Never mark a gameplay criterion ✅ from reasoning alone.** If it hasn't been played, it's "unverified".
   - Physics outcomes vary from run to run. Where a criterion is about physics, ask for at least 3 attempts and
     record how many succeeded.
5. **Authenticity check:** diff the stock tags this task touched (if any) and confirm that every change is one
   the spec and ADRs approved.
6. Check `git status`/`git diff` for stray changes: stock tags, `.map` files, tool output, local paths.
7. **Review the diff:**
   - Run `/code-review` (default level; never `max`/`ultra` unless the owner asks) when the change adds or significantly
     changes repo tooling or scripts; otherwise state "code review skipped: <reason>" (lighter process, 2026-11-23).
     It covers scripts and tooling; binary tags are covered by step 5.
   - Run `/security-review` if the change touches repo tooling that handles files, paths, downloads or
     dependencies. Otherwise state "security review not needed: <reason>".
   - Fix confirmed findings that are in scope, then rerun the checks. List findings outside the scope for the owner.
8. Report the results honestly, including failures and anything unverified.
9. If everything passes and the owner agrees:
   - Set the task to `done` in `docs/tasks/backlog.md`.
   - Add a dated entry to the top of `docs/progress.md` (what changed, how it was verified, what we learned).
   - Update `docs/architecture/overview.md` and `docs/architecture/code-map.md` if the structure changed.
   - Update `docs/research/feasibility-matrix.md` if the task confirmed or refuted a capability.
   - Add "Worth knowing" points to `docs/learning-notes.md`.
   - Check `README.md`; update it, or state "README checked — no change".
10. Suggest `/checkpoint`. Do not commit.
