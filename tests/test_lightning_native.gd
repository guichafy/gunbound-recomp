extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func run() -> void:
	var model = Match.new()
	model.start(8,1,42,"","original",null,[],[],[],0,4)
	check(bool(model.shot_shells(0,30,50,0)[0].skip_actors),"Native Lightning T1 passes mobiles in flight")
	check(bool(model.shot_shells(0,30,50,1)[0].skip_actors),"Native Lightning T2 passes mobiles in flight")
	var script = load("res://scripts/lightning_combat.gd")
	check(script != null,"Lightning native resolver exists")
	if script == null:
		finish("LIGHTNING NATIVE CHECKS")
		return
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/lightning_damage_native.json"))
	for row in rows:
		check(Shared.falloff(Vector2i(row[0],row[1]),row[2],row[3])==int(row[4]),"Independent native falloff%s"%str(row))
	var probes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/lightning_shock_native.json"))
	for probe in probes:
		check(script.shock_hit(Vector2i(probe[2],probe[3]),Vector2i(200,200),probe[0],70,probe[1],Vector2i(400,300))==bool(probe[4]),"Discrete shock%s"%str(probe))
	# No ground contact is required to show SSFlame, but SS has no own blast.
	model.actors[0].pos=Vector2(200,189)
	model.actors[0].shield=0
	model.actors[1].pos=Vector2(600,100)
	var hp_before:=int(model.actors[0].hp)
	model.explode(Vector2(200,200),-1,model.shot_shells(0,30,50,2)[0])
	script.resolve(model)
	check(int(model.actors[0].hp)==hp_before,"SS does not invent a blast at projectile impact")
	test_stride(script)
	test_ss_items(script)
	test_shock(script)
	for weapon in 3:
		for facing in [-1,1]:
			for wind in [Vector2.ZERO,Vector2(12,0),Vector2(-12,8)]:
				model = Match.new()
				model.start(8,1,42,"","original",null,[],[],[],0,4)
				model.actors[0].facing=facing
				model.wind=wind
				model.actors[0].ss_lock=0
				var shells: Array = model.shot_shells(0,30,30,weapon)
				var sim = Snapshot.capture(model)
				Snapshot.arm(sim,0,weapon,shells.duplicate(true))
				check(model.fire(30,30,weapon),"Lightning real launch")
				for tick in 260:
					if model.phase==Match.PHASE_FLIGHT:model.advance_projectile_tick(0.05)
					if sim.phase==Match.PHASE_FLIGHT:sim.advance_projectile_tick(0.05)
				var same:=true
				for index in 2:
					for key in ["pos","hp","shield","attributes","tilt"]:
						same=same and model.actors[index][key]==sim.actors[index][key]
				check(same,"Real/prediction damage/shock/attributes %s"%str([weapon,facing,wind]))
				check(model.terrain.native_cells==sim.terrain.native_cells,"Real/prediction crater")
	check(Mobiles.force_max(8)==47 and Mobiles.gravity_native(8)==90,"DAT force47 and gravity90 preserved")
	finish("LIGHTNING NATIVE CHECKS")

