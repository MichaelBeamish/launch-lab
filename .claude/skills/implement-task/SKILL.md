---
name: implement-task
description: Implement one approved, planned Launch Lab task on its own branch, in small steps that follow CLAUDE.md conventions. Use after /plan-task has been approved.
---

# Implement a task

1. Confirm the task is `planned` and its spec was approved in this conversation. If not, run `/plan-task` first.
2. Create the task branch from an up-to-date `main`:
   `git switch main && git pull --ff-only && git switch -c task/<n>-<short-slug>`.
   If the branch already exists, switch to it. (Before a remote exists, skip the pull.)
3. Set the task status to `in-progress` in `docs/tasks/backlog.md`.
4. Work in small steps, building often:
   - **Repo first.** Edit our sources in the repo (`mod/data/…`, `mod/tags/…`), then sync them into the mod-tools
     folder with the sync script (see CLAUDE.md → Commands). Never edit the only copy inside the mod-tools install:
     work that lives only there isn't version-controlled.
   - **Build after each meaningful step** (`tool` structure / scripts / cache file) and read the full output.
     A HaloScript compile error is a failed step, not a warning.
   - **Never commit stock content.** Stock tags, `.map` files, extracted assets and tool binaries stay out of git.
     Check `git status` after every sync.
   - **Authentic physics.** Don't change stock physics-relevant tag values (vehicle physics, projectiles, damage
     effects, globals) unless the approved spec says to and an ADR records it.
   - Steps that only the owner can do (GUI work in Sapien or Guerilla, playtesting): write exact click-by-click
     instructions, then wait for the owner's result. **Never assume a GUI step succeeded.**
5. Stay inside the spec. Stop and ask if you need something outside it, such as new software, a design change or extra scope.
6. Briefly explain the notable engine concepts used ("Worth knowing", see CLAUDE.md → Mentoring).
7. When done, hand off to `/verify-task`. Do not commit.
