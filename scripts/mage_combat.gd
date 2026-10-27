extends RefCounted
## Mage native damage/EMP. Shared algorithms are the same PE45db20/455cc0.
## See MAGE_CLIENT_REVIEW.md for source ABI, units and offline bridges.
const Shared = preload("res://scripts/aduka_combat.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Items = preload("res://scripts/items.gd")
const Damage = preload("res://scripts/damage.gd")
static var catalog: Dictionary = {}

static func warmup() -> void:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/mage/original/combat_native.json"))

static func active(projectile: Dictionary) -> bool:
	return int(projectile.get("vehicle",0))==1 and not bool(projectile.get("beacon",false))

static func prepare(projectile: Dictionary, actor: Dictionary) -> void:
	if not active(projectile):
		return
	var data: Dictionary = catalog.weapons[int(projectile.weapon)]
	#488ac0 passes divisor1/2/1 to41da80: divide the attribute addition
	# before adding it to each component, with signed IDIV truncation.
	var divisor := 2 if int(projectile.weapon)==1 else 1
	projectile.damage = int(data.power)+Physics.quot(3*Attributes.points(actor,Attributes.ATTACK),divisor)
	projectile.mage_dimension = int(data.dimension)+Physics.quot(Physics.quot(Attributes.points(actor,Attributes.DIG),2),divisor)
	projectile.blast_radius = Physics.quot(int(projectile.mage_dimension),2)
	# Keep the authorized offline item effects until native activation is ported.
	projectile.mage_crater_percent = 100+int(Items.dig(str(actor.get("turn_item",""))))

static func parameters(projectile: Dictionary, actor: Dictionary) -> Dictionary:
	var source: Dictionary = catalog.weapons[int(projectile.weapon)]
	return {"power":int(projectile.damage),"dimension":int(projectile.mage_dimension),
		"aspect":int(source.aspect),"flags":int(source.flags),
		"weather_bonus":int(projectile.get("native_force",0)),
		"percent":100+int(Items.attack(str(actor.get("turn_item",""))))}

static func apply(actors: Array, events: Array, impact: Vector2i, projectile: Dictionary, actor: Dictionary) -> int:
	var data: Dictionary = catalog.weapons[int(projectile.weapon)]
	var removed_shield := 0
	#48d8e0→425ac0: strict squared distance at native originY-10. Drain
	# before48de60→450eb0: the normal blast must then reach health directly.
	if int(data.emp)>0:
		for index in actors.size():
			var target: Dictionary = actors[index]
			if int(target.hp)<=0 or bool(target.get("invulnerable",false)):
				continue
			var delta := Shared.origin(target)-Vector2i(0,10)-impact
			if delta.length_squared()<int(data.emp)*int(data.emp):
				var shield := int(target.shield)
				target.shield = 0
				if shield>0:
					removed_shield += shield
					events.append({"type":"shield_damage","actor":index,"amount":shield,"position":target.pos,"kind":"emp"})
	return removed_shield+Shared.apply(actors,events,impact,parameters(projectile,actor))
