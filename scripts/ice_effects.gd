extends RefCounted
## Ice state: native actor+b728/b94c/bb70/bd94. See ICE_EFFECTS_ISSUE_29.md.
## Positive values increase typed vulnerability; these are not profile stats.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Items = preload("res://scripts/items.gd")
static var catalog: Dictionary = {}

static func warmup() -> void:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/ice_effects.json"))

static func active(shell: Dictionary) -> bool:
	return int(shell.get("vehicle",0)) == 11 and int(shell.get("weapon",0)) > 0 and not bool(shell.get("beacon",false))

static func attack_mask(vehicle: int, weapon: int) -> int:
	return int(catalog.attack_masks[str(vehicle)][clampi(weapon,0,2)])

static func pose(vehicle: int) -> Dictionary:
	return catalog.poses[str(vehicle)]

static func prepare(shell: Dictionary, actor: Dictionary) -> void:
	if not active(shell):
		return
	var data: Dictionary = catalog.weapons[int(shell.weapon)]
	shell.damage = int(data.power) + 3 * Attributes.points(actor,Attributes.ATTACK)
	shell.ice_dimension = int(data.dimension) + Physics.quot(Attributes.points(actor,Attributes.DIG),2)
	shell.blast_radius = Physics.quot(int(shell.ice_dimension),2)
	shell.ice_crater_percent = 100 + int(Items.dig(str(actor.get("turn_item",""))))

static func parameters(shell: Dictionary, actor: Dictionary) -> Dictionary:
	var data: Dictionary = catalog.weapons[int(shell.weapon)]
	return {"power":int(shell.damage),"dimension":int(shell.ice_dimension),
		"aspect":int(data.aspect),"flags":int(data.flags),
		"weather_bonus":int(shell.get("native_force",0)),
		"percent":100 + int(Items.attack(str(actor.get("turn_item",""))))}

static func eligible(actor: Dictionary) -> bool:
	# The source alive bit is cleared by the actor update, after the blast.
	return bool(actor.get("ice_alive",int(actor.hp)>0)) and not bool(actor.get("invulnerable",false)) and int(actor.vehicle) != 15

static func t2(actor: Dictionary, amount: int) -> bool:
	if amount <= 0 or not eligible(actor):
		return false
	var values: Array = actor.get("native_resistance",[0,0,0,0]).duplicate()
	for i in 4:
		values[i] = mini(int(values[i]) + (5 if i == 2 else 0),50)
	actor.native_resistance = values
	return true

static func ss(actor: Dictionary, origin: Vector2i, impact: Vector2i) -> bool:
	if not eligible(actor):
		return false
	var delta := origin - Vector2i(0,10) - impact
	var radius := int(catalog.weapons[2].effect_radius)
	if delta.length_squared() >= radius * radius:
		return false
	var values: Array = actor.get("native_resistance",[0,0,0,0]).duplicate()
	for i in 4:
		values[i] = mini(int(values[i]) + 5,20)
	actor.native_resistance = values
	return true

static func modify_damage(actor: Dictionary, amount: int, flags: int) -> int:
	var values: Array = actor.get("native_resistance",[0,0,0,0])
	for i in 4:
		if (flags & (8 >> i)) != 0:
			amount = Physics.quot(amount * (100 + int(values[i])),100)
	return maxi(0,amount)

static func publishes_t2_pose(vehicle: int) -> bool:
	# Native type5/6/8/10 suppress damage/ice poses, not the state update.
	return vehicle not in [6,7,9,11]
