extends RefCounted
## Raon S1 PE0x497730/0x495e80 and private placed-mine state.
## Native evidence and explicit terrain/S2 fallbacks: RAON_CLASSIC_FIX.md.
## No presentation clock, scene, live model or shared mutable state is read.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Combat = preload("res://scripts/combat.gd")
const MODE := "raon_orbit"
const RANGE_SQUARED := 8100.0
const TURN_STEPS := 90
const SS_CALLS := 100
const STEP := 0.05
const EPSILON := 0.0000001

static func active(shell: Dictionary) -> bool:
	return str(shell.get("flight","")) == MODE and not bool(shell.get("beacon",false))

static func prepare(shell: Dictionary, entry: Dictionary) -> void:
	var component := int(entry.get("raon_component",shell.get("raon_component",0)))
	shell.raon_component = component
	shell.raon_phase = (component & 1)*180
	shell.raon_ticks = 0

## The original x87 truncates to whole pixels BEFORE SHL8. Heading is the
## perpendicular heading (velocity_angle+90), matching the native angle field.
static func offset_fp(heading: int, phase: int) -> Vector2i:
	return Vector2i(int(13.0*Physics.s(phase)*Physics.s(heading+90)) << 8,int(-13.0*Physics.s(phase)*Physics.s(heading)) << 8)

static func hit_point(shell: Dictionary, carrier: Vector2) -> Vector2:
	if not active(shell) or int(shell.get("raon_component",0)) == 0:
		return carrier
	var velocity: Vector2i = shell.get("fp_velocity",Physics.velocity_fp(shell.get("velocity",Vector2.ZERO)))
	var phase := posmod(int(shell.get("raon_phase",0))+40,360)
	return carrier+Vector2(offset_fp(Physics.velocity_angle(velocity)+90,phase))/Physics.SCALE

static func finish_tick(shell: Dictionary) -> void:
	if not active(shell):
		return
	shell.raon_phase = posmod(int(shell.get("raon_phase",0))+40,360)
	shell.raon_ticks = int(shell.get("raon_ticks",0))+1

static func create_mine(projectile: Dictionary, position: Vector2, owner: int, vehicle: int, facing: float = 1.0) -> Dictionary:
	var supermine := int(projectile.get("weapon",1)) == 2
	var direction := signf(Vector2(projectile.get("velocity",Vector2.ZERO)).x)
	if direction == 0.0:
		direction = signf(facing)
	if direction == 0.0:
		direction = 1.0
	var radius := float(projectile.get("mine_radius",projectile.get("blast_radius",21.0)))
	if radius <= 0.0:
		radius = 21.0
	return {
		"pos":position,"previous_pos":position,"owner":owner,"vehicle":vehicle,
		"weapon":int(projectile.get("weapon",1)),"damage":int(projectile.get("mine_damage",projectile.get("damage",0))),
		"radius":radius,"crystal":false,"crawl":supermine,"dir":direction,
		"raon_mine":true,"state":"active" if supermine else "normal","state_tick":0,
		"age":0.0,"state_age":0.0,"mine_ticks":0,"move_ticks":0,"debt":0.0,
		"steps":0,"target":-1,"queued":false,"waiting_ticks":0,
	}

static func _set_state(mine: Dictionary, state: String) -> void:
	if str(mine.get("state","normal")) == state:
		return
	mine.state = state
	mine.state_tick = 0
	mine.state_age = 0.0

## S2 fallback from OpenBound: living mobiles only, strict <90px. The owner
## can be the closest target; an explicit owner does not confer immunity.
static func refresh_target(mine: Dictionary, actors: Array) -> void:
	if bool(mine.get("crawl",false)):
		return
	var closest := -1
	var best := RANGE_SQUARED
	for index in actors.size():
		if int(actors[index].get("hp",0)) <= 0:
			continue
		var gap := Vector2(actors[index].pos).distance_squared_to(Vector2(mine.pos))
		if gap < best:
			closest = index
			best = gap
	mine.target = closest
	if closest < 0:
		mine.steps = 0
		mine.queued = false
		_set_state(mine,"normal")
		return
	var dx := float(actors[closest].pos.x)-float(mine.pos.x)
	if dx != 0.0:
		mine.dir = signf(dx)
	if str(mine.get("state","normal")) == "normal":
		_set_state(mine,"active")

