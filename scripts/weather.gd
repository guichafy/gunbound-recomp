extends RefCounted
## OpenBound weather, wind and Thor state (MatchMetadata.cs, WeatherDisplay.cs,
## WeatherHandler.cs, WeatherEffect/*.cs, ThorSatellite.cs). Pure model data:
## live shots and CPU prediction apply the same rules on independent copies.
## Copyright (C) 2020, Carlos H.M.S.; reference logic GPL-3.0-or-later.

# Map.cs WeatherPreset order.
const TYPES := ["force", "tornado", "electricity", "wind", "weakness", "protection", "ignorance", "thor", "mirror", "random"]
const RANDOMIZABLE := ["force", "tornado", "electricity", "weakness", "mirror"]
# Column half-widths from each Weather constructor (collisionRectangleOffset.X).
const HALF_WIDTH := {"force": 20.0, "tornado": 35.0, "electricity": 20.0, "weakness": 20.0, "mirror": 20.0, "random": 40.0}
const OUTER_MARGIN := 10.0
# NetworkObjectParameters: wind 0–35, disturbance ±2 force / ±3 degrees, 50% skip.
const MAX_WIND := 35
const WIND_FORCE_DISTURBANCE := 4
const WIND_ANGLE_DISTURBANCE := 6
# Thor: x 10–90%, y 10–70% of the map; damage 40 + 20/level, XP table.
const THOR_TABLE := [800, 1400, 2000, 2400, 3000]
const THOR_RADIUS := 25.0
const THOR_BASE_DAMAGE := 40
const THOR_DAMAGE_PER_LEVEL := 20
# Electricity: lightning crater 10 with no damage; shock 30 within 30 of the beam.
const LIGHTNING_RADIUS := 10.0
const LIGHTNING_SHOCK_RADIUS := 30.0
const LIGHTNING_SHOCK_DAMAGE := 30
const TORNADO_MIN_SPEED := 25.0
const PROTECTION_HEAL := 35
const DISPLAYED := 4

var world := Vector2(1280, 800)
var weights: Array = []
# WeatherDisplay keeps four entries: queue[0] is active, the rest are the forecast.
var queue: Array = []
var columns: Array = []
var next_id := 0
var wind_force := 0
var wind_angle := 0
var thor := {"active": false, "pos": Vector2.ZERO, "level": 1, "xp": 0}

