extends "res://tests/support/suite.gd"
const Water = preload("res://scripts/classic_projectile_art.gd")
const Sprite = preload("res://scripts/classic_sprite.gd")
const Match = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func test_water_strip() -> void:
	var history: Array = []
	for index in 16:
		history.append(Vector2(index*18, sin(index*0.45)*28))
	var shot := {"pos":history[-1], "hit_pos":history[-1], "trail":history, "age":0.6, "flight_ticks":0}
	var frozen := shot.duplicate(true)
	for phase in 8:
		shot.flight_ticks = phase
		var strip: Array = Water.water_segments(shot)
		check(strip.size() == 15, "Turtle water retains all 15 historical segments")
		# Native 0x4c495b/73 maps eight full 32px columns of WaterEffect.xtf.
		check(is_equal_approx(strip[0].uv[0].x, phase/8.0) and is_equal_approx(strip[0].uv[1].x, (phase+1)/8.0), "Water phase %d samples a complete source column" % phase)
		for index in range(strip.size()-1):
			check(strip[index].points[3].is_equal_approx(strip[index+1].points[0]) and strip[index].points[2].is_equal_approx(strip[index+1].points[1]), "Curved Turtle water has a shared edge, without an open seam")
	shot.flight_ticks = 0
	check(shot == frozen, "Rendering leaves the collision history and model untouched")
	check(str(Water.water_segments(shot)) == str(Water.water_segments(shot)), "Paused water has identical geometry and UV")

func test_ss_child_art() -> void:
	var sprite = Sprite.new()
	sprite.setup("turtle")
	var child: Dictionary = sprite.sheet("SSChild.png")
	check(child.get("entry", "") == "bullet12c.img", "Turtle SS fragments load their own original bubble sheet")
	check(child.get("frames", 0) == 15 and child.get("states", {}).has("normal"), "Turtle SS fragment animates its 15 original frames")
	check(sprite.has_method("projectile_sheet"), "Turtle SS selects body art by parent/fragment stage")
	if sprite.has_method("projectile_sheet"):
		check(sprite.projectile_sheet({"child":true},2) == "SSChild.png", "A fragment never redraws the opening parent bubble")
		check(sprite.projectile_sheet({"child":false},2) == "Bullet3.png", "The closed SS retains its original parent sheet")
	check(sprite.has_method("effect_sheets"), "Turtle impact composition distinguishes parent and fragments")
	if sprite.has_method("effect_sheets"):
		check(sprite.effect_sheets({"weapon":2,"child":false}) == ["Flame3.png","SSFlame.png"], "Unsplit SS impact retains both proven source layers")
		check(sprite.effect_sheets({"weapon":2,"child":false,"ss_state":"change"}) == ["Flame3.png"], "An opening parent's impact cannot replay the closed bubble's extra flame")
		check(sprite.effect_sheets({"weapon":2,"child":true}) == ["Flame3.png"], "A fragment impact uses flame123 without the parent's extra stage")

func fresh():
	var model = Match.new()
	model.start(12,1,42,"","original")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.cells.fill(0)
	model.actors[0].pos = Vector2(100,650)
	model.actors[1].pos = Vector2(1200,700)
	model.actors[0].ss_lock = 0
	model.fire(80,80,2)
	model.events.clear()
	return model

