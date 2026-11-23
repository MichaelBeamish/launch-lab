---
name: adr
description: Record an agreed Launch Lab architecture decision as a short ADR in docs/decisions/. Use when a significant technical, legal/distribution or physics-authenticity choice is made or changed.
---

# Write an ADR

1. Confirm the owner has actually discussed and agreed the decision. If not, present 2–4 options with ➕/➖,
   recommend one, and wait.
2. Find the next number in `docs/decisions/` (`NNNN-kebab-title.md`).
3. Write it with this template (keep it under about 25 lines):
   ```
   # NNNN — Title
   - **Status:** Proposed | Accepted | Superseded by NNNN
   - **Date:** YYYY-MM-DD
   ## Context        (include evidence links: research notes, c20 pages, experiment results)
   ## Decision
   ## Consequences   (➕ benefits, ➖ costs, alternatives considered, when to revisit)
   ```
4. If it replaces an earlier ADR, mark the old one `Superseded by NNNN`.
5. If the decision changes rules or structure, update `CLAUDE.md` or `docs/architecture/overview.md`.
6. Decisions that change stock physics behaviour, or that affect what gets distributed publicly, always need an ADR.
