extends RefCounted
## Owns the entire combat lifecycle. Presentation consumes events, never decides damage.

const Terrain = preload("res://scripts/terrain.gd")
const Combat = preload("res://scripts/combat.gd")
const VEHICLES := [
	{"name": "Escaravelho", "hp": 580, "move": 110.0, "delay": 0.0, "color": Color("65dce4")},
	{"name": "Carapaça", "hp": 700, "move": 80.0, "delay": 18.0, "color": Color("ffbc79")},
	{"name": "Bigfoot", "hp": 1100, "move": 90.0, "delay": 0.0, "color": Color("71c0ff")}
]
var terrain
var actors: Array = []
var projectiles: Array = []
var events: Array = []
var rng := RandomNumberGenerator.new()
var active := 0
var phase := "menu"
var wind := 0.0
var clock := 0.0
var turn_time := 30.0
var movement_left := 110.0
var difficulty := 1
var winner := -1
var total_turns := 0
var accumulator := 0.0
var shot_weapon := 0
var shot_actor := 0
var resolve_wait := 0.0
var last_shots: Array = [{}, {}]

func start(vehicle: int, cpu_difficulty: int = 1, seed_value: int = -1) -> void:
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	terrain = Terrain.new()
	terrain.generate()
	actors.clear()
	for index in range(2):
		var kind := vehicle if index == 0 else (1 - vehicle if vehicle < 2 else 1)
		var x := 235.0 if index == 0 else 1045.0
		actors.append({"vehicle": kind, "hp": VEHICLES[kind].hp, "max_hp": VEHICLES[kind].hp, "pos": Vector2(x, terrain.surface_at(x) - 24.0), "facing": 1 if index == 0 else -1, "ready": 0.0, "turns": 0, "special_used": false})
	difficulty = clampi(cpu_difficulty, 0, 2)
	active = 0
	winner = -1
	clock = 0.0
	total_turns = 0
	accumulator = 0.0
	resolve_wait = 0.0
	projectiles.clear()
	events.clear()
	last_shots = [{}, {}]
	begin_turn()

func movement_budget() -> float:
	return float(VEHICLES[actors[active].vehicle].move)

func begin_turn() -> void:
	phase = "aim"
	turn_time = 30.0
	movement_left = movement_budget()
	actors[active].turns += 1
	total_turns += 1
	wind = float(rng.randi_range(-30, 30))
	events.append({"type": "turn", "actor": active})

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
		var next_x := clampf(float(actor.pos.x) + dx, 24.0, 1256.0)
		if absf(next_x - float(actors[1 - active].pos.x)) < 60.0:
			break
		var floor_y: float = terrain.surface_at(next_x, actor.pos.y + 8.0)
		var next_y := floor_y - 24.0
		if next_y < float(actor.pos.y) - 12.0:
			break
		actor.pos = Vector2(next_x, next_y)
		movement_left = maxf(0.0, movement_left - absf(dx))
		if floor_y > 740.0:
			actor.hp = 0
			events.append({"type": "fall", "actor": active})
			check_end()
			break

func body_rotation(index: int) -> float:
	# Nearby supports only: do not tilt toward a distant lower floor or the abyss.
	var pos: Vector2 = actors[index].pos
	var left: float = terrain.surface_at(pos.x - 18.0, pos.y - 16.0)
	var right: float = terrain.surface_at(pos.x + 18.0, pos.y - 16.0)
	if left > 740.0 or right > 740.0 or absf(left - pos.y - 24.0) > 60.0 or absf(right - pos.y - 24.0) > 60.0:
		return 0.0
	return clampf(atan2(right - left, 36.0), -PI / 6.0, PI / 6.0)

func shot_velocity(index: int, angle: float, power: float, weapon: int) -> Vector2:
	return Combat.launch_velocity(angle, power, actors[index].facing, weapon, body_rotation(index))

func cannon_pivot(index: int) -> Vector2:
	return actors[index].pos + Vector2(0, -14).rotated(body_rotation(index))

func muzzle(index: int, angle: float) -> Vector2:
	return cannon_pivot(index) + shot_velocity(index, angle, 100.0, 0).normalized() * 38.0

