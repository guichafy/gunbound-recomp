extends RefCounted
## Owns the entire combat lifecycle. Presentation consumes events, never decides damage.

const Terrain = preload("res://scripts/terrain.gd")
const Maps = preload("res://scripts/maps.gd")
const Weather = preload("res://scripts/weather.gd")
# Procedural arena has no map preset: only the Wind weather re-rolls each round.
const PROCEDURAL_WEATHER := [0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
const Combat = preload("res://scripts/combat.gd")
const BigfootAttacks = preload("res://scripts/bigfoot_attacks.gd")
# Stable mobile IDs are independent of menu slots. Removed ID0 is not playable.
const PLAYABLE_VEHICLES := [1, 2]
const VEHICLES := {
	1: {"name": "Mage", "hp": 760, "move": 90.0, "delay": 0.0, "color": Color("a9b7ff")},
	2: {"name": "Bigfoot", "hp": 1100, "move": 90.0, "delay": 0.0, "color": Color("71c0ff")}
}
# Original Mage metadata from OpenBound, normalized to this prototype's delay units.
# Copyright (C) 2020, Carlos H.M.S.; reference code GPL-3.0-or-later.
const MAGE_WEAPONS := [
	{"name": "Laser", "damage": 150.0, "radius": 25.0, "delay": 100.0, "count": 1, "helix": 0.0, "emp": 0.0, "color": Color("b3ceff")},
	{"name": "Duplo laser", "damage": 200.0, "radius": 25.0, "delay": 120.0, "count": 2, "helix": 15.0, "emp": 0.0, "color": Color("d43e70")},
	{"name": "EMP", "damage": 200.0, "radius": 25.0, "delay": 1300.0 / 7.5, "count": 1, "helix": 0.0, "emp": 100.0, "color": Color("b6adff")}
]
var terrain
var actors: Array = []
var projectiles: Array = []
var events: Array = []
var rng := RandomNumberGenerator.new()
var active := 0
var phase := "menu"
var wind := Vector2.ZERO
var weather
var clock := 0.0
var turn_time := 30.0
var movement_left := 90.0
var difficulty := 1
var winner := -1
var total_turns := 0
var accumulator := 0.0
var shot_weapon := 0
var shot_actor := 0
var resolve_wait := 0.0
var flight_elapsed := 0.0
var last_shots: Array = [{}, {}]
var map_id := ""

static func normalize_vehicle(vehicle: int) -> int:
	return vehicle if VEHICLES.has(vehicle) else 2

func start(vehicle: int, cpu_difficulty: int = 1, seed_value: int = -1, map: String = Maps.DEFAULT) -> void:
	vehicle = normalize_vehicle(vehicle)
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	terrain = Terrain.new()
	# An empty or unavailable map falls back to the procedural arena.
	var spawns := [Vector2(235.0, 0.0), Vector2(1045.0, 0.0)]
	map_id = map if not map.is_empty() and terrain.load_map(map) else ""
	if map_id.is_empty():
		terrain.generate()
	else:
		# RoomMetadata.cs draws each spawn from the original list; 1×1 keeps sides.
		for index in range(2):
			var options: Array = Maps.spawn_points(Maps.get_map(map_id), index == 0, terrain.world_size().x)
			spawns[index] = options[rng.randi_range(0, options.size() - 1)]
	actors.clear()
	for index in range(2):
		var kind := vehicle if index == 0 else 3 - vehicle
		var x: float = spawns[index].x
		# Search from just above the listed spawn so layered maps keep its platform.
		var ground: float = terrain.surface_at(x, maxf(0.0, spawns[index].y - 80.0))
		actors.append({"vehicle": kind, "hp": VEHICLES[kind].hp, "max_hp": VEHICLES[kind].hp, "pos": Vector2(x, ground - 24.0), "facing": 1 if index == 0 else -1, "shield": 220 if kind == 1 else 0, "max_shield": 220 if kind == 1 else 0, "ready": 0.0, "turns": 0, "special_used": false})
	difficulty = clampi(cpu_difficulty, 0, 2)
	active = 0
	winner = -1
	clock = 0.0
	total_turns = 0
	accumulator = 0.0
	resolve_wait = 0.0
	flight_elapsed = 0.0
	projectiles.clear()
	events.clear()
	last_shots = [{}, {}]
	weather = Weather.new()
	var preset: Array = Maps.get_map(map_id).weather if not map_id.is_empty() else PROCEDURAL_WEATHER
	apply_weather(weather.setup(preset, terrain.world_size(), rng))
	begin_turn()

func movement_budget() -> float:
	return float(VEHICLES[actors[active].vehicle].move)

func begin_turn() -> void:
	phase = "aim"
	turn_time = 30.0
	movement_left = movement_budget()
	if actors[active].vehicle == 1:
		actors[active].max_shield = 220 + int(actors[active].max_hp) - int(actors[active].hp)
		actors[active].shield = mini(int(actors[active].max_shield), int(actors[active].shield) + 20)
	actors[active].turns += 1
	total_turns += 1
	# A round is two turns (RoomSize 2 in MatchMetadata.PassTurn).
	if total_turns > 1 and (total_turns - 1) % 2 == 0:
		apply_weather(weather.next_round(rng))
	wind = weather.wind_vector()
	events.append({"type": "turn", "actor": active})

func apply_weather(entry: Dictionary) -> void:
	wind = weather.wind_vector()
	if entry.type == "protection":
		# WeatherDisplay: Protection regenerates every mobile (HealthRegenerationProtection 35).
		for actor in actors:
			if int(actor.hp) > 0:
				actor.hp = mini(int(actor.max_hp), int(actor.hp) + Weather.PROTECTION_HEAL)
	events.append({"type": "weather", "weather": entry.type, "extra": entry.extra, "queue": weather.queue.duplicate(true), "wind_force": weather.wind_force, "wind_angle": weather.wind_angle})

func can_use_special(index: int) -> bool:
	return int(actors[index].turns) >= 3 and not bool(actors[index].special_used)

func move_actor(direction: float, delta: float) -> void:
	if phase != "aim" or is_zero_approx(direction):
		return
	var actor: Dictionary = actors[active]
	actor.facing = int(signf(direction))
	if movement_left <= 0.0:
		return
	var distance := minf(movement_left, absf(direction) * 60.0 * delta)
	var steps := maxi(1, int(ceil(distance / 2.0)))
	for i in range(steps):
		var dx := signf(direction) * distance / steps
		var next_x := clampf(float(actor.pos.x) + dx, 24.0, terrain.world_size().x - 24.0)
		if absf(next_x - float(actors[1 - active].pos.x)) < 60.0:
			break
		var floor_y: float = terrain.surface_at(next_x, actor.pos.y + 8.0)
		var next_y := floor_y - 24.0
		if next_y < float(actor.pos.y) - 12.0:
			break
		actor.pos = Vector2(next_x, next_y)
		movement_left = maxf(0.0, movement_left - absf(dx))
		if terrain.is_void(floor_y):
			actor.hp = 0
			events.append({"type": "fall", "actor": active})
			check_end()
			break

func body_rotation(index: int) -> float:
	# Nearby supports only: do not tilt toward a distant lower floor or the abyss.
	var pos: Vector2 = actors[index].pos
	var left: float = terrain.surface_at(pos.x - 18.0, pos.y - 16.0)
	var right: float = terrain.surface_at(pos.x + 18.0, pos.y - 16.0)
	if terrain.is_void(left) or terrain.is_void(right) or absf(left - pos.y - 24.0) > 60.0 or absf(right - pos.y - 24.0) > 60.0:
		return 0.0
	return clampf(atan2(right - left, 36.0), -PI / 6.0, PI / 6.0)

func weapon_rules(index: int, weapon: int) -> Dictionary:
	if actors[index].vehicle == 1:
		return MAGE_WEAPONS[weapon]
	return BigfootAttacks.WEAPONS[weapon]

func aim_limits(index: int, weapon: int = 0) -> Vector2:
	if actors[index].vehicle == 2:
		return BigfootAttacks.AIM_LIMITS[weapon]
	return Vector2(15, 50)

func shot_velocity(index: int, angle: float, power: float, weapon: int, angle_offset: float = 0.0, power_offset: float = 0.0) -> Vector2:
	var limits := aim_limits(index, weapon)
	var velocity := Combat.launch_velocity(clampf(angle, limits.x, limits.y), power, actors[index].facing, body_rotation(index), power_offset)
	# Emitter spread comes after base aim limiting and mirrors with facing.
	return velocity.rotated(-float(actors[index].facing) * deg_to_rad(angle_offset))

func projectile_parameters(index: int, angle: float, power: float, weapon: int) -> Array:
	var rules := weapon_rules(index, weapon)
	var result: Array = []
	var emission: Array = BigfootAttacks.salvo(weapon) if actors[index].vehicle == 2 else []
	if emission.is_empty():
		for component in range(int(rules.count)):
			emission.append({"spawn": 0.0, "angle": 0.0, "power": 0.0})
	for component in range(emission.size()):
		var entry: Dictionary = emission[component]
		var original: bool = actors[index].vehicle == 2
		var initial := muzzle(index, angle if original else angle + float(entry.angle), weapon)
		var velocity := shot_velocity(index, angle, power, weapon, entry.angle, entry.power) if original else shot_velocity(index, angle + float(entry.angle), power, weapon)
		result.append({"pos": initial, "hit_pos": initial, "velocity": velocity, "age": 0.0, "trail": [initial], "helix": float(rules.get("helix", 0)), "phase": float(component) * PI, "spawn_at": entry.spawn, "launched": false,
			# Weather state per shell (Projectile.cs): base damage, columns touched, influences.
			"damage": int(rules.damage), "launch_speed": velocity.length(), "inside": {}, "influenced": [], "electric": false, "thor": false, "tornado": {}})
	return result

func launch_projectile(projectile: Dictionary) -> void:
	projectile.launched = true
	# Thor intersects everything: every shell fired while active attaches to it.
	projectile.thor = bool(weather.thor.active)
	events.append({"type": "projectile_launch", "actor": shot_actor, "vehicle": actors[shot_actor].vehicle, "weapon": shot_weapon, "time": projectile.spawn_at})

func predict_shot(index: int, angle: float, power: float, weapon: int) -> Dictionary:
	var shells := projectile_parameters(index, angle, power, weapon)
	# Weather, Thor and salvo craters change the flight: always run the real
	# flight loop on isolated copies of mask, actors, wind and weather.
	var simulation = get_script().new()
	simulation.terrain = terrain.collision_copy()
	simulation.actors = actors.duplicate(true)
	simulation.wind = wind
	simulation.weather = weather.copy()
	simulation.shot_actor = index
	simulation.shot_weapon = weapon
	simulation.projectiles = shells
	simulation.phase = "flight"
	var closest: Dictionary = {}
	var distance := INF
	var last_spawn := 0.0
	for shell in shells:
		last_spawn = maxf(last_spawn, float(shell.spawn_at))
	for frame in range(ceili((12.0 + last_spawn) / Combat.STEP) + 1):
		simulation.advance_projectiles(Combat.STEP)
		for event in simulation.events:
			if event.type not in ["explosion", "miss"]:
				continue
			var score := Vector2(event.position).distance_to(actors[1 - index].pos)
			if score < distance:
				distance = score
				closest = {"position": event.position, "actor": event.get("collided_actor", -1), "hit": event.type == "explosion"}
		simulation.events.clear()
		if simulation.phase != "flight":
			break
	return closest

func cannon_pivot(index: int) -> Vector2:
	return actors[index].pos + Vector2(0, -14).rotated(body_rotation(index))

func muzzle(index: int, angle: float, weapon: int = 0) -> Vector2:
	return cannon_pivot(index) + shot_velocity(index, angle, 100.0, weapon).normalized() * 38.0

func initiative_preview(weapon: int) -> Array:
	var ready := [float(actors[0].ready), float(actors[1].ready)]
	if phase in ["aim", "flight", "settle"]:
		var selected := clampi(weapon, 0, 2) if phase == "aim" else shot_weapon
		ready[active] = maxf(ready[active], clock) + float(weapon_rules(active, selected).delay) + float(VEHICLES[actors[active].vehicle].delay)
	var first := 1 - active if is_zero_approx(ready[0] - ready[1]) else (0 if ready[0] < ready[1] else 1)
	return [{"actor": first, "ready": ready[first], "delay": maxf(0.0, ready[first] - clock)}, {"actor": 1 - first, "ready": ready[1 - first], "delay": maxf(0.0, ready[1 - first] - clock)}]

func fire(angle: float, power: float, weapon: int) -> bool:
	if phase != "aim" or weapon < 0 or weapon >= MAGE_WEAPONS.size():
		return false
	if weapon == 2 and not can_use_special(active):
		return false
	shot_weapon = weapon
	shot_actor = active
	if weapon == 2:
		actors[active].special_used = true
	var limits := aim_limits(active, weapon)
	angle = clampf(angle, limits.x, limits.y)
	power = clampf(power, 15.0, 100.0)
	last_shots[active] = {"angle": angle, "power": power, "weapon": weapon}
	projectiles.clear()
	projectiles = projectile_parameters(active, angle, power, weapon)
	phase = "flight"
	accumulator = 0.0
	flight_elapsed = 0.0
	events.append({"type": "fire", "actor": active, "weapon": weapon})
	for projectile in projectiles:
		if float(projectile.spawn_at) <= 0.0:
			launch_projectile(projectile)
	return true

func schedule(index: int, delay: float) -> void:
	actors[index].ready = maxf(float(actors[index].ready), clock) + delay
	var difference := float(actors[0].ready) - float(actors[1].ready)
	active = (1 - index) if is_zero_approx(difference) else (0 if difference < 0.0 else 1)
	clock = float(actors[active].ready)
	begin_turn()

func pass_turn() -> void:
	if phase != "aim":
		return
	events.append({"type": "pass", "actor": active})
	schedule(active, 80.0 + float(VEHICLES[actors[active].vehicle].delay))

func tick(delta: float) -> void:
	if phase == "aim":
		turn_time = maxf(0.0, turn_time - delta)
		if turn_time <= 0.0:
			pass_turn()
	elif phase == "flight":
		accumulator += minf(delta, 0.1)
		while accumulator >= Combat.STEP and phase == "flight":
			accumulator -= Combat.STEP
			advance_projectiles(Combat.STEP)
	elif phase == "settle":
		resolve_wait -= delta
		if resolve_wait <= 0.0:
			settle_actors()
			if not check_end():
				schedule(shot_actor, float(weapon_rules(shot_actor, shot_weapon).delay) + float(VEHICLES[actors[shot_actor].vehicle].delay))

func advance_projectiles(delta: float) -> void:
	flight_elapsed += delta
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[i]
		var travel_delta := delta
		if not projectile.launched:
			if float(projectile.spawn_at) > flight_elapsed + 0.0000001:
				continue
			launch_projectile(projectile)
			travel_delta = clampf(flight_elapsed - float(projectile.spawn_at), 0.0, delta)
			if travel_delta <= 0.0000001:
				continue
		apply_weather_contact(projectile)
		var next: Dictionary = tornado_step(projectile, travel_delta) if not projectile.tornado.is_empty() else Combat.advance(projectile.pos, projectile.velocity, wind, travel_delta)
		# Only ignore the firing actor until the shell has cleared its muzzle.
		var ignored := Combat.ignored_shooter(float(projectile.age), shot_actor)
		var actual: Vector2 = Combat.sample_position(next.position, next.velocity, float(projectile.age) + travel_delta, projectile.helix, projectile.phase)
		var hit: Dictionary = Combat.trace_segment(projectile.hit_pos, actual, terrain, actors, ignored)
		projectile.hit_pos = actual
		projectile.age += travel_delta
		projectile.pos = next.position
		projectile.velocity = next.velocity
		if int(float(projectile.age) * 120.0) % 4 == 0:
			projectile.trail.append(projectile.hit_pos)
			if projectile.trail.size() > 28:
				projectile.trail.pop_front()
		if not hit.is_empty():
			explode(hit.position, int(hit.actor), projectile)
			projectiles.remove_at(i)
		elif Combat.out_of_bounds(projectile.pos, terrain) or projectile.age > 12.0:
			events.append({"type": "miss", "position": projectile.hit_pos})
			projectiles.remove_at(i)
	if projectiles.is_empty():
		phase = "settle"
		resolve_wait = 0.55

func explode(position: Vector2, collided_actor: int = -1, projectile: Dictionary = {}) -> void:
	var weapon: Dictionary = weapon_rules(shot_actor, shot_weapon)
	var removed: int = terrain.carve(position, float(weapon.radius))
	var heading: float = Vector2(projectile.velocity).angle() if projectile.has("velocity") else PI * 0.5
	events.append({"type": "explosion", "position": position, "radius": weapon.radius, "weapon": shot_weapon, "vehicle": actors[shot_actor].vehicle, "collided_actor": collided_actor, "removed": removed, "angle": heading})
	blast(position, float(weapon.radius), float(maxi(0, int(projectile.get("damage", weapon.damage)))), float(weapon.get("emp", 0)))
	# OnExplodeAction order: Thor attached at launch, then Electricity.
	if bool(projectile.get("thor", false)):
		thor_strike(position)
	if bool(projectile.get("electric", false)):
		lightning_strike(position)

func blast(position: Vector2, radius: float, damage: float, emp: float = 0.0) -> int:
	var dealt := 0
	for index in range(actors.size()):
		if int(actors[index].hp) <= 0:
			continue
		var distance := position.distance_to(actors[index].pos)
		if emp > 0 and distance <= emp + 22.0 and int(actors[index].shield) > 0:
			events.append({"type": "shield_damage", "actor": index, "amount": actors[index].shield, "position": actors[index].pos})
			actors[index].shield = 0
		dealt += deal_damage(index, Combat.damage_at(distance, damage, radius))
	return dealt

func deal_damage(index: int, damage: int) -> int:
	# Shield absorbs first (Mobile.ReceiveDamage / ReceiveShock).
	if damage <= 0:
		return 0
	var absorbed := mini(damage, int(actors[index].shield))
	if absorbed > 0:
		actors[index].shield -= absorbed
		events.append({"type": "shield_damage", "actor": index, "amount": absorbed, "position": actors[index].pos})
	var remaining := damage - absorbed
	if remaining > 0:
		actors[index].hp = maxi(0, int(actors[index].hp) - remaining)
		events.append({"type": "damage", "actor": index, "amount": remaining, "position": actors[index].pos})
	return damage

func thor_strike(impact: Vector2) -> void:
	# ThorProjectile: beam from the satellite to the impact hits the first solid
	# point on its path (radius 25, damage 40 + 20/level); dealt damage is XP.
	var origin: Vector2 = weather.thor.pos
	var hit: Dictionary = Combat.trace_segment(origin, impact, terrain, actors, -1)
	var strike: Vector2 = hit.position if not hit.is_empty() else impact
	var removed: int = terrain.carve(strike, Weather.THOR_RADIUS)
	var level := int(weather.thor.level)
	var dealt := blast(strike, Weather.THOR_RADIUS, float(weather.thor_damage()))
	weather.gain_thor_experience(dealt)
	events.append({"type": "thor", "from": origin, "position": strike, "removed": removed, "level": level, "new_level": weather.thor.level, "xp": weather.thor.xp})

func lightning_strike(impact: Vector2) -> void:
	# LightningBaseProjectile: a vertical beam rises from the impact to the top of
	# the terrain; the topmost solid point takes a radius-10 blast without damage
	# and actors within 30 of the beam above it take a 30 shock.
	var top := Vector2(impact.x, terrain.first_solid_y - 2.0)
	var hit: Dictionary = Combat.trace_segment(top, impact, terrain, actors, -1) if top.y < impact.y else {}
	var strike: Vector2 = hit.position if not hit.is_empty() else impact
	var removed: int = terrain.carve(strike, Weather.LIGHTNING_RADIUS)
	events.append({"type": "lightning", "position": strike, "top": top, "removed": removed})
	for index in range(actors.size()):
		if int(actors[index].hp) <= 0:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(Vector2(actors[index].pos), top, strike)
		if Vector2(actors[index].pos).distance_to(closest) < 24.0 + Weather.LIGHTNING_SHOCK_RADIUS:
			deal_damage(index, Weather.LIGHTNING_SHOCK_DAMAGE)

func apply_weather_contact(projectile: Dictionary) -> void:
	# Weather.CheckProjectileInteraction: entering a column's inner rectangle
	# interacts once; leaving through the outer margin re-arms it.
	var point: Vector2 = projectile.pos
	for column in weather.columns.duplicate():
		var id := int(column.id)
		var inner: bool = weather.inside_inner(column, point)
		var inside: bool = projectile.inside.has(id)
		if inner and not inside:
			projectile.inside[id] = true
			weather_interact(projectile, column)
		elif inside and not inner and column.type not in ["random", "tornado"] and weather.inside_outer(column, point):
			projectile.inside.erase(id)

func weather_interact(projectile: Dictionary, column: Dictionary) -> void:
	var type: String = column.type
	var first: bool = type not in projectile.influenced
	if first and type != "tornado" and type != "random":
		projectile.influenced.append(type)
	var damage := int(projectile.damage)
	match type:
		"force":
			if first and damage != 0:
				projectile.damage = int(damage * 1.2 + 10.0)
		"weakness":
			# Weakness.cs divides by the Force factors, not its own constants.
			if first and damage != 0:
				projectile.damage = int(damage / 1.2 - 10.0)
		"mirror":
			if first and damage != 0:
				projectile.damage = int(damage * 1.1 + 5.0)
			projectile.velocity = Vector2(-projectile.velocity.x, projectile.velocity.y)
		"electricity":
			if first:
				projectile.electric = true
		"tornado":
			if projectile.tornado.is_empty():
				var velocity: Vector2 = projectile.velocity
				projectile.tornado = {"column": int(column.id), "step": 1, "direction": velocity.normalized() if velocity != Vector2.ZERO else Vector2.DOWN, "speed": maxf(velocity.length(), Weather.TORNADO_MIN_SPEED)}
		"random":
			if not bool(column.used):
				column.used = true
				var spawned: Dictionary = weather.add_column(column.extra, float(column.x), 1.0)
				projectile.inside.erase(int(spawned.id))
	events.append({"type": "weather_hit", "weather": type, "position": projectile.pos, "extra": column.get("extra", "")})

func tornado_step(projectile: Dictionary, delta: float) -> Dictionary:
	# Tornado.cs: cross the column along the entry heading, back across mirrored,
	# then out along the heading; afterwards relaunch at the initial speed.
	var state: Dictionary = projectile.tornado
	var column: Dictionary = weather.find_column(int(state.column))
	var direction: Vector2 = state.direction
	var travel: float = float(state.speed) * delta
	var position: Vector2 = projectile.pos
	var heading := direction
	if column.is_empty():
		state.step = 3
	match int(state.step):
		1:
			var next := position + direction * travel
			if weather.inside_inner(column, next):
				position = next
			else:
				state.step = 2
		2:
			heading = Vector2(-direction.x, direction.y)
			var next := position + heading * travel
			if weather.inside_inner(column, next):
				position = next
			else:
				state.step = 3
		_:
			position += direction * travel
			if column.is_empty() or not weather.inside_outer(column, position):
				projectile.tornado = {}
				projectile.inside.erase(int(state.column))
				return {"position": position, "velocity": direction * float(projectile.launch_speed)}
	return {"position": position, "velocity": heading * float(state.speed)}

func settle_actors() -> void:
	for index in range(actors.size()):
		var actor: Dictionary = actors[index]
		if int(actor.hp) <= 0:
			continue
		var floor_y: float = terrain.surface_at(actor.pos.x, actor.pos.y + 10.0)
		var drop := maxf(0.0, floor_y - 24.0 - float(actor.pos.y))
		actor.pos.y = floor_y - 24.0
		if terrain.is_void(floor_y):
			actor.hp = 0
			events.append({"type": "fall", "actor": index})
		elif drop > 70.0:
			var damage := int((drop - 70.0) * 0.9)
			actor.hp = maxi(0, int(actor.hp) - damage)
			events.append({"type": "damage", "actor": index, "amount": damage, "position": actor.pos})

func check_end() -> bool:
	if int(actors[0].hp) > 0 and int(actors[1].hp) > 0:
		return false
	winner = -1 if int(actors[0].hp) <= 0 and int(actors[1].hp) <= 0 else (0 if int(actors[0].hp) > 0 else 1)
	phase = "finished"
	projectiles.clear()
	events.append({"type": "finished", "winner": winner})
	return true

func choose_cpu_shot() -> Dictionary:
	var actor: Dictionary = actors[active]
	var target: Dictionary = actors[1 - active]
	actor.facing = 1 if target.pos.x > actor.pos.x else -1
	var weapon := 1 if rng.randf() < 0.35 else 0
	if can_use_special(active) and rng.randf() < 0.45:
		weapon = 2
	var best := {"angle": 45.0, "power": 65.0, "weapon": weapon}
	var best_score := INF
	var limits := aim_limits(active, weapon)
	for angle in range(int(maxf(15, limits.x)), int(minf(80, limits.y)) + 1, 5):
		for power in range(20, 101, 4):
			var impact := predict_shot(active, angle, power, weapon)
			var score := Vector2(impact.position).distance_to(target.pos)
			if int(impact.actor) == 1 - active:
				score -= 20.0
			elif int(impact.actor) == active:
				score += 500.0
			if score < best_score:
				best_score = score
				best = {"angle": float(angle), "power": float(power), "weapon": weapon}
	var angle_error: float = [5.0, 2.5, 0.7][difficulty]
	var power_error: float = [10.0, 4.0, 1.0][difficulty]
	best.angle = clampf(float(best.angle) + rng.randf_range(-angle_error, angle_error), limits.x, limits.y)
	best.power = clampf(float(best.power) + rng.randf_range(-power_error, power_error), 15.0, 100.0)
	return best
