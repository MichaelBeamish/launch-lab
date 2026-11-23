---
name: checkpoint
description: Commit verified Launch Lab work on the task branch, then push it and open a pull request, all after one explicit owner approval. Then report CI and, only after the owner has merged, sync main. Use after /verify-task.
---

# Checkpoint (commit → push branch → pull request)

1. Confirm you're on the task or fix branch (`task/<n>-…` / `fix/<n>-…`). Never commit on `main`.
2. Confirm `/verify-task` ran in this conversation, including its playtest and review steps. If it didn't, run it first.
3. Run `git status` and `git diff --stat`. Confirm that **nothing proprietary** is staged: no stock tags, `.map` files,
   extracted assets, tool binaries or screenshots containing personal information. Also check for secrets and
   machine-specific paths.
4. Propose, in one message:
   - The exact files to stage, and how to split them into commits if there's more than one.
   - Conventional Commit message(s), e.g. `feat(arena): add grenade launch test arena`
     (types: feat, fix, docs, test, refactor, chore, ci), each ending with the Co-Authored-By line.
   - The PR title (`<type>: <summary> (task #n)`) and a body that follows `.github/pull_request_template.md`,
     ending with the "Generated with Claude Code" line.
5. **Ask the owner for approval and wait.** One explicit "yes" covers commit + push of this branch + opening the PR.
   Before a GitHub remote exists, the approval covers the local commit only.
6. On approval: stage only those files, commit, `git push -u origin <branch>`, then
   `gh pr create --base main --title … --body-file …`. Share the PR URL.
7. Watch CI (`gh pr checks <n> --watch`) and report the result. If it fails, fix the problem on the branch and ask again before pushing.
8. **The owner merges.** Merge only when they explicitly ask (`gh pr merge <n> --squash`).
9. After the owner confirms the merge (`gh pr view <n> --json state` → `MERGED`):
   `git switch main && git pull --ff-only && git fetch --prune && git branch -D <branch>`, then show `git log --oneline -3`.
10. Never amend pushed commits, force-push or skip hooks unless the owner explicitly asks.
