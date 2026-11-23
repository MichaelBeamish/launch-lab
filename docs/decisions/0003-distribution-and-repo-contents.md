# 0003 — Distribute to MCC owners only; repo holds only our own work; browser is a local experiment

- **Status:** Accepted (2026-11-23, by the owner)
- **Date:** 2026-11-23

## Context
The Game Content Usage Rules and the 343 MCC EULA FAQ allow non-commercial mods and videos. The MCC and tools EULAs
forbid redistributing game files or tools, and forbid any commercial use. OpenCE is a decompiled Microsoft build, and
Microsoft has sent DMCA notices to Halo derivative projects before. See `docs/research/legal-and-distribution.md`. This is not legal advice.

## Decision
- **The repo contains only our own work:** scripts, Blender sources, our own tags, tooling and docs. It never contains stock tags, extracted
  data, `.map` builds, tool binaries or OpenCE code. This is enforced by `.gitignore` and the CI guard (task 7).
- **Distribution, if any, happens after an EULA review:** a map for MCC owners via Steam Workshop and/or GitHub Releases.
  - Strictly non-commercial.
  - No Halo logos, and "Halo" is used only descriptively.
  - Include a trademark notice, a not-affiliated statement, and the Content Usage Rules attribution.
- **Browser (OpenCE) testing is local and owner-only.** We don't host, fork, vendor or redistribute it.

## Consequences
- ➕ Legal exposure stays low, and the portfolio (source, docs, video) stays publishable.
- ➖ There won't be a public "click to play" browser demo unless the legal picture changes.
- Alternatives: hosting an OpenCE build with bring-your-own-data. Rejected: the engine code itself carries the risk.
- Revisit if Microsoft or Halo Studios publishes guidance that covers community engine ports.
