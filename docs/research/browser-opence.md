# Research: Running Launch Lab in a browser (OpenCE)

Researched 2026-11-23 from the [OpenCE repo](https://github.com/OpenCommunityEdition/OpenCE) (README, `port/web/README.md`,
`port/windows/README.md`, `port/linux/NETCODE.md`, `AGENTS.md`, `docs/mcc_maps.md`, `docs/custom_edition_caches.md`), read through `gh api`.

## What OpenCE is
- **CONFIRMED.** OpenCE ports a **decompilation** of the original Xbox game. The game's code was reconstructed as C and
  is compiled natively for each platform. It is not an emulator.
  - **The base is an Xbox development build (2342, `cachebeta.exe`)**, not retail Xbox, Halo PC, Custom Edition or MCC.
  - Lineage: punpckhdq/halo → bnunu/halo-1 → OpenCE.
- **CONFIRMED.** It is very active:
  - about 2k stars;
  - near-daily release builds (Build 387 on 2026-11-16);
  - targets Windows (32-bit x86), Linux, Android and the web (macOS is in progress).
- **CONFIRMED licence:** AGPL-3.0-or-later from a certain commit onward; earlier code is CC0.
  - The README says it contains no game data and "gives no rights in Halo".
  - The AGPL's network clause means that **hosting a modified build obliges us to publish its source**.

## Data requirements (CONFIRMED, README)
- **You must provide your own Xbox disc image** (.iso/.xiso, any region). Halo PC `maps/` is refused as primary data.
- Custom Edition maps (cache v609, including Invader-built ones) load from `custom_maps/`. They need `bitmaps.map`,
  `sounds.map` and `loc.map` from a CE install. Maps that need OpenSauce are refused.
- MCC (H1A, cache v13) maps load from `mcc_maps/` through an **"experimental runtime adapter"**. They need MCC's own resource
  maps, and some MCC-only script functions are unsupported (issue #662). The docs say a map that reaches the menu "is not proof that it plays
  correctly".

## Web build (CONFIRMED, `port/web/README.md`)
- **Toolchain:**
  - Emscripten 6.0.10 + SDL3, built with `python configure.py && ninja web`.
  - It uses pthreads with `PROXY_TO_PTHREAD` and OffscreenCanvas, so the page must be **cross-origin isolated** (COOP/COEP headers).
- **Data loading:** the user picks a disc image in the browser. A worker extracts `maps/` into the browser's private file storage (OPFS, mounted at `/data`),
  and nothing is uploaded.
  - It needs about 3 GB of storage and a 2.1 GB WebAssembly memory space.
  - It has importers for CE files, MCC packages and mods.
- **What works:** audio through an AudioWorklet, pointer lock, gamepad, touch, split screen, and WebRTC multiplayer.
- **Limits:**
  - no UDP;
  - no relay;
  - no Bink video;
  - WebGL 2 shortcomings: lens flares come a frame late, and there is no SSAA/SMAA.
- **A hosted instance exists** (third-party): its availability has been unstable.

## Physics fidelity
- **CONFIRMED.** The simulation runs at **30 ticks/s like the Xbox**, and rendering interpolates between ticks. The builds disable fused
  multiply-add (FMA) and bundle musl's maths library, so floating-point results match across machines.
- **CONFIRMED.** Networking was rewritten from lockstep to host-authoritative with client prediction. This affects multiplayer, not our
  singleplayer sandbox.
- **CONFIRMED.** Optional deviations exist: Jolt ragdolls and a fix for negative point-physics radii. "Instant Aim" changes how input feels.
- **UNKNOWN.** How far the pre-release build 2342 physics differ from retail and MCC.
  **This is the key fidelity question for the browser path.**

## Assessment
| Question | Answer |
|---|---|
| Can a browser preserve original-code physics? | **Likely yes** for defaults: it runs the decompiled original code at 30 Hz. |
| Is it identical to our MCC baseline? | **Unknown.** It comes from a different build lineage (Xbox dev build vs MCC/PC). Needs a side-by-side test. |
| Will our H1A-built map run? | **Unknown.** The MCC adapter is experimental. The CE-format path (via Invader) is more mature but needs a tag-conversion step. |
| Can players get the data? | Only owners of an **original Xbox disc**, a small and shrinking group. MCC ownership is not enough. |
| Can we host it publicly? | **Not recommended.** See `legal-and-distribution.md`. The engine is decompiled Microsoft code. |

**Conclusion:** OpenCE is a genuinely interesting *compatibility experiment*, not a distribution channel. Treat it as a
local, owner-only test (if the owner has an Xbox disc) in Milestone 5, and keep MCC as the primary platform.
