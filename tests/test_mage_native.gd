extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func empty_model():
	var model = Match.new()
	model.start(1,1,42,"")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.terrain.cells.fill(0)
	model.terrain.native_cells = PackedByteArray()
	model.terrain.enable_native()
	model.actors[0].pos = Vector2(200,350)
	model.actors[1].pos = Vector2(1100,700)
	model.wind = Vector2.ZERO
	return model

func run() -> void:
	var model = empty_model()
	for weapon in 3:
		var shells: Array = model.shot_shells(0,35,60,weapon)
		check(shells.size()==[1,2,1][weapon],"Native Mage1/2/1 components")
		for shell in shells:
			check(int(shell.damage)==[200,186,380][weapon],"Native Mage base power per component weapon%d"%weapon)
			check(int(shell.blast_radius)==[33,27,30][weapon],"Native Mage dimension/2 weapon%d"%weapon)
			check(is_equal_approx(float(shell.spawn_at),0.05),"MainAction emission tick1")
	model.actors[0].attributes = [7,0,0,0,0,0,11,0]
	for weapon in 3:
		var attributed: Dictionary = model.shot_shells(0,35,60,weapon)[0]
		check(attributed.damage==[221,196,401][weapon],"Native3*Attack divided by1/2/1 before addition")
		check(int(attributed.get("mage_dimension",0))==[71,56,65][weapon],"Native Dig/2 divided by1/2/1 before addition")
	# Real loop must retain24.8 in tornado, rather than invent vector min-speed.
	for weapon in 3:
		model = empty_model()
		var shells: Array = model.shot_shells(0,35,10,weapon)
		model.weather.add_column("tornado",shells[0].pos.x,2.0)
		model.fire(35,10,weapon)
		model.advance_projectiles(0.1)
		check(not model.projectiles.is_empty(),"Tornado fixture keeps Mage in flight")
		for shell in model.projectiles:
			check(bool(shell.tornado.get("native",false)),"Mage weapon%d uses native tornado"%weapon)
			check(shell.fp_velocity==shell.launch_velocity_fp,"Tornado suspends acceleration without adding impulse weapon%d"%weapon)
	model = empty_model()
	var force: Dictionary = model.shot_shells(0,35,60,0)[0]
	model.weather.add_column("force",force.pos.x,1.0)
	model.fire(35,60,0)
	model.advance_projectiles(0.1)
	check(model.projectiles[0].damage==200 and int(model.projectiles[0].get("native_force",0))==20,"Force is separate from200 native power")
	check(ResourceLoader.exists("res://scripts/mage_combat.gd"),"Native Mage damage/EMP resolver exists")
	if ResourceLoader.exists("res://scripts/mage_combat.gd"):
		var Mage = load("res://scripts/mage_combat.gd")
		model = empty_model()
		# MageSS removes shield first, then ordinary blast reaches HP.
		var target: Dictionary = model.actors[1]
		target.pos = Vector2(600,300)
		target.shield = 100
		var at := Shared.center(target)
		var shell: Dictionary = model.shot_shells(0,35,60,2)[0]
		var data: Dictionary = Mage.parameters(shell,model.actors[0])
		var expected := Shared.amount(target,at,data)
		model.shot_actor = 0; model.shot_weapon = 2
		model.events.clear()
		model.explode(Vector2(at),1,shell)
		check(target.shield==0 and target.hp==1100-expected,"EMP removes shield before full native HP blast")
		check(model.events.filter(func(e):return e.type=="shield_damage").size()==1,"EMP shield event published once")
		#425ac0 uses squared distance from native origin minus10, strict radius.
		for dx in [149,150,151]:
			model = empty_model()
			target = model.actors[1]; target.pos = Vector2(600,300); target.shield = 100
			at = Shared.origin(target)-Vector2i(0,10)+Vector2i(dx,0)
			shell = model.shot_shells(0,35,60,2)[0]
			model.shot_actor = 0; model.shot_weapon = 2
			model.explode(Vector2(at),-1,shell)
			check(target.shield==(0 if dx<150 else 100) and target.hp==1100,"Native strict EMP boundary%d"%dx)
		var fixture: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/mage_damage_native.json"))
		for row in fixture:
			check(Shared.falloff(Vector2i(row[0],row[1]),row[2],row[3])==int(row[4]),"Independent Mage falloff"+str(row.slice(0,4)))
	#4a5b8c publishes the displaced integer before the tornado bounds test.
	# Carrier and contact can straddle the border on the same native tick.
	var Climate = load("res://scripts/aduka_weather.gd")
	for entry in [[131,133,1],[133,131,0]]:
		var wave := {"vehicle":1,"flight":"mage_wave","fp_pos":Vector2i(entry[0]*256,0),"hit_pos":Vector2(entry[1],0),"fp_velocity":Vector2i(1000,0),"tornado":{"native":true,"center":100,"half":32,"turns":0}}
		Climate.finish(wave)
		check(int(wave.tornado.turns)==int(entry[2]),"MageT2 tornado crossing uses wave contact, not carrier")
	# Real/predicted state must agree across both components, wind and items.
	for weapon in 3:
		for facing in [-1,1]:
			for item in ["","dual","dual_plus","teleport","thunder"]:
				if weapon==2 and not item.is_empty():
					model = empty_model(); model.actors[0].turn_item = item
					check(not model.fire(35,60,weapon),"SS remains item-locked for "+item)
					continue
				model = empty_model()
				model.actors[0].pos = Vector2(650,350)
				model.actors[0].facing = facing
				model.actors[0].turn_item = item
				model.wind = Vector2(27,-12)
				var shells: Array = model.shot_shells(0,35,60,weapon)
				model.weather.add_column("tornado",shells[0].pos.x,1.0)
				model.weather.add_column("force",shells[0].pos.x+facing*100,1.0)
				var sim = Snapshot.capture(model)
				Snapshot.arm(sim,0,weapon,shells.duplicate(true))
				check(model.fire(35,60,weapon),"Legal Mage item/shot launches")
				# arm() starts flight only; fire() also charges the turn's SS lock.
				sim.actors[0].ss_lock = model.actors[0].ss_lock
				model.events.clear()
				for initial in sim.projectiles:
					if float(initial.spawn_at)<=0:sim.launch_projectile(initial)
				sim.events.clear()
				for tick in 240:
					model.advance_projectiles(0.05); sim.advance_projectiles(0.05)
					check(model.projectiles==sim.projectiles and model.events==sim.events,"Mage real=CPU weapon%d facing%d %s tick%d"%[weapon,facing,item,tick])
					check(model.actors==sim.actors and model.terrain.native_cells==sim.terrain.native_cells,"Mage real=CPU damage/craters")
					if model.phase!=Match.PHASE_FLIGHT:break
	for wind in [Vector2(27,0),Vector2(-27,0),Vector2(0,27),Vector2(0,-27)]:
		for facing in [-1,1]:
			for weapon in 3:
				model = empty_model()
				model.actors[0].pos = Vector2(650,350); model.actors[0].facing = facing
				model.wind = wind
				var shells: Array = model.shot_shells(0,35,60,weapon)
				model.weather.add_column("tornado",shells[0].pos.x,1.0)
				var sim = Snapshot.capture(model); Snapshot.arm(sim,0,weapon,shells.duplicate(true))
				check(model.fire(35,60,weapon),"Mage wind fixture launches")
				model.events.clear()
				for tick in 60:
					model.advance_projectiles(0.05); sim.advance_projectiles(0.05)
					check(model.projectiles==sim.projectiles,"Mage wind/current-gravity snapshot %s facing%d weapon%d tick%d"%[str(wind),facing,weapon,tick])
	finish("MAGE NATIVE CHECKS")
