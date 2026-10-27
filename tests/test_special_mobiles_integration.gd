extends "res://tests/support/suite.gd"
## Regression for the reported missing effects, through the real Match API.
const Match = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func fresh(vehicle: int, weapon: int):
	var model = Match.new()
	model.start(vehicle,1,42,"")
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.terrain.cells.fill(0)
	for y in range(220,model.terrain.HEIGHT):
		for x in model.terrain.WIDTH:
			model.terrain.cells[y*model.terrain.WIDTH+x] = 1
	model.actors[0].pos = Vector2(200,415)
	model.actors[1].pos = Vector2(640,415)
	model.actors[1].hp = 2000
	model.actors[1].max_hp = 2000
	model.actors[1].shield = 250
	model.actors[0].ss_lock = 0
	if vehicle==16:
		# This fixture replaces the generated terrain after Match.start.
		model.terrain.native_cells.clear()
		model.terrain.enable_native()
		# Native Thor starts atY500; this artificial floor isY440. Place the
		# test satellite above its target to exercise a damaging contact.
		model.weather.thor.pos=Vector2(600,100)
		model.weather.thor.display_pos=model.weather.thor.pos
		model.weather.thor.previous_display_pos=model.weather.thor.pos
	model.fire(40,50,weapon)
	model.events.clear()
	return model

func pool(model) -> int:
	return int(model.actors[1].hp)+int(model.actors[1].shield)

func impact(model, point: Vector2) -> void:
	var shell: Dictionary = model.projectiles[0].duplicate(true)
	model.projectiles.clear()
	model.explode(point,-1,shell)

func test_jd() -> void:
	var model = fresh(9,1)
	impact(model,Vector2(600,415))
	var before: Vector2 = model.actors[1].pos
	for tick in 8:
		model.advance_projectiles(0.05)
	check(float(model.actors[1].pos.x) < before.x,"JD T2 attracts an actor near the crystal through Match ticks")
	model = fresh(9,2)
	impact(model,Vector2(640,415))
	var before_pool := pool(model)
	for tick in 24:
		model.advance_projectiles(0.05)
	check(pool(model) < before_pool,"JD SS deals its crystal effect despite zero primary projectile power")
	model = fresh(9,1)
	var original: Dictionary = model.projectiles[0].duplicate(true)
	impact(model,Vector2(600,415))
	model.explode(Vector2(620,415),-1,original)
	check(model.battle_effects.size() == 1 and Vector2(model.battle_effects[0].pos) == Vector2(620,415),"JD replaces the owner's previous crystal on a second impact")

func test_asate() -> void:
	for weapon in 3:
		var model = fresh(10,weapon)
		var before_pool := pool(model)
		impact(model,Vector2(640,415))
		check(pool(model) == before_pool,"ASate guide %d cannot substitute direct damage for satellite children" % weapon)
		check(model.phase == Match.PHASE_FLIGHT,"ASate keeps the turn in flight after the guide impact")
		var children := 0
		for tick in 200:
			model.advance_projectiles(0.05)
			for event in model.events:
				if event.type == "projectile_launch" and bool(event.get("child",false)):
					children += 1
			model.events.clear()
			if model.phase != Match.PHASE_FLIGHT:
				break
		check(children == [1,3,6][weapon],"ASate %d emits its native satellite children once" % weapon)
		check(pool(model) < before_pool,"ASate children %d can damage the target" % weapon)

func test_aduka() -> void:
	for weapon in [1,2]:
		var model = fresh(16,weapon)
		var before_pool := pool(model)
		impact(model,Vector2(640,415))
		for tick in 30:
			model.advance_projectiles(0.05)
		var beams := 0
		for event in model.events:
			if event.type == "thor":
				beams += 1
		check(beams > 0,"Aduka %d requests Thor without Thor weather" % weapon)
		check(pool(model) < before_pool,"Aduka %d damages with Thor rather than zero-power guide" % weapon)

