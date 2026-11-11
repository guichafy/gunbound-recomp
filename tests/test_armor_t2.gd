extends "res://tests/support/suite.gd"
## REQ-04/05/07/08/19/44/45 — issue27, one shell through two craters.
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Armor = preload("res://scripts/armor_flight.gd")
const NativeWeather = preload("res://scripts/aduka_weather.gd")

func fresh():
	var model = Match.new()
	model.start(4, 1, 31, "", "original")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.WIDTH = 200
	model.terrain.HEIGHT = 150
	model.terrain.cells.resize(30000)
	model.terrain.cells.fill(0)
	model.terrain.native_cells = PackedByteArray()
	model.terrain.image = null
	model.terrain.texture = null
	model.terrain.visual = null
	model.terrain.visual_texture = null
	for y in range(75,150):
		for x in 200:
			model.terrain.cells[y*200+x]=1
	model.terrain.enable_native()
	model.actors[0].pos=Vector2(40,125)
	model.actors[1].pos=Vector2(360,125)
	return model

func arm(model, velocity: Vector2i = Vector2i(0,2560), weapon: int = 1) -> Dictionary:
	check(model.fire(35,60,weapon),"Armor fires")
	var shell: Dictionary=model.projectiles[0]
	shell.launched=true
	Physics.seed(shell,Vector2i(200*256,145*256),velocity,Vector2i(0,11))
	shell.hit_pos=shell.pos
	shell.age=0.5
	model.events.clear()
	return shell

func explosions(model) -> Array:
	return model.events.filter(func(e):return e.type=="explosion")

func test_two_contacts(direction: int) -> void:
	var model=fresh()
	var shell=arm(model,Vector2i(direction*512,2560))
	var initial: Array=shell.get("armor_fields",[]).duplicate()
	var first_velocity: Vector2i=shell.fp_velocity
	model.advance_projectiles(0.05)
	check(explosions(model).size()==1,"First contact makes one crater")
	check(model.projectiles.size()==1,"First contact preserves one projectile")
	if model.projectiles.is_empty():return
	check(is_same(shell,model.projectiles[0]),"First contact preserves Dictionary identity")
	check(int(shell.get("armor_phase",-1))==1,"First contact advances physical phase")
	check(initial==[236,236,236,56,56,56],"DAT three powers and dimensions initialized")
	check(shell.get("armor_fields",[])==[165,165,165,39,39,39],"All six values truncate7/10")
	check(shell.damage==165 and is_equal_approx(shell.blast_radius,19.5),"Bridge consumes reduced power/dimension")
	check(shell.fp_velocity==first_velocity+Vector2i(0,11),"First hit preserves speed and applies this tick acceleration")
	check(Physics.integer_position(shell)==Vector2i(shell.hit_pos),"Contact writes back fixed-point position")
	check(not model.terrain.native_solid(Vector2i(explosions(model)[0].position)),"First impact modifies collision terrain")
	check(int(explosions(model)[0].removed)>0,"First crater removes ground")
	var first_tick:=int(shell.flight_ticks)
	var first_point: Vector2=explosions(model)[0].position
	for step in 80:
		if model.projectiles.is_empty():break
		model.advance_projectiles(0.05)
	check(model.projectiles.is_empty(),"Second contact removes original shell")
	check(explosions(model).size()==2,"Exactly two impacts")
	if explosions(model).size()==2:
		check(Vector2(explosions(model)[1].position).y>first_point.y,"Second contact sees first crater")
		check(int(explosions(model)[1].removed)>0,"Second impact makes a smaller crater")
	check(int(shell.flight_ticks)>first_tick+1,"Crosses crater before second hit")
	check(int(shell.armor_phase)==1 and shell.armor_fields==[165,165,165,39,39,39],"Second hit never reduces again")
	check(model.phase==Match.PHASE_SETTLE,"No remaining shell leaves flight phase")

