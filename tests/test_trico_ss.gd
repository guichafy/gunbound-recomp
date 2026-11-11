extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Trico = preload("res://scripts/trico_flight.gd")
const Sprite = preload("res://scripts/classic_sprite.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func vec(a: Array) -> Vector2:
	return Vector2(float(a[0]),float(a[1]))

func fresh():
	var model = Match.new()
	model.start(5,2,42,"","original")
	model.weather.columns.clear()
	model.weather.thor.active=false
	model.wind=Vector2.ZERO
	model.terrain.image=null
	model.terrain.texture=null
	model.terrain.WIDTH=1000
	model.terrain.cells.resize(1000*model.terrain.HEIGHT)
	model.terrain.native_cells.resize(2000*model.terrain.HEIGHT*2)
	model.terrain.cells.fill(0)
	model.terrain.native_cells.fill(0)
	model.actors[0].pos=Vector2(100,700)
	model.actors[1].pos=Vector2(1700,700)
	return model

func run() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/trico_native.json"))
	for scenario in fixture.ss:
		var model = fresh()
		var shell: Dictionary = model.shot_shells(0,30,60,2)[0]
		var point := vec(scenario.position)
		# Force the native contact boundary on a single ground pixel.
		# Negative coordinates are tested on the state helper after that boundary.
		if point.y<0:
			continue
		Physics.seed(shell,Physics.position_fp(point),Vector2i.ZERO,Vector2i.ZERO)
		shell.hit_pos=point
		shell.launched=true
		model.terrain.native_cells[int(point.y)*2000+int(point.x)]=1
		model.terrain.cells[int(point.y/2)*model.terrain.WIDTH+int(point.x/2)]=1
		Snapshot.arm(model,0,2,[shell])
		model.advance_projectiles(0.05)
		check(model.events.filter(func(e):return e.type=="explosion").is_empty(),"SS contact has no invented blast")
		check(int(shell.get("trico_ss_tick",-999))==0,"SS contact starts counter0")
		check(int(shell.get("trico_seed",-999))==int(scenario.initial_seed),"SS seed is uint32(x+y)")
		model.events.clear()
		for row in scenario.ticks:
			model.advance_projectiles(0.05)
			var blasts: Array = model.events.filter(func(e):return e.type=="explosion")
			check(blasts.size()==row.blasts.size(),"SS native action count tick%d" % int(row.tick))
			if blasts.size()==1 and row.blasts.size()==1:
				check(Vector2(blasts[0].position)==vec(row.blasts[0]),"SS native random position tick%d" % int(row.tick))
			check(int(shell.get("trico_seed",-999))==int(row.seed),"SS uint32 RNG state tick%d" % int(row.tick))
			check(model.projectiles.is_empty()==bool(row.removed),"SS remains through20 then terminates21")
			model.events.clear()
	for scenario in fixture.ss:
		var shell: Dictionary = fresh().shot_shells(0,30,60,2)[0]
		Trico.begin_ss(shell,vec(scenario.position))
		shell.trico_width=int(scenario.width)
		for row in scenario.ticks:
			var action := Trico.tick_ss(shell)
			check(int(shell.trico_seed)==int(row.seed),"SS isolated signed-origin/odd-width state matches x86")
			check(action.has("position")==not row.blasts.is_empty(),"SS isolated action boundary")
			if action.has("position"):
				check(action.position==vec(row.blasts[0]),"SS isolated uint32 wrap coordinate")
	var model = fresh()
	var shell: Dictionary = model.shot_shells(0,30,60,2)[0]
	shell.launched=true
	Trico.begin_ss(shell,Vector2(500,400))
	Snapshot.arm(model,0,2,[shell])
	var copy = Snapshot.capture(model)
	Snapshot.arm(copy,0,2,[shell.duplicate(true)])
	for tick in 20:
		model.advance_projectiles(0.025)
		check(int(shell.trico_ss_tick)==tick,"SS fractional half-tick never advances early")
		model.advance_projectiles(0.025)
		copy.advance_projectiles(0.05)
		check(model.projectiles==copy.projectiles,"SS snapshot and execution states identical each tick")
		check(model.events==copy.events,"SS snapshot and execution events identical")
		var stopped: Dictionary = shell.duplicate(true)
		model.advance_projectiles(0.0)
		check(shell==stopped,"SS zero elapsed time preserves paused state")
	check(int(shell.trico_ss_tick)==20,"SS still pending after last blast16 until20")
	model.advance_projectiles(0.05)
	check(model.projectiles.is_empty(),"SS terminal tick21 removes without another blast")
	var sprite = Sprite.new()
	sprite.setup("trico")
	check(sprite.effect_sheets({"weapon":2,"ss_state":"trico_start"})==["SSFlame.png"],"SS contact draws only native ssflame4")
	check(sprite.effect_sheets({"weapon":2,"child":true})==["Flame3.png"],"SS later actions use common flame43")
	for item in ["dual","dual_plus","thunder","teleport"]:
		var item_model = fresh()
		item_model.actors[0].turn_item=item
		var t2: Array = item_model.shot_shells(0,30,60,1)
		check(t2.size()==(6 if item=="dual" else 4 if item=="dual_plus" else 1 if item=="teleport" else 3),"Trico keeps item emission contract "+item)
		if item=="dual":
			check(t2[0].trico_component==t2[3].trico_component,"Dual second salvo owns independent Trico component state")
			t2[0].trico_phase=-123
			check(int(t2[3].trico_phase)!=-123,"Dual state never aliases first salvo")
	var live = fresh()
	var actors_before: Array = live.actors.duplicate(true)
	var mask_before: PackedByteArray = live.terrain.native_cells.duplicate()
	live.predict_shot(0,30,60,2)
	check(live.actors==actors_before and live.terrain.native_cells==mask_before,"SS prediction preserves live actors and native mask")
	var credit = fresh()
	credit.actors[0].turns=3
	credit.actors[1].pos=Vector2(500,400)
	credit.actors[1].hp=10000
	credit.actors[1].max_hp=10000
	check(credit.fire(30,60,2),"SS starts through public fire with Gold record")
	var credited: Dictionary = credit.projectiles[0]
	credited.launched=true
	credited.electric=true
	Physics.seed(credited,Vector2i(128000,102400),Vector2i.ZERO,Vector2i.ZERO)
	credited.hit_pos=credited.pos
	credit.terrain.native_cells[400*2000+500]=1
	credit.terrain.cells[200*1000+250]=1
	credit.events.clear()
	credit.advance_projectiles(0.05)
	for tick in 21:
		credit.advance_projectiles(0.05)
	check(credit.events.filter(func(e):return e.type=="lightning").size()==1,"SS Thunder attachment consumed once across eight actions")
	check(credit.events.filter(func(e):return e.type=="trico_ss_start").size()==1,"SS contact visual publishes once")
	check(credit.events.filter(func(e):return e.type=="explosion").size()==8,"SS publishes exactly eight real blasts")
	var dealt := 0
	for event in credit.events:
		if event.type in ["damage","shield_damage"] and int(event.actor)==1:
			dealt+=int(event.amount)
	check(dealt>0 and int(credit.shot_gold.enemy_damage)==dealt,"Gold counts actual component damage once, including attached shock")
	finish("TRICO SS CHECKS")