func test_shock(script) -> void:
	var model=Match.new()
	model.start(8,1,42,"","original",null,[],[],[],0,4)
	model.actors[0].pos=Vector2(50,50)
	var target: Dictionary=model.actors[1]
	target.vehicle=4 # mechanical flag8
	target.pos=Vector2(200,158) # native feet(200,180)
	target.hp=1000
	target.shield=0
	target.attributes[2]=50
	target.tilt=0.0
	model.actors[0].tilt=0.0
	var shell: Dictionary=model.shot_shells(0,30,40,0)[0]
	script.queue_shock(model,shell,Vector2i(200,250),0,script.catalog.weapons[0])
	script.resolve(model)
	check(target.hp==918,"Mechanical shock76+trunc(76×8/100)=82 ignores Defense50")
	target.vehicle=5 # biological flag2 receives direct shock
	target.pos=Vector2(200,156) # original feet180
	target.hp=1000
	script.queue_shock(model,shell,Vector2i(200,250),0,script.catalog.weapons[0])
	script.resolve(model)
	check(target.hp==924,"Biological direct shock76")
	# Chain uses feet delta, strict radius70; mechanical source can propagate.
	for distance in [69,70,71]:
		target.vehicle=4
		target.pos=Vector2(200,178)
		target.hp=1000
		model.actors[0].vehicle=8
		model.actors[0].pos=Vector2(200+distance,177)
		model.actors[0].hp=750
		model.actors[0].shield=0
		target.lightning_pending={"primary":56,"secondary":20,"radius":70,"projectile":shell}
		script.resolve(model)
		check(model.actors[0].hp==(730 if distance<70 else 750),"Chain20 strict70px %d hp%d feet%s/%s"%[distance,model.actors[0].hp,Shared.origin(model.actors[0]),Shared.origin(target)])
	# A diagonal from sky to(200,250) extends UP/LEFT, not down/right.
	model.actors[0].pos=Vector2(50,50)
	target.pos=Vector2(102,130) # native feet(102,152), exactly two steps upstream
	target.hp=1000
	model.terrain.native_cells.fill(0)
	model.terrain.native_cells[250*int(model.terrain.world_size().x)+200]=1
	shell.weapon=1
	script.ray(model,shell,Vector2i(200,250),1,1)
	script.resolve(model)
	check(target.hp==918,"T2 upward shock follows the same diagonal as its visible ray")
	# Native pending survives lethal blast until the electrical flush.
	target.pos=Vector2(245,178)
	target.hp=1
	model.actors[0].vehicle=8
	model.actors[0].pos=Vector2(314,177)
	model.actors[0].hp=750
	model.actors[0].shield=0
	model.terrain.native_cells.fill(0)
	model.terrain.native_cells[200*int(model.terrain.world_size().x)+200]=1
	shell.weapon=0
	script.impact(model,shell,Vector2(200,200))
	script.resolve(model)
	check(target.hp==0 and model.actors[0].hp==730,"Lethal T1 still propagates20 before result resolution")

func test_stride(script) -> void:
	var model=Match.new()
	model.start(8,1,42,"","original",null,[],[],[],0,4)
	model.terrain.native_cells.fill(0)
	model.terrain.native_cells[40*int(model.terrain.world_size().x)+3]=1
	var shot: Dictionary=model.shot_shells(0,30,40,0)[0]
	var hit:=Shared.projectile_contact(Vector2i(0,40),Vector2i(30,40),model.terrain,[],shot,model)
	check(not hit.is_empty(),"T1 stride3 detects a pixel at3 that stride8 skips")
	model.weather.columns.clear()
	model.weather.add_column("force",100,1.0)
	var weather=load("res://scripts/aduka_weather.gd")
	for index in 3:
		weather.sample(model,shot,Vector2i(100,100),false)
	check(int(shot.native_force)==26,"T1 Force20/23/26 increments3 rather than8")

func test_ss_items(script) -> void:
	for distance in [119,120,121]:
		var model=Match.new()
		model.start(8,1,42,"","original",null,[],[],[],0,4)
		model.terrain.native_cells.fill(0)
		model.actors[0].pos=Vector2(50,50)
		model.actors[1].pos=Vector2(200+distance,188)
		model.actors[1].tilt=0.0
		var shot: Dictionary=model.shot_shells(0,30,40,2)[0]
		script.impact(model,shot,Vector2(200,200))
		var rays: Array=model.events.filter(func(event):return event.type=="mobile_lightning")
		check(rays.size()==(1 if distance<120 else 0),"SS strict radius120 at nativeY−10, distance%d"%distance)
		script.resolve(model)
	var model=Match.new()
	model.start(8,1,42,"","original",null,["dual_plus","teleport","thunder"])
	model.use_item(0)
	var shells: Array=model.shot_shells(0,30,40,1)
	check(shells.size()==2,"Dual+ creates independent T1/T2 native shells")
	check(int(shells[0].native_contact_stride)==8 and int(shells[1].native_contact_stride)==3,"Dual+ retains per-weapon stride")
	model=Match.new()
	model.start(8,1,42,"","original",null,["teleport"])
	model.use_item(0)
	var beacon: Dictionary=model.shot_shells(0,30,40,0)[0]
	check(bool(beacon.beacon) and not script.active(beacon),"Teleport bypasses Lightning impact and weather specials")
	var actor: Dictionary=model.actors[0]
	actor.hp=700
	actor.shield=200
	actor.attributes.fill(0)
	Mobiles.regenerate(actor)
	check(actor.hp==700 and actor.shield==220,"Lightning retains shield regen20 and no HP regen")
	check(Mobiles.weapon(8,0).cost==750 and Mobiles.weapon(8,1).cost==800 and Mobiles.weapon(8,2).cost==1300,"Native shot delays750/800/1300 preserved")
