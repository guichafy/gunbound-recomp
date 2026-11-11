extends RefCounted
## Thor's Hammer type4: 489580→42bbb0/42de70→41da80.
## Consumers45db20/4e4450, evidence and bridges: BIGFOOT_COMBAT_ISSUE_28.md.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Items = preload("res://scripts/items.gd")
const POWER := [86, 70, 92]
const DIMENSION := [52, 40, 48]
const ASPECT := [134, 124, 126]
const DIVISOR := [4, 6, 8]

static func launch_velocity_fp(theta: int, power: int, entry: Dictionary) -> Vector2i:
	# MainAction operates on protected integers. In particular, adding theta
	# before truncating a fractional support angle is wrong across zero.
	return Physics.launch_velocity_fp(theta + int(entry.native_angle),power + int(entry.native_power))

static func active(shell: Dictionary) -> bool:
	return int(shell.get("vehicle",0)) == 2 and not bool(shell.get("beacon",false))

static func prepare(shell: Dictionary, actor: Dictionary) -> void:
	if not active(shell):
		return
	var weapon := int(shell.weapon)
	# Three material cells are identical in this pinned DAT. Divide only the
	# attribute additions; never divide the base power by the salvo size.
	shell.damage = POWER[weapon] + Physics.quot(3 * Attributes.points(actor,Attributes.ATTACK),DIVISOR[weapon])
	shell.bigfoot_dimension = DIMENSION[weapon] + Physics.quot(Physics.quot(Attributes.points(actor,Attributes.DIG),2),DIVISOR[weapon])
	shell.blast_radius = Physics.quot(int(shell.bigfoot_dimension),2)
	# Explicit offline item bridge, as for Mage/Boomer/Grub.
	shell.bigfoot_crater_percent = 100 + int(Items.dig(str(actor.get("turn_item",""))))

static func parameters(shell: Dictionary, actor: Dictionary) -> Dictionary:
	return {"power":int(shell.damage),"dimension":int(shell.bigfoot_dimension),
		"aspect":ASPECT[int(shell.weapon)],"flags":8,
		"weather_bonus":int(shell.get("native_force",0)),
		"percent":100 + int(Items.attack(str(actor.get("turn_item",""))))}
