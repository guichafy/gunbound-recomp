extends "res://tests/tools/shot_damage_audit/probe.gd"
## Observes existing offline battle paths on a controlled map, with real fire and
## a separately armed FlightSnapshot. Weather positions and seeds are fixtures.

const Climate = preload("res://scripts/mage_weather.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Items = preload("res://scripts/items.gd")
const Maps = preload("res://scripts/maps.gd")
const WEATHER_THOR_SOURCES := ["weather", "mage_weather", "bigfoot_weather", "boomer_weather"]
const TICK_BUDGET := 760
var confirmed := 0
var failures := 0

func verify(ok: bool, message: String) -> void:
	confirmed += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func configure_turn(model, weapon: int, angle: float, category: String, strength: int, heading: int) -> Dictionary:
	# Run a real turn boundary with deterministic climate and column placement.
	# The chosen slot keeps the pre-oscillation force legal at 0 and 26.
	model.total_turns = 4 if strength == 26 else 0
	model.weather.last_turn = -1
	model.weather.calendar.fill(Climate.NATIVE_TYPES.find(category) if category != "neutral" else 3)
	model.weather.columns.clear()
	model.weather.thor.transition_turn = -1
	model.weather.wind_force = strength - int(Climate.WIND_OSCILLATION[model.total_turns % 8])
	model.weather.next_wind_force = model.weather.wind_force
	model.weather.wind_angle = heading
	model.weather.next_wind_delta = 0
	model.rng.seed = 42
	model.actors[0].hp = 200
	model.actors[1].hp = 300
	var healing: int = int(Mobiles.definition(int(model.actors[0].vehicle)).hp_regen)
	var moon_percent := 8 if (int(Shared.body(model.actors[0]).flags) & 2) != 0 else 3
	var maximum := int(model.actors[0].max_hp)
	var hp_without_moon := mini(maximum, 200 + healing)
	var hp_with_moon := mini(maximum, hp_without_moon + Physics.quot(maximum * moon_percent, 100))
	var inventory := Items.sanitize(["dual", "dual_plus"]).map(func(id): return {"id": id, "used": false})
	model.actors[0].items = inventory.duplicate(true)
	if category == "ignorance":
		model.actors[0].turn_item = "dual"
		model.actors[1].turn_item = "dual_plus"
	if category in ["force", "tornado", "electricity"]:
		var x: int = floori(model.muzzle(0, angle, weapon).x + 7.0 * float(model.actors[0].facing))
		var ranges: Array[Vector2i] = []
		ranges.resize(8)
		ranges.fill(Vector2i(x, x + 1))
		model.weather.spawn_ranges[category] = ranges
	if category == "thor":
		# Position the satellite in air so its line can reach the flat range.
		model.weather.thor.pos = Vector2(480, 180)
	model.begin_turn()
	var moon_gained := int(model.actors[0].hp) - hp_without_moon
	return {
		"active": model.weather.queue[0].type,
		"wind_force": model.weather.wind_force,
		"wind_angle": model.weather.wind_angle,
		"columns": model.weather.columns.duplicate(true),
		"moon_hp": moon_gained,
		"moon_expected": hp_with_moon - hp_without_moon if category == "protection" else 0,
		"moon_has_protection_flag": bool(model.actors[0].get("native_protection", false)),
		"eclipse_locked": model.items_locked(),
		"eclipse_rejects_dual": not model.use_item(0) if category == "ignorance" else false,
		"eclipse_preserves_inventory": model.actors[0].items == inventory,
		"eclipse_clears_both": str(model.actors[0].turn_item).is_empty() and str(model.actors[1].turn_item).is_empty(),
		"ss_ready": model.can_use_special(0),
		"thor_active": bool(model.weather.thor.active),
	}

func observe_events(events: Array, category: String, tick: int, metrics: Dictionary, trace: Array) -> void:
	for event in events:
		if event.type in ["weather_hit", "thor", "lightning", "mobile_lightning", "explosion", "damage", "shield_damage", "fall"]:
			var point: Vector2 = event.get("position", Vector2.ZERO)
			trace.append({
				"tick": tick, "type": event.type, "pixel": [point.x, point.y] if event.has("position") else [],
				"weapon": event.get("weapon"), "source": event.get("source"), "actor": event.get("actor"),
				"amount": event.get("amount"), "weather": event.get("weather"), "removed": event.get("removed"),
			})
		match event.type:
			"projectile_launch":
				metrics.launches += 1
			"weather_hit":
				if event.weather == category:
					metrics.column_hits += 1
			"thor":
				if str(event.get("source", "aduka")) in WEATHER_THOR_SOURCES:
					metrics.weather_thor += 1
					metrics.thor_contacts += int(bool(event.get("contact", false)))
				else:
					metrics.weapon_thor += 1
			"lightning":
				metrics.weather_lightning += 1
			"mobile_lightning":
				if str(event.get("source", "")) == "weather":
					metrics.weather_lightning += 1
			"explosion":
				metrics.explosions += 1
				metrics.actor_impacts += int(int(event.get("collided_actor", -1)) == 1)
			"damage", "shield_damage":
				if int(event.get("actor", -1)) == 1:
					var amount := int(event.get("amount", 0))
					metrics.target_damage_events += 1
					metrics.target_damage_event_sum += amount
					metrics.target_damage_event_peak = maxi(metrics.target_damage_event_peak, amount)

func compare_flight(base, shooter: int, weapon: int, category: String, strength: int, heading: int, scenario: String = "range", item: String = "") -> Dictionary:
	var model = Snapshot.capture(base)
	var limits: Vector2 = model.aim_limits(0, weapon)
	var angle := limits.x
	const POWER := 35.0
	var turn := configure_turn(model, weapon, angle, category, strength, heading)
	if not item.is_empty():
		model.actors[0].items = Items.sanitize([item]).map(func(id): return {"id": id, "used": false})
		var activated: bool = model.use_item(0)
		verify(activated == (category != "ignorance"), "%s item activation in %s" % [item, category])
		turn.item = item
		turn.item_activated = activated
	var hp: int = model.actors[1].hp
	var shield: int = model.actors[1].shield
	var sim = Snapshot.capture(model)
	var shells: Array = model.shot_shells(0, angle, POWER, weapon)
	Snapshot.arm(sim, 0, weapon, shells)
	model.events.clear()
	var fired: bool = model.fire(angle, POWER, weapon)
	var metrics := {
		"launches": 0, "column_hits": 0, "weather_thor": 0, "thor_contacts": 0,
		"weapon_thor": 0, "weather_lightning": 0, "explosions": 0, "actor_impacts": 0,
		"target_damage_events": 0, "target_damage_event_sum": 0, "target_damage_event_peak": 0,
		"native_force_peak": 0, "tornado_turns_peak": 0, "wind_seeded": false,
		"launch_accelerations": [],
	}
	# Match.fire installs the shot's Gold accounting and SS lock. Arm the
	# snapshot independently, then align this metadata to compare resolution.
	sim.shot_gold = model.shot_gold.duplicate(true)
	sim.actors[0].ss_lock = model.actors[0].ss_lock
	for shell in sim.projectiles:
		if float(shell.spawn_at) <= 0.0:
			sim.launch_projectile(shell)
	var first_difference := -1
	var trace: Array = []
	var electric_seeded := false
	var calm := Physics.acceleration_fp(Mobiles.gravity_native(shooter), 0, 0)
	for tick in range(TICK_BUDGET + 1):
		if tick == 0:
			model.events = model.events.filter(func(event): return event.type != "fire")
		else:
			model.advance_projectiles(Physics.STEP)
			sim.advance_projectiles(Physics.STEP)
		observe_events(model.events, category, tick, metrics, trace)
		for shell in model.projectiles:
			metrics.native_force_peak = maxi(metrics.native_force_peak, int(shell.get("native_force", 0)))
			metrics.tornado_turns_peak = maxi(metrics.tornado_turns_peak, int(shell.get("tornado", {}).get("turns", 0)))
			if bool(shell.launched) and bool(shell.fp_ready) and is_zero_approx(float(shell.age)) and not bool(shell.get("child", false)):
				electric_seeded = electric_seeded or bool(shell.electric)
				var acceleration: Vector2i = shell.fp_acceleration
				var components := [acceleration.x, acceleration.y]
				if components not in metrics.launch_accelerations:
					metrics.launch_accelerations.append(components)
				metrics.wind_seeded = metrics.wind_seeded or acceleration != calm
		if first_difference < 0 and (
			model.events != sim.events or model.projectiles != sim.projectiles or
			model.actors != sim.actors or model.weather.thor != sim.weather.thor or
			model.shot_gold != sim.shot_gold or model.mines != sim.mines or
			model.terrain.revision != sim.terrain.revision or model.phase != sim.phase
		):
			first_difference = tick
		model.events.clear()
		sim.events.clear()
		if model.phase != Match.PHASE_FLIGHT:
			break
	var terminal_equal: bool = (
		model.terrain.cells == sim.terrain.cells and model.terrain.native_cells == sim.terrain.native_cells and
		model.weather.columns == sim.weather.columns and model.battle_effects == sim.battle_effects and
		model.satellites == sim.satellites
	)
	metrics.snapshot_equal = first_difference < 0 and terminal_equal
	metrics.first_snapshot_difference = first_difference
	metrics.terminated = model.phase != Match.PHASE_FLIGHT
	metrics.hp_lost = hp - int(model.actors[1].hp)
	metrics.shield_lost = shield - int(model.actors[1].shield)
	metrics.target_reported_minus_loss = int(metrics.target_damage_event_sum) - int(metrics.hp_lost) - int(metrics.shield_lost)
	if int(metrics.target_damage_event_sum) >= 600:
		metrics.high_damage_trace = trace
	metrics.merge({
		"shooter": shooter, "weapon": weapon, "category": category, "turn": turn,
		"facing": int(base.actors[0].facing), "scenario": scenario,
	})
	var label := "%s id=%d weapon=%d climate=%s wind=%s/%s" % [scenario, shooter, weapon, category, strength, heading]
	verify(fired and metrics.terminated and metrics.launches > 0, label + " finite real launch")
	verify(metrics.snapshot_equal, label + " exact replay")
	verify(turn.active == (category if category != "neutral" else "wind"), label + " real turn selection")
	verify(turn.wind_force == strength and turn.wind_angle == heading, label + " effective wind")
	verify(turn.moon_hp == turn.moon_expected, label + " measured Moon heal")
	verify(turn.thor_active == (category == "thor"), label + " Thor state")
	if category == "ignorance":
		verify(turn.eclipse_locked and turn.eclipse_rejects_dual and turn.eclipse_preserves_inventory and turn.eclipse_clears_both and turn.ss_ready, label + " Eclipse")
	if category in ["force", "tornado", "electricity"]:
		verify(turn.columns.size() == 1 and turn.columns[0].type == category, label + " spawned column")
		if category == "electricity" and item == "thunder":
			verify(electric_seeded, label + " Thunder already attached electricity at launch")
		else:
			verify(metrics.column_hits > 0, label + " consumed column")
	if category == "wind":
		# The Teleport beacon has zero wind multiplier.
		verify(metrics.wind_seeded == (item != "teleport"), label + " observed expected initial acceleration")
	if category == "neutral":
		verify(not metrics.wind_seeded and not metrics.launch_accelerations.is_empty(), label + " observed calm initial projectile acceleration")
	return metrics

func verify_map_calendar() -> Array:
	var rows: Array = []
	verify(Maps.available_ids().size() == 22, "22 classic map sides available")
	for map_id in Maps.available_ids():
		for mode in ["original", "all"]:
			var model = Match.new()
			model.start(4, 1, 42, map_id, mode)
			var calendar: Array = model.weather.calendar.duplicate()
			var preset := Maps.native_weather(Maps.get_map(map_id))
			var expected: Array = [1, 1, 1, 1, 1, 1, 1]
			if mode == "original":
				expected = Climate.LEGACY_INDICES.map(func(index): return int(preset[index])) if preset.size() >= 10 else preset.map(func(value): return int(value))
			verify(model.map_id == map_id and model.weather.weights == expected, map_id + "/" + mode + " initial map and weights")
			var generated := 0
			var seen: Dictionary = {}
			for index in 18:
				var cursor := ((index >> 1) * 3) & 1023
				var slot := (index >> 1) & 7
				if index > 0:
					model.events.clear()
					model.active = index & 1
					model.begin_turn()
				var entry: Dictionary = model.weather.queue[0]
				var category: String = Climate.NATIVE_TYPES[int(calendar[slot])]
				var label := "%s/%s turn=%d" % [map_id, mode, index]
				seen[category] = int(seen.get(category, 0)) + 1
				verify(model.weather.calendar == calendar and model.weather.random_cursor == ((cursor + 3) & 1023), label + " untouched calendar and RNG cursor")
				var forecast: Array = []
				for offset in 4:
					forecast.append(Climate.NATIVE_TYPES[int(calendar[(slot + offset) & 7])])
				verify(model.weather.queue.map(func(item): return item.type) == forecast, label + " active and forecast")
				verify(model.weather.wind_force >= 0 and model.weather.wind_force <= 26 and model.wind == model.weather.wind_vector(), label + " legal wind propagated")
				verify(model.weather.thor.active == (category == "thor"), label + " Thor follows boundary")
				verify(model.weather.columns.all(func(col): return col.type == category), label + " owned climate columns")
				if (index & 1) == 0 and category in ["force", "tornado", "electricity"]:
					generated += 1
					var range_slot: int = int(model.weather.random_table[cursor]) & 7
					var bounds: Vector2i = model.weather.spawn_ranges[category][range_slot]
					var value: int = int(entry.get("native_x", -1))
					var width: int = int(entry.get("native_width", -1))
					var upper := maxi(bounds.x + 1, bounds.y)
					verify(bounds.x <= value and value < upper and width >= 64 and width <= 127, label + " spawned inside selected DAT range")
			rows.append({"map": map_id, "mode": mode, "turns": 18, "column_spawns": generated, "category_turns": seen})
	return rows

func verify_nak_contact() -> Array:
	# Nak SS ignores terrain. A separate elevated target on its line shows
	# attached rays at a real mobile impact, absent from the flat-range probe.
	var base = fixture(3, 4, 30)
	base.actors[1].pos.x = 265.0
	var rows: Array = []
	for category in ["electricity", "thor"]:
		var row := compare_flight(base, 3, 2, category, 13, 60, "nak_close")
		verify(row.actor_impacts > 0, "Nak SS hits an elevated target")
		verify((row.weather_lightning if category == "electricity" else row.weather_thor) > 0, "Nak SS triggers " + category + " after hitting a target")
		rows.append(row)
	return rows

func run_target_matrix() -> void:
	var categories: Array = ["neutral"] + Climate.NATIVE_TYPES
	var cases := 0
	for shooter in Mobiles.PLAYABLE:
		for target in Mobiles.PLAYABLE:
			var base = fixture(shooter, target)
			for weapon in 3:
				for category in categories:
					var strength := 0 if category == "neutral" else 13
					var row := compare_flight(base, shooter, weapon, category, strength, 60, "target_matrix")
					row.target = target
					cases += 1
					print("WEATHER_ROW ", JSON.stringify(row))
	print("WEATHER_CHECKS ", JSON.stringify({"cases": cases, "checks": confirmed, "failures": failures}))
	quit(0 if failures == 0 else 2)

func run_auxiliary() -> void:
	var map_cases := 0
	for map_id in Maps.available_ids():
		var model = Match.new()
		model.start(4, 1, 42, map_id, "original", null, [], [], [], 0, 2)
		verify(model.map_id == map_id and not model.terrain.native_cells.is_empty(), map_id + " native mask")
		var row := compare_flight(model, 4, 0, "neutral", 0, 60, "native_map")
		row.map = map_id
		map_cases += 1
		print("WEATHER_ROW ", JSON.stringify(row))
	var item_cases := 0
	var categories: Array = ["neutral"] + Climate.NATIVE_TYPES
	for shooter in Mobiles.PLAYABLE:
		var base = fixture(shooter, 4)
		for weapon in 2:
			for item in ["dual", "dual_plus", "thunder", "teleport", "bunge_shot"]:
				for category in categories:
					var strength := 0 if category == "neutral" else 13
					var row := compare_flight(base, shooter, weapon, category, strength, 60, "items", item)
					item_cases += 1
					print("WEATHER_ROW ", JSON.stringify(row))
	print("WEATHER_CHECKS ", JSON.stringify({"cases": map_cases + item_cases, "native_maps": map_cases,
		"item_cases": item_cases, "checks": confirmed, "failures": failures}))
	quit(0 if failures == 0 else 2)

func run() -> void:
	if OS.get_cmdline_user_args().has("--all-targets"):
		run_target_matrix()
		return
	if OS.get_cmdline_user_args().has("--maps-items"):
		run_auxiliary()
		return
	var rows: Array = []
	var categories: Array = ["neutral"] + Climate.NATIVE_TYPES
	for shooter in Mobiles.PLAYABLE:
		var base = fixture(shooter, 4)
		for facing in [1, -1]:
			if facing < 0:
				for actor in base.actors:
					actor.pos.x = base.terrain.world_size().x - actor.pos.x
					actor.facing = -int(actor.facing)
			for weapon in 3:
				for category in categories:
					var strength := 0 if category == "neutral" else 13
					rows.append(compare_flight(base, shooter, weapon, category, strength, 60))
				# Exercise both signs of the cardinal wind axes at low and high force.
				for wind in [Vector2i(1, 0), Vector2i(26, 90), Vector2i(26, 180), Vector2i(26, 270)]:
					rows.append(compare_flight(base, shooter, weapon, "wind", wind.x, wind.y))
	rows.append_array(verify_nak_contact())
	for row in rows:
		print("WEATHER_ROW ", JSON.stringify(row))
	var maps := verify_map_calendar()
	for map_row in maps:
		print("WEATHER_MAP ", JSON.stringify(map_row))
	print("WEATHER_CHECKS ", JSON.stringify({
		"cases": rows.size(), "maps_modes": maps.size(), "map_turns": maps.size() * 18,
		"checks": confirmed, "failures": failures,
	}))
	quit(0 if failures == 0 else 2)
