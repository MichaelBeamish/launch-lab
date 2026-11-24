; Launch Lab: level scripts (H1A / MCC Halo CE).
; Every function used here was confirmed in the installed tools with `tool script-doc <name>` (task 8).
;
; ---- Debug scripts (task 8 launch experiment) -------------------------------------------------------
; Debug only: "dbg_" scripts are called by hand from the Standalone console, e.g. (dbg_boom_4).
; Remove them before any release.
;
; dbg_boom_N sets off N stock frag explosions at boom_flag (under the Warthog) in the same 1/30 s tick:
; the stacking a player can't do by hand (task 2). It uses the stock, unmodified frag explosion (ADR 0002):
;   weapons\frag grenade\effects\explosion.effect, the same effect a thrown frag detonates with. Its parts include
;   the damage (explosion.damage_effect: radius 1.5-2.5 WU, 80-120 damage, acceleration 4.0) as well as the sound,
;   light and particles, so effect_new alone is one complete frag explosion.
;   (The first version also called damage_new, which doubled the damage: see docs/research/launch-experiment.md.)
; Stand at least 5 WU away: the blast radius is 2.5 WU.

(script static void dbg_boom_1
	(effect_new "weapons\frag grenade\effects\explosion" boom_flag)
)

(script static void dbg_boom_2
	(dbg_boom_1) (dbg_boom_1)
)

(script static void dbg_boom_3
	(dbg_boom_2) (dbg_boom_1)
)

(script static void dbg_boom_4
	(dbg_boom_2) (dbg_boom_2)
)

(script static void dbg_boom_6
	(dbg_boom_4) (dbg_boom_2)
)

(script static void dbg_boom_8
	(dbg_boom_4) (dbg_boom_4)
)

; Put the Warthog back where it was placed: "creates an object, destroying it first if it already exists".
(script static void dbg_hog_reset
	(object_create_anew hog)
)

; ---- Debug teleports (task 10 world-scale experiment) ---------------------------------------------------
; Jump straight to a level of the world: e.g. (dbg_tp_island_top) puts you on the island at z 900.
; (player0) is defined in the stock data\global_scripts.hsc as (unit (list_get (players) 0)).

(script static void dbg_tp_ground
	(object_teleport (player0) ground_flag)
)

(script static void dbg_tp_island_low
	(object_teleport (player0) island_low_flag)
)

(script static void dbg_tp_island_top
	(object_teleport (player0) island_top_flag)
)
