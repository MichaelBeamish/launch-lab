# Roadmap

Each milestone ends in something **played and verified**. Later milestones stay rough on purpose; we refine them once
earlier ones teach us how the tools really behave.

| # | Milestone | Outcome | Key risk retired |
|---|---|---|---|
| **0** | Technical feasibility ✅ *(this kickoff)* | Research, feasibility matrix, architecture, workflow | "Is this possible and allowed?" (on paper) |
| **1** | First Warthog launch ✅ *(mostly)* | Tasks 1–3, 8, 9 done: toolchain, our arena, stacked-explosion launches, grenade pile gun and overshield gun. Open: MCC-side endless grenades and reset (tasks 4–5) | "Does the real engine + our content loop work?" |
| **2** | First interactive challenge | Landing platform trigger, success feedback, counter, challenge reset; a CI guard | "Can scripts detect physics outcomes reliably?" |
| **3** | Sandbox systems | Object pools + respawn, overshields, teleport pads, modifier toggles via cheat globals, input-driven controls | "How far does HSC go as a sandbox UI?" |
| **4** | Expanded playground: **Sky Islands** | A massive vertical world of floating islands, climbed level by level (`docs/product/map-design.md`): task 10 experiment, then stages from task 11; enemies, ships and the big ship later | World size and height limits, floating geometry, lightmap time, performance budgets |
| **5** | Browser validation | **Local-only** OpenCE test (needs an Xbox disc image): does our map load? Side-by-side physics comparison with MCC | "Is browser play viable and faithful?" |
| **6** | Portfolio release | Video, screenshots, engineering write-up, Workshop/Releases build for MCC owners (after an EULA review) | Presentation, legal check |

**Should browser validation move earlier?** A tiny OpenCE smoke test could happen right after Milestone 1, *if* the owner
has an original Xbox disc image to hand. It would only take an hour or two and would tell us early whether our map works
there. If there's no disc, it stays at Milestone 5, and the result doesn't block anything, because MCC is the primary platform.
