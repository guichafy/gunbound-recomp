extends RefCounted
## Extra flight of the classic mobiles, on the same projectile dictionary the
## prediction copies. Rules come from the OpenBound projectile classes where
## that mobile exists there, and from characterdata where it does not.
##
## open: Armor SS waits 2 s, pauses while the shell opens, then adds the extra
##   damage (ProjectileArmorSSTransformTime / SSE damage). Turtle SS starts
##   change at tick44; after10 EPA ticks it divides into6 and removes its parent.
## chain: Trico SS, 8 blasts, 20 px and ±45° every 0.1 s.
## orbit: Trico S2 and Raon S1. Turtle S2 uses its native integer wave schedule.
## mine: Raon S2/SS leaves a mine. It walks up to 90 px on its owner's turn and
##   explodes inside 90 px (ProjectileRaonLauncherS2MineSquaredProximityRange).
## bolt: Lightning electricity added at the impact.
## chill: Ice S2, −5 defense on each mobile it hits.

const Attributes = preload("res://scripts/player_attributes.gd")
const Combat = preload("res://scripts/combat.gd")
const Damage = preload("res://scripts/damage.gd")
const ShellState = preload("res://scripts/shell_state.gd")
const GoldTracker = preload("res://scripts/gold_tracker.gd")
const MageFlight = preload("res://scripts/mage_flight.gd")
const TurtleFlight = preload("res://scripts/turtle_flight.gd")
const MINE_RANGE := 90.0
const MINE_STEPS := 90

static func prepare(projectile: Dictionary, entry: Dictionary) -> void:
	if MageFlight.active(projectile):
		MageFlight.prepare(projectile,int(round(float(projectile.phase)*180.0/PI)))
	projectile.orbit = entry.get("orbit", Vector2.ZERO)
	projectile.spin = float(entry.get("spin", 0.0))
	projectile.phase_orbit = float(entry.get("phase", 0.0))
	if str(projectile.get("flight","")) == TurtleFlight.MODE:
		TurtleFlight.prepare(projectile,int(entry.get("wave_phase",0)))

static func hit_point(projectile: Dictionary, carrier: Vector2) -> Vector2:
	if MageFlight.active(projectile):
		return MageFlight.hit_point(projectile,carrier)
	if str(projectile.get("flight","")) == TurtleFlight.MODE:
		return TurtleFlight.hit_point(projectile,carrier)
	var orbit: Vector2 = projectile.get("orbit", Vector2.ZERO)
	if orbit == Vector2.ZERO:
		return carrier
	return carrier + orbit.rotated(float(projectile.phase_orbit) + float(projectile.age) * float(projectile.spin))

static func finish_tick(projectile: Dictionary) -> void:
	if MageFlight.active(projectile):
		MageFlight.finish_tick(projectile)
	if str(projectile.get("flight","")) == TurtleFlight.MODE:
		TurtleFlight.finish_tick(projectile)

static func hold(projectile: Dictionary, travel: float) -> bool:
	var remaining := float(projectile.get("hold", 0.0))
	if remaining <= 0.0000001:
		return false
	# The frozen model has no new movement endpoints. Reusing the arrival
	# segment would make the renderer replay that segment once every20Hz tick.
	projectile.previous_draw_pos = projectile.pos
	projectile.previous_hit_pos = projectile.hit_pos
	projectile.hold = 0.0 if remaining-travel <= 0.0000001 else remaining-travel
	# Armor resumes in cnormal; Turtle's EPA finishes the parent and the common
	# simulation replaces it with its children. Never fly a terminal change frame.
	if str(projectile.get("flight", "")) == "open" and bool(projectile.get("opened", false)) and not bool(projectile.get("boomer", false)):
		if float(projectile.hold) <= 0.0:
			projectile.ss_state = "split" if int(projectile.get("burst",0)) > 0 else "cnormal"
			projectile.ss_state_tick = 0
		else:
			projectile.ss_state_tick = int(projectile.get("ss_state_tick", 0)) + 1
	projectile.age += travel
	return true

