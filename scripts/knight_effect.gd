extends RefCounted
## Knight Ion (client type 14, ADR-154). The guide of every shot only wakes the
## Ion: SpawnKnightIon 0x438100, Animate 0x47ca40, S1/S2 activation 0x47c040,
## SS 0x47c3f0, children 0x4305c0 (vtable 0x556008, Animate 0x47ab00).
##  - idle: hovers over its owner at y-200, closing ceil(|d|/8) per tick and
##    aiming 0x47bfd0 at the last target; busy moves close ceil(|d|/2).
##  - S1/S2: "move" back over the owner, then fire1/fire2; on frame 2 it fans
##    3 (theta, +4, -4) or 5 (theta, +2, -2, +4, -4) children. Each starts R
##    back from the target along its own angle (R = |Ion - target|), so the fan
##    converges, and waits 3/7/7(/11/11) ticks before flying.
##  - SS: goes to the sweep start at owner y-400 (tan 4 deg * 400 = 27 px per
##    step, as ASate), fire1, and on frame 1 emits 8 children at 276/272/268/264
##    and back, x stepping +27 and back, each waiting i*2 ticks.
## Children fly (cos, -sin)*6144 with acceleration (cos, -sin)*768: no gravity,
## no wind (0x4305c0 floats 0x55809c/0x558098/0x558094/0x558090).
const Physics = preload("res://scripts/classic_ballistics.gd")
const ShellState = preload("res://scripts/shell_state.gd")
const Asate = preload("res://scripts/asate_effect.gd")
const VEHICLE := 15
const MODE := "knight_guide"
const CHILD := "knight_child"
const HEIGHT := 200
const SS_HEIGHT := 400
const SPEED := 6144.0
const ACCELERATION := 768.0
const FANS := {0: [[0, 3], [4, 7], [-4, 7]], 1: [[0, 3], [2, 7], [-2, 7], [4, 11], [-4, 11]]}
const SS_CHILDREN := 8
const FIRE_TICKS := 20

static func guide(shell: Dictionary) -> bool:
	return str(shell.get("flight", "")) == MODE and not bool(shell.get("beacon", false))

static func owner_position(model, owner: int) -> Vector2i:
	return Vector2i(Vector2(model.actors[owner].pos).floor())

static func home(model, owner: int) -> Vector2i:
	var base := owner_position(model, owner)
	var y := base.y - HEIGHT
	# Same snapshot-owned ceiling policy as ASate: never read the live camera.
	if model.get("satellite_ceiling") != null:
		y = mini(y, int(model.get("satellite_ceiling")))
	return Vector2i(base.x, y)

static func ensure_ion(model, owner: int) -> Dictionary:
	if not model.satellites.has(owner):
		var start := home(model, owner)
		model.satellites[owner] = {"kind": "knight", "owner": owner, "pos": start, "previous_pos": start,
			"state": "normal", "state_tick": 0, "angle": 270, "target": start, "busy": false, "idle_tick": 0}
	return model.satellites[owner]

static func approach(point: Vector2i, destination: Vector2i, divisor: int) -> Vector2i:
	return Vector2i(Asate.approach(point.x, destination.x, divisor), Asate.approach(point.y, destination.y, divisor))

static func step_ions(model) -> void:
	for owner in model.actors.size():
		if int(model.actors[owner].vehicle) != VEHICLE:
			continue
		var ion := ensure_ion(model, owner)
		if bool(ion.busy):
			continue
		ion.previous_pos = ion.pos
		ion.pos = approach(Vector2i(ion.pos), home(model, owner), 8)
		var target: Vector2i = ion.target
		for projectile in model.projectiles:
			if guide(projectile) and int(projectile.get("owner", model.shot_actor)) == owner and bool(projectile.get("launched", false)):
				target = Vector2i(Vector2(projectile.hit_pos).floor())
		ion.target = target
		if target != Vector2i(ion.pos):
			ion.angle = Asate.aim_angle(target - Vector2i(ion.pos))
		ion.state = "normal"
		ion.state_tick = (int(ion.state_tick) + 1) % 20
		ion.idle_tick = (int(ion.idle_tick) + 1) % 22

## Guide impact: the Ion takes over this shot.
static func begin(model, projectile: Dictionary, impact: Vector2) -> Dictionary:
	var owner := int(projectile.get("owner", model.shot_actor))
	var weapon := int(projectile.weapon)
	ensure_ion(model, owner)
	var target := Vector2i(impact.floor())
	var base := owner_position(model, owner)
	var destination := home(model, owner)
	var x_step := 0
	if weapon == 2:
		# 0x47c3f0: tan(0x558070) * 400, then the sweep starts 1.5 steps to the left.
		x_step = int(tan(0.06977777928113937) * float(SS_HEIGHT))
		destination = Vector2i(target.x - Physics.quot(x_step, 2) - x_step, base.y - SS_HEIGHT)
	return {"kind": "knight", "owner": owner, "weapon": weapon, "target": target, "destination": destination,
		"stage": "move", "activated": false, "tick": 0, "x_step": x_step, "rules": model.weapon_rules(owner, weapon).duplicate(true),
		"volley": int(projectile.get("volley", 0)), "age": 0}

