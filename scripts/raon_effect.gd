extends RefCounted
## Raon S1 PE0x497730/0x495e80 and private placed-mine state.
## Native evidence and explicit terrain/S2 fallbacks: RAON_CLASSIC_FIX.md.
## No presentation clock, scene, live model or shared mutable state is read.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const MODE := "raon_orbit"
const RANGE_SQUARED := 8100.0
const TURN_STEPS := 90
const SS_CALLS := 100
const STEP := 0.05
const EPSILON := 0.0000001
## Placed-mine constants (AnimateMine 0x498b60, 0x4986a0, ExplodeMine 0x497ad0):
## S2/SS block field [66]/[79]=8, WinMain 15/10/20, bounce at speed5, y<-200.
const TRIGGER_RADIUS := 8
const GROUND_PROBE := 15.0
const SNAP := 15.0
const SLOPE_HALF := 10
const SLOPE_CLIFF := 20
const BOUNCE_SPEED := 5
const WORLD_TOP := -200.0
const BLAST_LIFT := 10.0
## Mobile06_MainAction spawns idx0/2/3 (Dual 8/10/11). idx%8==0 is the common
## projectile; the others orbit with phase (idx&1)*180 (0x42c295/0x42c2af).
const NATIVE_INDEX := [0,2,3]

static func active(shell: Dictionary) -> bool:
	return str(shell.get("flight","")) == MODE and not bool(shell.get("beacon",false))

static func prepare(shell: Dictionary, entry: Dictionary) -> void:
	var component := int(entry.get("raon_component",shell.get("raon_component",0)))
	shell.raon_component = component
	shell.raon_phase = (int(NATIVE_INDEX[clampi(component,0,2)]) & 1)*180
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

static func create_mine(projectile: Dictionary, position: Vector2, owner: int, vehicle: int, _facing: float = 1.0) -> Dictionary:
	var supermine := int(projectile.get("weapon",1)) == 2
	# DetonateSuperShot_Bullet7 0x49c064: SETG on vx [obj+0x488]; zero is left.
	var velocity: Vector2i = projectile.fp_velocity if bool(projectile.get("fp_ready",false)) else Physics.velocity_fp(projectile.get("velocity",Vector2.ZERO))
	var vx := float(velocity.x)
	var direction := 1.0 if vx > 0.0 else -1.0
	var radius := float(projectile.get("mine_radius",projectile.get("blast_radius",21.0)))
	if radius <= 0.0:
		radius = 21.0
	# Native mines live on integer ground pixels (SpawnMine stores the hit point).
	var at := position.floor()
	return {
		"pos":at,"previous_pos":at,"owner":owner,"vehicle":vehicle,
		"weapon":int(projectile.get("weapon",1)),"damage":int(projectile.get("mine_damage",projectile.get("damage",0))),
		"radius":radius,"crystal":false,"crawl":supermine,"dir":direction,
		"raon_mine":true,"state":"active" if supermine else "normal","state_tick":0,
		"age":0.0,"state_age":0.0,"mine_ticks":0,"move_ticks":0,"debt":0.0,
		"steps":0,"target":-1,"queued":false,"waiting_ticks":0,
		"slope":0,"falling":false,"fall_speed":0,"lost":false,
	}

## FindGroundHeightAtColumn probe used by AnimateMine/0x4986a0: from y-15.
static func ground_at(terrain, x: float, y: float) -> float:
	return float(terrain.surface_at(x,y-GROUND_PROBE))

## 0x4986a0: heights at x-10/x/x+10, cliff deeper than h0+20 mirrored through
## h0, native int16 angle LUT for (20,dy); angles above 270 wrap negative.
## The returned value is what 0x499d50 publishes as the draw angle.
static func slope_angle(terrain, x: float, y: float) -> int:
	var h0 := int(ground_at(terrain,x,y))
	var left := int(ground_at(terrain,x-SLOPE_HALF,y))
	var right := int(ground_at(terrain,x+SLOPE_HALF,y))
	var limit := h0+SLOPE_CLIFF
	if limit < left:
		if right <= limit:
			if right < limit:
				left = h0*2-right
		else:
			left = h0
			right = h0
	elif limit < right and left < limit:
		right = h0*2-left
	var dx := SLOPE_HALF*2
	var dy := right-left
	while dx < -127 or dx > 128 or dy < -127 or dy > 128:
		dx = Physics.quot(dx,2)
		dy = Physics.quot(dy,2)
	var angle := Physics.angles.decode_s16(2*(dx+127+256*(dy+127)))
	return angle-360 if angle > 270 else angle

## AnimateMine ground handling and fall (0x498b60/0x4921e0): snap within15px,
## otherwise fall accelerating1px/tick; a landing at speed>=5 bounces by it.
## A buried mine rises to the probed surface (the native30px search is pending).
static func settle(mine: Dictionary, terrain) -> void:
	var x := float(mine.pos.x)
	var y := float(mine.pos.y)
	var ground := ground_at(terrain,x,y)
	if y < ground:
		if y >= ground-SNAP:
			y = ground
		elif not bool(mine.get("falling",false)):
			mine.falling = true
			mine.fall_speed = 0
	else:
		y = ground
	if bool(mine.get("falling",false)):
		var speed := int(mine.get("fall_speed",0))
		if y+speed < ground:
			y += speed+1
			mine.fall_speed = speed+1
		elif speed < BOUNCE_SPEED:
			y = ground
			mine.fall_speed = 0
			mine.falling = false
		else:
			y = ground-speed
			mine.fall_speed = 1
	mine.pos = Vector2(x,y)