static func begin_turn(mines: Array, actors: Array, owner: int) -> void:
	for mine in mines:
		if not bool(mine.get("raon_mine",false)) or bool(mine.get("crawl",false)):
			continue
		mine.queued = false
		mine.steps = 0
		refresh_target(mine,actors)
		if int(mine.get("owner",-1)) == owner and int(mine.target) >= 0:
			mine.steps = TURN_STEPS
			mine.queued = true
			mine.waiting_ticks = 10
		elif str(mine.get("state","normal")) == "move":
			_set_state(mine,"active")

static func contact(mine: Dictionary, actors: Array) -> int:
	var point := Vector2(mine.pos)+Vector2(0,5)
	for index in actors.size():
		if int(actors[index].get("hp",0)) > 0 and Combat.box_gap(point,actors[index]) <= 0.0:
			return index
	return -1

static func visual_state(mine: Dictionary) -> String:
	return str(mine.get("state","normal"))

static func visual_age(mine: Dictionary) -> float:
	return float(mine.get("state_age",0.0))

## Surface following remains the Godot adaptation: scan each1px move so a
## three-pixel tick cannot skip a mobile. SS reverses on invalid terrain;
## S2 yields. Native falling/slope-speed arithmetic is deliberately not claimed.
static func _walk(mine: Dictionary, actors: Array, terrain, budget: int) -> bool:
	for _pixel in budget:
		var next_x := float(mine.pos.x)+float(mine.get("dir",1.0))
		var ground := float(terrain.surface_at(next_x,float(mine.pos.y)-40.0))
		var invalid: bool = terrain.is_void(ground) or absf((ground-5.0)-float(mine.pos.y)) > 15.0
		if invalid:
			if bool(mine.get("crawl",false)):
				mine.dir = -float(mine.dir)
			else:
				mine.steps = 0
				mine.queued = false
				_set_state(mine,"active")
			return false
		mine.pos = Vector2(next_x,ground-5.0)
		if not bool(mine.get("crawl",false)):
			mine.steps = maxi(0,int(mine.steps)-1)
		if contact(mine,actors) >= 0:
			return true
	return false

static func _tick(mine: Dictionary, actors: Array, terrain, may_move: bool) -> bool:
	mine.previous_pos = mine.pos
	mine.mine_ticks = int(mine.get("mine_ticks",0))+1
	mine.age = int(mine.mine_ticks)*STEP
	mine.state_tick = int(mine.get("state_tick",0))+1
	mine.state_age = int(mine.state_tick)*STEP
	if contact(mine,actors) >= 0:
		return true
	if bool(mine.get("crawl",false)):
		mine.move_ticks = int(mine.get("move_ticks",0))+1
		#0x492f50 checks expiry before selecting pose or attempting movement.
		if int(mine.move_ticks) >= SS_CALLS:
			return true
		_set_state(mine,"move")
		return _walk(mine,actors,terrain,3)
	refresh_target(mine,actors)
	if not may_move or not bool(mine.get("queued",false)) or int(mine.get("steps",0)) <= 0:
		return false
	if int(mine.get("waiting_ticks",0)) > 0:
		mine.waiting_ticks = int(mine.waiting_ticks)-1
		return false
	mine.move_ticks = int(mine.get("move_ticks",0))+1
	_set_state(mine,"move")
	var detonate := _walk(mine,actors,terrain,mini(3,int(mine.steps)))
	if int(mine.steps) <= 0:
		mine.queued = false
		_set_state(mine,"active")
	return detonate

## Returns descending indices. The owner-aware caller applies damage/Gold and
## removes each mine; this helper never removes from the array while iterating.
static func step_mines(mines: Array, actors: Array, terrain, delta: float) -> Array[int]:
	var detonated: Array[int] = []
	if delta <= 0.0:
		return detonated
	for mine in mines:
		if bool(mine.get("raon_mine",false)):
			mine.debt = float(mine.get("debt",0.0))+delta
	var pending := true
	while pending:
		pending = false
		var moving_index := -1
		for index in mines.size():
			if index not in detonated and bool(mines[index].get("queued",false)):
				moving_index = index
				break
		for index in mines.size():
			var mine: Dictionary = mines[index]
			if index in detonated or not bool(mine.get("raon_mine",false)) or float(mine.debt)+EPSILON < STEP:
				continue
			pending = true
			mine.debt = maxf(0.0,float(mine.debt)-STEP)
			if _tick(mine,actors,terrain,index == moving_index):
				detonated.append(index)
	detonated.sort()
	detonated.reverse()
	return detonated