static func open_shell(projectile: Dictionary) -> void:
	if str(projectile.get("flight", "")) != "open":
		return
	if bool(projectile.get("opened", false)):
		if not bool(projectile.get("boomer", false)) and str(projectile.get("ss_state", "normal")) == "cnormal":
			projectile.ss_state_tick = int(projectile.get("ss_state_tick", 0)) + 1
		return
	var transform_ticks := int(projectile.get("transform_ticks",0))
	if transform_ticks > 0:
		if int(projectile.get("flight_ticks",0)) < transform_ticks:
			return
	elif float(projectile.age) < float(projectile.get("transform_at", 0.0)):
		return
	projectile.opened = true
	if not bool(projectile.get("boomer", false)):
		projectile.ss_state = "change"
		projectile.ss_state_tick = 0
	projectile.damage = int(projectile.damage) + int(projectile.get("extra_damage", 0))
	projectile.blast_radius = float(projectile.get("extra_radius", 0.0))
	projectile.hold = float(projectile.get("transform_hold",0.73))

static func split_open_shell(model, projectile: Dictionary) -> bool:
	if str(projectile.get("ss_state","")) != "split":
		return false
	# Division is a stage transition, not an impact: no terrain carving,
	# blast damage, Gold attribution or extra explosion sound in the air.
	burst(model,projectile,projectile.hit_pos,projectile.velocity)
	return true

static func begin_chain(projectile: Dictionary, position: Vector2, facing: float) -> bool:
	if str(projectile.get("flight", "")) != "chain" or bool(projectile.get("chaining", false)):
		return false
	projectile.chaining = true
	projectile.chain_left = int(projectile.get("chain", 8)) - 1
	projectile.chain_wait = float(projectile.get("chain_gap", 0.1))
	projectile.chain_origin = position
	projectile.chain_angle = Vector2(projectile.velocity).angle()
	projectile.chain_sign = facing
	projectile.chain_index = 1
	return true

static func chain_point(projectile: Dictionary) -> Vector2:
	var index := int(projectile.chain_index)
	var turn := 1.0 if index % 2 == 0 else -1.0
	var angle := float(projectile.chain_angle) + index * turn * deg_to_rad(45.0) * float(projectile.chain_sign)
	return Vector2(projectile.chain_origin) + Vector2(float(projectile.get("chain_step", 20.0)), 0).rotated(angle)

static func tick_chain(projectile: Dictionary, travel: float) -> bool:
	if not bool(projectile.get("chaining", false)):
		return false
	projectile.chain_wait = float(projectile.chain_wait) - travel
	projectile.age += travel
	if float(projectile.chain_wait) > 0.0:
		return true
	return int(projectile.chain_left) > 0

static func advance_chain(projectile: Dictionary) -> Vector2:
	projectile.chain_left = int(projectile.chain_left) - 1
	projectile.chain_wait = float(projectile.get("chain_gap", 0.1))
	var point := chain_point(projectile)
	projectile.chain_index = int(projectile.chain_index) + 1
	projectile.hit_pos = point
	return point

static func plant_mine(model, projectile: Dictionary, position: Vector2) -> void:
	var flight := str(projectile.get("flight", ""))
	if flight != "mine" and flight != "crystal":
		return
	# The crystal vtable uses the common simulator and the common detonate.
	# InitProjectile leaves velocity at 0 and SpawnCrystalShot only writes the
	# impact position, so the crystal falls from that point and bursts on land.
	if flight == "crystal":
		var crystal := ShellState.create(position, Vector2.ZERO, 0.0, {"damage": 0, "radius": 0.0}, int(projectile.weapon), 0)
		prepare(crystal, {})
		crystal.launched = true
		crystal.crystal_body = true
		model.projectiles.append(crystal)
		return
	var damage := int(projectile.damage)
	var radius := float(projectile.get("blast_radius", projectile.get("extra_radius", 21.0)))
	var direction := signf(float(Vector2(projectile.get("velocity", Vector2.RIGHT)).x))
	if direction == 0.0:
		direction = float(model.actors[model.shot_actor].facing)
	model.mines.append({
		"pos": position, "owner": model.shot_actor,
		"radius": radius,
		"damage": damage, "weapon": int(projectile.weapon),
		"vehicle": model.actors[model.shot_actor].vehicle, "crystal": flight == "crystal",
		"crawl": bool(projectile.get("mine_crawl", false)), "dir": direction,
		"steps": int(projectile.get("mine_steps", 0)), "debt": 0.0,
	})