## AnimateMine bounds: x<0, x>=width, y>=height or y<-200 removes the mine.
static func outside(mine: Dictionary, terrain) -> bool:
	if not terrain.has_method("world_size"):
		return false
	var world: Vector2 = terrain.world_size()
	var at := Vector2(mine.pos)
	return at.x < 0.0 or at.x >= world.x or at.y >= world.y or at.y < WORLD_TOP

## AnimateMine/AnimateSuperMine: any living mobile (dead flag+0xbff7 skipped,
## owner included) whose ground anchor is inside the weapon radius [66]/[79]=8.
static func touching(mine: Dictionary, actors: Array) -> int:
	var at := Vector2i(Vector2(mine.pos).floor())
	for index in actors.size():
		var actor: Dictionary = actors[index]
		if int(actor.get("hp",0)) <= 0:
			continue
		var foot := Vector2i((Vector2(actor.pos)+Vector2(0,float(Mobiles.definition(int(actor.vehicle)).stance))).floor())
		var gap := at-foot
		if gap.x*gap.x+gap.y*gap.y < TRIGGER_RADIUS*TRIGGER_RADIUS:
			return index
	return -1

## AnimateSuperMine also detonates on another placed mine inside the radius.
static func touching_mine(mine: Dictionary, mines: Array) -> bool:
	var at := Vector2i(Vector2(mine.pos).floor())
	for other in mines:
		if other == mine or not bool(other.get("raon_mine",false)) or bool(other.get("lost",false)):
			continue
		var gap := at-Vector2i(Vector2(other.pos).floor())
		if gap.x*gap.x+gap.y*gap.y < TRIGGER_RADIUS*TRIGGER_RADIUS:
			return true
	return false

## 0x499d50 + RayonTexture quad 0x4ebbc0: pivot on the ground point, rotated
## counterclockwise by the slope; flag 0x3fa8 (facing right) mirrors the
## left-facing sheet inside its 32px cell (local x -> -x-1).
static func draw_transform(mine: Dictionary) -> Transform2D:
	var placed := Transform2D(-deg_to_rad(float(mine.get("slope",0))),Vector2(mine.pos))
	if float(mine.get("dir",-1.0)) > 0.0:
		return placed*Transform2D(0.0,Vector2(-1,1),0.0,Vector2(-1,0))
	return placed

## Center of the native ExplodeMine blast: ten pixels above the ground point.
static func blast_point(mine: Dictionary) -> Vector2:
	return Vector2(mine.pos)-Vector2(0,BLAST_LIFT)

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
	# 0x49867c: flag 0x3fa8 = target to the right (SETL on mine-target).
	mine.dir = 1.0 if float(actors[closest].pos.x) > float(mine.pos.x) else -1.0
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
	return touching(mine,actors)

static func visual_state(mine: Dictionary) -> String:
	return str(mine.get("state","normal"))

static func visual_age(mine: Dictionary) -> float:
	return float(mine.get("state_age",0.0))

## Surface following remains the Godot adaptation: scan each1px move so a
## three-pixel tick cannot skip a mobile. SS reverses on invalid terrain;
## S2 yields. Native slope-speed arithmetic is deliberately not claimed.
static func _walk(mine: Dictionary, actors: Array, terrain, budget: int) -> bool:
	if bool(mine.get("falling",false)):
		return false
	for _pixel in budget:
		var next_x := float(mine.pos.x)+float(mine.get("dir",1.0))
		var ground := float(terrain.surface_at(next_x,float(mine.pos.y)-40.0))
		var invalid: bool = terrain.is_void(ground) or absf(ground-float(mine.pos.y)) > SNAP
		if invalid:
			if bool(mine.get("crawl",false)):
				mine.dir = -float(mine.dir)
			else:
				mine.steps = 0
				mine.queued = false
				_set_state(mine,"active")
			return false
		mine.pos = Vector2(next_x,ground)
		if not bool(mine.get("crawl",false)):
			mine.steps = maxi(0,int(mine.steps)-1)
		if contact(mine,actors) >= 0:
			return true
	return false

## AnimateMine order: slope, ground/fall, bounds, proximity; movement after.
static func _tick(mine: Dictionary, actors: Array, terrain, may_move: bool, mines: Array = []) -> bool:
	mine.previous_pos = mine.pos
	mine.mine_ticks = int(mine.get("mine_ticks",0))+1
	mine.age = int(mine.mine_ticks)*STEP
	mine.state_tick = int(mine.get("state_tick",0))+1
	mine.state_age = int(mine.state_tick)*STEP
	mine.slope = slope_angle(terrain,float(mine.pos.x),float(mine.pos.y))
	settle(mine,terrain)
	if outside(mine,terrain):
		mine.lost = true
		return false
	if touching(mine,actors) >= 0:
		return true
	if bool(mine.get("crawl",false)) and touching_mine(mine,mines):
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
			if index in detonated or not bool(mine.get("raon_mine",false)) or bool(mine.get("lost",false)) or float(mine.debt)+EPSILON < STEP:
				continue
			pending = true
			mine.debt = maxf(0.0,float(mine.debt)-STEP)
			if _tick(mine,actors,terrain,index == moving_index,mines):
				detonated.append(index)
	detonated.sort()
	detonated.reverse()
	return detonated