func setup(preset: Array, world_size: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	weights = preset.duplicate()
	world = world_size
	queue.clear()
	columns.clear()
	thor = {"active": false, "pos": Vector2.ZERO, "level": 1, "xp": 0}
	# Adaptation: the original starts windless; training starts with a Wind draw.
	change_wind(rng)
	for i in range(DISPLAYED):
		queue.append(draw_entry(rng))
	return process_active(rng, "")

func next_round(rng: RandomNumberGenerator) -> Dictionary:
	# MatchMetadata.PassTurn: enqueue one, the oldest leaves and the next applies.
	var previous: String = queue[0].type
	queue.append(draw_entry(rng))
	queue.pop_front()
	return process_active(rng, previous)

func draw_entry(rng: RandomNumberGenerator) -> Dictionary:
	var total := 0
	for weight in weights:
		total += int(weight)
	var entry := {"type": "wind", "x": 0.5, "y": 0.5, "extra": ""}
	if total <= 0:
		return entry
	var value := rng.randi_range(0, total - 1)
	for index in range(TYPES.size()):
		value -= int(weights[index])
		if value < 0:
			entry.type = TYPES[index]
			break
	if entry.type in ["force", "tornado", "electricity", "weakness", "mirror", "random", "thor"]:
		entry.x = rng.randf()
		entry.y = rng.randf()
		if entry.type == "random":
			entry.extra = RANDOMIZABLE[rng.randi_range(0, RANDOMIZABLE.size() - 1)]
		if entry.type == "thor":
			entry.x = 0.1 + entry.x * 0.8
			entry.y = 1.0 - (0.3 + entry.y * 0.6)
	return entry

func process_active(rng: RandomNumberGenerator, previous: String) -> Dictionary:
	var entry: Dictionary = queue[0]
	disturb_wind(rng)
	if entry.type == "wind":
		change_wind(rng)
	# ApplyCurrentWeatherEffect: a new type wipes the others (Thor deactivates).
	if previous != entry.type:
		for i in range(columns.size() - 1, -1, -1):
			if columns[i].type != entry.type:
				columns.remove_at(i)
		if entry.type != "thor":
			thor.active = false
	if HALF_WIDTH.has(entry.type):
		add_column(entry.type, float(entry.x) * world.x, 1.0, entry.extra)
	elif entry.type == "thor":
		thor.active = true
		thor.pos = Vector2(float(entry.x) * world.x, float(entry.y) * world.y)
	return entry

func disturb_wind(rng: RandomNumberGenerator) -> void:
	if rng.randf() <= 0.5:
		return
	wind_force = maxi(0, wind_force + rng.randi_range(0, WIND_FORCE_DISTURBANCE - 1) - WIND_FORCE_DISTURBANCE / 2)
	wind_angle = (wind_angle + rng.randi_range(0, WIND_ANGLE_DISTURBANCE - 1) - WIND_ANGLE_DISTURBANCE / 2) % 360

func change_wind(rng: RandomNumberGenerator) -> void:
	wind_force = rng.randi_range(0, MAX_WIND - 1)
	wind_angle = rng.randi_range(0, 359)

func wind_vector() -> Vector2:
	# Screen angle (y down) times force; Combat scales it by its WIND_ACCELERATION.
	return Vector2(cos(deg_to_rad(wind_angle)), sin(deg_to_rad(wind_angle))) * float(wind_force)

func add_column(type: String, x: float, scale: float, extra: String = "") -> Dictionary:
	# WeatherHandler.CheckAndMergeWeatherEffects: overlapping same-type columns
	# merge at the mean position with summed scale; Random never merges.
	var column := {"id": next_id, "type": type, "x": x, "scale": scale, "extra": extra, "used": false}
	next_id += 1
	if type != "random":
		var merged := true
		while merged:
			merged = false
			for i in range(columns.size()):
				var other: Dictionary = columns[i]
				if other.type == type and absf(other.x - column.x) <= outer_half(other) + outer_half(column):
					column.x = (other.x + column.x) * 0.5
					column.scale = float(other.scale) + float(column.scale)
					columns.remove_at(i)
					merged = true
					break
	columns.append(column)
	return column

func inner_half(column: Dictionary) -> float:
	return float(HALF_WIDTH[column.type]) * float(column.scale)

func outer_half(column: Dictionary) -> float:
	return inner_half(column) + OUTER_MARGIN

func inside_inner(column: Dictionary, point: Vector2) -> bool:
	return absf(point.x - float(column.x)) <= inner_half(column) and point.y >= 0.0 and point.y <= world.y

func inside_outer(column: Dictionary, point: Vector2) -> bool:
	return absf(point.x - float(column.x)) <= outer_half(column) and point.y >= -OUTER_MARGIN and point.y <= world.y + OUTER_MARGIN

func find_column(id: int) -> Dictionary:
	for column in columns:
		if int(column.id) == id:
			return column
	return {}

func thor_damage() -> int:
	return THOR_BASE_DAMAGE + THOR_DAMAGE_PER_LEVEL * int(thor.level)

func gain_thor_experience(amount: int) -> void:
	# ThorSatellite.GainExperience: level is the first threshold not yet passed.
	if amount <= 0:
		return
	thor.xp = int(thor.xp) + amount
	var last := THOR_TABLE.size() - 1
	var level := last + 1 if int(thor.xp) < int(THOR_TABLE[last]) else last + 2
	for i in range(last):
		if int(thor.xp) <= int(THOR_TABLE[i]):
			level = i + 1
			break
	thor.level = level

func copy():
	var result = get_script().new()
	result.world = world
	result.weights = weights.duplicate()
	result.queue = queue.duplicate(true)
	result.columns = columns.duplicate(true)
	result.next_id = next_id
	result.wind_force = wind_force
	result.wind_angle = wind_angle
	result.thor = thor.duplicate(true)
	return result
