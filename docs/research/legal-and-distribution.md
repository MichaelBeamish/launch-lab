# Research: Legal and distribution posture

> **Not legal advice.** This is a summary of public terms as researched on 2026-11-23. Before any public release, read the actual
> EULAs shown in Steam (CE Mod Tools, app 1532190, and MCC) in full.

## Three different things we might do
| Activity | Risk | Notes |
|---|---|---|
| **Personal mod**: build and play locally with official tools | **Low** | This is what the tools are for. |
| **Distribute the custom map** to MCC owners (Workshop or download) | **Low–moderate** | The 343 EULA FAQ supports it. It must stay non-commercial and contain our own assets plus MCC content only. |
| **Publicly host a browser-playable build** (OpenCE) | **High** | The engine is decompiled Microsoft code. "Bring your own data" doesn't cure that (SM64 PC port precedent). |

## Permitted (CONFIRMED)
- **Using the official mod tools for MCC content.**
  - [MS Learn](https://learn.microsoft.com/en-us/halo-master-chief-collection/general/overview-tools)
  - The [343 MCC EULA FAQ](https://www.halowaypoint.com/news/mccs-eula-the-faq) says "you are free to share your mods as you see fit". It also says anything in MCC may be used for modding.
- **Non-commercial videos, screenshots and write-ups** under the [Game Content Usage Rules](https://www.xbox.com/en-US/developers/rules).
  - These need the attribution notice and a link to the rules.
  - The licence is personal and revocable.
- **Referring to the game by name descriptively**, without implying endorsement. ([Microsoft trademark guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks))

## Prohibited (CONFIRMED)
- **Monetisation of any kind.** No sales, paywalls, merch, or ads on our own site. The tools EULA also excludes non-profit and revenue-generating use.
- **Reverse engineering games to access assets.** This rules out ripping assets with our own extraction tools.
- **Redistributing the tools.** "Don't just rip art resources and pass them around."
- **Microsoft or Halo logos**, or "Halo" in our product name, domain or social account names.
- **Assets from non-MCC games** in MCC mods.

## Grey areas (UNRESOLVED)
1. **"Share mods as you see fit" (FAQ) vs. "you may not distribute Modded Versions" (MCC EULA).**
   - Our best reading: self-made map files are "mods"; modified game executables or packages are "Modded Versions". Unconfirmed.
2. **Running an H1A-built map in a non-MCC engine.** The tools licence speaks of use "solely with" MCC titles.
3. **OpenCE itself.** A decompiled pre-release build. The repo makes no legal claim, and takedown status is unclear.
   - Microsoft has a track record of DMCA actions against Halo derivative projects: ElDorito (2015), ElDewrito (2018), and a Halo 3 recreation in CS2.
4. **Committing our own `.scenario` and BSP tags to a public repo.** They're our work, but they reference stock tag paths. We believe this is fine: a reference is a path, not the asset itself. Still, it should be reviewed before the repo goes public.

## Our posture (accepted, see ADR 0003)
1. **The primary platform is MCC on Steam.** We build with H1A-EK, using stock MCC tags and our own original geometry, scripts and textures.
2. **The repo contains only our own work:**
   - Our own sources: scripts, Blender files, our own tags, tooling and docs.
   - Never stock tags, extracted data, `.map` builds or tool binaries. `.gitignore` plus a CI guard enforce this.
3. **The map is distributed (later, after reading the EULAs) via Steam Workshop and/or GitHub Releases, to MCC owners only.**
4. **The browser is a local experiment only.** We don't host an OpenCE build or any game data. At most, the portfolio links to upstream and shows
   our recorded test results.
5. **Naming:** "Launch Lab: a physics sandbox map for Halo: Combat Evolved (MCC)".
   - Keep "halo" out of the repo slug and any domain.
   - Use no logos.
   - Include the trademark notice, the "not affiliated with or endorsed by Microsoft" line, and the Content Usage Rules attribution.
6. **Portfolio:** videos, screenshots, the engineering write-up and source on GitHub. That stays valuable even if nothing is playable in a browser.
7. **Comply immediately with any takedown request.**