func test_snapshot_and_clock(delta: float) -> void:
	var model=fresh()
	var shell=arm(model)
	model.advance_projectiles(0.05)
	if model.projectiles.is_empty():
		check(false,"Snapshot starts between impacts")
		return
	var sim=Snapshot.capture(model)
	Snapshot.arm(sim,0,1,model.projectiles.duplicate(true))
	sim.flight_elapsed=model.flight_elapsed
	var before: Dictionary=shell.duplicate(true)
	var terrain_before: PackedByteArray=model.terrain.native_cells.duplicate()
	sim.projectiles[0].armor_fields[1]=-777
	check(shell.armor_fields[1]==165,"Snapshot owns deeply copied material fields")
	sim.projectiles[0].armor_fields[1]=165
	model.events.clear()
	# The GPU capture separately freezes an active phase1 shell for30frames.
	for step in 100:
		if model.phase!=Match.PHASE_FLIGHT:break
		sim.advance_projectiles(delta)
		if step==0:
			check(model.terrain.native_cells==terrain_before and shell==before,"Prediction cannot mutate live terrain or shell")
		model.advance_projectiles(delta)
	check(model.events==sim.events,"Execution and prediction events match at delta%s"%delta)
	check(model.actors==sim.actors and model.terrain.native_cells==sim.terrain.native_cells,"Execution/prediction actors and craters match")
	check(model.projectiles==sim.projectiles and model.phase==sim.phase,"Execution/prediction phases match")

func test_tick_boundaries() -> void:
	var model=fresh()
	var shell=arm(model)
	var initial: Dictionary=shell.duplicate(true)
	model.advance_projectiles(0.025)
	check(shell==initial and explosions(model).is_empty(),"N−1 fractional step cannot trigger contact")
	model.advance_projectiles(0.025)
	check(explosions(model).size()==1 and int(shell.armor_phase)==1,"N exact tick triggers first contact")
	var phase1: Dictionary=shell.duplicate(true)
	model.advance_projectiles(0.025)
	check(shell==phase1 and explosions(model).size()==1,"N+fraction cannot replay contact")
	model.advance_projectiles(0.025)
	check(int(shell.flight_ticks)==int(phase1.flight_ticks)+1 and explosions(model).size()==1,"N+1 advances within the first crater")
	for direction in [-1,1]:
		model=fresh()
		shell=arm(model,Vector2i(direction*2560,-512))
		Physics.seed(shell,Vector2i((1 if direction<0 else 399)*256,50*256),Vector2i(direction*2560,-512),Vector2i.ZERO)
		shell.hit_pos=shell.pos
		model.advance_projectiles(0.05)
		check(model.projectiles.is_empty() and explosions(model).is_empty(),"Edge exit cannot fabricate two impacts")

func test_terminal_paths() -> void:
	for weapon in [0,2]:
		var model=fresh()
		arm(model,Vector2i(0,2560),weapon)
		model.advance_projectiles(0.05)
		check(model.projectiles.is_empty() and explosions(model).size()==1,"T1/SS retain one impact")
	var model=fresh()
	var shell=arm(model)
	model.advance_projectiles(0.05)
	if model.projectiles.is_empty():return
	model.terrain.cells.fill(0)
	model.terrain.native_cells.fill(0)
	for step in 300:
		if model.projectiles.is_empty():break
		model.advance_projectiles(0.05)
	check(model.projectiles.is_empty() and model.phase==Match.PHASE_SETTLE,"No second terrain exits without hanging")
	check(explosions(model).size()==1 and model.events.any(func(e):return e.type=="miss"),"Missing second contact cannot synthesize an impact")
	model=fresh()
	shell=arm(model,Vector2i.ZERO)
	model.advance_projectiles(0.05)
	# Age limit must also work after the first impact, even for stationary shells.
	if not model.projectiles.is_empty():
		shell.age=12.01
		model.terrain.cells.fill(0)
		model.terrain.native_cells.fill(0)
		model.advance_projectiles(0.05)
		check(model.projectiles.is_empty(),"Age guard still applies after first phase")

class FixtureTerrain extends RefCounted:
	var floor_y: int
	var boxes: Array
	func native_solid(point: Vector2i) -> bool:
		if point.y>=floor_y and point.x>=0 and point.x<400 and point.y<300:return true
		for box in boxes:
			if point.x>=int(box[0]) and point.x<=int(box[2]) and point.y>=int(box[1]) and point.y<=int(box[3]):return true
		return false

