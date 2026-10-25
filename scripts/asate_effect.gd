extends RefCounted
## ASate Ion state machine. Proven PE480310/47fad0/47fee0/42f4b0;
## see ASATE_CLASSIC_FIX.md for camera/damage adaptation limits.
const Physics = preload("res://scripts/classic_ballistics.gd")
const ShellState = preload("res://scripts/shell_state.gd")
const OFFSETS := [200,550,400]
const MODE := "asate_guide"
const CHILD := "asate_child"

static func guide(shell: Dictionary) -> bool:
	return str(shell.get("flight","")) == MODE and not bool(shell.get("beacon",false))

static func approach(current: int, target: int, divisor: int) -> int:
	var delta := target-current
	return current+signi(delta)*Physics.quot(absi(delta)+divisor-1,divisor)

static func aim_angle(delta: Vector2i) -> int:
	var x := delta.x
	var y := delta.y
	while x < -127 or x > 128 or y < -127 or y > 128:
		x = Physics.quot(x,2)
		y = Physics.quot(y,2)
	return Physics.angles.decode_s16(2*(x+127+256*(y+127)))

static func owner_position(model, owner: int) -> Vector2i:
	return Vector2i(Vector2(model.actors[owner].pos).floor())

static func height(model, owner: int, weapon: int) -> int:
	var target := owner_position(model,owner).y-int(OFFSETS[clampi(weapon,0,2)])
	# Explicit snapshot-owned policy: never consult camera from a worker.
	return mini(target,int(model.get("satellite_ceiling"))) if model.get("satellite_ceiling") != null else target

static func ensure_satellite(model, owner: int) -> Dictionary:
	if not model.satellites.has(owner):
		var home := owner_position(model,owner)
		model.satellites[owner] = {"owner":owner,"pos":Vector2i(home.x,height(model,owner,0)),
			"previous_pos":Vector2i(home.x,height(model,owner,0)),"state":"normal","state_tick":0,
			"angle":270,"weapon":0,"busy":false,"idle_tick":0}
	return model.satellites[owner]

static func step_satellites(model) -> void:
	for owner in model.actors.size():
		if int(model.actors[owner].vehicle) != 10:
			continue
		var satellite := ensure_satellite(model,owner)
		if bool(satellite.busy):
			continue
		satellite.previous_pos = satellite.pos
		var home := owner_position(model,owner)
		var old := Vector2i(satellite.pos)
		var selected := int(satellite.get("weapon",0))
		satellite.pos = Vector2i(approach(old.x,home.x,8),approach(old.y,height(model,owner,selected),8))
		for projectile in model.projectiles:
			if guide(projectile) and int(projectile.get("owner",model.shot_actor)) == owner and bool(projectile.get("launched",false)):
				satellite.weapon = 1 if int(projectile.weapon) == 1 else 0
				satellite.angle = aim_angle(Vector2i(Vector2(projectile.hit_pos).floor())-Vector2i(satellite.pos))
		satellite.state = "normal"
		satellite.state_tick = (int(satellite.state_tick)+1)%20
		satellite.idle_tick = (int(satellite.idle_tick)+1)%22

static func begin(model, projectile: Dictionary, impact: Vector2) -> Dictionary:
	var owner := int(projectile.get("owner",model.shot_actor))
	var weapon := int(projectile.weapon)
	ensure_satellite(model,owner)
	var target := Vector2i(impact.floor())
	var home := owner_position(model,owner)
	var x_step := 0
	var destination := home.x
	if weapon == 2:
		# tan(4deg) constant from558070, FPTAN*height then trunc toward0.
		x_step = int(tan(0.06977777928113937)*float(home.y-height(model,owner,2)))
		destination = target.x-Physics.quot(x_step,2)-x_step
		if target.y < 0:
			destination = target.x+Physics.quot(x_step,2)+x_step
			x_step = -x_step
	var rules: Dictionary = model.weapon_rules(owner,weapon).duplicate(true)
	# A parent guide's public damage may intentionally be zero. Child base
	# comes from catalog, not parent payload; bonuses remain common blast rules.
	return {"kind":"asate","owner":owner,"weapon":weapon,"target":target,"destination_x":destination,
		"stage":"move","activated":false,"tick":0,"index":0,"x_step":x_step,"rules":rules,
		"volley":int(projectile.get("volley",0)),"electric":bool(projectile.get("electric",false)),
		"thor":bool(projectile.get("thor",false)),"age":0}

