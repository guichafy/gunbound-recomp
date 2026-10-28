extends RefCounted
## Owns the entire combat lifecycle. Presentation consumes events, never decides damage.

const Attributes = preload("res://scripts/player_attributes.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Maps = preload("res://scripts/maps.gd")
const Weather = preload("res://scripts/weather.gd")
const MageWeather = preload("res://scripts/mage_weather.gd")
const MageWeatherEffects = preload("res://scripts/mage_weather_effects.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const BoomerFlight = preload("res://scripts/boomer_flight.gd")
const Combat = preload("res://scripts/combat.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const FlightSnapshot = preload("res://scripts/flight_snapshot.gd")
const Damage = preload("res://scripts/damage.gd")
const TurnTable = preload("res://scripts/turn_table.gd")
const Items = preload("res://scripts/items.gd")
const ItemEffects = preload("res://scripts/item_effects.gd")
const WeatherContact = preload("res://scripts/weather_contact.gd")
const GoldTracker = preload("res://scripts/gold_tracker.gd")
const CpuPlanner = preload("res://scripts/cpu_planner.gd")
const ActorState = preload("res://scripts/actor_state.gd")
const ShellState = preload("res://scripts/shell_state.gd")
const ClassicFlight = preload("res://scripts/classic_flight.gd")
const AsateEffect = preload("res://scripts/asate_effect.gd")
const JDEffect = preload("res://scripts/jd_effect.gd")
const AdukaEffect = preload("res://scripts/aduka_effect.gd")
const AdukaCombat = preload("res://scripts/aduka_combat.gd")
const LightningCombat = preload("res://scripts/lightning_combat.gd")
const MageCombat = preload("res://scripts/mage_combat.gd")
const AdukaWeather = preload("res://scripts/aduka_weather.gd")
# Procedural arena has no map preset: only the Wind weather re-rolls each round.
const PROCEDURAL_WEATHER := [0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
# Training option "all": equal weight for every weather type, Thor included.
const ALL_WEATHER := [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
# Training slots. Index 0 is the human, index 1 is the CPU. The match stays 1×1.
const PLAYER := 0
const CPU := 1
# TimePerPlayerTurn. The original clock is 20 s, but the user kept 30 (ADR-076).
# Phases of the match. Strings, because events, the scene and the suites read them.
const PHASE_MENU := "menu"
const PHASE_AIM := "aim"
const PHASE_MINES := "mines"
const PHASE_FLIGHT := "flight"
const PHASE_SETTLE := "settle"
const PHASE_FINISHED := "finished"
const TURN_TIME := 30.0
# start(opening): draw the first actor from the match rng (real matches).
const RANDOM_OPENING := -1
# Lateral distance a mobile keeps from the world edges (move, teleport, drift).
const WORLD_MARGIN := 24.0
# Wait between the last shell and settling the mobiles.
const RESOLVE_WAIT := 0.55
# Tolerance when comparing the salvo clock with a spawn time.
const TIME_EPSILON := 0.0000001
const SPECIAL_WEAPON := Mobiles.SPECIAL
# Stable mobile IDs are independent of menu slots. Removed ID 0 is not playable.
const PLAYABLE_VEHICLES := Mobiles.PLAYABLE
static var VEHICLES := {}
static var NATIVE_STAGE := {}
var mines: Array = []
var battle_effects: Array = []
var satellites: Dictionary = {}
var projectile_accumulator := 0.0
# Cosmetic native20Hz timestamp, separate from turn/delay/ballistic state.
var spark_tick := 0

static func _static_init() -> void:
	AdukaCombat.warmup()
	MageCombat.warmup()
	LightningCombat.warmup()
	NATIVE_STAGE = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/weather/native_stage.json"))
	Physics.warmup()
	VEHICLES = Mobiles.ALL
var terrain
var actors: Array = []
var projectiles: Array = []
var events: Array = []
var rng := RandomNumberGenerator.new()
var active := 0
var phase := PHASE_MENU
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
# Dual second volley start times; snapshots reconstruct them from their shells.
var volleys: Array = []
# Gold metadata of the shot in flight (GoldTracker); a FlightSnapshot field.
var shot_gold: Dictionary = {}

static func normalize_vehicle(vehicle: int) -> int:
	return Mobiles.normalize(vehicle)

static func other(index: int) -> int:
	return TurnTable.other(index)

func start(vehicle: int, cpu_difficulty: int = 1, seed_value: int = -1, map: String = Maps.DEFAULT, weather_mode: String = "original", mask = null, loadout: Array = [], attributes_by_actor: Array = [], gear_bonuses_by_actor: Array = [], opening: int = PLAYER, cpu_vehicle: int = -1, spawn_override: Array = []) -> void:
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
		# The loading screen passes the points it already showed.
		if spawn_override.size() >= 2:
			spawns[PLAYER] = Vector2(spawn_override[PLAYER])
			spawns[CPU] = Vector2(spawn_override[CPU])
		else:
			for index in [PLAYER, CPU]:
				var options: Array = Maps.spawn_points(Maps.get_map(map_id), index == PLAYER, terrain.world_size().x)
				spawns[index] = options[rng.randi_range(0, options.size() - 1)]
	actors.clear()
	for index in [PLAYER, CPU]:
		# cpu_vehicle < 0 keeps the pairing (1↔2, Nak→Mage, anyone else→Mage).
		var cpu_kind := Mobiles.opponent(vehicle) if cpu_vehicle < 0 else normalize_vehicle(cpu_vehicle)
		var kind := vehicle if index == PLAYER else cpu_kind
		var x: float = spawns[index].x
		# Search from just above the listed spawn so layered maps keep its platform.
		var ground: float = terrain.surface_at(x, maxf(0.0, spawns[index].y - 80.0))
		var spec: Dictionary = Mobiles.definition(kind)
		var values: Array = Attributes.sanitize(attributes_by_actor[index] if index < attributes_by_actor.size() and attributes_by_actor[index] is Array else [])
		# Pilot points plus signed gear modifiers (XFS equipment).
		values = Attributes.with_equipment(values, gear_bonuses_by_actor[index] if index < gear_bonuses_by_actor.size() and gear_bonuses_by_actor[index] is Array else [])
		var max_health := Attributes.health(int(spec.hp), int(values[Attributes.HEALTH]))
		# Equipped items (EquippedButtonBar); the CPU plays without items for now.
		var items: Array = Items.sanitize(loadout) if index == PLAYER else []
		actors.append(ActorState.create(kind, Vector2(x, ground - float(spec.stance)), 1 if index == PLAYER else -1, max_health, int(spec.shield), items, values))
	difficulty = clampi(cpu_difficulty, 0, 2)
	active = PLAYER
	shot_elapsed = 0
	winner = -1
	clock = 0.0
	total_turns = 0
	accumulator = 0.0
	resolve_wait = 0.0
	flight_elapsed = 0.0
	projectile_accumulator = 0.0
	spark_tick = 0
	projectiles.clear()
	mines.clear()
	battle_effects.clear()
	satellites.clear()
	volleys.clear()
	events.clear()
	shot_gold = {}
	last_shots = [{}, {}]
	var mage_climate := actors.any(func(actor):return int(actor.vehicle)==1)
	weather = MageWeather.new() if mage_climate else Weather.new()
	var preset: Array = Maps.get_map(map_id).weather if not map_id.is_empty() else PROCEDURAL_WEATHER
	if weather_mode == "all":
		preset = ALL_WEATHER
	if mage_climate and map_id==Maps.DEFAULT:
		var stage: Dictionary = NATIVE_STAGE.miramo_town_a
		if weather_mode!="all":preset=stage.weights
		for kind in stage.column_ranges:
			weather.spawn_ranges[kind]=[]
			for pair in stage.column_ranges[kind]:
				weather.spawn_ranges[kind].append(Vector2i(pair[0],pair[1]))
	var initial: Dictionary = weather.setup(preset, terrain.world_size(), rng)
	if mage_climate:
		# Seed and room period are explicit offline inputs, not network replay.
		MageWeatherEffects.setup_thor(self,rng.seed)
	else:
		apply_weather(initial)
	for actor_index in actors.size():
		if int(actors[actor_index].vehicle) in [1,8]:
			terrain.enable_native()
		if int(actors[actor_index].vehicle) == 10:
			AsateEffect.ensure_satellite(self,actor_index)
		elif int(actors[actor_index].vehicle) == 16:
			terrain.enable_native()
			AdukaEffect.ensure_thor(self)
	# The server draws the turn order (MatchManager / jglim start_game); fixtures
	# pass an explicit side so their first shot stays the player's.
	active = rng.randi_range(PLAYER, CPU) if opening == RANDOM_OPENING else clampi(opening, PLAYER, CPU)
	begin_turn()

func movement_budget() -> float:
	return float(VEHICLES[actors[active].vehicle].move)

func begin_turn() -> void:
	phase = PHASE_AIM
	cpu_thinking = false
	turn_time = TURN_TIME
	actors[active].turns += 1
	total_turns += 1
	var native_climate: bool = weather.get("is_native")==true
	if native_climate:
		var entry: Dictionary = weather.advance_turn(total_turns-1,rng)
		MageWeatherEffects.transition(self,total_turns)
		weather.eclipse_reset(actors)
		if (total_turns-1)%int(weather.period)==0:apply_weather(entry)
	else:
		if total_turns > 1:
			weather.disturb_wind(rng)
		if total_turns > 1 and (total_turns - 1) % 2 == 0:
			apply_weather(weather.next_round(rng))
	for actor in actors:
		Mobiles.regenerate(actor)
	if native_climate:
		weather.moon_heal(actors[active])
	actors[active].ss_lock = maxi(int(actors[active].ss_lock) - 1, 0)
	movement_left = movement_budget()
	ClassicFlight.walk_mines(self)
	ClassicFlight.detonate_mines(self)
	if check_end():
		return
	wind = weather.wind_vector()
	stamp_tilt()
	if mines.any(func(mine):return bool(mine.get("raon_mine",false)) and bool(mine.get("queued",false))):
		phase = PHASE_MINES
	events.append({"type": "turn", "actor": active})

func stance_of(index: int) -> float:
	return float(Mobiles.definition(int(actors[index].vehicle)).stance)

func stamp_tilt() -> void:
	for index in range(actors.size()):
		actors[index].tilt = body_rotation(index)

func apply_weather(entry: Dictionary) -> void:
	wind = weather.wind_vector()
	if entry.type == "protection" and weather.get("is_native")!=true:
		# WeatherDisplay: Protection regenerates every mobile (HealthRegenerationProtection 35).
		for actor in actors:
			if int(actor.hp) > 0:
				var heal := int(Mobiles.definition(int(actor.vehicle)).protection)
				actor.hp = mini(int(actor.max_hp), int(actor.hp) + Attributes.heal(heal, Attributes.points(actor, Attributes.REGEN)))
	events.append({"type": "weather", "weather": entry.type, "extra": entry.extra, "queue": weather.queue.duplicate(true), "wind_force": weather.wind_force, "wind_angle": weather.wind_angle})

func can_use_special(index: int) -> bool:
	# SS starts open. Firing it adds SS_LOCK; each own turn decrements it.
	# HUD.DisableSS: using an item locks SS for the rest of the turn.
	return int(actors[index].get("ss_lock", 0)) <= 0 and str(actors[index].get("turn_item", "")).is_empty()

## HUD.UnlockItem / WeatherDisplay: the Ignorance weather locks the item bar.
func items_locked() -> bool:
	return weather != null and not weather.queue.is_empty() and str(weather.queue[0].type) == "ignorance"

func can_use_item(index: int, slot: int) -> bool:
	if phase != PHASE_AIM or index != active or items_locked():
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
	actor.ready = maxf(float(actor.ready), clock) + Items.delay(id, Attributes.points(actor, Attributes.ITEM_DELAY))
	var event := {"type": "item", "actor": active, "item": id, "slot": slot, "position": actor.pos}
	ItemEffects.apply_instant(self, actor, Items.definition(id), event)
	events.append(event)
	return true

func move_actor(direction: float, delta: float) -> void:
	if phase != PHASE_AIM or is_zero_approx(direction):
		return
	var actor: Dictionary = actors[active]
	actor.facing = int(signf(direction))
	if movement_left <= 0.0:
		return
	var distance := minf(movement_left, absf(direction) * 60.0 * delta)
	var steps := maxi(1, int(ceil(distance / 2.0)))
	for i in range(steps):
		var dx := signf(direction) * distance / steps
		var next_x := clampf(float(actor.pos.x) + dx, WORLD_MARGIN, terrain.world_size().x - WORLD_MARGIN)
		var floor_y: float = terrain.surface_at(next_x, actor.pos.y + 8.0)
		var next_y := floor_y - stance_of(active)
		if absf(next_x - float(actors[other(active)].pos.x)) < 60.0 or next_y < float(actor.pos.y) - 12.0:
			events.append({"type": "blocked", "actor": active})
			break
		actor.pos = Vector2(next_x, next_y)
		movement_left = maxf(0.0, movement_left - absf(dx))
		if terrain.is_void(floor_y):
			kill_by_fall(active)
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
	return Mobiles.weapon(actors[index].vehicle, weapon, Attributes.points(actors[index], Attributes.SHOT_DELAY))

func aim_limits(index: int, weapon: int = 0) -> Vector2:
	return Mobiles.aim_limits(actors[index].vehicle, weapon)

func shot_velocity_fp(index: int, angle: float, power: float, weapon: int, angle_offset: float = 0.0, power_offset: float = 0.0, native_offset: int = 0) -> Vector2i:
	var limits := aim_limits(index, weapon)
	return Combat.launch_velocity_fp(clampf(angle, limits.x, limits.y) + angle_offset, power, int(actors[index].facing), body_rotation(index), power_offset, Mobiles.force_max(int(actors[index].vehicle)), native_offset)

func shot_velocity(index: int, angle: float, power: float, weapon: int, angle_offset: float = 0.0, power_offset: float = 0.0, native_offset: int = 0) -> Vector2:
	return Vector2(shot_velocity_fp(index, angle, power, weapon, angle_offset, power_offset, native_offset)) / (256.0 * Combat.STEP)

func minimum_power(index: int) -> float:
	return Mobiles.minimum_power(int(actors[index].vehicle))

func normalized_power(index: int, percent: float) -> float:
	var maximum := Mobiles.force_max(int(actors[index].vehicle))
	return Physics.power_percent(Physics.native_power(percent, maximum), maximum)

func projectile_parameters(index: int, angle: float, power: float, weapon: int) -> Array:
	var rules := weapon_rules(index, weapon)
	var result: Array = []
	var vehicle_id := int(actors[index].vehicle)
	var emission: Array = Mobiles.emission(vehicle_id, weapon)
	var spread_after: bool = Mobiles.spread_after_clamp(vehicle_id)
	for component in range(emission.size()):
		var entry: Dictionary = emission[component]
		var initial := muzzle(index, angle if spread_after else angle + float(entry.angle), weapon)
		var native := int(entry.get("native_power", 0))
		var velocity := shot_velocity(index, angle, power, weapon, entry.angle, entry.power, native) if spread_after else shot_velocity(index, angle + float(entry.angle), power, weapon, 0.0, 0.0, native)
		var shell := ShellState.create(initial, velocity, entry.spawn, rules, weapon, component)
		shell.owner = index
		shell.vehicle = vehicle_id
		shell.sound_group = int(entry.get("sound_group", component))
		shell.sound = bool(entry.get("sound", true))
		shell.pose_start_at = float(entry.get("pose_start_at", 0.0))
		# Preserve exact launch integers instead of re-quantizing their float projection.
		shell.launch_velocity_fp = shot_velocity_fp(index, angle, power, weapon, entry.angle, entry.power, native) if spread_after else shot_velocity_fp(index, angle + float(entry.angle), power, weapon, 0.0, 0.0, native)
		ClassicFlight.prepare(shell, entry)
		BoomerFlight.prepare(shell,actors[index])
		AdukaCombat.prepare(shell,actors[index])
		MageCombat.prepare(shell,actors[index])
		LightningCombat.prepare(shell,actors[index])
		result.append(shell)
	return result

## Mobile.ShootWithModifiers: the shells of a shot under this turn's item.
## fire() and predict_shot() both build from here, so the CPU sees the same flight.
func shot_shells(index: int, angle: float, power: float, weapon: int) -> Array:
	var item: String = str(actors[index].get("turn_item", ""))
	var shells := projectile_parameters(index, angle, power, weapon)
	if item.is_empty():
		return shells
	return ItemEffects.modify_shells(self, index, angle, power, weapon, Items.definition(item), shells)

func launch_projectile(projectile: Dictionary) -> void:
	projectile.launched = true
	seed_projectile(projectile)
	# Thor intersects everything: every shell fired while active attaches to it.
	if not bool(projectile.get("child",false)):
		projectile.thor = bool(weather.thor.active)
	events.append({"type": "projectile_launch", "actor": int(projectile.get("owner",shot_actor)), "vehicle": int(projectile.get("vehicle",actors[shot_actor].vehicle)), "weapon": int(projectile.get("weapon", shot_weapon)), "time": projectile.spawn_at, "beacon": bool(projectile.get("beacon", false)), "child":bool(projectile.get("child",false)), "sound": bool(projectile.get("sound", true)), "sound_group": int(projectile.get("sound_group", 0)), "volley": int(projectile.get("volley", 0))})

func seed_projectile(projectile: Dictionary) -> void:
	if bool(projectile.get("fp_ready", false)):
		return
	var force := roundi(wind.length() * float(projectile.get("wind_scale", 1.0)))
	var phi := roundi(-rad_to_deg(wind.angle())) if force > 0 else 0
	var gravity := Mobiles.gravity_native(int(actors[shot_actor].vehicle))
	var velocity: Vector2i = Physics.velocity_fp(projectile.velocity)
	if projectile.has("launch_velocity_fp"):
		var pending: Vector2i = projectile.launch_velocity_fp
		if Vector2(pending) / (256.0 * Combat.STEP) == Vector2(projectile.velocity):
			velocity = pending
	Physics.seed(projectile, Physics.position_fp(projectile.pos), velocity, Physics.acceleration_fp(gravity, force, phi))
	projectile.launch_speed = Vector2(projectile.velocity).length()
	if bool(projectile.get("boomer", false)):
		BoomerFlight.seed(projectile)

func predict_shot(index: int, angle: float, power: float, weapon: int) -> Dictionary:
	var shells := shot_shells(index, angle, power, weapon)
	# Weather, Thor and salvo craters change the flight: always run the real
	# flight loop on isolated copies of mask, actors, wind and weather.
	var simulation = FlightSnapshot.capture(self)
	FlightSnapshot.arm(simulation, index, weapon, shells)
	var closest: Dictionary = {}
	var distance := INF
	# A guide can use its complete lifetime before a satellite starts its
	# own children. The per-shell age guard still limits each flight to12s.
	for frame in range(ceili((Combat.MAX_FLIGHT_AGE * 3.0 + ShellState.last_spawn(shells)) / Combat.STEP) + 1):
		simulation.advance_projectiles(Combat.STEP)
		for event in simulation.events:
			if event.type not in ["explosion", "miss", "teleport", "thor", "mine_plant"]:
				continue
			var score := Vector2(event.position).distance_to(actors[other(index)].pos)
			if score < distance:
				distance = score
				closest = {"position": event.position, "actor": event.get("collided_actor", -1), "hit": event.type != "miss"}
		simulation.events.clear()
		if simulation.phase != PHASE_FLIGHT:
			break
	return closest

func cannon_pivot(index: int) -> Vector2:
	return actors[index].pos + Vector2(0, -14).rotated(body_rotation(index))

func muzzle(index: int, angle: float, weapon: int = 0) -> Vector2:
	if int(actors[index].vehicle) == 6:
		return BoomerFlight.muzzle(Vector2(actors[index].pos),int(actors[index].facing),body_rotation(index))
	return cannon_pivot(index) + shot_velocity(index, angle, 100.0, weapon).normalized() * 38.0

func current_order() -> Array:
	return TurnTable.current_order(self)

func initiative_preview(weapon: int) -> Array:
	return TurnTable.initiative_preview(self, weapon)

func fire(angle: float, power: float, weapon: int) -> bool:
	if phase != PHASE_AIM or weapon < 0 or weapon >= Mobiles.weapon_count(actors[active].vehicle):
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
	power = clampf(power, minimum_power(active), Combat.MAX_POWER)
	last_shots[active] = {"angle": angle, "power": power, "weapon": weapon}
	projectiles.clear()
	projectiles = shot_shells(active, angle, power, weapon)
	shot_gold = GoldTracker.begin(self, angle, power, weapon)
	volleys = second_volley(projectiles)
	phase = PHASE_FLIGHT
	accumulator = 0.0
	flight_elapsed = 0.0
	projectile_accumulator = 0.0
	events.append({"type": "fire", "actor": active, "vehicle": actors[active].vehicle, "weapon": weapon, "item": str(actors[active].get("turn_item", ""))})
	for projectile in projectiles:
		if float(projectile.spawn_at) <= 0.0:
			launch_projectile(projectile)
	return true

## Dual: the second pose starts at its salvo offset; source spawn ticks
## follow it. Pose start must not be delayed to the first emitted component.
static func second_volley(shells: Array) -> Array:
	for shell in shells:
		if int(shell.volley) == 1:
			var start := float(shell.get("pose_start_at", shell.spawn_at))
			for other_shell in shells:
				if int(other_shell.volley) == 1:
					start = minf(start, float(other_shell.get("pose_start_at", other_shell.spawn_at)))
			return [{"time": start, "weapon": int(shell.weapon)}]
	return []

func schedule(index: int, delay: float) -> void:
	TurnTable.schedule(self, index, delay)

func pass_turn() -> void:
	TurnTable.pass_turn(self)

func tick(delta: float) -> void:
	if phase in [PHASE_AIM, PHASE_SETTLE, PHASE_MINES, PHASE_FINISHED]:
		# Placed mines use the same fixed clock even while no shell is flying.
		accumulator += delta
		while accumulator + TIME_EPSILON >= Combat.STEP:
			accumulator = maxf(0.0, accumulator - Combat.STEP)
			spark_tick+=1
			if phase==PHASE_FINISHED:continue
			ClassicFlight.crawl_mines(self, Combat.STEP)
			AsateEffect.step_satellites(self)
			AdukaEffect.step_thor(self)
			if int(actors[PLAYER].hp) <= 0 or int(actors[CPU].hp) <= 0:
				finish_gold_shot()
				check_end()
				return
	if phase == PHASE_MINES:
		if not mines.any(func(mine):return bool(mine.get("raon_mine",false)) and bool(mine.get("queued",false))):
			phase = PHASE_AIM
		return
	if phase == PHASE_AIM:
		if cpu_thinking and active == CPU:
			return
		turn_time = maxf(0.0, turn_time - delta)
		if turn_time <= 0.0:
			pass_turn()
	elif phase == PHASE_FLIGHT:
		accumulator += delta
		while accumulator + TIME_EPSILON >= Combat.STEP and phase == PHASE_FLIGHT:
			accumulator = maxf(0.0, accumulator - Combat.STEP)
			advance_projectiles(Combat.STEP)
	elif phase == PHASE_SETTLE:
		resolve_wait -= delta
		if resolve_wait <= 0.0:
			settle_actors()
			finish_gold_shot()
			if not check_end():
				schedule(shot_actor, TurnTable.shot_cost(self, shot_actor, shot_weapon, shot_elapsed))

func advance_projectiles(delta: float) -> void:
	# Public callers (tests and scene bridges) may pass arbitrary deltas. The
	# model integrates only complete native ticks; never drop a fractional tick.
	projectile_accumulator += delta
	while projectile_accumulator + TIME_EPSILON >= Combat.STEP and phase == PHASE_FLIGHT:
		projectile_accumulator = maxf(0.0, projectile_accumulator - Combat.STEP)
		advance_projectile_tick(Combat.STEP)

func advance_projectile_tick(delta: float) -> void:
	spark_tick+=1
	ClassicFlight.crawl_mines(self, delta)
	AsateEffect.step_satellites(self)
	AdukaEffect.step_thor(self)
	advance_battle_effects()
	stamp_tilt()
	flight_elapsed += delta
	# Dual: OnStartInteracting of the second shot plays the shooting animation.
	if not volleys.is_empty() and flight_elapsed + TIME_EPSILON >= float(volleys[0].time):
		events.append({"type": "volley", "actor": shot_actor, "vehicle": actors[shot_actor].vehicle, "weapon": int(volleys[0].weapon)})
		volleys.pop_front()
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[i]
		var travel_delta := delta
		if not projectile.launched:
			if float(projectile.spawn_at) > flight_elapsed + TIME_EPSILON:
				continue
			launch_projectile(projectile)
			travel_delta = clampf(flight_elapsed - float(projectile.spawn_at), 0.0, delta)
			if travel_delta <= TIME_EPSILON:
				continue
		if ClassicFlight.hold(projectile, travel_delta):
			if ClassicFlight.split_open_shell(self,projectile):
				projectiles.remove_at(i)
			continue
		if bool(projectile.get("chaining", false)):
			if ClassicFlight.tick_chain(projectile, travel_delta):
				if float(projectile.chain_wait) <= 0.0:
					var link: Vector2 = ClassicFlight.advance_chain(projectile)
					explode(link, -1, projectile)
					if int(projectile.chain_left) <= 0:
						projectiles.remove_at(i)
			continue
		seed_projectile(projectile)
		projectile.previous_draw_pos = projectile.pos
		projectile.previous_hit_pos = projectile.hit_pos
		var underground := bool(projectile.get("underground", false))
		var entered_burrow := false
		var next: Dictionary
		# SS change freezes all motion/contact, including a newly entered column.
		if bool(projectile.get("boomer", false)) and not BoomerFlight.advance_state(projectile):
			projectile.age += travel_delta
			continue
		if not underground:
			apply_weather_contact(projectile)
		var native_weather := AdukaWeather.active(projectile)
		var external: bool = not projectile.tornado.is_empty() and not native_weather
		if bool(projectile.get("boomer", false)):
			if not BoomerFlight.begin_tick(projectile, projectile.tornado.is_empty(), false):
				projectile.age += travel_delta
				continue
		else:
			projectile.flight_ticks = int(projectile.get("flight_ticks", 0)) + 1
		if external:
			next = tornado_step(projectile, Combat.STEP)
			Physics.import_external_motion(projectile, next.position, next.velocity)
		else:
			Physics.move(projectile)
			next = {"position": projectile.pos, "velocity": projectile.velocity}
		# Only ignore the firing actor until the shell has cleared its muzzle.
		var ignored := Combat.ignored_shooter(float(projectile.age), shot_actor)
		ClassicFlight.open_shell(projectile)
		var carrier: Vector2 = Combat.sample_position(next.position, next.velocity, float(projectile.age) + travel_delta, projectile.helix, projectile.phase)
		var actual: Vector2 = ClassicFlight.hit_point(projectile, carrier)
		# The teleportation beacon only collides with the ground.
		var beacon := bool(projectile.get("beacon", false))
		var hit: Dictionary
		if native_weather:
			var previous_fp := Physics.position_fp(projectile.hit_pos)
			# MageS2 samples the displaced laser, not its ballistic carrier.
			var actual_fp := Physics.position_fp(actual)
			hit = AdukaCombat.projectile_contact(Vector2i(previous_fp.x>>8,previous_fp.y>>8),Vector2i(actual_fp.x>>8,actual_fp.y>>8),terrain,[] if bool(projectile.get("skip_actors",false)) else actors,projectile,self)
		elif bool(projectile.get("ghost", false)) or underground:
			hit = Combat.trace_actors(projectile.hit_pos, actual, actors, ignored)
			# A buried shell explodes on the first free pixel where it resurfaces.
			if underground:
				var exit: Dictionary = Combat.burrow_exit(terrain, projectile.hit_pos, actual)
				if not exit.is_empty() and (hit.is_empty() or float(exit.fraction) < float(hit.fraction)):
					hit = {"position": exit.position, "actor": -1}
		else:
			var bodies: Array = [] if beacon or bool(projectile.get("skip_actors", false)) else actors
			hit = Combat.trace_segment(projectile.hit_pos, actual, terrain, bodies, ignored)
			# SimulateShot2_Bullet3: the first solid pixel switches the shell to its
			# "special" underground state there and halves the vertical speed.
			if bool(projectile.get("burrow", false)) and not hit.is_empty() and int(hit.actor) < 0:
				projectile.underground = true
				entered_burrow = true
				next.position = hit.position
				next.velocity = Vector2(next.velocity.x, next.velocity.y * Combat.BURROW_ENTRY_DAMPING)
				Physics.import_external_motion(projectile, next.position, next.velocity)
				projectile.fp_acceleration = Vector2i(0, -Physics.quot(Mobiles.gravity_native(int(actors[shot_actor].vehicle)) * 2 * 256, 100))
				projectile.previous_draw_pos = next.position
				projectile.previous_hit_pos = next.position
				actual = hit.position
				hit = {}
				events.append({"type": "burrow", "position": actual})
		var previous: Vector2 = projectile.hit_pos
		projectile.hit_pos = actual
		projectile.age += travel_delta
		projectile.pos = next.position
		projectile.velocity = next.velocity
		projectile.trail.append(projectile.hit_pos)
		if projectile.trail.size() > 28:
			projectile.trail.pop_front()
		if not hit.is_empty():
			if beacon:
				land_beacon(hit.position, previous, projectile)
				projectiles.remove_at(i)
			elif ClassicFlight.begin_chain(projectile, hit.position, float(actors[shot_actor].facing)):
				explode(hit.position, int(hit.actor), projectile)
			else:
				explode(hit.position, int(hit.actor), projectile)
				projectiles.remove_at(i)
		else:
			var accelerate := not native_weather or AdukaWeather.finish(projectile)
			Physics.finish_tick(projectile, not external and not entered_burrow and accelerate)
			ClassicFlight.finish_tick(projectile)
			if bool(projectile.get("boomer", false)):
				BoomerFlight.finish_tick(projectile, not external and accelerate)
		if hit.is_empty() and (Physics.outside(projectile.fp_pos, Vector2i(terrain.world_size())) or projectile.age > Combat.MAX_FLIGHT_AGE):
			events.append({"type": "miss", "position": projectile.hit_pos})
			projectiles.remove_at(i)
	LightningCombat.resolve(self)
	var pending_supermine := mines.any(func(mine):return bool(mine.get("raon_mine",false)) and bool(mine.get("crawl",false)) and int(mine.get("owner",-1)) == shot_actor)
	if projectiles.is_empty() and battle_effects.is_empty() and not pending_supermine:
		phase = PHASE_SETTLE
		resolve_wait = RESOLVE_WAIT

func advance_battle_effects() -> void:
	var asate_owners := {}
	var finished: Array[int] = []
	for effect_index in battle_effects.size():
		var effect: Dictionary = battle_effects[effect_index]
		var alive := false
		if str(effect.kind) == "asate":
			# One Ion belongs to each actor. Dual queues the second request;
			# it cannot advance the same satellite twice in one physical tick.
			if asate_owners.has(int(effect.owner)):
				continue
			asate_owners[int(effect.owner)] = true
			alive = AsateEffect.step(effect,self)
		elif str(effect.kind) == "jd_crystal":
			var event_start := events.size()
			alive = JDEffect.step(effect,actors,mines,terrain,events)
			collect_gold_damage(event_start,Vector2(effect.pos),effect.projectile)
		elif str(effect.kind) == "aduka":
			alive = AdukaEffect.tick(self,effect)
		if not alive:
			finished.append(effect_index)
	finished.reverse()
	for effect_index in finished:
		battle_effects.remove_at(effect_index)
	for mine_index in range(mines.size()-1,-1,-1):
		if bool(mines[mine_index].get("jd_detonate",false)):
			ClassicFlight._detonate_mine(self,mine_index)

func explode(position: Vector2, collided_actor: int = -1, projectile: Dictionary = {}) -> void:
	if LightningCombat.active(projectile):
		LightningCombat.impact(self,projectile,position)
		return
	if AdukaEffect.active(projectile):
		var effect_start := events.size()
		if AdukaEffect.impact(self,projectile,position):
			explode_actions(position,projectile,effect_start)
		return
	if AsateEffect.guide(projectile):
		var guide_start := events.size()
		var effect := AsateEffect.begin(self,projectile,position)
		# Item/weather actions belong to this guide, once. Copying them to
		# every satellite child would multiply Thunder by three or six.
		effect.electric = false
		effect.thor = false
		battle_effects.append(effect)
		explode_actions(position,projectile,guide_start)
		return
	if str(projectile.get("flight","")) == "mine" and not bool(projectile.get("beacon",false)):
		var mine_start := events.size()
		ClassicFlight.plant_mine(self,projectile,position)
		explode_actions(position,projectile,mine_start)
		return
	# Tilt stays as stamped at the start of the step. A crater must not
	# rotate the target before this explosion's damage is measured.
	var event_start := events.size()
	if MageCombat.active(projectile) or BoomerFlight.active(projectile):
		#4572b0/4a4950/483ff0: attached electricity and Thor precede
		# even the SS EMP; shock pending is flushed at the shared tick end.
		MageWeatherEffects.impact(self,projectile,position)
	# Each shell keeps its own weapon (Dual+ mixes S1 and S2 in one turn).
	var weapon_index := int(projectile.get("weapon", shot_weapon))
	var weapon: Dictionary = weapon_rules(shot_actor, weapon_index)
	var item: String = str(actors[shot_actor].get("turn_item", ""))
	# Projectile.Explode: erosion radius × (1 + Owner.Dig / 100) (Bunge Shot).
	var radius := float(weapon.radius)
	if projectile.has("blast_radius"):
		radius = float(projectile.blast_radius)
	var native_aduka := int(projectile.get("vehicle",0))==16 and weapon_index==0 and not bool(projectile.get("beacon",false))
	var native_mage := MageCombat.active(projectile)
	var native_boomer := BoomerFlight.active(projectile)
	var native_data: Dictionary = AdukaCombat.t1_parameters(projectile,actors[shot_actor]) if native_aduka else {}
	if native_mage:
		native_data = MageCombat.parameters(projectile,actors[shot_actor])
	elif native_boomer:
		native_data = BoomerFlight.parameters(projectile,actors[shot_actor])
	var crater_percent := int(projectile.get("mage_crater_percent",100)) if native_mage else int(projectile.get("aduka_crater_percent",100))
	if native_boomer:
		crater_percent = int(projectile.get("boomer_crater_percent",100))
	var crater_dimension := Physics.quot(int(native_data.get("dimension",0))*crater_percent,100)
	var removed: int = terrain.carve_native(AdukaCombat.crater_spans(Vector2i(position),crater_dimension,int(native_data.aspect))) if native_aduka or native_mage or native_boomer else terrain.carve(position, Attributes.crater(radius, Attributes.points(actors[shot_actor], Attributes.DIG) + int(Items.dig(item))))
	var heading := PI * 0.5
	var velocity := Vector2.ZERO
	if projectile.has("velocity"):
		velocity = projectile.velocity
		heading = velocity.angle()
	events.append({"type": "explosion", "position": position, "radius": radius, "weapon": weapon_index, "vehicle": actors[shot_actor].vehicle, "child":bool(projectile.get("child",false)), "ss_state":str(projectile.get("ss_state","normal")), "collided_actor": collided_actor, "removed": removed, "angle": heading})
	if native_mage:
		MageCombat.apply(actors,events,Vector2i(position),projectile,actors[shot_actor])
	elif native_aduka or native_boomer:
		AdukaCombat.apply(actors,events,Vector2i(position),native_data)
	else:
		blast(position, radius, float(maxi(0, int(projectile.get("damage", weapon.damage)))), float(weapon.get("emp", 0)), Items.attack(item), shot_actor)
	if not projectile.is_empty():
		ClassicFlight.bolts(self, projectile, position)
		ClassicFlight.chill(self, projectile, event_start)
		ClassicFlight.plant_mine(self, projectile, position)
		ClassicFlight.burst(self, projectile, position, velocity)
		if str(projectile.get("flight","")) == "crystal":
			var owner := int(projectile.get("owner",shot_actor))
			for index in range(battle_effects.size()-1,-1,-1):
				if str(battle_effects[index].kind) == "jd_crystal" and int(battle_effects[index].owner) == owner:
					battle_effects.remove_at(index)
			battle_effects.append(JDEffect.create(projectile,position,owner))
	explode_actions(position, projectile, event_start)
	if native_boomer:
		detonate_boomer_mines(Vector2i(position), projectile, native_data)

## 450eb0 -> 499650: only the blast, not the flight scan, tests Raon mines.
## The mine's existing blast remains the declared offline bridge. Collect the
## primary shot before this stage so mine credit cannot be counted twice.
func detonate_boomer_mines(impact: Vector2i, projectile: Dictionary, data: Dictionary) -> void:
	var index := 0
	var radius := Physics.quot(int(data.dimension),2) + 10
	while index < mines.size():
		var mine: Dictionary = mines[index]
		if not bool(mine.get("raon_mine",false)) or bool(mine.get("lost",false)):
			index += 1
			continue
		var delta := Vector2i(Vector2(mine.pos).floor()) - impact
		var dx := Physics.quot(delta.x * 100, int(data.aspect))
		if dx * dx + delta.y * delta.y >= radius * radius:
			index += 1
			continue
		mine.owner = int(projectile.get("owner",shot_actor))
		ClassicFlight._detonate_mine(self,index)

## OnExplodeAction order: Thor attached at launch, then Electricity; then the
## Gold metadata of everything this impact dealt.
func explode_actions(position: Vector2, projectile: Dictionary, event_start: int) -> void:
	if not MageCombat.active(projectile) and not BoomerFlight.active(projectile) and bool(projectile.get("thor", false)):
		thor_strike(position)
	if not MageCombat.active(projectile) and not BoomerFlight.active(projectile) and bool(projectile.get("electric", false)):
		lightning_strike(position)
	collect_gold_damage(event_start, position, projectile)

func blast(position: Vector2, radius: float, damage: float, emp: float = 0.0, attack: float = 0.0, shooter: int = -1) -> int:
	return Damage.blast(actors, events, position, radius, damage, emp, attack, shooter)

## TeleportationBeacon.Explode: explode actions (Thor, Electricity) first, then
## the owner moves to previousPosition (the free point just before the contact)
## and stands on the ground below it.
func land_beacon(position: Vector2, previous: Vector2, projectile: Dictionary) -> void:
	explode_actions(position, projectile, events.size())
	var actor: Dictionary = actors[shot_actor]
	if int(actor.hp) <= 0:
		return
	var origin: Vector2 = actor.pos
	var x := clampf(previous.x, WORLD_MARGIN, terrain.world_size().x - WORLD_MARGIN)
	var floor_y: float = terrain.surface_at(x, maxf(0.0, previous.y))
	actor.pos = Vector2(x, floor_y - stance_of(shot_actor))
	events.append({"type": "teleport", "actor": shot_actor, "from": origin, "to": actor.pos, "position": position})
	if terrain.is_void(floor_y):
		kill_by_fall(shot_actor)

## Losing the support below the island eliminates (REQ-05).
func kill_by_fall(index: int) -> void:
	actors[index].hp = 0
	events.append({"type": "fall", "actor": index})

func deal_damage(index: int, damage: int, kind: String = "") -> int:
	return Damage.deal_damage(actors, events, index, damage, kind)

func thor_strike(impact: Vector2) -> void:
	if bool(weather.thor.get("native",false)):
		AdukaEffect.strike(self,{"owner":shot_actor,"weapon":shot_weapon},impact,"weather")
		return
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
	WeatherContact.apply(self, projectile)

func weather_interact(projectile: Dictionary, column: Dictionary) -> void:
	WeatherContact.interact(self, projectile, column)

func tornado_step(projectile: Dictionary, delta: float) -> Dictionary:
	return WeatherContact.tornado_step(self, projectile, delta)

# Movement.ApplyGravity (Parameter.cs TankMovementInitialGravity/GravityFactor).
const FALL_INITIAL_SPEED := 3.0
const FALL_SPEED_STEP := 0.15
const FALL_WIND_DIVISOR := 45.0

func drift_fall(actor: Dictionary, drop: float) -> void:
	# The offline fall and wall check remain approximations. Other mobiles keep
	# ADR-077; Boomer uses the client's integer wind accumulation per step.
	# Vertical steps fall int(GravitySpeed) px (starting at 3, +0.15 per step).
	var x := float(actor.pos.x)
	var y := float(actor.pos.y)
	var remaining := drop
	var speed := FALL_INITIAL_SPEED
	var boomer_fall := int(actor.get("vehicle",0)) == 6
	var remainder := 0
	var wind_force := roundi(wind.length())
	var wind_angle := roundi(-rad_to_deg(wind.angle())) if wind_force > 0 else 0
	while remaining > 0.0:
		var fall := minf(float(int(speed)), remaining)
		var delta := wind.x / FALL_WIND_DIVISOR
		if boomer_fall:
			var wind_step := BoomerFlight.fall_wind_step(remainder,wind_force,wind_angle)
			delta = float(wind_step.x)
			remainder = wind_step.y
		var next := clampf(x + delta, WORLD_MARGIN, terrain.world_size().x - WORLD_MARGIN)
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
			kill_by_fall(index)
	stamp_tilt()

func check_end() -> bool:
	return TurnTable.check_end(self)

func choose_cpu_shot() -> Dictionary:
	var plan := begin_cpu_plan()
	search_cpu_plan(plan)
	return finish_cpu_plan(plan)

## CPU aim (REQ-32/ADR-053) lives in CpuPlanner; search runs on the snapshot only.
func begin_cpu_plan() -> Dictionary:
	return CpuPlanner.begin(self)

static func search_cpu_plan(plan: Dictionary) -> void:
	CpuPlanner.search(plan)

static func score_cpu_shot(plan: Dictionary, angle: int, power: int) -> void:
	CpuPlanner.score(plan, angle, power)

func finish_cpu_plan(plan: Dictionary) -> Dictionary:
	return CpuPlanner.finish(self, plan)

func collect_gold_damage(event_start: int, impact: Vector2, projectile: Dictionary) -> void:
	GoldTracker.collect(self, event_start, impact, projectile)

func finish_gold_shot() -> void:
	GoldTracker.finish(self)

func player_gold_reward() -> int:
	return GoldTracker.player_reward(self, PLAYER)