func test_native_oracle() -> void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/armor_t2_native.json"))
	for scenario in fixture.cases:
		var shell: Dictionary={"vehicle":4,"weapon":1,"beacon":false,"armor_phase":0,
			"armor_fields":scenario.initial_fields.duplicate(),"damage":int(scenario.initial_fields[0]),"blast_radius":28.0}
		Physics.seed(shell,Vector2i(25600,25600),Vector2i(int(scenario.direction)*2560,1280),Vector2i(int(scenario.direction)*7,11))
		for row in scenario.ticks:
			Physics.move(shell)
			var alive:=true
			if row.tick in scenario.contacts:
				Armor.write_contact(shell,Vector2(Physics.integer_position(shell)))
				alive=Armor.after_impact(shell)
			if alive:Physics.finish_tick(shell)
			check(shell.fp_pos==Vector2i(int(row.position_fp[0]),int(row.position_fp[1])),"Native tick position%s"%row.tick)
			check(shell.fp_velocity==Vector2i(int(row.velocity_fp[0]),int(row.velocity_fp[1])),"Native tick velocity%s"%row.tick)
			check(shell.armor_fields==row.fields.map(func(v):return int(v)) and shell.armor_phase==int(row.phase),"Native six-field phase%s"%row.tick)
			check(alive==(int(row.removed)==0),"Native removal at contact%s"%row.tick)
	for scenario in fixture.contact_cases:
		var terrain=FixtureTerrain.new()
		terrain.floor_y=int(scenario.floor)
		terrain.boxes=scenario.boxes
		var shell: Dictionary={}
		var from:=Vector2i(int(scenario.start_fp[0]),int(scenario.start_fp[1]))
		var to:=Vector2i(int(scenario.end_fp[0]),int(scenario.end_fp[1]))
		Physics.seed(shell,to,to-from,Vector2i.ZERO)
		var hit:=Armor.contact(shell,terrain,[])
		check(not hit.is_empty()==bool(scenario.contact),"Native sweep contact presence")
		if not hit.is_empty():
			Armor.write_contact(shell,hit.position)
			check(shell.fp_pos==Vector2i(int(scenario.position_fp[0]),int(scenario.position_fp[1])),"Native contact snap and scan order")

func test_items_and_credit() -> void:
	for item in ["","dual","dual_plus","thunder","power_up","bunge_shot","teleport"]:
		var model=fresh()
		model.actors[0].turn_item=item
		model.actors[1].pos=Vector2(200,125)
		model.actors[1].hp=10000
		model.actors[1].max_hp=10000
		model.actors[1].shield=0
		check(model.fire(35,60,1),"Item fires %s"%item)
		var originals: Array=model.projectiles.duplicate()
		for index in model.projectiles.size():
			var shell: Dictionary=model.projectiles[index]
			shell.launched=true
			Physics.seed(shell,Vector2i(200*256,110*256),Vector2i(0,2560),Vector2i(0,11))
			shell.hit_pos=shell.pos
			shell.age=0.5
		model.events.clear()
		var contact_count:=0
		for step in 300:
			if model.phase!=Match.PHASE_FLIGHT:break
			model.advance_projectiles(0.05)
		for shell in originals:
			contact_count+=2 if Armor.active(shell) else (0 if bool(shell.beacon) else 1)
		check(model.projectiles.is_empty(),"Item completes without stuck shell %s"%item)
		check(explosions(model).size()==contact_count,"Only native phases contribute impacts %s"%item)
		if item=="teleport":
			check(model.events.filter(func(e):return e.type=="teleport").size()==1,"Teleport remains one beacon")
		var credited:=0
		for event in model.events:
			if event.type in ["damage","shield_damage"] and int(event.actor)==1:
				credited+=int(event.amount)
		check(int(model.shot_gold.enemy_damage)==credited,"Gold credits each new damage event once %s"%item)
		check(model.shot_actor==0 and originals.all(func(p):return int(p.owner)==0),"Both impacts preserve owner %s"%item)
		if item=="thunder":
			check(model.events.filter(func(e):return e.type=="lightning").size()==2,"Thunder bridge runs once per actual contact")
		model.finish_gold_shot()
		var paid: Dictionary=model.actors[0].gold_state.duplicate(true)
		model.finish_gold_shot()
		check(model.actors[0].gold_state==paid,"Final Gold settlement is idempotent %s"%item)

func run() -> void:
	test_tick_boundaries()
	test_native_oracle()
	test_items_and_credit()
	test_two_contacts(1)
	test_two_contacts(-1)
	test_snapshot_and_clock(0.05)
	test_snapshot_and_clock(0.025)
	test_terminal_paths()
	check(NativeWeather.NATIVE_TERRAIN_VEHICLES==[1,2,6,8,13,16],"Armor stays outside native inventory; Bigfoot explicitly added by issue28")
	finish("ARMOR T2 CHECKS")