func test_ss_division() -> void:
	var model = fresh()
	var sim = Snapshot.capture(model)
	Snapshot.arm(sim,0,2,model.projectiles.duplicate(true))
	# Spawn is source tick6; physical tick1 is the next full native tick.
	for step in 6+43:
		model.advance_projectiles(0.05)
		sim.advance_projectiles(0.05)
	check(model.projectiles.size() == 1 and model.projectiles[0].ss_state == "normal", "SS is a closed bubble through physical tick43")
	model.advance_projectiles(0.05)
	sim.advance_projectiles(0.05)
	var parent: Dictionary = model.projectiles[0]
	check(parent.flight_ticks == 44 and parent.ss_state == "change", "Native tick44 starts SS opening")
	var fixed_position: Vector2 = parent.pos
	for step in 9:
		model.advance_projectiles(0.05)
		sim.advance_projectiles(0.05)
	check(model.projectiles.size() == 1 and model.projectiles[0].pos == fixed_position, "All opening frames complete before the parent is removed")
	check(parent.previous_draw_pos == parent.pos and parent.previous_hit_pos == parent.hit_pos, "A held SS has stationary visual endpoints, without a repeated20Hz interpolation jump")
	model.advance_projectiles(0.05)
	sim.advance_projectiles(0.05)
	check(model.projectiles.size() == 6 and model.projectiles.all(func(p): return bool(p.get("child",false))), "Opening completion replaces the parent with six SS fragments in the air")
	check(model.events.filter(func(e): return e.type == "explosion").is_empty(), "SS division creates no impact damage or crater in the air")
	check(model.projectiles == sim.projectiles and model.events == sim.events, "Prediction and actual flight share the complete division transition")
	# Give fragments an actual landing surface so impact-stage checks cannot
	# pass vacuously when every fragment simply leaves an empty arena.
	for y in range(350,model.terrain.HEIGHT):
		for x in model.terrain.WIDTH:
			model.terrain.cells[y*model.terrain.WIDTH+x] = 1
	for step in 200:
		if model.phase != Match.PHASE_FLIGHT:
			break
		model.advance_projectiles(0.05)
	var impacts: Array = model.events.filter(func(e): return e.type == "explosion")
	check(not impacts.is_empty() and impacts.all(func(e): return bool(e.get("child",false))), "SS fragment impacts preserve their presentation stage")

func test_scene_impact_stage() -> void:
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/turtle-fix/isolated-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.opening = 0
	view.start_match()
	view.model.events = [{"type":"explosion","position":Vector2.ZERO,"radius":23.0,"weapon":2,"vehicle":12,"child":true,"ss_state":"change","angle":0.0}]
	view.consume_events()
	check(not view.effects.is_empty() and bool(view.effects[-1].get("child",false)), "Scene preserves the fragment marker through the event/effect boundary")
	check(view.effects[-1].get("ss_state","") == "change", "Scene preserves the SS state through the event/effect boundary")
	view.model = fresh()
	view.art.reset(view.model.actors)
	view.screen = "match"
	for frame in 150:
		view._process(1.0/60)
	view.paused = true
	var frozen: Array = view.model.projectiles.duplicate(true)
	for frame in 60:
		view._process(1.0/60)
	check(view.model.projectiles == frozen, "Pausing during SS opening freezes the complete state without splitting")
	view.paused = false
	for frame in 30:
		view._process(1.0/60)
	check(view.model.projectiles.size() == 6 and view.model.projectiles.all(func(p): return bool(p.get("child",false))), "Unpausing completes the SS division once")
	view.queue_free()
	await process_frame

func test_frame_rates() -> void:
	var reference: Array = []
	for fps in [30,60,120]:
		var model = fresh()
		for frame in 3*fps:
			model.tick(1.0/fps)
		check(model.projectiles.size() == 6 and model.projectiles.all(func(p): return bool(p.get("child",false))), "%d FPS completes exactly one SS division" % fps)
		if reference.is_empty():
			reference = model.projectiles.duplicate(true)
		else:
			check(model.projectiles == reference, "%d FPS keeps the same fragment state as30FPS" % fps)

func test_impact_during_opening() -> void:
	var model = fresh()
	for step in 6+44:
		model.advance_projectiles(0.05)
	var parent: Dictionary = model.projectiles[0]
	check(parent.ss_state == "change", "Boundary impact fixture reaches opening tick44")
	# Reproduce the collision branch on the exact step open_shell changed state.
	model.projectiles.clear()
	model.explode(parent.hit_pos,-1,parent)
	check(model.projectiles.is_empty(), "An impact at opening tick44 cannot bypass change and spawn six children")

func run() -> void:
	test_water_strip()
	test_ss_child_art()
	test_ss_division()
	test_impact_during_opening()
	test_frame_rates()
	await test_scene_impact_stage()
	finish("TURTLE PROJECTILE CHECKS")
