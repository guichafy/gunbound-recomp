extends RefCounted
## Owns the entire combat lifecycle. Presentation consumes events, never decides damage.

const GoldRewards = preload("res://scripts/gold_rewards.gd")
var shot_gold: Dictionary = {}
const Attributes = preload("res://scripts/player_attributes.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Maps = preload("res://scripts/maps.gd")
const Weather = preload("res://scripts/weather.gd")
const Combat = preload("res://scripts/combat.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const FlightSnapshot = preload("res://scripts/flight_snapshot.gd")
const Damage = preload("res://scripts/damage.gd")
const TurnTable = preload("res://scripts/turn_table.gd")
const Items = preload("res://scripts/items.gd")
# Procedural arena has no map preset: only the Wind weather re-rolls each round.
const PROCEDURAL_WEATHER := [0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
# Training option "all": equal weight for every weather type, Thor included.
const ALL_WEATHER := [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
# Training slots. Index 0 is the human, index 1 is the CPU. The match stays 1×1.
const PLAYER := 0
const CPU := 1
# TimePerPlayerTurn. The original clock is 20 s, but the user kept 30 (ADR-076).
const TURN_TIME := 30.0
# start(opening): draw the first actor from the match rng (real matches).
const RANDOM_OPENING := -1
const SPECIAL_WEAPON := Mobiles.SPECIAL
# Stable mobile IDs are independent of menu slots. Removed ID 0 is not playable.
const PLAYABLE_VEHICLES := Mobiles.PLAYABLE
const VEHICLES := Mobiles.DEFINITIONS
# Original Mage metadata lives in mobiles.gd. Kept here so older notes still resolve.
const MAGE_WEAPONS := Mobiles.MAGE_WEAPONS
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
var turn_time := TURN_TIME
var movement_left := 90.0
var difficulty := 1
var winner := -1
var total_turns := 0
var accumulator := 0.0
var shot_weapon := 0
var shot_actor := 0
# Whole seconds spent before the last shot; charged with its delay (ADR-076).
var shot_elapsed := 0
# True while the CPU aim search runs: the turn clock is frozen (ADR-076), so a
# slow machine can never make the CPU time out and pass.
var cpu_thinking := false
var resolve_wait := 0.0
var flight_elapsed := 0.0
var last_shots: Array = [{}, {}]
var map_id := ""
# Dual second volley start times (presentation event only; not in the snapshot).
var volleys: Array = []

static func normalize_vehicle(vehicle: int) -> int:
	return Mobiles.normalize(vehicle)

static func other(index: int) -> int:
	return TurnTable.other(index)

func start(vehicle: int, cpu_difficulty: int = 1, seed_value: int = -1, map: String = Maps.DEFAULT, weather_mode: String = "original", mask = null, loadout: Array = [], attributes_by_actor: Array = [], gear_bonuses_by_actor: Array = [], opening: int = PLAYER) -> void:
	vehicle = normalize_vehicle(vehicle)
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	terrain = mask if mask != null else Terrain.new()
	# An empty or unavailable map falls back to the procedural arena.
	var spawns := [Vector2(235.0, 0.0), Vector2(1045.0, 0.0)]
	map_id = map if not map.is_empty() and terrain.load_map(map) else ""
	if map_id.is_empty():
		terrain.generate()
	else:
		# RoomMetadata.cs draws each spawn from the original list; 1×1 keeps sides.
		for index in [PLAYER, CPU]:
			var options: Array = Maps.spawn_points(Maps.get_map(map_id), index == PLAYER, terrain.world_size().x)
			spawns[index] = options[rng.randi_range(0, options.size() - 1)]
	actors.clear()
	for index in [PLAYER, CPU]:
		var kind := vehicle if index == PLAYER else Mobiles.opponent(vehicle)
		var x: float = spawns[index].x
		# Search from just above the listed spawn so layered maps keep its platform.
		var ground: float = terrain.surface_at(x, maxf(0.0, spawns[index].y - 80.0))
		var stance := float(Mobiles.definition(kind).stance)
		var shield := int(Mobiles.definition(kind).shield)
		# Equipped items (EquippedButtonBar); the CPU plays without items for now.
		var items: Array = []
		for id in (Items.sanitize(loadout) if index == PLAYER else []):
			items.append({"id": id, "used": false})
		var values: Array = Attributes.sanitize(attributes_by_actor[index] if index < attributes_by_actor.size() and attributes_by_actor[index] is Array else [])
		values=Attributes.with_equipment(values,gear_bonuses_by_actor[index] if index<gear_bonuses_by_actor.size() and gear_bonuses_by_actor[index] is Array else [])
		var max_health := Attributes.health(int(VEHICLES[kind].hp),int(values[1]))
		actors.append({"gold_state":{"gold":0,"enemy_damage":0},"attributes":values,"vehicle": kind, "hp": max_health, "max_hp": max_health, "pos": Vector2(x, ground - stance), "facing": 1 if index == PLAYER else -1, "shield": shield, "max_shield": shield, "ready": 0.0, "turns": 0, "ss_lock": 0, "tilt": 0.0,
			"items": items, "turn_item": ""})
	difficulty = clampi(cpu_difficulty, 0, 2)
	active = PLAYER
	shot_elapsed = 0
	winner = -1
	clock = 0.0
	total_turns = 0
	accumulator = 0.0
	resolve_wait = 0.0
	flight_elapsed = 0.0
	projectiles.clear()
	volleys.clear()
	events.clear()
	shot_gold = {}
	last_shots = [{}, {}]
	weather = Weather.new()
	var preset: Array = Maps.get_map(map_id).weather if not map_id.is_empty() else PROCEDURAL_WEATHER
	if weather_mode == "all":
		preset = ALL_WEATHER
	apply_weather(weather.setup(preset, terrain.world_size(), rng))
	# The server draws the turn order (MatchManager / jglim start_game); fixtures
	# pass an explicit side so their first shot stays the player's.
	active = rng.randi_range(PLAYER, CPU) if opening == RANDOM_OPENING else clampi(opening, PLAYER, CPU)
	begin_turn()

func movement_budget() -> float:
	return float(VEHICLES[actors[active].vehicle].move)

func begin_turn() -> void:
	phase = "aim"
	cpu_thinking = false
	turn_time = TURN_TIME
	actors[active].turns += 1
	total_turns += 1
	# A round is two turns (RoomSize 2 in MatchMetadata.PassTurn).
	# Weather, including Protection, is applied before Regenerate().
	if total_turns > 1 and (total_turns - 1) % 2 == 0:
		apply_weather(weather.next_round(rng))
	for actor in actors:
		Mobiles.regenerate(actor)
	actors[active].ss_lock = maxi(int(actors[active].ss_lock) - 1, 0)
	movement_left = movement_budget()
	wind = weather.wind_vector()
	stamp_tilt()
	events.append({"type": "turn", "actor": active})

func stance_of(index: int) -> float:
	return float(Mobiles.definition(int(actors[index].vehicle)).stance)

func stamp_tilt() -> void:
	for index in range(actors.size()):
		actors[index].tilt = body_rotation(index)

func apply_weather(entry: Dictionary) -> void:
	wind = weather.wind_vector()
	if entry.type == "protection":
		# WeatherDisplay: Protection regenerates every mobile (HealthRegenerationProtection 35).
		for actor in actors:
			if int(actor.hp) > 0:
				var heal := int(Mobiles.definition(int(actor.vehicle)).protection)
				actor.hp = mini(int(actor.max_hp), int(actor.hp) + Attributes.heal(heal, Attributes.points(actor,3)))
	events.append({"type": "weather", "weather": entry.type, "extra": entry.extra, "queue": weather.queue.duplicate(true), "wind_force": weather.wind_force, "wind_angle": weather.wind_angle})

func can_use_special(index: int) -> bool:
	# SS starts open. Firing it adds SS_LOCK; each own turn decrements it.
	# HUD.DisableSS: using an item locks SS for the rest of the turn.
	return int(actors[index].get("ss_lock", 0)) <= 0 and str(actors[index].get("turn_item", "")).is_empty()

## HUD.UnlockItem / WeatherDisplay: the Ignorance weather locks the item bar.
func items_locked() -> bool:
	return weather != null and not weather.queue.is_empty() and str(weather.queue[0].type) == "ignorance"

func can_use_item(index: int, slot: int) -> bool:
	if phase != "aim" or index != active or items_locked():
		return false
	var actor: Dictionary = actors[index]
	var items: Array = actor.get("items", [])
	# One item per turn: the whole bar is disabled after a use.
	if slot < 0 or slot >= items.size() or bool(items[slot].used) or not str(actor.get("turn_item", "")).is_empty():
		return false
	return int(actor.hp) > 0

## Mobile.UseItem plus MatchManager.ComputePlayerItem: the delay cost is
## charged at once; instant items act now, turn items modify this turn's shot.
func use_item(slot: int) -> bool:
	if not can_use_item(active, slot):
		return false
	var actor: Dictionary = actors[active]
	var id: String = actor.items[slot].id
	actor.items[slot].used = true
	actor.turn_item = id
	actor.ready = maxf(float(actor.ready), clock) + Items.delay(id,Attributes.points(actor,5))
	var event := {"type": "item", "actor": active, "item": id, "slot": slot, "position": actor.pos}
	match id:
		"energy_up_1", "energy_up_2":
			# Mobile.Heal: percentage of the base health; shield untouched.
			var percent := Items.ENERGY_UP_1 if id == "energy_up_1" else Items.ENERGY_UP_2
			if bool(Mobiles.definition(int(actor.vehicle)).bionic):
				percent += Items.ENERGY_UP_EXTRA
			var before := int(actor.hp)
			actor.hp = mini(int(actor.max_hp), before + int(minf(float(actor.max_hp), float(actor.max_hp) * percent / 100.0)))
			event["amount"] = int(actor.hp) - before
		"blood":
			var before := int(actor.hp)
			actor.hp = maxi(1, int(float(actor.hp) - float(actor.max_hp) * Items.BLOOD_HEALTH / 100.0))
			event["amount"] = int(actor.hp) - before
		"change_wind":
			weather.wind_angle = posmod(int(weather.wind_angle) + Items.CHANGE_WIND_DEGREES, 360)
			wind = weather.wind_vector()
			event["wind_angle"] = weather.wind_angle
	events.append(event)
	return true

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
		var floor_y: float = terrain.surface_at(next_x, actor.pos.y + 8.0)
		var next_y := floor_y - stance_of(active)
		if absf(next_x - float(actors[other(active)].pos.x)) < 60.0 or next_y < float(actor.pos.y) - 12.0:
			events.append({"type": "blocked", "actor": active})
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
	var stance := stance_of(index)
	var left: float = terrain.surface_at(pos.x - 18.0, pos.y - 16.0)
	var right: float = terrain.surface_at(pos.x + 18.0, pos.y - 16.0)
	if terrain.is_void(left) or terrain.is_void(right) or absf(left - pos.y - stance) > 60.0 or absf(right - pos.y - stance) > 60.0:
		return 0.0
	return clampf(atan2(right - left, 36.0), -PI / 6.0, PI / 6.0)

func weapon_rules(index: int, weapon: int) -> Dictionary:
	var rules: Dictionary = Mobiles.weapon(actors[index].vehicle, weapon).duplicate(true)
	var points := Attributes.points(actors[index],4)
	if points != 0:
		rules.delay = Attributes.delay(roundi(float(rules.delay) * 7.5), points)
	return rules

func aim_limits(index: int, weapon: int = 0) -> Vector2:
	return Mobiles.aim_limits(actors[index].vehicle, weapon)

func shot_velocity(index: int, angle: float, power: float, weapon: int, angle_offset: float = 0.0, power_offset: float = 0.0) -> Vector2:
	var limits := aim_limits(index, weapon)
	var velocity := Combat.launch_velocity(clampf(angle, limits.x, limits.y), power, actors[index].facing, body_rotation(index), power_offset)
	# Emitter spread comes after base aim limiting and mirrors with facing.
	return velocity.rotated(-float(actors[index].facing) * deg_to_rad(angle_offset))

func projectile_parameters(index: int, angle: float, power: float, weapon: int) -> Array:
	var rules := weapon_rules(index, weapon)
	var result: Array = []
	var vehicle_id := int(actors[index].vehicle)
	var emission: Array = Mobiles.emission(vehicle_id, weapon)
	var spread_after: bool = Mobiles.spread_after_clamp(vehicle_id)
	for component in range(emission.size()):
		var entry: Dictionary = emission[component]
		var initial := muzzle(index, angle if spread_after else angle + float(entry.angle), weapon)
		var velocity := shot_velocity(index, angle, power, weapon, entry.angle, entry.power) if spread_after else shot_velocity(index, angle + float(entry.angle), power, weapon)
		result.append({"pos": initial, "hit_pos": initial, "velocity": velocity, "age": 0.0, "trail": [initial], "helix": float(rules.get("helix", 0)), "phase": float(component) * PI, "spawn_at": entry.spawn, "launched": false,
			# Weather state per shell (Projectile.cs): base damage, columns touched, influences.
			"damage": int(rules.damage), "launch_speed": velocity.length(), "inside": {}, "influenced": [], "electric": false, "thor": false, "tornado": {},
			"weapon": weapon, "volley": 0, "beacon": false, "wind_scale": float(rules.get("wind_scale", 1.0)),
			# Nak (ADR-074): S2 burrows and resurfaces, SS crosses the terrain.
			"burrow": bool(rules.get("burrow", false)), "ghost": bool(rules.get("ghost", false)), "underground": false})
	return result

## Mobile.ShootWithModifiers: the shells of a shot under this turn's item.
## fire() and predict_shot() both build from here, so the CPU sees the same flight.
func shot_shells(index: int, angle: float, power: float, weapon: int) -> Array:
	var item: String = str(actors[index].get("turn_item", ""))
	var shells := projectile_parameters(index, angle, power, weapon)
	match item:
		"dual", "dual_plus":
			var last_spawn := 0.0
			for shell in shells:
				last_spawn = maxf(last_spawn, float(shell.spawn_at))
			# Dual+: S2 after S1, S1 after anything else.
			var second := weapon if item == "dual" else (1 if weapon == 0 else 0)
			# InteractionTime (1 + last spawn of the first shot), then each SpawnTime.
			for shell in projectile_parameters(index, angle, power, second):
				shell.spawn_at = float(shell.spawn_at) + Items.DUAL_WAIT + last_spawn
				shell.volley = 1
				shells.append(shell)
		"teleport":
			# TeleportationBeacon replaces the shot: one shell, mass 10, no wind.
			var beacon: Dictionary = shells[0]
			var velocity := shot_velocity(index, angle, power, weapon) * Items.BEACON_SPEED
			var initial := muzzle(index, angle, weapon)
			beacon.merge({"pos": initial, "hit_pos": initial, "velocity": velocity, "trail": [initial], "helix": 0.0, "phase": 0.0,
				"spawn_at": float(Mobiles.definition(int(actors[index].vehicle)).beacon_delay), "damage": 0, "launch_speed": velocity.length(), "beacon": true, "wind_scale": Items.BEACON_WIND, "burrow": false, "ghost": false}, true)
			shells = [beacon]
		"thunder":
			# An invisible Electricity column of scale 1000 around the mobile:
			# every shell is electric once, and the weather column does not stack.
			for shell in shells:
				shell.electric = true
				shell.influenced.append("electricity")
	return shells

func launch_projectile(projectile: Dictionary) -> void:
	projectile.launched = true
	# Thor intersects everything: every shell fired while active attaches to it.
	projectile.thor = bool(weather.thor.active)
	events.append({"type": "projectile_launch", "actor": shot_actor, "vehicle": actors[shot_actor].vehicle, "weapon": int(projectile.get("weapon", shot_weapon)), "time": projectile.spawn_at, "beacon": bool(projectile.get("beacon", false))})

func predict_shot(index: int, angle: float, power: float, weapon: int) -> Dictionary:
	var shells := shot_shells(index, angle, power, weapon)
	# Weather, Thor and salvo craters change the flight: always run the real
	# flight loop on isolated copies of mask, actors, wind and weather.
	var simulation = FlightSnapshot.capture(self)
	FlightSnapshot.arm(simulation, index, weapon, shells)
	var closest: Dictionary = {}
	var distance := INF
	var last_spawn := 0.0
	for shell in shells:
		last_spawn = maxf(last_spawn, float(shell.spawn_at))
	for frame in range(ceili((12.0 + last_spawn) / Combat.STEP) + 1):
		simulation.advance_projectiles(Combat.STEP)
		for event in simulation.events:
			if event.type not in ["explosion", "miss", "teleport"]:
				continue
			var score := Vector2(event.position).distance_to(actors[other(index)].pos)
			if score < distance:
				distance = score
				closest = {"position": event.position, "actor": event.get("collided_actor", -1), "hit": event.type != "miss"}
		simulation.events.clear()
		if simulation.phase != "flight":
			break
	return closest

func cannon_pivot(index: int) -> Vector2:
	return actors[index].pos + Vector2(0, -14).rotated(body_rotation(index))

func muzzle(index: int, angle: float, weapon: int = 0) -> Vector2:
	return cannon_pivot(index) + shot_velocity(index, angle, 100.0, weapon).normalized() * 38.0

func current_order() -> Array:
	return TurnTable.current_order(self)

func initiative_preview(weapon: int) -> Array:
	return TurnTable.initiative_preview(self, weapon)

func fire(angle: float, power: float, weapon: int) -> bool:
	if phase != "aim" or weapon < 0 or weapon >= Mobiles.weapon_count(actors[active].vehicle):
		return false
	if Mobiles.is_special(actors[active].vehicle, weapon) and not can_use_special(active):
		return false
	shot_weapon = weapon
	shot_actor = active
	shot_elapsed = TurnTable.elapsed_seconds(self)
	if Mobiles.is_special(actors[active].vehicle, weapon):
		actors[active].ss_lock = int(actors[active].ss_lock) + Mobiles.SS_LOCK
	var limits := aim_limits(active, weapon)
	angle = clampf(angle, limits.x, limits.y)
	power = clampf(power, 15.0, 100.0)
	last_shots[active] = {"angle": angle, "power": power, "weapon": weapon}
	projectiles.clear()
	projectiles = shot_shells(active, angle, power, weapon)
	var launch_angle: float = rad_to_deg(shot_velocity(active,angle,power,weapon).angle())+180.0
	shot_gold = {"enemy_damage":0,"ally_damage":0,"enemy_kills":0,"ally_kills":0,"angle":fposmod(launch_angle,360.0),"travelled":0.0,"tornado":false,"mirror":false,"boomer":false,"backward":false,"facing":actors[active].facing,"start":actors[active].pos,"dead":[actors[0].hp<=0,actors[1].hp<=0]}
	volleys.clear()
	for projectile in projectiles:
		if int(projectile.volley) == 1:
			var start := float(projectile.spawn_at)
			for other_shell in projectiles:
				if int(other_shell.volley) == 1:
					start = minf(start, float(other_shell.spawn_at))
			volleys = [{"time": start, "weapon": int(projectile.weapon)}]
			break
	phase = "flight"
	accumulator = 0.0
	flight_elapsed = 0.0
	events.append({"type": "fire", "actor": active, "weapon": weapon, "item": str(actors[active].get("turn_item", ""))})
	for projectile in projectiles:
		if float(projectile.spawn_at) <= 0.0:
			launch_projectile(projectile)
	return true

func schedule(index: int, delay: float) -> void:
	TurnTable.schedule(self, index, delay)

func pass_turn() -> void:
	TurnTable.pass_turn(self)

func tick(delta: float) -> void:
	if phase == "aim":
		if cpu_thinking and active == CPU:
			return
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
			finish_gold_shot()
			if not check_end():
				schedule(shot_actor, TurnTable.shot_cost(self, shot_actor, shot_weapon, shot_elapsed))

func advance_projectiles(delta: float) -> void:
	stamp_tilt()
	flight_elapsed += delta
	# Dual: OnStartInteracting of the second shot plays the shooting animation.
	if not volleys.is_empty() and flight_elapsed + 0.0000001 >= float(volleys[0].time):
		events.append({"type": "volley", "actor": shot_actor, "vehicle": actors[shot_actor].vehicle, "weapon": int(volleys[0].weapon)})
		volleys.pop_front()
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
		var underground := bool(projectile.get("underground", false))
		var next: Dictionary
		if underground:
			next = Combat.advance_buried(projectile.pos, projectile.velocity, travel_delta)
		else:
			apply_weather_contact(projectile)
			next = tornado_step(projectile, travel_delta) if not projectile.tornado.is_empty() else Combat.advance(projectile.pos, projectile.velocity, wind * float(projectile.get("wind_scale", 1.0)), travel_delta)
		# Only ignore the firing actor until the shell has cleared its muzzle.
		var ignored := Combat.ignored_shooter(float(projectile.age), shot_actor)
		var actual: Vector2 = Combat.sample_position(next.position, next.velocity, float(projectile.age) + travel_delta, projectile.helix, projectile.phase)
		# The teleportation beacon only collides with the ground.
		var beacon := bool(projectile.get("beacon", false))
		var hit: Dictionary
		if bool(projectile.get("ghost", false)) or underground:
			hit = Combat.trace_actors(projectile.hit_pos, actual, actors, ignored)
			# A buried shell explodes on the first free pixel where it resurfaces.
			if underground:
				var exit: Dictionary = Combat.burrow_exit(terrain, projectile.hit_pos, actual)
				if not exit.is_empty() and (hit.is_empty() or float(exit.fraction) < float(hit.fraction)):
					hit = {"position": exit.position, "actor": -1}
		else:
			hit = Combat.trace_segment(projectile.hit_pos, actual, terrain, [] if beacon else actors, ignored)
			# SimulateShot2_Bullet3: the first solid pixel switches the shell to its
			# "special" underground state there and halves the vertical speed.
			if bool(projectile.get("burrow", false)) and not hit.is_empty() and int(hit.actor) < 0:
				projectile.underground = true
				next.position = hit.position
				next.velocity = Vector2(next.velocity.x, next.velocity.y * Combat.BURROW_ENTRY_DAMPING)
				actual = hit.position
				hit = {}
				events.append({"type": "burrow", "position": actual})
		var previous: Vector2 = projectile.hit_pos
		projectile.hit_pos = actual
		projectile.age += travel_delta
		projectile.pos = next.position
		projectile.velocity = next.velocity
		if int(float(projectile.age) * 120.0) % 4 == 0:
			projectile.trail.append(projectile.hit_pos)
			if projectile.trail.size() > 28:
				projectile.trail.pop_front()
		if not hit.is_empty():
			if beacon:
				land_beacon(hit.position, previous, projectile)
			else:
				explode(hit.position, int(hit.actor), projectile)
			projectiles.remove_at(i)
		elif Combat.out_of_bounds(projectile.pos, terrain) or projectile.age > 12.0:
			events.append({"type": "miss", "position": projectile.hit_pos})
			projectiles.remove_at(i)
	if projectiles.is_empty():
		phase = "settle"
		resolve_wait = 0.55

func explode(position: Vector2, collided_actor: int = -1, projectile: Dictionary = {}) -> void:
	# Tilt stays as stamped at the start of the step. A crater must not
	# rotate the target before this explosion's damage is measured.
	var event_start := events.size()
	# Each shell keeps its own weapon (Dual+ mixes S1 and S2 in one turn).
	var weapon_index := int(projectile.get("weapon", shot_weapon))
	var weapon: Dictionary = weapon_rules(shot_actor, weapon_index)
	var item: String = str(actors[shot_actor].get("turn_item", ""))
	# Projectile.Explode: erosion radius × (1 + Owner.Dig / 100) (Bunge Shot).
	var removed: int = terrain.carve(position, Attributes.crater(float(weapon.radius),Attributes.points(actors[shot_actor],6)+int(Items.dig(item))))
	var heading: float = Vector2(projectile.velocity).angle() if projectile.has("velocity") else PI * 0.5
	events.append({"type": "explosion", "position": position, "radius": weapon.radius, "weapon": weapon_index, "vehicle": actors[shot_actor].vehicle, "collided_actor": collided_actor, "removed": removed, "angle": heading})
	blast(position, float(weapon.radius), float(maxi(0, int(projectile.get("damage", weapon.damage)))), float(weapon.get("emp", 0)), Items.attack(item), shot_actor)
	# OnExplodeAction order: Thor attached at launch, then Electricity.
	if bool(projectile.get("thor", false)):
		thor_strike(position)
	if bool(projectile.get("electric", false)):
		lightning_strike(position)
	collect_gold_damage(event_start,position,projectile)

func blast(position: Vector2, radius: float, damage: float, emp: float = 0.0, attack: float = 0.0, shooter: int = -1) -> int:
	return Damage.blast(actors, events, position, radius, damage, emp, attack, shooter)

## TeleportationBeacon.Explode: explode actions (Thor, Electricity) first, then
## the owner moves to previousPosition (the free point just before the contact)
## and stands on the ground below it.
func land_beacon(position: Vector2, previous: Vector2, projectile: Dictionary) -> void:
	var event_start := events.size()
	if bool(projectile.get("thor", false)):
		thor_strike(position)
	if bool(projectile.get("electric", false)):
		lightning_strike(position)
	collect_gold_damage(event_start,position,projectile)
	var actor: Dictionary = actors[shot_actor]
	if int(actor.hp) <= 0:
		return
	var origin: Vector2 = actor.pos
	var x := clampf(previous.x, 24.0, terrain.world_size().x - 24.0)
	var floor_y: float = terrain.surface_at(x, maxf(0.0, previous.y))
	actor.pos = Vector2(x, floor_y - stance_of(shot_actor))
	events.append({"type": "teleport", "actor": shot_actor, "from": origin, "to": actor.pos, "position": position})
	if terrain.is_void(floor_y):
		actor.hp = 0
		events.append({"type": "fall", "actor": shot_actor})

func deal_damage(index: int, damage: int, kind: String = "") -> int:
	return Damage.deal_damage(actors, events, index, damage, kind)

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
		if Combat.box_gap(closest, actors[index]) < Weather.LIGHTNING_SHOCK_RADIUS:
			deal_damage(index, Weather.LIGHTNING_SHOCK_DAMAGE, "shock")

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

# Movement.ApplyGravity (Parameter.cs TankMovementInitialGravity/GravityFactor).
const FALL_INITIAL_SPEED := 3.0
const FALL_SPEED_STEP := 0.15
const FALL_WIND_DIVISOR := 45.0

func drift_fall(actor: Dictionary, drop: float) -> void:
	# ADR-077: the C# intent, one wind push of wind.x / 45 per gravity step.
	# Each step falls int(GravitySpeed) px (starting at 3, +0.15 per step); the
	# literal C# accumulator reset is not reproduced. Walls stop the push.
	var x := float(actor.pos.x)
	var y := float(actor.pos.y)
	var remaining := drop
	var speed := FALL_INITIAL_SPEED
	while remaining > 0.0:
		var fall := minf(float(int(speed)), remaining)
		var next := clampf(x + wind.x / FALL_WIND_DIVISOR, 24.0, terrain.world_size().x - 24.0)
		if not terrain.is_solid(Vector2(next, y)):
			x = next
		y += fall
		remaining -= fall
		speed += FALL_SPEED_STEP
	actor.pos.x = x

func settle_actors() -> void:
	for index in range(actors.size()):
		var actor: Dictionary = actors[index]
		if int(actor.hp) <= 0:
			continue
		var stance := stance_of(index)
		var floor_y: float = terrain.surface_at(actor.pos.x, actor.pos.y + 10.0)
		var drop := maxf(0.0, floor_y - stance - float(actor.pos.y))
		if drop > 0.0:
			drift_fall(actor, drop)
			floor_y = terrain.surface_at(actor.pos.x, actor.pos.y + 10.0)
		actor.pos.y = floor_y - stance
		if terrain.is_void(floor_y) or float(actor.pos.y) > terrain.world_size().y:
			actor.hp = 0
			events.append({"type": "fall", "actor": index})
	stamp_tilt()

func check_end() -> bool:
	return TurnTable.check_end(self)

func choose_cpu_shot() -> Dictionary:
	var plan := begin_cpu_plan()
	search_cpu_plan(plan)
	return finish_cpu_plan(plan)

## CPU aim in three steps (REQ-32/ADR-053) so the grid can run off the main
## thread: begin draws the weapon and snapshots mask, actors, wind and weather;
## search scores the grid only on that snapshot (no RNG, no live state); finish
## draws the aim errors. Same RNG order and result as a one-shot search.
func begin_cpu_plan() -> Dictionary:
	var actor: Dictionary = actors[active]
	var target: Dictionary = actors[other(active)]
	actor.facing = 1 if target.pos.x > actor.pos.x else -1
	var weapon := 1 if rng.randf() < 0.35 else 0
	if can_use_special(active) and rng.randf() < 0.45:
		weapon = 2
	var snapshot = FlightSnapshot.capture(self)
	snapshot.active = active
	cpu_thinking = true
	return {"actor": active, "weapon": weapon, "limits": aim_limits(active, weapon), "snapshot": snapshot,
		"target": target.pos, "best": {"angle": 45.0, "power": 65.0, "weapon": weapon}}

static func search_cpu_plan(plan: Dictionary) -> void:
	var limits: Vector2 = plan.limits
	plan.best_score = INF
	for angle in range(int(maxf(15, limits.x)), int(minf(80, limits.y)) + 1, 5):
		for power in range(20, 101, 4):
			score_cpu_shot(plan, angle, power)
	# Refine around the best cell: range grows with force² under the C# ballistics
	# (ADR-076), so a 4-point power step alone lands about 100 px apart.
	var coarse: Dictionary = plan.best
	for angle in range(int(coarse.angle) - 4, int(coarse.angle) + 5, 2):
		for power in range(int(coarse.power) - 3, int(coarse.power) + 4):
			if angle >= limits.x and angle <= limits.y and power >= 15 and power <= 100:
				score_cpu_shot(plan, angle, power)

## Predicts one grid cell on the plan snapshot and keeps it if it lands closer.
static func score_cpu_shot(plan: Dictionary, angle: int, power: int) -> void:
	var index: int = plan.actor
	var impact: Dictionary = plan.snapshot.predict_shot(index, angle, power, plan.weapon)
	var score := Vector2(impact.position).distance_to(plan.target)
	if int(impact.actor) == other(index):
		score -= 20.0
	elif int(impact.actor) == index:
		score += 500.0
	if score < float(plan.best_score):
		plan.best_score = score
		plan.best = {"angle": float(angle), "power": float(power), "weapon": plan.weapon}

func finish_cpu_plan(plan: Dictionary) -> Dictionary:
	var best: Dictionary = plan.best
	var limits: Vector2 = plan.limits
	var angle_error: float = [5.0, 2.5, 0.7][difficulty]
	var power_error: float = [10.0, 4.0, 1.0][difficulty]
	best.angle = clampf(float(best.angle) + rng.randf_range(-angle_error, angle_error), limits.x, limits.y)
	best.power = clampf(float(best.power) + rng.randf_range(-power_error, power_error), 15.0, 100.0)
	plan.snapshot = null
	cpu_thinking = false
	return best

func collect_gold_damage(event_start: int, impact: Vector2, projectile: Dictionary) -> void:
	if shot_gold.is_empty():
		return
	var any_hit := false
	var enemy_hit := false
	for event in events.slice(event_start):
		if event.type in ["damage","shield_damage"] and not event.get("emp",false) and int(event.amount)>0:
			var key := "ally_damage" if int(event.actor)==shot_actor else "enemy_damage"
			shot_gold[key] += int(event.amount)
			any_hit = true
			enemy_hit = enemy_hit or int(event.actor)!=shot_actor
	if not any_hit:
		return
	shot_gold.travelled = maxf(float(shot_gold.travelled),float(projectile.get("age",0)))
	for effect in projectile.get("influenced",[]):
		if effect in ["tornado","mirror"]:
			shot_gold[effect] = true
	if not enemy_hit:
		return
	var dx: float = impact.x-Vector2(shot_gold.start).x
	var angle := float(shot_gold.angle)
	var facing := int(shot_gold.facing)
	shot_gold.boomer = bool(shot_gold.boomer) or (facing==-1 and dx<0 and angle>90) or (facing==1 and dx>0 and angle<90)
	shot_gold.backward = bool(shot_gold.backward) or (facing==-1 and dx>0) or (facing==1 and dx<0)
func finish_gold_shot() -> void:
	if shot_gold.is_empty():
		return
	for index in range(actors.size()):
		if not bool(shot_gold.dead[index]) and int(actors[index].hp)<=0:
			shot_gold["ally_kills" if index==shot_actor else "enemy_kills"] += 1
	actors[shot_actor].gold_state = GoldRewards.apply_shot(actors[shot_actor].gold_state,shot_gold,Attributes.points(actors[shot_actor],7))
	shot_gold = {}
func player_gold_reward() -> int:
	return int(actors[PLAYER].gold_state.gold)+GoldRewards.result_bonus(winner==PLAYER,winner==-1)
