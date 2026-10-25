extends RefCounted
## Generated EPA/MainAction timeline, loaded once as Mobiles initializes on the
## main thread. CPU workers only read this immutable catalog (no filesystem IO).
const STEP := 0.05
static var records: Dictionary = {}

static func prewarm() -> void:
	if not records.is_empty():
		return
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/classic/shot_timing.json"))
	for row in source.records:
		if not records.has(int(row.game_id)):
			records[int(row.game_id)] = {}
		records[int(row.game_id)][int(row.weapon)] = row

static func shot(vehicle: int, weapon: int) -> Dictionary:
	return records.get(vehicle, {}).get(weapon, {})

static func pose_duration(vehicle: int, weapon: int) -> float:
	return float(shot(vehicle, weapon).get("pose_ticks", 20)) * STEP

## Keep existing geometry/phase and power offsets; source spawn groups alone
## control timing and component count. Sequential groups repeat that geometry.
static func emission(vehicle: int, weapon: int, geometry: Array) -> Array:
	var source := shot(vehicle, weapon)
	if source.is_empty():
		return geometry
	var result: Array = []
	var cursor := 0
	for group in source.spawn_ticks.size():
		for component in int(source.components_per_spawn[group]):
			var entry: Dictionary = geometry[cursor % geometry.size()].duplicate(true)
			entry.spawn = int(source.spawn_ticks[group]) * STEP
			entry.sound_group = group
			entry.sound = component == 0
			entry.pose_start_at = 0.0
			result.append(entry)
			cursor += 1
	return result

static func stream(vehicle: int, weapon: int, role: String) -> AudioStream:
	var resource := str(shot(vehicle, weapon).get("sounds", {}).get(role, {}).get("resource", ""))
	# ResourceLoader shares imported PCM with the scene's owning sprite. Keeping
	# those Resources in a static Dictionary would retain them past scene exit.
	# Explicit empty PCM preserves source silence, bypassing Sound's synth fallback.
	return load(resource) if not resource.is_empty() and ResourceLoader.exists(resource) else AudioStreamWAV.new()

## Durations are EPA ticks; looping/clamping is chosen by the caller's state.
static func frame(frames: Array, durations: Array, age: float, looping: bool = true) -> int:
	if frames.is_empty():
		return 0
	var total := 0
	for duration in durations:
		total += maxi(1, int(duration))
	if total <= 0:
		total = frames.size()
	var tick := maxi(0, int(floor((age + 0.000001) / STEP)))
	tick = tick % total if looping else mini(tick, total - 1)
	for index in frames.size():
		var duration := maxi(1, int(durations[index])) if index < durations.size() else 1
		if tick < duration:
			return int(frames[index])
		tick -= duration
	return int(frames[-1])
