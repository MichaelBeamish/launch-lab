# 0005 — Gameplay devices may be new tags copied from stock, if every force stays stock

- **Status:** Accepted (2026-11-23, by the owner)
- **Date:** 2026-11-23

## Context
The owner wants a gun that drops grenade piles (task 9). A weapon trigger can only fire projectiles
("equipment tags cannot be referenced here", invader-edit), but an effect part can create a stock `frag grenade.equipment`.
That needs our own `weapon`, `projectile` and `effect` tags. ADR 0002 says a modified `projectile` copy needs an ADR.

## Decision
- Launch Lab may add **gameplay devices**: new tags of our own, copied from stock and changed only as needed, with
  clearly ours names (e.g. `pile_gun`). They are **generated** into the tools folder (`tags\levels\launch_lab\<device>\`) by
  `tools/devices.ps1` and not committed: the script is their source (like the BSP from the arena script).
- **Every force and outcome stays stock:** damage, knockback and explosions come only from stock, unmodified tags
  (here, the stock frag pickup and its stock explosion). A device may *deliver*, *place* or *trigger* stock things.
  It may not push, damage or explode with values of its own.
- Devices are **built as code** from the stock tags (`invader-edit`, as in ADR 0004) by a committed script, so each
  change from stock is listed and reviewable.
- Stock tags stay untouched, and the hash check proves it.

## Consequences
- ➕ Opens up creative tools (grenade pile guns, launch pads, spawners) while the physics on screen stays authentic.
- ➖ More of our own tags to maintain, and each tools update may need them rebuilt (scripted, so cheap).
- ➖ "Delivered by a device" is a gameplay liberty. It must be clear in game (names, later a label) that devices are ours.
- Distinct from ADR 0002's *tuned variants*, which change physics values and still need their own ADR.
- Revisit if a device needs a force of its own (that would be a tuned variant).