static func _nearest_actor(model, mine: Dictionary) -> int:
	var closest := -1
	var best := INF
	for index in range(model.actors.size()):
		if int(model.actors[index].hp) <= 0:
			continue
		var gap := Vector2(model.actors[index].pos).distance_squared_to(Vector2(mine.pos))
		if gap < best:
			best = gap
			closest = index
	return closest

static func _mine_hits(model, mine: Dictionary) -> int:
	var center := Vector2(mine.pos) + Vector2(0, 5)
	for index in range(model.actors.size()):
		if int(model.actors[index].hp) <= 0:
			continue
		if Combat.box_gap(center, model.actors[index]) <= 0.0:
			return index
	return -1

static func _detonate_mine(model, index: int) -> void:
	var mine: Dictionary = model.mines[index]
	model.mines.remove_at(index)
	var dead: Array = model.actors.map(func(actor): return int(actor.hp) <= 0)
	var event_start: int = model.events.size()
	model.blast(Vector2(mine.pos), float(mine.radius), float(mine.damage), 0.0, 0.0, int(mine.owner))
	GoldTracker.collect_mine(model, event_start, int(mine.owner), dead)
	model.events.append({"type": "explosion", "actor": int(mine.owner), "position": mine.pos, "radius": mine.radius, "weapon": mine.weapon, "vehicle": mine.vehicle, "collided_actor": -1, "removed": 0, "angle": 0.0})

static func walk_mines(model) -> void:
	var owner: int = int(model.active)
	for mine in model.mines:
		if int(mine.owner) != owner or bool(mine.get("crystal", false)) or bool(mine.get("crawl", false)):
			continue
		var target := _nearest_actor(model, mine)
		if target < 0:
			continue
		var goal_x := float(model.actors[target].pos.x)
		for _step in MINE_STEPS:
			var dx := goal_x - float(mine.pos.x)
			if absf(dx) < 1.0:
				break
			var next_x := float(mine.pos.x) + signf(dx)
			var ground := float(model.terrain.surface_at(next_x, float(mine.pos.y) - 40.0))
			if model.terrain.is_void(ground):
				break
			mine.pos = Vector2(next_x, ground - 5.0)
			if _mine_hits(model, mine) >= 0:
				break

## Raon SS mine: keep walking the way it faces, flip at a gap, burst on a
## mobile or when the 360-step budget ends.
static func crawl_mines(model, delta: float) -> void:
	var spent: Array[int] = []
	for index in range(model.mines.size()):
		var mine: Dictionary = model.mines[index]
		if not bool(mine.get("crawl", false)) or int(mine.get("steps", 0)) <= 0:
			continue
		mine.debt = float(mine.get("debt", 0.0)) + delta * 60.0
		while float(mine.debt) >= 1.0 and int(mine.steps) > 0:
			mine.debt = float(mine.debt) - 1.0
			mine.steps = int(mine.steps) - 1
			var next_x := float(mine.pos.x) + float(mine.dir)
			var ground: float = model.terrain.surface_at(next_x, float(mine.pos.y) - 40.0)
			if model.terrain.is_void(ground):
				mine.dir = -float(mine.dir)
				continue
			mine.pos = Vector2(next_x, ground - 5.0)
			if _mine_hits(model, mine) >= 0:
				mine.steps = 0
				break
		if int(mine.steps) <= 0:
			spent.append(index)
	spent.reverse()
	for index in spent:
		if index < model.mines.size():
			_detonate_mine(model, index)

static func detonate_mines(model) -> void:
	for index in range(model.mines.size() - 1, -1, -1):
		if _mine_hits(model, model.mines[index]) >= 0:
			_detonate_mine(model, index)