func test_raon() -> void:
	var model = fresh(7,1)
	var before_pool := pool(model)
	impact(model,Vector2(640,415))
	check(pool(model) == before_pool,"Raon planting cannot also deal the future mine blast immediately")
	check(model.mines.size() == 1,"Raon impact plants one independently owned mine")
	model = fresh(7,2)
	model.actors[0].pos = Vector2(200,100)
	model.actors[1].pos = Vector2(900,100)
	impact(model,Vector2(300,435))
	for tick in 99:
		model.advance_projectiles(0.05)
	check(model.phase == Match.PHASE_FLIGHT and model.mines.size() == 1,"Raon SS retains its firing turn through mine tick99")
	model.advance_projectiles(0.05)
	check(model.mines.is_empty() and model.phase == Match.PHASE_SETTLE,"Raon SS finishes only when its mine detonates at tick100")
	model = fresh(7,1)
	var shell: Dictionary = model.projectiles[0].duplicate(true)
	shell.electric = true
	shell.thor = true
	model.explode(Vector2(500,435),-1,shell)
	check(model.events.any(func(event):return event.type == "lightning"),"Raon planting preserves the attached Thunder action")
	check(model.events.any(func(event):return event.type == "thor"),"Raon planting preserves the attached weather Thor action")
	model = fresh(7,1)
	model.projectiles.clear()
	var Raon = load("res://scripts/raon_effect.gd")
	model.mines = [Raon.create_mine({"weapon":1,"damage":200,"blast_radius":21.0},Vector2(600,435),0,7)]
	model.active = 0
	model.begin_turn()
	check(model.phase != Match.PHASE_AIM,"Raon S2 resolves its queued movement before the owner can act")
	model.pass_turn()
	check(model.active == 0,"Passing cannot cancel Raon S2's pending movement")
	for tick in 45:
		model.tick(0.05)
		if model.phase == Match.PHASE_AIM:
			break
	check(model.phase == Match.PHASE_AIM and model.turn_time == Match.TURN_TIME,"Raon grants the owner's full turn after mine movement")

func test_shared_step(vehicle: int, weapon: int, facing: int, item: String = "") -> void:
	var model = fresh(vehicle,weapon)
	model.actors[0].facing = facing
	if not item.is_empty():
		model.actors[0].turn_item = item
	model.projectiles = model.shot_shells(0,40,50,weapon)
	model.volleys = model.second_volley(model.projectiles)
	# A controlled real contact makes every late effect run, independently of
	# whether this fixture's angle happens to hit the procedural island.
	for shell in model.projectiles:
		shell.pos = Vector2(640,405)
		shell.hit_pos = shell.pos
		shell.previous_draw_pos = shell.pos
		shell.previous_hit_pos = shell.pos
		shell.velocity = Vector2(0,200)
		shell.age = 1.0
		shell.fp_ready = false
		shell.erase("launch_velocity_fp")
	model.events.clear()
	var sim = Snapshot.capture(model)
	Snapshot.arm(sim,0,weapon,model.projectiles.duplicate(true))
	sim.shot_gold = model.shot_gold.duplicate(true)
	for frame in 1800:
		sim.advance_projectiles(0.05)
		if frame == 0:
			check(model.battle_effects.is_empty() and model.mines.is_empty(),"Prediction cannot create live effects for mobile%d weapon%d" % [vehicle,weapon])
		model.advance_projectiles(0.05)
		if model.phase != Match.PHASE_FLIGHT:
			break
	var label := "%d/%d/%d/%s" % [vehicle,weapon,facing,item]
	check(model.phase == Match.PHASE_SETTLE and sim.phase == model.phase,"Late effects complete the shot "+label)
	check(model.events == sim.events,"Complete real/predicted effect events agree "+label)
	check(model.actors == sim.actors and model.terrain.cells == sim.terrain.cells,"Real/predicted damage, movement and crater agree "+label)
	check(model.mines == sim.mines and model.battle_effects == sim.battle_effects and model.satellites == sim.satellites,"Real/predicted private state agrees "+label)
	if vehicle == 16:
		check(model.weather.thor == sim.weather.thor,"Real/predicted native Thor clocks, level and XP agree "+label)
	if item == "teleport":
		check(model.battle_effects.is_empty() and model.mines.is_empty(),"Teleport discards the mobile special effect "+label)
	if not model.satellites.is_empty():
		var saved: Dictionary = model.satellites.duplicate(true)
		sim.satellites[0].pos = Vector2i(-99,-99)
		check(model.satellites == saved,"Satellite position is copied deeply "+label)

