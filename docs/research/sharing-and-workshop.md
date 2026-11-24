# Research: sharing the map with people who own MCC (task 20)

Researched 2026-11-24 from official Microsoft / Halo Waypoint sources (URLs below). **Not legal advice.**

## Steam Workshop is the official route (confirmed)
- **Excession**, Microsoft's "MCC Mod Uploader", uploads MCC mods to the Steam Workshop. Halo: CE is supported,
  **including campaign (singleplayer) mods**: you "create a campaign consisting of multiple maps".
  ([Excession overview](https://learn.microsoft.com/en-us/halo-master-chief-collection/excession/excessionoverview))
- **Package layout:** a mod folder one level below a root folder. Our `.map` goes in its `maps\` subfolder.
  Excession writes `ModInfo.json` and, per campaign map, `campaign\<scenario>.json`. Metadata: title, description,
  version, min/max game version; per map the **Scenario File Name** (`levels/launch_lab/launch_lab`, the tag path, not
  the .map name), a thumbnail, a large image and a loading-screen image (PNG). One campaign per mod package.
  ([folder structure](https://learn.microsoft.com/en-us/halo-master-chief-collection/excession/setup/folderstructure),
  [campaign mod](https://learn.microsoft.com/en-us/halo-master-chief-collection/excession/creatingmodpackage/campaignmod),
  [properties](https://learn.microsoft.com/en-us/halo-master-chief-collection/excession/creatingmodpackage/specifyingproperties))
- **Its own menu entry, no file swap:** subscribed mods are listed by MCC; a Halo Waypoint feature describes playing a CE
  campaign mod "from the list of 'Halo: CE Anniversary' options in the 'Campaigns' menu".
  ([Mod Minute 2](https://www.halowaypoint.com/news/mcc-mod-minute-2))
- **Players need anti-cheat off:** "Mods are never enumerated under EAC-enabled"; launch option "MCC Anti-Cheat
  Disabled (Mods and Limited Services)". ([December 2022 update](https://www.halowaypoint.com/news/halo-mcc-december-2022-update))
- **Upload:** Steam running and logged in; accept the Steam Workshop Contribution Agreement.

## What the terms say
- **MCC EULA:** Mods are fine to distribute, Modded Versions are not: "By 'Mods,' we mean something original … that
  doesn't contain a substantial part of our copyrightable code or content. When you combine your Mod with the Halo: The
  Master Chief Collection software, we will call that combination a 'Modded Version' … You may not distribute any Modded
  Versions." ([EULA PDF](https://wpassets.halowaypoint.com/wp-content/2021/11/MCCandMODDING_EULA_ENG.pdf))
- **EULA FAQ:** "we do plan to facilitate an ecosystem for mods within Steam Workshop, you are free to share your mods as
  you see fit"; "Only the assets contained within the retail version of MCC are allowed for use in modding efforts";
  selling mods: "At this time no". ([FAQ](https://www.halowaypoint.com/news/mccs-eula-the-faq))
- **Mod tools licence:** don't share or distribute **the tools**, and no commercial use. That's about the tools, not the
  maps they build.
- **Tension:** a built `.map` packs stock tag data, which strains the "Mod" definition. But Microsoft built Excession
  specifically to distribute `.map` files through the Workshop. **Reading: the Workshop via Excession is the sanctioned
  channel; other hosting has less explicit cover.**
- **Requirements:** non-commercial; must not look official (Trademark & Brand guidelines); assets only from retail MCC
  (we use only stock MCC tags and our own geometry and scripts). The **Game Content Usage Rules** ask for a notice:
  "[Game] © Microsoft Corporation. [Title] was created under Microsoft's 'Game Content Usage Rules' using assets from
  [Game], and it is not endorsed by or affiliated with Microsoft", with a link to
  [the Rules](https://www.xbox.com/en-US/developers/rules).

## Gotchas
- MCC updates "may require you to rebuild your maps" (stock tags can change), so republish after updates
  ([tools overview](https://learn.microsoft.com/en-us/halo-master-chief-collection/general/overview-tools)).
  Our stock-tag hash check will flag that.
- Min/max game version mismatches give "Mod does not support this version of the product".
- Community-reported: players need both Halo CE Campaign and Multiplayer installed (as we found).
- **Not found:** a Workshop file-size limit; official guidance on name clashes (our tag path is unique, so likely fine).

## What publishing would take (proposed task 20)
1. Install **Excession** (official, free; new software, so the owner's OK first).
2. Build the release map; make the PNG images (thumbnail, large image, loading screen) from screenshots.
3. Fill in the mod package: campaign, one map, Scenario File Name `levels/launch_lab/launch_lab`, game version range.
4. Test locally through MCC's mod list (anti-cheat off), from its own menu entry: no more `a10` swap.
5. Owner reviews the EULA reading above, then uploads (owner's Steam account; Workshop agreement).
6. Add the Game Content Usage Rules notice to the Workshop description and the README.
