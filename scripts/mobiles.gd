extends RefCounted
## Playable mobiles. IDs stay 1 (Mage) and 2 (Bigfoot). Removed ID 0 is absent.
## Combat reads this catalog; it does not branch on the numeric id.

const Attributes = preload("res://scripts/player_attributes.gd")
const BigfootAttacks = preload("res://scripts/bigfoot_attacks.gd")

const PLAYABLE := [1, 2]
const DEFAULT_ID := 2
const SPECIAL := 2
# NetworkObjectParameters.SSCooldownTimer + 1, applied when the SS is fired.
const SS_LOCK := 4

const MAGE_WEAPONS := [
	{"name": "Laser", "damage": 150.0, "radius": 25.0, "delay": 100.0, "count": 1, "helix": 0.0, "emp": 0.0, "color": Color("b3ceff")},
	{"name": "Duplo laser", "damage": 200.0, "radius": 25.0, "delay": 120.0, "count": 2, "helix": 15.0, "emp": 0.0, "color": Color("d43e70")},
	{"name": "EMP", "damage": 200.0, "radius": 25.0, "delay": 1300.0 / 7.5, "count": 1, "helix": 0.0, "emp": 100.0, "color": Color("b6adff")}
]
const MAGE_AIM := [Vector2(15, 50), Vector2(15, 50), Vector2(15, 50)]

const DEFINITIONS := {
	1: {
		"name": "Mage", "hp": 760, "move": 90.0, "delay": 0.0, "color": Color("a9b7ff"),
		"shield": 220, "shield_regen": 20, "hp_regen": 0, "protection": 35,
		"box": Vector2(38, 33), "box_offset": Vector2(0, 10), "stance": 30.0,
		"beacon_delay": 0.0, "smoke": false, "bionic": false,
		"weapons": MAGE_WEAPONS, "aim_limits": MAGE_AIM,
		"spread_after_clamp": false, "generic_trail": false, "shot_sound_on": "fire",
		"death": 1.6, "hurt": 1.05, "special": SPECIAL,
		"summary": "220 de escudo · duplo laser e especial EMP."
	},
	2: {
		"name": "Bigfoot", "hp": 1100, "move": 90.0, "delay": 0.0, "color": Color("71c0ff"),
		"shield": 0, "shield_regen": 0, "hp_regen": 0, "protection": 35,
		"box": Vector2(46, 40), "box_offset": Vector2(0, 10), "stance": 25.0,
		"beacon_delay": 0.4, "smoke": true, "bionic": false,
		"weapons": BigfootAttacks.WEAPONS, "aim_limits": BigfootAttacks.AIM_LIMITS,
		"spread_after_clamp": true, "generic_trail": true, "shot_sound_on": "projectile_launch",
		"death": 1.15, "hurt": 1.05, "special": SPECIAL,
		"summary": "T1: 4 bombas · T2: 6 · SS: 8 bombas."
	}
}

static func has_id(vehicle_id: int) -> bool:
	return DEFINITIONS.has(vehicle_id)

static func normalize(vehicle_id: int) -> int:
	return vehicle_id if DEFINITIONS.has(vehicle_id) else DEFAULT_ID

static func opponent(vehicle_id: int) -> int:
	for other_id in PLAYABLE:
		if other_id != vehicle_id:
			return other_id
	return DEFAULT_ID

static func definition(vehicle_id: int) -> Dictionary:
	return DEFINITIONS[vehicle_id]

static func weapon(vehicle_id: int, weapon_index: int) -> Dictionary:
	return DEFINITIONS[vehicle_id].weapons[weapon_index]

static func weapon_count(vehicle_id: int) -> int:
	return DEFINITIONS[vehicle_id].weapons.size()

static func aim_limits(vehicle_id: int, weapon_index: int) -> Vector2:
	return DEFINITIONS[vehicle_id].aim_limits[weapon_index]

static func is_special(vehicle_id: int, weapon_index: int) -> bool:
	return weapon_index == int(DEFINITIONS[vehicle_id].special)

static func spread_after_clamp(vehicle_id: int) -> bool:
	return bool(DEFINITIONS[vehicle_id].spread_after_clamp)

static func generic_trail(vehicle_id: int) -> bool:
	return bool(DEFINITIONS[vehicle_id].generic_trail)

static func shot_sound_on(vehicle_id: int) -> String:
	return str(DEFINITIONS[vehicle_id].shot_sound_on)

static func emission(vehicle_id: int, weapon_index: int) -> Array:
	if spread_after_clamp(vehicle_id):
		return BigfootAttacks.salvo(weapon_index)
	var rules: Dictionary = weapon(vehicle_id, weapon_index)
	var result: Array = []
	for _component in range(int(rules.get("count", 1))):
		result.append({"spawn": 0.0, "angle": 0.0, "power": 0.0})
	return result

## Mobile.Regenerate. The shield cap reads health from before this tick's heal.
static func regenerate(actor: Dictionary) -> void:
	var spec: Dictionary = DEFINITIONS[int(actor.vehicle)]
	var points := Attributes.points(actor, 3)
	var current_hp := int(actor.hp)
	var cap := int(spec.shield) + int(actor.max_hp) - current_hp
	actor.hp = mini(int(actor.max_hp), current_hp + Attributes.heal(int(spec.hp_regen), points))
	actor.shield = mini(cap, int(actor.shield) + Attributes.heal(int(spec.shield_regen), points))
	actor.max_shield = int(spec.shield)

## Point bodies keep item fixtures that carry no vehicle id.
static func body(actor: Dictionary) -> Dictionary:
	if not actor.has("vehicle") or not DEFINITIONS.has(int(actor.vehicle)):
		return {"box": Vector2.ZERO, "offset": Vector2.ZERO, "stance": 24.0}
	var spec: Dictionary = DEFINITIONS[int(actor.vehicle)]
	return {"box": spec.box, "offset": spec.box_offset, "stance": float(spec.stance)}