static func child(effect: Dictionary, position: Vector2i, angle: int, index: int, delay: int) -> Dictionary:
	var rules: Dictionary = effect.rules.duplicate(true)
	rules.flight = CHILD
	var shell := ShellState.create(Vector2(position), Vector2.ZERO, 0.0, rules, int(effect.weapon), index)
	var velocity := Vector2i(int(Physics.s(angle + 90) * SPEED), int(Physics.s(angle) * -SPEED))
	var acceleration := Vector2i(int(Physics.s(angle + 90) * ACCELERATION), int(Physics.s(angle) * -ACCELERATION))
	Physics.seed(shell, position * 256, velocity, acceleration)
	shell.launch_velocity_fp = velocity
	shell.child = true
	shell.launched = true
	shell.owner = int(effect.owner)
	shell.vehicle = VEHICLE
	shell.volley = int(effect.volley)
	shell.knight_delay = delay
	shell.knight_angle = angle
	return shell

## S1/S2 fan around the target: start = target - R * (cos, -sin) of each angle.
static func fan(effect: Dictionary, ion: Vector2i) -> Array:
	var target: Vector2i = effect.target
	var delta := target - ion
	var radius := int(sqrt(float(delta.x * delta.x + delta.y * delta.y)))
	var theta := Asate.aim_angle(delta)
	var shells: Array = []
	for entry in FANS[clampi(int(effect.weapon), 0, 1)]:
		var angle: int = theta + int(entry[0])
		var start := Vector2i(target.x + int(float(radius) * Physics.s(angle + 270)), target.y - int(float(radius) * Physics.s(angle + 180)))
		shells.append(child(effect, start, angle, shells.size(), int(entry[1])))
	return shells

## SS rain: x and angle step four times, then retrace the same four.
static func rain(effect: Dictionary, ion: Vector2i) -> Array:
	var x := int(effect.destination.x)
	var step := int(effect.x_step)
	var angle := 276
	var turn := -4
	var shells: Array = []
	for index in SS_CHILDREN:
		shells.append(child(effect, Vector2i(x, ion.y), angle, index, index * 2))
		if index == 3:
			step = -step
			turn = -turn
		else:
			x += step
			angle += turn
	return shells

## One native tick; true while the Ion still holds the shot.
static func step(effect: Dictionary, model) -> bool:
	var ion := ensure_ion(model, int(effect.owner))
	if not bool(effect.activated):
		effect.activated = true
		ion.busy = true
		ion.state = "move"
		ion.state_tick = 0
		ion.target = effect.target
	ion.previous_pos = ion.pos
	effect.age = int(effect.age) + 1
	var point := Vector2i(ion.pos)
	if Vector2i(effect.target) != point:
		ion.angle = Asate.aim_angle(Vector2i(effect.target) - point)
	if str(effect.stage) == "move":
		ion.pos = approach(point, Vector2i(effect.destination), 2)
		ion.state_tick = (int(ion.state_tick) + 1) % 20
		if Vector2i(ion.pos) == Vector2i(effect.destination):
			effect.stage = "fire"
			effect.tick = 0
			ion.state = "fire2" if int(effect.weapon) == 1 else "fire1"
			ion.state_tick = 0
		return true
	if str(effect.stage) == "fire":
		effect.tick = int(effect.tick) + 1
		ion.state_tick = int(effect.tick)
		var weapon := int(effect.weapon)
		if (weapon == 2 and int(effect.tick) == 1) or (weapon != 2 and int(effect.tick) == 2):
			var shells := rain(effect, Vector2i(ion.pos)) if weapon == 2 else fan(effect, Vector2i(ion.pos))
			for shell in shells:
				model.projectiles.append(shell)
		if int(effect.tick) >= FIRE_TICKS:
			effect.stage = "return"
		return true
	ion.pos = approach(point, home(model, int(effect.owner)), 8)
	ion.state = "normal"
	ion.state_tick = (int(ion.state_tick) + 1) % 20
	if Vector2i(ion.pos) == home(model, int(effect.owner)):
		ion.busy = false
		return false
	return true

## 0x47ab00: the child counts its own ticks and only flies from the delay on.
static func waiting(shell: Dictionary) -> bool:
	if str(shell.get("flight", "")) != CHILD:
		return false
	shell.knight_wait = int(shell.get("knight_wait", 0)) + 1
	return int(shell.knight_wait) < int(shell.get("knight_delay", 0))
