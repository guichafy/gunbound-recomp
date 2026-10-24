extends RefCounted
## Presentation catalog per mobile: sprite script, HD rig layout, HD projectile
## style and UsingItem aura (ADR-081). Rules stay in mobiles.gd; combat never
## reads this file. Adding a mobile adds an entry here instead of branches in
## the rig, the projectile art, the item art and the scene.

# Pose clocks shared by BattleArt (pose timers) and MobileRig (HD motion).
const RECOIL_TIME := 1.16
# MobileFlipbook UsingItem: 20 frames at 19 fps.
const USING_ITEM_TIME := 20.0 / 19.0

# The approved HD parts (mobile_parts.png, projectile_heads.png) have one row
# per mobile. A look without "rig"/"projectile" draws only its original atlas.
const LOOKS := {
	1: {
		"kind": "mage", "sprite": "res://scripts/mage_sprite.gd",
		# COMPOSITION_FIX_0_6_3: seat, body, staff and tip on the 60 px layout.
		"rig": {"row": 1, "parts": 2, "hull": 46.0, "seat": Vector2(18, -28), "body_size": Vector2(60, 36),
			"body_top": -36.0, "gun_pivot": Vector2(-19, -34), "gun_rect": Rect2(-17, -23, 29, 23),
			"tip": Vector2(-13, -15), "wheels": false},
		# Lasers: continuous ribbon over the real trail, tinted helix pair.
		"projectile": {"row": 1, "style": "ribbon", "sizes": [Vector2(6, 10), Vector2(6, 10), Vector2(28, 28)]},
		"using": {"file": "UsingItemMage.png", "cell": Vector2(109, 150)},
	},
	2: {
		"kind": "bigfoot", "sprite": "res://scripts/bigfoot_sprite.gd",
		"rig": {"row": 0, "parts": 3, "hull": 49.0, "seat": Vector2(17, -20), "body_size": Vector2(60, 24),
			"body_top": -31.0, "gun_pivot": Vector2(-17, -37), "gun_rect": Rect2(-13, -18, 25, 21),
			"tip": Vector2(-12, -13), "wheels": true},
		# Bombs: constant head with the flame cut from shots.png behind it.
		"projectile": {"row": 0, "style": "flame", "sizes": [Vector2(14, 11), Vector2(8, 6), Vector2(18, 12)]},
		"using": {"file": "UsingItemBigfoot.png", "cell": Vector2(129, 130)},
	},
	3: {
		# Nak: HD postponed by the user (NAK_0_15.md). The tank3.epa "item" state
		# is only a jump of the body (frames 203–222) and the fork has no
		# UsingItem sheet, so there is no aura until such art exists.
		"kind": "nak", "sprite": "res://scripts/nak_sprite.gd",
		"rig": {}, "projectile": {}, "using": {},
	},
}

static func ids() -> Array:
	return LOOKS.keys()

static func look(vehicle_id: int) -> Dictionary:
	return LOOKS.get(vehicle_id, {})

## Look of the asset folder name used by sprites and the rig ("bigfoot", "mage", "nak").
static func by_kind(kind: String) -> Dictionary:
	for vehicle_id in LOOKS:
		if LOOKS[vehicle_id].kind == kind:
			return LOOKS[vehicle_id]
	return {}

static func id_of(kind: String) -> int:
	for vehicle_id in LOOKS:
		if LOOKS[vehicle_id].kind == kind:
			return vehicle_id
	return -1

static func rig_layout(kind: String) -> Dictionary:
	return by_kind(kind).get("rig", {})

static func projectile_style(kind: String) -> Dictionary:
	return by_kind(kind).get("projectile", {})

static func using_aura(kind: String) -> Dictionary:
	return by_kind(kind).get("using", {})