func test_prediction_contract() -> void:
	for vehicle in [7,9,10,16]:
		for weapon in 3:
			var model = fresh(vehicle,weapon)
			model.phase = Match.PHASE_AIM
			var before: Array = model.actors.duplicate(true)
			var thor_before: Dictionary = model.weather.thor.duplicate(true)
			var hit: Dictionary = model.predict_shot(0,40,40,weapon)
			check(hit.has("position") and hit.has("hit") and hit.has("actor"),"CPU prediction returns a candidate for %d/%d" % [vehicle,weapon])
			check(model.actors == before,"CPU prediction keeps live actors intact for %d/%d" % [vehicle,weapon])
			if vehicle == 16:
				check(model.weather.thor == thor_before,"CPU prediction keeps live native Thor intact for weapon%d"%weapon)

func test_attached_actions() -> void:
	for vehicle in [7,9,10,16]:
		var model = fresh(vehicle,1)
		var shell: Dictionary = model.projectiles[0].duplicate(true)
		shell.electric = true
		shell.thor = false
		model.projectiles.clear()
		model.explode(Vector2(640,415),-1,shell)
		for tick in 200:
			model.advance_projectiles(0.05)
			if model.phase != Match.PHASE_FLIGHT:
				break
		var bolts: int = model.events.filter(func(event):return event.type == "lightning").size()
		check(bolts == 1,"Thunder remains one action on the original guide for mobile%d" % vehicle)

func run() -> void:
	var weather_art = load("res://scripts/weather_art.gd").new()
	var sound = load("res://scripts/sound.gd").new()
	sound.muted = true
	var beam_model = fresh(16,1)
	weather_art.react({"type":"thor","from":Vector2(600,100),"position":Vector2(640,415),"level":6,"removed":0,"native":true,"ttl":1.0,"period":400,"rgb":0xffffff},beam_model,sound)
	weather_art.tick(0.75,beam_model)
	check(weather_art.beams.size() == 1,"Native Aduka ray survives beyond the old weather beam TTL")
	weather_art.tick(0.3,beam_model)
	check(weather_art.beams.is_empty(),"Native Aduka ray expires after twenty ticks")
	sound.free()
	var Sprite = load("res://scripts/classic_sprite.gd")
	check(Sprite.placed_state({"crystal":true,"state":"work","state_age":0.2},[]) == "work","Crystal renderer respects the model work state")
	check(Sprite.placed_state({"crawl":true,"steps":100,"state":"active"},[]) == "active","Raon SS uses the native active landing state")
	var sprites: Dictionary = load("res://scripts/game.gd").build_sprites()
	check(sprites[10].get("satellite_sounds") != null,"ASate exposes original Ion launch streams separately from the guide")
	check(sprites[10].satellite_sounds.size() == 3 and sprites[10].satellite_sounds[0].get_length() > 0.0 and sprites[10].satellite_sounds[1].get_length() > 0.0 and sprites[10].satellite_sounds[2].get_length() == 0.0,"Ion T1/T2 use original PCM while missing SS stays silent")
	for fixture in [[10,0.5],[9,1.0],[16,1.0],[7,0.25]]:
		var sprite = sprites[fixture[0]]
		check(sprite.native_animation,"Mobile %d uses EPA action lifetimes for hurt and death" % fixture[0])
		check(is_equal_approx(sprite.pose_duration("destroyed"),fixture[1]),"Mobile %d preserves native death duration" % fixture[0])
	test_jd()
	test_asate()
	test_aduka()
	test_raon()
	test_prediction_contract()
	test_attached_actions()
	for vehicle in [7,9,10,16]:
		for weapon in 3:
			for facing in [1,-1]:
				test_shared_step(vehicle,weapon,facing)
		for item in ["dual","dual_plus","teleport"]:
			test_shared_step(vehicle,1,1,item)
	finish("SPECIAL MOBILE INTEGRATION CHECKS")
