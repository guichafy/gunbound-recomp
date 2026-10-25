extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Water = preload("res://scripts/classic_projectile_art.gd")
var oracle: Dictionary

func fresh(facing: int = 1, item: String = ""):
	var model = Match.new()
	model.start(12,1,42,"","original",null,[] if item.is_empty() else [item])
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.WIDTH = 2000
	model.terrain.cells.resize(model.terrain.WIDTH*model.terrain.HEIGHT)
	model.terrain.cells.fill(0)
	model.actors[0].pos = Vector2(100 if facing == 1 else 1800,650)
	model.actors[0].facing = facing
	model.actors[1].pos = Vector2(3000,750)
	if not item.is_empty():
		model.use_item(0)
	return model

func seed_shell(model, strand: int, position: Vector2i, velocity: Vector2i, acceleration: Vector2i) -> Dictionary:
	model.fire(45,60,1)
	var shell: Dictionary = model.projectiles[strand]
	model.projectiles = [shell]
	shell.launched = true
	Physics.seed(shell,position,velocity,acceleration)
	shell.hit_pos = shell.pos
	shell.previous_draw_pos = shell.pos
	shell.previous_hit_pos = shell.pos
	shell.trail = [shell.pos]
	model.events.clear()
	return shell

func vector_i(value: Array) -> Vector2i:
	return Vector2i(int(value[0]),int(value[1]))

func test_native_schedule() -> void:
	for strand in 2:
		var model = fresh()
		var shot := seed_shell(model,strand,Vector2i(128000,76800),Vector2i(2560,0),Vector2i.ZERO)
		for tick in 162:
			model.advance_projectiles(0.05)
			for row in oracle.state_samples:
				if int(row.strand) != strand or int(row.sample_tick) != tick+1:
					continue
				check(int(shot.get("wave_counter",-1)) == int(row.after.counter), "Native T2 counter advances once per physical tick")
				check(int(shot.get("wave_phase",-1)) == int(row.after.phase), "T2 strand%d phase after tick%d matches PE fixture" % [strand,tick+1])
				check(int(shot.get("wave_amplitude",-1)) == int(row.after.amplitude) and int(shot.get("wave_step",-1)) == int(row.after.phase_step), "T2 growth/deceleration/convergence match original integer schedule")
				var delta := Vector2i((Vector2(shot.hit_pos)-Vector2(shot.pos))*256)
				check(delta == vector_i(row.horizontal_offset_fp), "T2 samples the pre-advance phase without accumulating offsets into the carrier")

func test_native_geometry() -> void:
	for scenario in oracle.geometry_cases:
		for row in scenario.samples:
			var model = fresh()
			var velocity := vector_i(scenario.velocity_fp_before_acceleration)
			var carrier := vector_i(scenario.carrier_fp_after_move)
			var shot := seed_shell(model,int(row.strand),carrier-velocity,velocity,vector_i(scenario.acceleration_fp))
			shot.wave_counter = int(row.counter_before)
			shot.wave_phase = int(row.phase_before)
			shot.wave_amplitude = int(row.amplitude_before)
			model.advance_projectiles(0.05)
			check(Vector2i(Vector2(shot.hit_pos)*256) == vector_i(row.hit_fp), "%s native offset, heading and truncation at counter%d/strand%d" % [scenario.name,int(row.counter_before),int(row.strand)])
			check(shot.fp_pos == carrier, "T2 collision displacement never changes the ballistic carrier")
			var sides: Array = shot.get("water_sides",[])
			check(not sides.is_empty() and Vector2i(sides[-1]) == vector_i(scenario.section_side_pixel), "T2 water cross-section uses the post-acceleration carrier heading and width10")
			if sides.is_empty():
				continue
			var strip := Water.water_segments(shot)
			if not strip.is_empty():
				var head := (Vector2(strip[0].points[0])+Vector2(strip[0].points[1]))*0.5
				check(head == Vector2(vector_i(row.hit_pixel)), "T2 native cross-section is anchored to the original integer pixel")

func test_birth_and_beacon() -> void:
	var model = fresh()
	model.fire(45,60,1)
	for step in 7:
		model.advance_projectiles(0.05)
	check(model.projectiles.size() == 2, "T2 retains its original two emissions")
	for shot in model.projectiles:
		check(shot.hit_pos == shot.pos, "Both Turtle water heads start on the carrier before diverging")
	var beacon = fresh(1,"teleport")
	beacon.fire(45,60,1)
	for step in 5:
		beacon.advance_projectiles(0.05)
	check(beacon.projectiles.size() == 1 and beacon.projectiles[0].beacon and beacon.projectiles[0].hit_pos == beacon.projectiles[0].pos, "Teleport from T2 remains a plain beacon, without a water orbit")

