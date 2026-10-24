extends RefCounted
## Extra flight of the classic mobiles, on the same projectile dictionary the
## prediction copies. Rules come from the OpenBound projectile classes where
## that mobile exists there, and from characterdata where it does not.
##
## open: Armor SS waits 2 s, pauses while the shell opens, then adds the extra
##   damage (ProjectileArmorSSTransformTime / SSE damage). Turtle SS waits 1.5 s
##   and, once open, bursts into 6 fragments.
## chain: Trico SS, 8 blasts, 20 px and ±45° every 0.1 s.
## orbit: Trico S2, Raon S1 and Turtle S2. The carrier flies; the hit point spins.
## mine: Raon S2/SS leaves a mine. It walks up to 90 px on its owner's turn and
##   explodes inside 90 px (ProjectileRaonLauncherS2MineSquaredProximityRange).
## bolt: Lightning electricity added at the impact.
## chill: Ice S2, −5 defense on each mobile it hits.

const Attributes = preload("res://scripts/player_attributes.gd")
const Combat = preload("res://scripts/combat.gd")
const Damage = preload("res://scripts/damage.gd")
const MINE_RANGE := 90.0
const MINE_STEPS := 90

static func prepare(projectile: Dictionary, entry: Dictionary) -> void:
	projectile.orbit = entry.get("orbit", Vector2.ZERO)
	projectile.spin = float(entry.get("spin", 0.0))
	projectile.phase_orbit = float(entry.get("phase", 0.0))

static func hit_point(projectile: Dictionary, carrier: Vector2) -> Vector2:
	var orbit: Vector2 = projectile.get("orbit", Vector2.ZERO)
	if orbit == Vector2.ZERO:
		return carrier
	return carrier + orbit.rotated(float(projectile.phase_orbit) + float(projectile.age) * float(projectile.spin))

static func hold(projectile: Dictionary, travel: float) -> bool:
	var remaining := float(projectile.get("hold", 0.0))
	if remaining <= 0.0:
		return false
	projectile.hold = maxf(0.0, remaining - travel)
	projectile.age += travel
	return true

static func open_shell(projectile: Dictionary) -> void:
	if str(projectile.get("flight", "")) != "open" or bool(projectile.get("opened", false)):
		return
	if float(projectile.age) < float(projectile.get("transform_at", 0.0)):
		return
	projectile.opened = true
	projectile.damage = int(projectile.damage) + int(projectile.get("extra_damage", 0))
	projectile.blast_radius = float(projectile.get("extra_radius", 0.0))
	projectile.hold = 0.73

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
		model.projectiles.append({
			"pos": position, "hit_pos": position, "velocity": Vector2.ZERO, "age": 0.0, "trail": [position],
			"helix": 0.0, "phase": 0.0, "spawn_at": 0.0, "launched": true,
			"damage": 0, "launch_speed": 0.0, "inside": {}, "influenced": [],
			"electric": false, "thor": false, "tornado": {}, "weapon": int(projectile.weapon), "volley": 0,
			"beacon": false, "wind_scale": 1.0, "burrow": false, "ghost": false, "skip_actors": false,
			"underground": false, "flight": "", "orbit": Vector2.ZERO, "spin": 0.0, "phase_orbit": 0.0,
			"hold": 0.0, "crystal_body": true, "blast_radius": 0.0,
		})
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
	model.shot_actor = int(mine.owner)
	model.blast(Vector2(mine.pos), float(mine.radius), float(mine.damage), 0.0, 0.0, int(mine.owner))
	model.events.append({"type": "explosion", "position": mine.pos, "radius": mine.radius, "weapon": mine.weapon, "vehicle": mine.vehicle, "collided_actor": -1, "removed": 0, "angle": 0.0})

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
	if flight == "open" and not bool(projectile.get("opened", false)):
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
		var shell := {
			"pos": position, "hit_pos": position, "velocity": Vector2.from_angle(angle) * speed,
			"age": 0.0, "trail": [position], "helix": 0.0, "phase": 0.0, "spawn_at": 0.0, "launched": true,
			"damage": int(projectile.damage), "launch_speed": speed, "inside": {}, "influenced": [],
			"electric": false, "thor": false, "tornado": {}, "weapon": projectile.weapon, "volley": 0,
			"beacon": false, "wind_scale": 1.0, "burrow": false, "ghost": false, "underground": false,
			"flight": "", "orbit": Vector2.ZERO, "spin": 0.0, "phase_orbit": 0.0, "hold": 0.0,
		}
		model.projectiles.append(shell)
