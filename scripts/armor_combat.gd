extends RefCounted
## Ordinary Armor T1 projectile. T2's two-hit state lives in ArmorFlight.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Items = preload("res://scripts/items.gd")
const POWER := 210
const DIMENSION := 68
const ASPECT := 144
const FLAGS := 8

static func active(shell: Dictionary) -> bool:
	return int(shell.get("vehicle",0)) == 4 and int(shell.get("weapon",-1)) == 0 and not bool(shell.get("beacon",false))

static func prepare(shell: Dictionary, actor: Dictionary) -> void:
	if not active(shell):
		return
	# 41da80, divisor one. All three material cells agree in this DAT.
	shell.damage = POWER + 3 * Attributes.points(actor, Attributes.ATTACK)
	shell.armor_dimension = DIMENSION + Physics.quot(Attributes.points(actor, Attributes.DIG), 2)
	shell.blast_radius = Physics.quot(int(shell.armor_dimension), 2)
	shell.armor_crater_percent = 100 + int(Items.dig(str(actor.get("turn_item",""))))

static func parameters(shell: Dictionary, actor: Dictionary) -> Dictionary:
	return {"power": int(shell.damage), "dimension": int(shell.get("armor_dimension", DIMENSION)),
		"aspect": ASPECT, "flags": FLAGS, "weather_bonus": int(shell.get("native_force",0)),
		"percent": 100 + int(Items.attack(str(actor.get("turn_item",""))))}