func test_rates_and_prediction() -> void:
	for facing in [1,-1]:
		var reference: Array = []
		for fps in [30,60,120]:
			var model = fresh(facing)
			model.terrain.HEIGHT = 1000
			model.terrain.cells.resize(model.terrain.WIDTH*model.terrain.HEIGHT)
			model.terrain.cells.fill(0)
			model.wind = Vector2(26,0)
			model.fire(45,60,1)
			model.events.clear()
			var sim = Snapshot.capture(model)
			Snapshot.arm(sim,0,1,model.projectiles.duplicate(true))
			for frame in int(fps*3.5):
				model.tick(1.0/fps)
				sim.advance_projectiles(1.0/fps)
				if frame % fps == 0:
					check(model.projectiles == sim.projectiles and model.events == sim.events, "T2 real/prediction share all wave and section state at%dFPS/facing%d" % [fps,facing])
			check(model.projectiles.size() == 2 and model.projectiles.all(func(p): return int(p.get("wave_step",-1)) == 0), "T2 strands finish native angular deceleration during the flight")
			if model.projectiles.size() == 2:
				check(Vector2(model.projectiles[0].hit_pos).distance_to(model.projectiles[1].hit_pos) < 5, "T2 strands converge to the same trajectory instead of orbiting at constant radius")
				var original: Dictionary = model.projectiles[0].duplicate(true)
				for fraction in [0.0,0.5,1.0]:
					var visual: Dictionary = model.projectiles[0].duplicate()
					visual.draw_fraction = fraction
					var strip := Water.water_segments(visual)
					check(not strip.is_empty() and model.projectiles[0] == original, "T2 renderer interpolates original sections without mutating collision or wave state")
			if reference.is_empty():
				reference = model.projectiles.duplicate(true)
			else:
				check(model.projectiles == reference, "T2 native trajectory and sections are independent of rendering FPS")

func test_item_clocks() -> void:
	for item in ["dual","dual_plus"]:
		var model = fresh(1,item)
		model.fire(45,60,1)
		for step in 34:
			model.advance_projectiles(0.05)
		var early: Array = model.projectiles.filter(func(p): return int(p.volley) == 0)
		var late: Array = model.projectiles.filter(func(p): return int(p.volley) == 1)
		check(early.size() == 2 and not late.is_empty(), "Dual item retains both native T2 strands and its second salvo")
		if early.is_empty() or late.is_empty():
			continue
		if item == "dual":
			check(int(early[0].get("wave_counter",0)) > int(late[0].get("wave_counter",0)), "Dual salvos have independent T2 phase/envelope clocks")
		else:
			check(not late[0].has("wave_counter"), "Dual+ S1 does not inherit T2 wave state")

func test_crossed_sections() -> void:
	var model = fresh()
	model.actors[0].pos = Vector2(500,300)
	model.fire(25,0,1)
	for step in 8:
		model.advance_projectiles(0.05)
	var visual: Dictionary = model.projectiles[0].duplicate()
	visual.draw_fraction = 0.5
	var strip := Water.water_segments(visual)
	var crossed := false
	for segment in strip:
		crossed = crossed or Geometry2D.triangulate_polygon(segment.points).is_empty()
	check(crossed, "Legal minimum-power T2 reproduces a crossed section rejected by polygon triangulation")
	var art = Water.new()
	check(art.has_method("triangle_data"), "Turtle water submits the original two triangles instead of polygon ear-clipping")
	if art.has_method("triangle_data"):
		var triangles: Dictionary = art.triangle_data(visual)
		check(triangles.indices.size() == strip.size()*6 and triangles.points.size() == strip.size()*4, "Crossed sections retain all vertices and two explicit triangles")
		check(triangles.uv.size() == triangles.points.size() and triangles.colors.size() == triangles.points.size(), "Every explicit water vertex retains its UV and alpha")

func test_scene_pause() -> void:
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/turtle-t2/isolated-profile.json")
	view.sound = load("res://scripts/sound.gd").new()
	view.sound.muted = true
	root.add_child(view)
	view.set_process(false)
	view.opening = 0
	view.start_match()
	view.model = fresh()
	view.model.fire(45,60,1)
	view.art.reset(view.model.actors)
	for frame in 60:
		view._process(1.0/60)
	view.paused = true
	var frozen: Array = view.model.projectiles.duplicate(true)
	for frame in 60:
		view._process(1.0/60)
	check(view.model.projectiles == frozen, "Scene pause freezes native T2 phase, envelope, carrier and render sections")
	view.paused = false
	for frame in 3:
		view._process(1.0/60)
	check(int(view.model.projectiles[0].wave_counter) == int(frozen[0].wave_counter)+1, "Scene resumes T2 with exactly one physical tick")
	view.queue_free()
	await process_frame

func run() -> void:
	oracle = JSON.parse_string(FileAccess.get_file_as_string("res://tests/turtle_t2_fixtures.json"))
	test_native_schedule()
	test_native_geometry()
	test_birth_and_beacon()
	test_rates_and_prediction()
	test_item_clocks()
	test_crossed_sections()
	await test_scene_pause()
	finish("TURTLE T2 CHECKS")
