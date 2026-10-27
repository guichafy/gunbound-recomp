extends RefCounted
## Playable mobiles. IDs stay 1 (Mage), 2 (Bigfoot) and 3 (Nak). Removed ID 0 is absent.
## Combat reads this catalog; it does not branch on the numeric id.

const Attributes = preload("res://scripts/player_attributes.gd")
const BigfootAttacks = preload("res://scripts/bigfoot_attacks.gd")
const ClassicMobiles = preload("res://scripts/classic_mobiles.gd")
const ShotTiming = preload("res://scripts/classic_shot_timing.gd")
const DelayUnits = preload("res://scripts/delay_units.gd")

# 1 Mage, 2 Bigfoot, 3 Nak stay first so opponent() keeps 1↔2 and Nak→Mage.
const PLAYABLE := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
const DEFAULT_ID := 2
const SPECIAL := 2
# NetworkObjectParameters.SSCooldownTimer + 1, applied when the SS is fired.
const SS_LOCK := 4
# Low-health share: damaged idle/move frames and the Bigfoot smoke.
const LOW_HEALTH := 0.3

# "cost" is the OpenBound DelayPresets value; weapon() adds "delay" in turn units.
const MAGE_WEAPONS := [
	{"name": "Laser", "damage": 200.0, "radius": 33.0, "cost": 750, "count": 1, "helix": 0.0, "flight": "mage_laser", "emp": 0.0, "color": Color("b3ceff")},
	{"name": "Duplo laser", "damage": 186.0, "radius": 27.0, "cost": 900, "count": 2, "helix": 0.0, "flight": "mage_wave", "emp": 0.0, "color": Color("d43e70")},
	{"name": "EMP", "damage": 380.0, "radius": 30.0, "cost": 1300, "count": 1, "helix": 0.0, "emp": 150.0, "color": Color("b6adff")}
]
const MAGE_AIM := [Vector2(15, 50), Vector2(15, 50), Vector2(15, 50)]

# Nak (ADR-074). The fork only has MobileMetadata, AimPresets and DelayPresets.
# Damage is the first per-shot value of the original characterdata.dat record 2
# and the radius half of the second (same reading that matches Bigfoot); the
# flight rules come from the original client's Bullet3 classes (NAK_0_15.md).
# Delays are base [28] + shot [30/31/32] of that record (ADR-076): the fork's
# 760/910/1310 Nak row belongs to another mobile.
# "burrow": the shell enters the ground and explodes where it resurfaces.
# "ghost": the shell crosses terrain and only collides with mobiles.
const NAK_WEAPONS := [
	{"name": "Esfera", "damage": 200.0, "radius": 30.0, "cost": 770, "count": 1, "color": Color("f0a060")},
	{"name": "Bomba de oscilação", "damage": 350.0, "radius": 35.0, "cost": 920, "count": 1, "burrow": true, "color": Color("d0d0d8")},
	{"name": "Mini Nak", "damage": 360.0, "radius": 35.0, "cost": 1320, "count": 1, "ghost": true, "color": Color("e8743a")}
]
const NAK_AIM := [Vector2(10, 50), Vector2(10, 50), Vector2(10, 50)]

# time_delay: characterdata.dat [29], delay added per whole second spent before
# firing (ComputeTurnDelay). Mage HP/shield regeneration also come from that
# table (730/30), replacing the fork's 760/20 (ADR-076).
const DEFINITIONS := {
	1: {
		"name": "Mage", "hp": 730, "move": 90.0, "delay": 0.0, "time_delay": 10, "color": Color("a9b7ff"),
		"shield": 220, "shield_regen": 30, "hp_regen": 0, "protection": 35,
		"box": Vector2(38, 33), "box_offset": Vector2(0, 10), "stance": 30.0,
		"beacon_delay": 0.0, "smoke": false, "bionic": false,
		"weapons": MAGE_WEAPONS, "aim_limits": MAGE_AIM,
		"spread_after_clamp": false, "generic_trail": false, "shot_sound_on": "fire",
		"death": 1.6, "hurt": 1.05, "special": SPECIAL,
		"summary": "220 de escudo · duplo laser e especial EMP."
	},
	2: {
		"name": "Bigfoot", "hp": 1100, "move": 90.0, "delay": 0.0, "time_delay": 10, "color": Color("71c0ff"),
		"shield": 0, "shield_regen": 0, "hp_regen": 0, "protection": 35,
		"box": Vector2(46, 40), "box_offset": Vector2(0, 10), "stance": 25.0,
		"beacon_delay": 0.4, "smoke": true, "bionic": false,
		"weapons": BigfootAttacks.WEAPONS, "aim_limits": BigfootAttacks.AIM_LIMITS,
		"spread_after_clamp": true, "salvo": true, "generic_trail": true, "shot_sound_on": "projectile_launch",
		"death": 1.15, "hurt": 1.05, "special": SPECIAL,
		"summary": "T1: 4 bombas · T2: 6 · SS: 8 bombas."
	},
	3: {
		"name": "Nak", "hp": 1100, "move": 90.0, "delay": 0.0, "time_delay": 10, "color": Color("f2a65a"),
		"shield": 0, "shield_regen": 0, "hp_regen": 0, "protection": 35,
		"box": Vector2(46, 30), "box_offset": Vector2(0, 10), "stance": 25.0,
		"beacon_delay": 0.0, "smoke": false, "bionic": false,
		"weapons": NAK_WEAPONS, "aim_limits": NAK_AIM,
		"spread_after_clamp": false, "generic_trail": false, "shot_sound_on": "fire",
		"death": 1.15, "hurt": 1.05, "special": SPECIAL,
		"summary": "S2 cava e emerge · SS atravessa o chão."
	}
}