func initiative_preview(weapon: int) -> Array:
	var ready := [float(actors[0].ready), float(actors[1].ready)]
	if phase in ["aim", "flight", "settle"]:
		var selected := clampi(weapon, 0, 2) if phase == "aim" else shot_weapon
		ready[active] = maxf(ready[active], clock) + float(Combat.WEAPONS[selected].delay) + float(VEHICLES[actors[active].vehicle].delay)
	var first := 1 - active if is_zero_approx(ready[0] - ready[1]) else (0 if ready[0] < ready[1] else 1)
	return [{"actor": first, "ready": ready[first], "delay": maxf(0.0, ready[first] - clock)}, {"actor": 1 - first, "ready": ready[1 - first], "delay": maxf(0.0, ready[1 - first] - clock)}]

func fire(angle: float, power: float, weapon: int) -> bool:
	if phase != "aim" or weapon < 0 or weapon >= Combat.WEAPONS.size():
		return false
	if weapon == 2 and not can_use_special(active):
		return false
	shot_weapon = weapon
	shot_actor = active
	if weapon == 2:
		actors[active].special_used = true
	angle = clampf(angle, 10.0, 85.0)
	power = clampf(power, 15.0, 100.0)
	last_shots[active] = {"angle": angle, "power": power, "weapon": weapon}
	projectiles.clear()
	var count := int(Combat.WEAPONS[weapon].count)
	for i in range(count):
		var spread := (float(i) - float(count - 1) * 0.5) * 3.0
		var initial := muzzle(active, angle + spread)
		projectiles.append({"pos": initial, "velocity": shot_velocity(active, angle + spread, power, weapon), "age": 0.0, "trail": [initial]})
	phase = "flight"
	accumulator = 0.0
	events.append({"type": "fire", "actor": active, "weapon": weapon})
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
				schedule(shot_actor, float(Combat.WEAPONS[shot_weapon].delay) + float(VEHICLES[actors[shot_actor].vehicle].delay))

func advance_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[i]
		var next: Dictionary = Combat.advance(projectile.pos, projectile.velocity, wind, delta)
		# Only ignore the firing actor until the shell has cleared its muzzle.
		var ignored := Combat.ignored_shooter(float(projectile.age), shot_actor)
		var hit: Dictionary = Combat.trace_segment(projectile.pos, next.position, terrain, actors, ignored)
		projectile.age += delta
		projectile.pos = next.position
		projectile.velocity = next.velocity
		if int(float(projectile.age) * 120.0) % 4 == 0:
			projectile.trail.append(projectile.pos)
			if projectile.trail.size() > 28:
				projectile.trail.pop_front()
		if not hit.is_empty():
			explode(hit.position)
			projectiles.remove_at(i)
		elif projectile.pos.x < -150.0 or projectile.pos.x > 1430.0 or projectile.pos.y > 820.0 or projectile.age > 12.0:
			projectiles.remove_at(i)
	if projectiles.is_empty():
		phase = "settle"
		resolve_wait = 0.55

func explode(position: Vector2) -> void:
	var weapon: Dictionary = Combat.WEAPONS[shot_weapon]
	terrain.carve(position, float(weapon.radius))
	events.append({"type": "explosion", "position": position, "radius": weapon.radius, "weapon": shot_weapon})
	for index in range(actors.size()):
		var damage := Combat.damage_at(position.distance_to(actors[index].pos), float(weapon.damage), float(weapon.radius))
		if damage > 0 and int(actors[index].hp) > 0:
			actors[index].hp = maxi(0, int(actors[index].hp) - damage)
			events.append({"type": "damage", "actor": index, "amount": damage, "position": actors[index].pos})

func settle_actors() -> void:
	for index in range(actors.size()):
		var actor: Dictionary = actors[index]
		if int(actor.hp) <= 0:
			continue
		var floor_y: float = terrain.surface_at(actor.pos.x, actor.pos.y + 10.0)
		var drop := maxf(0.0, floor_y - 24.0 - float(actor.pos.y))
		actor.pos.y = floor_y - 24.0
		if floor_y > 740.0:
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
	for angle in range(20, 81, 5):
		for power in range(20, 101, 4):
			var origin := muzzle(active, angle)
			var velocity := shot_velocity(active, angle, power, weapon)
			var impact := Combat.predict(origin, velocity, wind, terrain, actors, active)
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
	best.angle = clampf(float(best.angle) + rng.randf_range(-angle_error, angle_error), 10.0, 85.0)
	best.power = clampf(float(best.power) + rng.randf_range(-power_error, power_error), 15.0, 100.0)
	return best
