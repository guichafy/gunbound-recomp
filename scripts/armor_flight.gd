extends RefCounted
## Armor T2, 4688b0 / ADR-160. One shell, two impacts; no visual clock.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Contact = preload("res://scripts/aduka_combat.gd")

static func active(shell: Dictionary) -> bool:
	return int(shell.get("vehicle",0))==4 and int(shell.get("weapon",-1))==1 and not bool(shell.get("beacon",false))

static func prepare(shell: Dictionary) -> void:
	if not active(shell):return
	# DAT row0[57..62]: three powers and three dimensions by terrain material.
	# The training damage/crater bridge uses material0; the other cells remain
	# private native state, not additional projectiles or weapon slots.
	shell.armor_fields=[236,236,236,56,56,56]
	shell.armor_phase=0

static func contact(shell: Dictionary, terrain, actors: Array) -> Dictionary:
	# 455cc0 recovers position−velocity, then scans toward the new endpoint.
	var end := Physics.integer_position(shell)
	var previous := Vector2i((int(shell.fp_pos.x)-int(shell.fp_velocity.x))>>8,(int(shell.fp_pos.y)-int(shell.fp_velocity.y))>>8)
	return Contact.projectile_contact(previous,end,terrain,actors)

static func write_contact(shell: Dictionary, point: Vector2) -> void:
	# 4566bc..456724 fixes +40/+264 to the contact pixel<<8. Do not relaunch,
	# damp velocity, preserve an overshoot or consume the rest of the sweep.
	shell.fp_pos=Vector2i(point)*256
	Physics.publish_motion(shell)
	shell.hit_pos=Vector2(Vector2i(point))

## Called only after this contact's crater/damage/actions have been resolved.
## True means keep this same shell and finish the ordinary physical tick.
static func after_impact(shell: Dictionary) -> bool:
	if not active(shell) or int(shell.armor_phase)!=0:return false
	# Retain the existing weather power bridge before applying the native ratio.
	shell.armor_fields[0]=int(shell.damage)
	for index in 6:
		shell.armor_fields[index]=Physics.quot(int(shell.armor_fields[index])*7,10)
	shell.damage=int(shell.armor_fields[0])
	shell.blast_radius=float(shell.armor_fields[3])*0.5
	shell.armor_phase=1
	return true
