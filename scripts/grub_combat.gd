extends RefCounted
## Grub (type 12) native damage and crater. Same PE routines as the Mage and
## Aduka ports (0x45db20 falloff, 0x4e4450 midpoint crater); the numbers are the
## characterdata.dat row of type 12 (docs/sdd/GRUB_CLIENT_FIX.md).
const Shared = preload("res://scripts/aduka_combat.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Items = preload("res://scripts/items.gd")
const VEHICLE := 13
static var catalog: Dictionary = {}

static func warmup() -> void:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/grub/combat_native.json"))

static func active(projectile: Dictionary) -> bool:
	return int(projectile.get("vehicle", 0)) == VEHICLE and not bool(projectile.get("beacon", false)) and not bool(projectile.get("child", false))

static func prepare(projectile: Dictionary, actor: Dictionary) -> void:
	# Shells built by hand (suites, bridges) may omit the vehicle the emission sets.
	if not projectile.has("vehicle") and int(actor.get("vehicle", 0)) == VEHICLE and projectile.has("g_kind"):
		projectile.vehicle = VEHICLE
	if not active(projectile):
		return
	var data: Dictionary = catalog.weapons[int(projectile.weapon)]
	# 41da80 adds 3 x Attack to the power and Dig / 2 to the dimension. The caller
	# divisor of Mage (0x488ac0) is not proven for Grub: kept at 1 (adaptation).
	projectile.damage = int(data.power) + 3 * Attributes.points(actor, Attributes.ATTACK)
	projectile.grub_dimension = int(data.dimension) + Physics.quot(Attributes.points(actor, Attributes.DIG), 2)
	projectile.blast_radius = Physics.quot(int(projectile.grub_dimension), 2)
	projectile.grub_crater_percent = 100 + int(Items.dig(str(actor.get("turn_item", ""))))

static func parameters(projectile: Dictionary, actor: Dictionary) -> Dictionary:
	if not projectile.has("grub_dimension"):
		prepare(projectile, actor)
	var source: Dictionary = catalog.weapons[int(projectile.weapon)]
	return {"power": int(projectile.damage), "dimension": int(projectile.grub_dimension),
		"aspect": int(source.aspect), "flags": int(source.flags),
		"weather_bonus": int(projectile.get("native_force", 0)),
		"percent": 100 + int(Items.attack(str(actor.get("turn_item", ""))))}

static func crater_spans(projectile: Dictionary, center: Vector2i) -> Array[Vector3i]:
	assert(projectile.has("grub_dimension"), "parameters() prepares the shell before the crater")
	var source: Dictionary = catalog.weapons[int(projectile.weapon)]
	var dimension := Physics.quot(int(projectile.grub_dimension) * int(projectile.get("grub_crater_percent", 100)), 100)
	return Shared.crater_spans(center, dimension, int(source.aspect))

static func apply(actors: Array, events: Array, impact: Vector2i, projectile: Dictionary, actor: Dictionary) -> int:
	return Shared.apply(actors, events, impact, parameters(projectile, actor))
