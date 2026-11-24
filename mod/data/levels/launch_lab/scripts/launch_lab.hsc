; Launch Lab: level scripts (H1A / MCC Halo CE). Debug-only scripts live in debug.hsc (not in release builds).
; Every function used here was confirmed in the installed tools with `tool script-doc <name>` (task 8).
;
; ---- Unlimited ammo, also in MCC (owner) -----------------------------------------------------------------
; MCC has no console, so the cheat is switched on by script, as the stock campaign does with other cheats
; (data\levels\b30\scripts\cinematics_b30.hsc in the extracted tools: (set cheat_deathless_player on)).
; Re-set once a second in case a checkpoint revert resets it.
; Covers grenades too (Standalone, task 2). Unverified in MCC until the MCC playtest.
(script continuous unlimited_ammo
	(set cheat_infinite_ammo on)
	(sleep 30)
)
