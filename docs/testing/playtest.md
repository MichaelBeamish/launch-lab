# Playtest protocol

Gameplay can't be tested automatically, so every gameplay task ends with a **recorded playtest by the owner**.
Claude writes the task-specific steps; the owner plays and reports the results.

## Before playing
1. Run the task's build commands and confirm they finish with **zero errors**. Note any warnings.
2. Note the environment:
   - **Standalone** (`halo_tag_test.exe`) or **MCC** (EAC off)
   - MCC build and tools version
   - whether the stock tags still match their hashes (`docs/research/toolchain-baseline.md`, from task 2)

## During
- Follow the numbered steps exactly. For each one, say **what you saw**, not what you expected to see.
- For physics outcomes, make **at least 3 attempts** (MVP criteria may say 5) and record the success count.
- Capture evidence for key moments, such as a screenshot or a short clip (Win+Alt+R with the Xbox Game Bar). Standalone console output
  (`print`) counts as evidence for script behaviour.

## Standard regression checks (every gameplay task)
- [ ] The map loads without errors and the player spawns.
- [ ] The Warthog can be entered, driven and exited.
- [ ] Grenades throw and explode with stock behaviour (knockback, damage).
- [ ] The reset (from task 5 onward) still works.
- [ ] There are no script errors in the console (Standalone).

## Record
Copy the results into the task's `docs/progress.md` entry:
`Playtest (MCC build …): step 1 ✅, step 2 ✅ (4/5 launches), step 3 ❌ (…)`.