static func child(effect: Dictionary, position: Vector2i, angle: int, index: int) -> Dictionary:
	var rules: Dictionary = effect.rules.duplicate(true)
	rules.flight = CHILD
	# Parent catalog may mark damage0; the normal per-child power is explicit.
	rules.damage = int(rules.get("child_damage",[190,160,140][int(effect.weapon)]))
	rules.radius = float(rules.get("child_radius",rules.get("radius",[27,23,22][int(effect.weapon)])))
	var shell := ShellState.create(Vector2(position),Vector2.ZERO,0.0,rules,int(effect.weapon),index)
	var velocity := Vector2i(int(Physics.s(angle+90)*7680.0),int(Physics.s(angle)*-7680.0))
	var acceleration := Vector2i(int(Physics.s(angle+90)*1024.0),int(Physics.s(angle)*-1024.0))
	Physics.seed(shell,position*256,velocity,acceleration)
	shell.launch_velocity_fp = velocity
	shell.child = true
	shell.owner = int(effect.owner)
	shell.vehicle = 10
	shell.volley = int(effect.volley)
	shell.electric = bool(effect.electric)
	shell.thor = bool(effect.thor)
	shell.asate_index = index
	shell.asate_angle = angle
	shell.laser_sides = [child_side(velocity)]
	return shell

static func step(effect: Dictionary, model) -> bool:
	var satellite := ensure_satellite(model,int(effect.owner))
	if not bool(effect.activated):
		effect.activated = true
		satellite.busy = true
		satellite.weapon = 1 if int(effect.weapon) == 1 else 0
		satellite.state = "move"
		satellite.state_tick = 0
	satellite.previous_pos = satellite.pos
	effect.age = int(effect.age)+1
	var weapon := int(effect.weapon)
	var point := Vector2i(satellite.pos)
	var home := owner_position(model,int(effect.owner))
	if str(effect.stage) == "return":
		satellite.pos = Vector2i(approach(point.x,home.x,8),approach(point.y,height(model,int(effect.owner),int(satellite.get("weapon",0))),8))
		satellite.state = "normal"
		satellite.state_tick = (int(satellite.state_tick)+1)%20
		if Vector2i(satellite.pos) == Vector2i(home.x,height(model,int(effect.owner),int(satellite.get("weapon",0)))):
			satellite.busy = false
			return false
		return true
	if str(effect.stage) == "move":
		var destination := Vector2i(int(effect.destination_x),height(model,int(effect.owner),weapon))
		satellite.pos = Vector2i(approach(point.x,destination.x,2),approach(point.y,destination.y,2))
		satellite.state = "move"
		satellite.state_tick = (int(satellite.state_tick)+1)%20
		if Vector2i(satellite.pos) == destination:
			effect.stage = "fire"
			effect.tick = 0
			satellite.state = "fire2" if weapon == 1 else "fire1"
			satellite.state_tick = 0
		return true
	effect.tick = int(effect.tick)+1
	satellite.state_tick = int(effect.tick)
	var emit := int(effect.tick) == 1 if weapon != 1 else int(effect.tick) in [1,3,5]
	if emit:
		# Native T2 emissions snap Ion at owner_x/owner_y−550. SS uses
		# current sweep x and owner_y−400; angle is recomputed from target.
		var position := Vector2i(int(effect.destination_x),home.y-int(OFFSETS[weapon]))
		satellite.pos = position
		var theta := aim_angle(Vector2i(effect.target)-position)
		if weapon == 1:
			theta += int(effect.index)-1
		satellite.angle = theta
		var projectile := child(effect,position,theta,int(effect.index))
		model.projectiles.append(projectile)
		model.launch_projectile(projectile)
		effect.index = int(effect.index)+1
		if weapon == 2:
			if int(effect.index) >= 6:
				effect.stage = "return"
			else:
				if int(effect.index) != 3:
					effect.destination_x = int(effect.destination_x)+int(effect.x_step)
				else:
					effect.x_step = -int(effect.x_step)
				effect.stage = "move"
				effect.tick = 0
	if weapon != 2 and int(effect.tick) >= 20:
		effect.stage = "return"
	return true

## Native49cc70 saves immutable six-pixel sections after the common step.
static func child_side(velocity: Vector2i) -> Vector2:
	var theta := Physics.velocity_angle(velocity)+90
	return Vector2(int(6*Physics.s(theta+90)),int(-6*Physics.s(theta)))

static func finish_child_tick(shell: Dictionary) -> void:
	if str(shell.get("flight","")) != CHILD:
		return
	shell.laser_sides.append(child_side(shell.fp_velocity))
	while shell.laser_sides.size() > mini(16,shell.trail.size()):
		shell.laser_sides.pop_front()
