# Publishing Launch Lab to the Steam Workshop (owner runbook, ADR 0006)

Excession (Steam Library: **"Halo MCC Mod Uploader"**, already installed) does the publishing. Steps from Microsoft's
Excession docs (learn.microsoft.com → Halo MCC → Excession); items marked *unverified* weren't on those pages.

## 0. Prepare (Claude's part)
1. `powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Step all -Release`: the release map (no debug scripts).
2. `powershell -ExecutionPolicy Bypass -File tools\package-mod.ps1 [-Images <folder>]`: builds
   `Documents\Launch Lab Workshop\LaunchLab\` with `maps\launch_lab.map` (SHA-256 checked) and `images\`.
3. **Images (yours):** three **PNG** screenshots, copied into `...\LaunchLab\images\`:
   - `thumbnail.png`: small, square-ish (recommended about 900 KB or less)
   - `large.png`: a wide hero shot (about 900 KB or less)
   - `loading.png`: high resolution, e.g. **1920 × 1080** (the loading screen)

   Take them in MCC with the Xbox Game Bar (Win+Alt+PrtScn), then save as PNG. The Workshop page image (optional) may be PNG
   or JPG, **up to 1 MB**.

## 1. Point Excession at the mod (one time)
1. Start Steam, then **Halo MCC Mod Uploader** from your Library.
2. **CONFIGURE** → **ADD FOLDER** → **BROWSE** → choose `Documents\Launch Lab Workshop` (the *root*, not `LaunchLab`).
3. **File → Save**. (Excession uses these root folders to write MCC's local-mod list, `ModManifest.txt`.)

## 2. Create the mod
1. On the **Home Screen** tab click **CREATE** (the MOD Info Editor opens).
2. **Mod Folder:** **BROWSE** → `Documents\Launch Lab Workshop\LaunchLab`. *(It becomes read-only after creation.)*
3. Fill in:
   - **Title:** `Launch Lab`
   - **Description:** the text in section 5 below
   - **Mod Version:** `1.0.0`
   - **Min. Game Version:** `1.3528.0` (MCC's current build, `MCC-Win64-Shipping.exe` 1.3528.0.0)
   - **Max. Game Version:** `1.3528.0`, or higher if you want it to keep loading after MCC updates (*unverified which
     is best; a mismatch gives "Mod does not support this version of the product"*)
   - **Game Title:** Halo: Combat Evolved (if offered)
4. In the **Campaign** section click **CREATE**: **Title** `Launch Lab`, **Description** a short line ("Climb the sky
   islands").
5. Under **Campaign Missions** click **ADD**, then on the map:
   - **Title:** `Launch Lab`; **Description:** "A 10-level climb of floating islands to a castle in the sky."
   - **Scenario File Name:** `levels/launch_lab/launch_lab` (the tag path, **not** the .map name)
   - **Image for Thumbnail / Large Image / Image for Loading Screen:** the three PNGs in `images\`
   - Insertion points / saved films: leave the defaults (*unverified whether one insertion point is required*)
6. **File → Save All**, then **REFRESH** on the Home Screen and read the **Trace List** for errors or warnings.

## 3. Test locally (before anything is public)
1. Quit MCC if it's running. In Steam, **Play** → **"Anti-Cheat Disabled (Mods and Limited Services)"**.
2. **Campaigns** → **Halo: Combat Evolved** → is **Launch Lab** listed? Play it: spawn, guns, unlimited ammo, a
   checkpoint, a level or two.
3. Tell Claude the result (and any Trace List messages). Claude also checks that Excession wrote `ModManifest.txt`.

## 4. Upload (public)
1. Read the terms summary in `docs/research/sharing-and-workshop.md` (your call to publish).
2. In Excession, select the mod → **UPLOAD**. Check the Title and Description; optionally pick a Workshop image (≤ 1 MB).
3. Tick **"I have read and accept the terms of the Steam Workshop Contribution Agreement"** → **UPLOAD**.
4. Copy the Workshop page link; Claude adds it to `docs/PLAY.md` and the README.

## 5. Workshop description (paste this)
> **Launch Lab:** a free, fan-made singleplayer map for Halo: Combat Evolved (MCC). Climb a 3 km world of floating
> islands by launching Warthogs with chain-reacting grenade piles, all on the original engine's physics. 10 levels,
> themed islands, a castle at the summit, unlimited ammo, checkpoints (flashlight = save anywhere).
>
> **Needs:** Halo: CE Anniversary on Steam with **both** the CE Campaign and CE Multiplayer parts installed. Launch MCC
> with **"Anti-Cheat Disabled (Mods and Limited Services)"**, then Campaigns → Halo: CE → Launch Lab.
> Guide and source: https://github.com/MichaelBeamish/launch-lab
>
> *Halo: The Master Chief Collection © Microsoft Corporation. Launch Lab was created under Microsoft's "Game Content
> Usage Rules" using assets from Halo: The Master Chief Collection, and it is not endorsed by or affiliated with
> Microsoft. Free and non-commercial.*

## Updating later
After an MCC update: rebuild (`-Release`), check the stock-tag hash baseline, re-run `package-mod.ps1`, bump **Mod
Version**, adjust the game versions, and upload again from Excession (*unverified: the docs don't say whether this
updates the same Workshop item; check that the Workshop ID stays the same*).