# DEFINITIONS is the original three. ALL adds the classic roster at load.
static var ALL := {}

static func _static_init() -> void:
	ShotTiming.prewarm()
	ALL = DEFINITIONS.duplicate(true)
	var extra: Dictionary = ClassicMobiles.definitions()
	for id in extra:
		ALL[id] = extra[id]

static func has_id(vehicle_id: int) -> bool:
	return ALL.has(vehicle_id)

static func normalize(vehicle_id: int) -> int:
	return vehicle_id if ALL.has(vehicle_id) else DEFAULT_ID

static func opponent(vehicle_id: int) -> int:
	for other_id in PLAYABLE:
		if other_id != vehicle_id:
			return other_id
	return DEFAULT_ID

static func definition(vehicle_id: int) -> Dictionary:
	return ALL[vehicle_id]

## Copy of the catalog shot with "delay" = cost reduced by AttackDelay points.
static func weapon(vehicle_id: int, weapon_index: int, delay_points: int = 0) -> Dictionary:
	var rules: Dictionary = ALL[vehicle_id].weapons[weapon_index].duplicate()
	rules.delay = DelayUnits.from_original(int(rules.cost), delay_points)
	return rules

static func weapon_count(vehicle_id: int) -> int:
	return ALL[vehicle_id].weapons.size()

static func aim_limits(vehicle_id: int, weapon_index: int) -> Vector2:
	return ALL[vehicle_id].aim_limits[weapon_index]

static func is_special(vehicle_id: int, weapon_index: int) -> bool:
	return weapon_index == int(ALL[vehicle_id].special)

static func spread_after_clamp(vehicle_id: int) -> bool:
	return bool(ALL[vehicle_id].spread_after_clamp)

static func generic_trail(vehicle_id: int) -> bool:
	return bool(ALL[vehicle_id].generic_trail)

static func shot_sound_on(vehicle_id: int) -> String:
	return "projectile_launch"

## Shells of one shot: the Bigfoot emitter salvo, else "count" shells at once.
static func emission(vehicle_id: int, weapon_index: int) -> Array:
	# Explicit user requirement after ADR-124: three T2 creatures. Keep the
	# extracted PE catalog (two calls) intact and publish this override once.
	if vehicle_id==16 and weapon_index==1:
		var three: Array = []
		for group in 3:
			three.append({"spawn":(2+group*4)*ShotTiming.STEP,"angle":0.0,"power":0.0,
				"sound_group":group,"sound":true,"pose_start_at":0.0})
		return three
	if bool(ALL[vehicle_id].get("salvo", false)):
		return ShotTiming.emission(vehicle_id, weapon_index, BigfootAttacks.salvo(weapon_index))
	var rules: Dictionary = weapon(vehicle_id, weapon_index)
	if rules.has("shells"):
		return ShotTiming.emission(vehicle_id, weapon_index, ClassicMobiles.emission(rules))
	var result: Array = []
	for _component in range(int(rules.get("count", 1))):
		result.append({"spawn": 0.0, "angle": 0.0, "power": 0.0})
	return ShotTiming.emission(vehicle_id, weapon_index, result)

## Mobile.Regenerate. The shield cap reads health from before this tick's heal.
static func regenerate(actor: Dictionary) -> void:
	var spec: Dictionary = ALL[int(actor.vehicle)]
	var points := Attributes.points(actor, Attributes.REGEN)
	var current_hp := int(actor.hp)
	var cap := int(spec.shield) + int(actor.max_hp) - current_hp
	actor.hp = mini(int(actor.max_hp), current_hp + Attributes.heal(int(spec.hp_regen), points))
	actor.shield = mini(cap, int(actor.shield) + Attributes.heal(int(spec.shield_regen), points))
	actor.max_shield = int(spec.shield)

static func low_health(actor: Dictionary) -> bool:
	return float(actor.hp) <= float(actor.max_hp) * LOW_HEALTH

## Point bodies keep item fixtures that carry no vehicle id.
static func body(actor: Dictionary) -> Dictionary:
	if not actor.has("vehicle") or not ALL.has(int(actor.vehicle)):
		return {"box": Vector2.ZERO, "offset": Vector2.ZERO, "stance": 24.0}
	var spec: Dictionary = ALL[int(actor.vehicle)]
	return {"box": spec.box, "offset": spec.box_offset, "stance": float(spec.stance)}

# characterdata.dat [25]/[40], in stable playable ID order (ADR-084).
const FORCE_MAX := {1:45, 2:42, 3:41, 4:46, 5:43, 6:35, 7:44, 8:47, 9:50, 10:45, 11:50, 12:46, 13:50, 14:50, 15:48, 16:48}
const GRAVITY_NATIVE := {1:90, 2:98, 3:98, 4:98, 5:98, 6:98, 7:98, 8:90, 9:98, 10:98, 11:98, 12:98, 13:98, 14:90, 15:98, 16:94}
static func force_max(vehicle_id: int) -> int:
	return FORCE_MAX[vehicle_id]
static func gravity_native(vehicle_id: int) -> int:
	return GRAVITY_NATIVE[vehicle_id]
static func minimum_power(vehicle_id: int) -> float:
	return 10.0 / force_max(vehicle_id)
