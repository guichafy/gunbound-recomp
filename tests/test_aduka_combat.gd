extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Aduka = preload("res://scripts/aduka_effect.gd")

func run() -> void:
	var emission := Mobiles.emission(16,1)
	check(emission.size() == 3,"Requested T2 has three independent creatures")
	var script = load("res://scripts/aduka_combat.gd")
	check(script != null,"Native Aduka damage and collision resolver exists")
	if script == null:
		finish("ADUKA COMBAT CHECKS")
		return
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/aduka_damage_native.json"))
	for row in fixtures:
		check(script.falloff(Vector2i(row[0],row[1]),int(row[2]),int(row[3])) == int(row[4]),"PE45db20 independent falloff fixture%s"%str(row))
	var actor := {"vehicle":16,"pos":Vector2(100,100),"hp":1000,"shield":0,"facing":1,"tilt":0.0,"attributes":[0,0,0,0,0,0,0,0]}
	check(script.origin(actor) == Vector2i(100,120),"Native hotspot conversion matches existing hull registration")
	check(script.hit_actor(Vector2i(86,96),actor) and script.hit_actor(Vector2i(114,120),actor),"AABB includes exact corners")
	check(not script.hit_actor(Vector2i(85,96),actor) and not script.hit_actor(Vector2i(114,121),actor),"AABB rejects first pixels outside")
	check(script.center(actor) == Vector2i(100,108),"Damage uses center rather than ground/box distance")
	#45f300/45f5d0: negative branch NEG/SUB4 is asymmetric to ADD4.
	for row in [[-5,0,0],[-6,0,0],[-13,0,0],[-14,-2,0],[-20,-2,0],[5,0,0],[6,2,0],[15,2,0],[16,4,1]]:
		actor.tilt = deg_to_rad(-row[0])
		check(script.tilt_offset(actor) == Vector2i(row[1],row[2]),"Native asymmetric tilt boundary%s"%str(row))
	actor.tilt = 0.0
	var mage: Dictionary = actor.duplicate(true)
	mage.vehicle = 1
	mage.tilt = deg_to_rad(-30)
	check(script.tilt_offset(mage) == Vector2i(9,0),"Native flag1 uses large X table and suppresses Y offset")
	var bunge = Match.new()
	bunge.start(16,1,42,"", "original",null,["bunge_shot"])
	var normal_shell: Dictionary = bunge.shot_shells(0,35,60,0)[0]
	bunge.use_item(0)
	var dig_shell: Dictionary = bunge.shot_shells(0,35,60,0)[0]
	check(normal_shell.aduka_crater_percent==100 and dig_shell.aduka_crater_percent==125,"Bunge retains its explicit offline crater effect")
	var base := {"power":152,"dimension":64,"aspect":120,"flags":70,"percent":100}
	check(script.amount(actor,Vector2i(100,108),base) == 132,"T1 center:152×(91−4)/100 truncates132")
	check(script.amount(actor,Vector2i(100,150),base) == 0,"Strict42px boundary has zero damage")
	actor.attributes[2] = 50
	check(script.amount(actor,Vector2i(100,108),base) == 71,"Defense50 subtracts40 before element−4:152×47/100")
	actor.attributes[2] = 0
	var beam := {"power":100,"dimension":44,"aspect":150,"flags":4,"percent":100}
	check(script.amount(actor,Vector2i(100,108),beam) == 91,"Thor center is91; guide has no own blast")
	var damage_events: Array = []
	actor.hp = 5
	actor.shield = 10
	check(script.apply([actor],damage_events,Vector2i(100,108),beam,true) == 91,"XP counts computed91 even if only15 health/shield remain")
	check(actor.hp == 0 and actor.shield == 0,"Model publishes terminal HP0 after native remainder")
	var terrain := Terrain.new()
	terrain.WIDTH = 80
	terrain.HEIGHT = 80
	terrain.cells.resize(6400)
	terrain.cells.fill(0)
	terrain.enable_native()
	terrain.native_cells[40*160+41] = 1
	var contact: Dictionary = script.projectile_contact(Vector2i(0,40),Vector2i(80,40),terrain,[])
	check(contact.is_empty(),"Native stride8 can skip an isolated pixel unlike swept DDA")
	terrain.native_cells[40*160+48] = 1
	contact = script.projectile_contact(Vector2i(0,40),Vector2i(80,40),terrain,[])
	check(contact.get("position",Vector2.INF) == Vector2(41,40),"Coarse contact refines previous8px to the first solid pixel")
	var ray: Dictionary = script.thor_contact(Vector2i(0,40),Vector2i(20,40),terrain,[])
	check(ray.get("position",Vector2.INF) == Vector2(48,40),"Thor step2 continues beyond target and skips odd isolated pixel")
	var copy = terrain.collision_copy()
	copy.native_cells[40*160+41] = 0
	check(terrain.native_solid(Vector2i(41,40)),"Prediction native pixel mask is isolated")
	for weapon in 3:
		for facing in [-1,1]:
			var model = Match.new()
			model.start(16,1,93,"", "original",null,[],[],[],0,16)
			model.actors[0].facing = facing
			model.actors[0].ss_lock = 0
			var shells: Array = model.shot_shells(0,35,60,weapon)
			check(shells.size() == [1,3,3][weapon],"Shared factory counts weapon%d facing%d"%[weapon,facing])
			var sim = load("res://scripts/flight_snapshot.gd").capture(model)
			var expected: Array = shells.duplicate(true)
			load("res://scripts/flight_snapshot.gd").arm(sim,0,weapon,expected)
			model.fire(35,60,weapon)
			for tick in 250:
				if model.phase != Match.PHASE_FLIGHT: break
				model.advance_projectile_tick(0.05)
			for tick in 250:
				if sim.phase != Match.PHASE_FLIGHT: break
				sim.advance_projectile_tick(0.05)
			var same: bool = model.weather.thor == sim.weather.thor
			for index in 2:
				for key in ["pos","hp","shield","tilt"]:
					same = same and model.actors[index][key] == sim.actors[index][key]
			check(same,"Native damage/contact execution equals prediction weapon%d facing%d"%[weapon,facing])
			check(model.terrain.native_cells == sim.terrain.native_cells,"Native craters execution equals prediction weapon%d facing%d"%[weapon,facing])
	finish("ADUKA COMBAT CHECKS")
