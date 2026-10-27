extends "res://tests/support/suite.gd"
## REQ-23/24/25: legacy OpenBound weather in matches without Mage.
## Native Mage coverage: test_mage_weather / test_mage_secondary_weather.
func run() -> void:
	var Weather = load("res://scripts/weather.gd")
	var Match = load("res://scripts/match.gd")
	var Maps = load("res://scripts/maps.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Draws follow the Miramo A preset: zero-weight types never appear.
	var weather = Weather.new()
	weather.setup(Maps.get_map(Maps.DEFAULT).weather, Vector2(1800, 1800), rng)
	check(weather.queue.size() == 4, "WeatherDisplay keeps the active weather plus three forecasts")
	var counts := {}
	for i in range(3000):
		var entry: Dictionary = weather.draw_entry(rng)
		counts[entry.type] = int(counts.get(entry.type, 0)) + 1
	var forbidden := false
	for type in ["weakness", "ignorance", "thor", "mirror"]:
		forbidden = forbidden or counts.has(type)
	check(not forbidden, "Zero-weight weathers never appear on Miramo A")
	check(absf(float(counts.get("force", 0)) / 3000.0 - 0.2) < 0.03 and absf(float(counts.get("random", 0)) / 3000.0 - 0.1) < 0.03, "Draw frequencies follow the preset weights")
	var thor_entry := {}
	var random_entry := {}
	weather.weights = [0, 0, 0, 0, 0, 0, 0, 1, 0, 1]
	for i in range(200):
		var entry: Dictionary = weather.draw_entry(rng)
		if entry.type == "thor":
			thor_entry = entry
		else:
			random_entry = entry
	check(thor_entry.x >= 0.1 and thor_entry.x <= 0.9 and thor_entry.y >= 0.1 and thor_entry.y <= 0.7, "Thor spawns within x 10–90% and y 10–70%")
	check(random_entry.extra in Weather.RANDOMIZABLE, "Random carries a randomizable extra weather")

	# Wind: 0–35 force and 0–360 angle; per-round disturbance is at most ±2/±3.
	weather.weights = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var bounded := true
	for i in range(200):
		var force: int = weather.wind_force
		var angle: int = weather.wind_angle
		weather.next_round(rng)
		bounded = bounded and absi(weather.wind_force - force) <= 2 and mini(posmod(weather.wind_angle - angle, 360), posmod(angle - weather.wind_angle, 360)) <= 3 and weather.wind_angle >= 0 and weather.wind_angle < 360 and weather.wind_force >= 0
	check(bounded, "Wind disturbance stays within force −2..+1 / angle −3..+2 degrees")
	weather.change_wind(rng)
	check(weather.wind_force >= 0 and weather.wind_force <= 26 and weather.wind_angle >= 0 and weather.wind_angle < 360, "Wind weather re-rolls force and angle")
	weather.wind_force = 20
	weather.wind_angle = 90
	check(weather.wind_vector().distance_to(Vector2(0, -20)) < 0.001, "Native wind90 pushes upward in screen space")

	# ADR-084: initial force0..25; events0..26; force oscillates every turn.
	var wind_reference = Weather.new()
	wind_reference.wind_force = 10
	var forces := []
	for _i in 8:
		wind_reference.disturb_wind(rng)
		forces.append(wind_reference.wind_force)
	check(forces == [9,9,10,10,11,11,10,10], "Native per-turn force oscillation")
	var initial_range := true
	var event_range := true
	for seed_value in 100:
		var sample = Weather.new()
		rng.seed = seed_value
		sample.setup([1,0,0,0,0,0,0,0,0,0],Vector2(1800,1800),rng)
		initial_range = initial_range and sample.wind_force >= 0 and sample.wind_force <= 25
		sample.change_wind(rng)
		event_range = event_range and sample.wind_force >= 0 and sample.wind_force <= 26
	check(initial_range, "Initial native wind0..25")
	check(event_range, "Native Wind events0..26")

	var particle_model = Match.new()
	particle_model.start(2,1,7)
	var particles = load("res://scripts/weather_art.gd").new()
	particles.reset(Maps.get_map(Maps.DEFAULT))
	for cardinal in [0,90,180,270]:
		particle_model.weather.wind_force = 26
		particle_model.weather.wind_angle = cardinal
		particles.particles.clear()
		particles.emit_ground(Vector2(600,300),32,0,particle_model)
		var expected: Vector2 = Vector2(0,500)+particle_model.weather.wind_vector()*5.0
		check(not particles.particles.is_empty() and Vector2(particles.particles[0].acceleration).is_equal_approx(expected),"Particles use the physical wind vector cardinal" + str(cardinal))

	# Columns: same-type overlaps merge at the mean with summed scale.
	weather.columns.clear()
	weather.add_column("force", 500, 1)
	var merged: Dictionary = weather.add_column("force", 530, 1)
	check(weather.columns.size() == 1 and is_equal_approx(merged.x, 515) and is_equal_approx(merged.scale, 2.0), "Overlapping Force columns merge (mean position, summed scale)")
	weather.add_column("force", 900, 1)
	weather.add_column("random", 300, 1, "tornado")
	weather.add_column("random", 310, 1, "mirror")
	check(weather.columns.size() == 4, "Distant columns stay separate and Random never merges")
	check(is_equal_approx(weather.inner_half(merged), 40.0) and is_equal_approx(weather.outer_half(merged), 50.0), "Collision widths scale with merged columns")
	weather.queue = [{"type": "force", "x": 0.5, "y": 0.5, "extra": ""}, {"type": "thor", "x": 0.5, "y": 0.3, "extra": ""}, {"type": "electricity", "x": 0.2, "y": 0.5, "extra": ""}, {"type": "wind", "x": 0.5, "y": 0.5, "extra": ""}]
	weather.thor.level = 3
	weather.thor.xp = 1500
	weather.next_round(rng)
	check(weather.columns.is_empty() and weather.thor.active and weather.thor.pos == Vector2(900, 540), "A new type wipes other columns and Thor takes its map position")
	weather.next_round(rng)
	check(not weather.thor.active and weather.thor.level == 3 and weather.columns.size() == 1 and weather.columns[0].type == "electricity", "Thor deactivates when another weather enters, keeping level/XP")

	# Thor experience table (ThorSatellite.GainExperience).
	var levels := []
	for xp in [1, 800, 801, 1400, 1401, 2000, 2401, 2999, 3000]:
		weather.thor.xp = 0
		weather.thor.level = 1
		weather.gain_thor_experience(xp)
		levels.append(weather.thor.level)
	check(levels == [1, 1, 2, 2, 3, 3, 5, 5, 6], "Thor levels follow 800/1400/2000/2400/3000 (%s)" % str(levels))

	# Match wiring: rounds every two turns, Protection heals 35.
	var model = Match.new()
	model.start(2, 1, 11, Maps.DEFAULT, "original", null, [], [], [], 0, 4)
	check(model.weather != null and model.weather.queue.size() == 4 and model.wind == model.weather.wind_vector(), "Match starts with four weathers and the 2D wind")
	var queue_before: Array = model.weather.queue.duplicate(true)
	model.schedule(0, 50.0)
	check(model.total_turns == 2 and model.weather.queue == queue_before, "The second turn stays in the same round")
	model.schedule(model.active, 50.0)
	check(model.total_turns == 3 and model.weather.queue[0] == queue_before[1], "Every two turns the forecast advances one slot")
	model.actors[0].hp = 1000
	model.actors[1].hp = model.actors[1].max_hp
	model.weather.queue[1] = {"type": "protection", "x": 0.5, "y": 0.5, "extra": ""}
	model.schedule(model.active, 50.0)
	model.schedule(model.active, 50.0)
	check(model.actors[0].hp == 1035 and model.actors[1].hp == model.actors[1].max_hp, "Protection heals 35, capped at full life")

	# Contact rules on a single Bigfoot shell (base damage 90).
	model.start(2, 1, 12, "", "original", null, [], [], [], 0, 4)
	var shell: Dictionary = model.projectile_parameters(0, 45, 60, 0)[0]
	model.weather.columns.clear()
	var force_column: Dictionary = model.weather.add_column("force", 600, 1)
	shell.pos = Vector2(600, 300)
	model.apply_weather_contact(shell)
	check(shell.damage == 118 and "force" in shell.influenced, "Force: damage ×1.2 + 10 once")
	model.weather.columns.clear()
	model.weather.add_column("force", 200, 1)
	shell.pos = Vector2(200, 300)
	model.apply_weather_contact(shell)
	check(shell.damage == 118, "A second Force column does not stack on the same shell")
	shell = model.projectile_parameters(0, 45, 60, 0)[0]
	model.weather.columns.clear()
	model.weather.add_column("weakness", 600, 1)
	shell.pos = Vector2(600, 300)
	model.apply_weather_contact(shell)
	check(shell.damage == 65, "Weakness: damage ÷1.2 − 10 (Force factors, as the original code)")
	shell = model.projectile_parameters(0, 45, 60, 0)[0]
	model.weather.columns.clear()
	var mirror: Dictionary = model.weather.add_column("mirror", 600, 1)
	var vx: float = shell.velocity.x
	shell.pos = Vector2(600, 300)
	model.apply_weather_contact(shell)
	check(shell.damage == 104 and is_equal_approx(shell.velocity.x, -vx), "Mirror: reflects horizontal speed, damage ×1.1 + 5")
	shell.pos = Vector2(625, 300)
	model.apply_weather_contact(shell)
	shell.pos = Vector2(600, 300)
	model.apply_weather_contact(shell)
	check(shell.damage == 104 and is_equal_approx(shell.velocity.x, vx), "Re-entering a Mirror reflects again without re-scaling damage")
	shell = model.projectile_parameters(0, 45, 60, 0)[0]
	model.weather.columns.clear()
	model.weather.add_column("electricity", 600, 1)
	shell.pos = Vector2(600, 300)
	model.apply_weather_contact(shell)
	check(shell.electric and shell.damage == 90, "Electricity marks the shell for a lightning strike")
	shell = model.projectile_parameters(0, 45, 60, 0)[0]
	model.weather.columns.clear()
	var random_column: Dictionary = model.weather.add_column("random", 600, 1, "force")
	shell.pos = Vector2(600, 300)
	model.apply_weather_contact(shell)
	model.apply_weather_contact(shell)
	check(random_column.used and model.weather.columns.size() == 2 and model.weather.columns[1].type == "force" and shell.damage == 118, "Random activates once, spawning its extra weather that then acts")

	# Tornado: across the column, back mirrored, out along the heading; relaunch.
	shell = model.projectile_parameters(0, 45, 60, 0)[0]
	model.weather.columns.clear()
	var tornado: Dictionary = model.weather.add_column("tornado", 600, 1)
	shell.pos = Vector2(570, 300)
	shell.velocity = Vector2(300, -100)
	model.apply_weather_contact(shell)
	check(not shell.tornado.is_empty() and shell.tornado.step == 1, "Tornado captures the shell")
	var steps := {}
	for i in range(400):
		if shell.tornado.is_empty():
			break
		steps[int(shell.tornado.step)] = true
		var moved: Dictionary = model.tornado_step(shell, 1.0 / 120.0)
		shell.pos = moved.position
		shell.velocity = moved.velocity
	check(shell.tornado.is_empty() and steps.has(1) and steps.has(2) and steps.has(3), "Tornado runs its three steps and releases the shell")
	check(shell.pos.x > 600 + model.weather.outer_half(tornado) and shell.velocity.distance_to(Vector2(300, -100).normalized() * float(shell.launch_speed)) < 0.01, "Release continues along the entry heading at the launch speed")

	# Thor strike: beam from the satellite, damage 40 + 20/level, XP from damage.
	model.start(2, 1, 13, "", "original", null, [], [], [], 0, 4)
	model.weather.columns.clear()
	model.weather.thor.active = true
	model.weather.thor.pos = Vector2(model.actors[1].pos.x, 100)
	model.weather.thor.level = 1
	model.weather.thor.xp = 0
	var hp_before: int = int(model.actors[1].hp) + int(model.actors[1].shield)
	model.events.clear()
	model.thor_strike(model.actors[1].pos + Vector2(0, 30))
	var thor_event := {}
	for event in model.events:
		if event.type == "thor":
			thor_event = event
	check(not thor_event.is_empty() and Vector2(thor_event.position).distance_to(model.actors[1].pos) < 30.0, "Thor's beam strikes the first solid point under the satellite (the target)")
	var thor_loss: int = hp_before - int(model.actors[1].hp) - int(model.actors[1].shield)
	check(thor_loss > 0 and model.weather.thor.xp == thor_loss, "Thor damage (shield first) becomes its experience")

	# Lightning: topmost solid point above the impact, shock 30 to nearby actors.
	model.start(2, 1, 14, "", "original", null, [], [], [], 0, 4)
	var target: Vector2 = model.actors[1].pos
	hp_before = int(model.actors[1].hp) + int(model.actors[1].shield)
	model.events.clear()
	model.lightning_strike(target + Vector2(10, 60))
	var lightning := {}
	for event in model.events:
		if event.type == "lightning":
			lightning = event
	check(not lightning.is_empty() and Vector2(lightning.position).y <= target.y + 30.0, "Lightning rises to the topmost solid point above the impact")
	check(hp_before - int(model.actors[1].hp) - int(model.actors[1].shield) == 30, "Actors next to the beam take a 30 shock (shield first)")

	# Live shots and CPU prediction agree with every weather in the path.
	for setup in [["force"], ["weakness"], ["mirror"], ["electricity"], ["tornado"], ["random"], ["thor"]]:
		model.start(2, 1, 21, "", "original", null, [], [], [], 0, 4)
		model.wind = Vector2.ZERO
		model.weather.columns.clear()
		model.weather.thor.active = false
		if setup[0] == "thor":
			model.weather.thor.active = true
			model.weather.thor.pos = Vector2(700, 80)
		elif setup[0] == "random":
			model.weather.add_column("random", 520, 1, "tornado")
		else:
			model.weather.add_column(setup[0], 520, 1)
		var weather_before = model.weather.copy()
		var rng_state: int = model.rng.state
		var actors_before: Array = model.actors.duplicate(true)
		var cells_before: PackedByteArray = model.terrain.cells.duplicate()
		var predicted: Dictionary = model.predict_shot(0, 45, 60, 1)
		var untouched: bool = model.rng.state == rng_state and model.actors == actors_before and model.terrain.cells == cells_before
		untouched = untouched and model.weather.columns == weather_before.columns and model.weather.thor == weather_before.thor
		check(untouched, "Prediction with %s leaves live state untouched" % setup[0])
		model.fire(45, 60, 1)
		var impacts: Array = []
		var weather_events := {}
		for frame in range(2400):
			model.advance_projectiles(1.0 / 120.0)
			for event in model.events:
				if event.type in ["explosion", "miss"]:
					impacts.append(event.position)
				weather_events[event.type] = true
			model.events.clear()
			if model.phase != "flight":
				break
		var matched := false
		for point in impacts:
			matched = matched or Vector2(point).distance_to(predicted.position) < 0.5
		check(matched, "Prediction and live flight agree with %s (%d impacts)" % [setup[0], impacts.size()])
		check(weather_events.has("thor") if setup[0] == "thor" else (weather_events.has("weather_hit")), "Shots in the path interact with %s" % setup[0])
	# Menu option "all": every type can be drawn and Thor really activates.
	model.start(2, 1, 41, Maps.DEFAULT, "all", null, [], [], [], 0, 4)
	check(model.weather.weights == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1], "Weather option 'all' weighs every type equally")
	var thor_round := -1
	for round in range(80):
		if model.weather.thor.active:
			thor_round = round
			break
		model.schedule(model.active, 50.0)
		model.schedule(model.active, 50.0)
	check(thor_round >= 0 and model.weather.queue[0].type == "thor", "Natural rounds in 'all' mode activate Thor")
	var thor_fired := false
	if model.weather.thor.active:
		var shooter: int = model.active
		var plan: Dictionary = model.choose_cpu_shot() if shooter == 1 else {"angle": 45.0, "power": 60.0, "weapon": 0}
		model.events.clear()
		model.fire(plan.angle, plan.power, plan.weapon)
		for frame in range(2400):
			model.advance_projectiles(1.0 / 120.0)
			for event in model.events:
				thor_fired = thor_fired or event.type == "thor"
			model.events.clear()
			if model.phase != "flight":
				break
	check(thor_fired, "A real shot under natural Thor triggers the satellite strike")
	model.start(2, 1, 41, Maps.DEFAULT, "original", null, [], [], [], 0, 4)
	check(model.weather.weights == Maps.get_map(Maps.DEFAULT).weather, "Default mode keeps the original Miramo preset")
	model.start(1, 2, 31)
	var cpu: Dictionary = model.choose_cpu_shot()
	check(cpu.angle >= 15.0 and cpu.power >= 15.0 and cpu.power <= 100.0, "CPU aims legally with weather and 2D wind")
	# Presentation: ground particles from Particle.png; pause freezes the layer (REQ-26).
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/weather-test-profile.json")
	root.add_child(scene)
	scene.sound.muted = true
	scene.opening = 0
	scene.start_match()
	await process_frame
	check(scene.weather_art.ground != null and scene.weather_art.ground_frames == 60, "Miramo ground particle sheet has 60 frames (Map.cs)")
	scene.weather_art.emit_ground(Vector2(900, 1400), 480, PI * 0.5, scene.model)
	check(scene.weather_art.particles.size() == 60, "Removed pixels / 32 particles are emitted (480 cells → 60)")
	scene.weather_art.react({"type": "thor", "from": Vector2(900, 900), "position": Vector2(900, 1400), "removed": 0, "level": 2}, scene.model, scene.sound)
	scene.show_pause()
	var frozen: Array = scene.weather_art.particles.duplicate(true)
	var beams: Array = scene.weather_art.beams.duplicate(true)
	scene._process(0.2)
	check(scene.weather_art.particles == frozen and scene.weather_art.beams == beams, "Pause freezes particles and beams")
	scene.close_overlay()
	scene._process(0.2)
	check(scene.weather_art.particles != frozen, "Particles move again after resuming")
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/weather-test-profile.json"))
	finish("WEATHER CHECKS")