## LightningUpdateBehavior: step 3 px along -angle from the impact. The blast
## stays on the last ground or mobile touched. Mobiles the beam passes after
## that point take the extra shock.
static func _trace_beam(model, origin: Vector2, angle: float, extra_radius: float) -> Dictionary:
	var cursor := origin
	var blast_at := origin
	var shocked := {}
	var world: Vector2 = model.terrain.world_size()
	var offset := Vector2(3, 0).rotated(-angle)
	for _guard in 2000:
		if cursor.x < 0.0 or cursor.y < 0.0 or cursor.x >= world.x or cursor.y >= world.y:
			break
		for index in range(model.actors.size()):
			if Combat.box_gap(cursor, model.actors[index]) < extra_radius:
				shocked[index] = true
		var hit_actor := false
		for index in range(model.actors.size()):
			if int(model.actors[index].hp) > 0 and Combat.box_gap(cursor, model.actors[index]) <= 0.0:
				hit_actor = true
		if model.terrain.is_solid(cursor) or hit_actor:
			shocked.clear()
			blast_at = cursor
		cursor += offset
	var indexes: Array = shocked.keys()
	return {"at": blast_at, "shocked": indexes}

static func _shock(model, indexes: Array, amount: float) -> void:
	for index in indexes:
		Damage.deal_damage(model.actors, model.events, int(index), int(amount))

static func bolts(model, projectile: Dictionary, position: Vector2) -> void:
	var damage := float(projectile.get("bolt", 0.0))
	if damage <= 0.0:
		return
	var radius := float(projectile.get("bolt_radius", 25.0))
	var extra := float(projectile.get("bolt_extra", 0.0))
	var extra_radius := float(projectile.get("bolt_extra_radius", radius))
	var count := int(projectile.get("bolt_count", 1))
	var angles: Array = projectile.get("bolt_angles", [PI * 0.5])
	if count < 0:
		var reach := float(projectile.get("bolt_reach", 100.0))
		for actor in model.actors:
			if Vector2(actor.pos).distance_to(position) > reach:
				continue
			var traced: Dictionary = _trace_beam(model, Vector2(actor.pos), PI * 0.5, extra_radius)
			if Vector2(traced.at).distance_to(Vector2(actor.pos)) > 4.0:
				model.blast(Vector2(traced.at), radius, damage, 0.0, 0.0, model.shot_actor)
			_shock(model, traced.shocked, extra)
		return
	for angle in angles:
		var traced: Dictionary = _trace_beam(model, position, float(angle), extra_radius)
		if Vector2(traced.at).distance_to(position) > 4.0:
			model.blast(Vector2(traced.at), radius, damage, 0.0, 0.0, model.shot_actor)
		_shock(model, traced.shocked, extra)

static func chill(model, projectile: Dictionary, event_start: int) -> void:
	var amount := int(projectile.get("chill", 0))
	if amount == 0:
		return
	var seen := {}
	for event in model.events.slice(event_start):
		if event.type != "damage":
			continue
		var index := int(event.actor)
		if seen.has(index):
			continue
		seen[index] = true
		var attributes: Array = model.actors[index].attributes
		attributes[Attributes.DEFENSE] = int(attributes[Attributes.DEFENSE]) + amount

static func burst(model, projectile: Dictionary, position: Vector2, velocity: Vector2) -> void:
	var flight := str(projectile.get("flight", ""))
	# Dragon SS (ExplodeSuperShot_Bullet14) spawns five child shots at the
	# impact. Turtle SS only bursts after the shell has opened.
	if flight == "open" and str(projectile.get("ss_state","")) != "split":
		return
	if flight != "open" and flight != "split":
		return
	var count := int(projectile.get("burst", 0))
	if count <= 0:
		return
	var speed := maxf(velocity.length() * 0.45, 80.0)
	var base := velocity.angle()
	var spread := deg_to_rad(float(projectile.get("burst_spread", 12.0)))
	for index in count:
		var angle := base + (float(index) - float(count - 1) * 0.5) * spread
		var rules := {"damage": int(projectile.damage), "radius": float(projectile.get("blast_radius", model.weapon_rules(model.shot_actor, int(projectile.weapon)).radius))}
		var shell := ShellState.create(position, Vector2.from_angle(angle) * speed, 0.0, rules, int(projectile.weapon), 0)
		prepare(shell, {})
		shell.child = true
		shell.launched = true
		model.projectiles.append(shell)
