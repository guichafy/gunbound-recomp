extends "res://tests/support/suite.gd"
## Issue26: removing the Mage gate must not enable another projectile physics.
const Match = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Contact = preload("res://scripts/aduka_weather.gd")
const Effects = preload("res://scripts/mage_weather_effects.gd")

func start_pair(left: int, right: int, map: String, mode: String, seed_value: int = 42):
	var model = Match.new()
	model.start(left,1,seed_value,map,mode,null,[],[],[],0,right)
	return model

func run() -> void:
	for map in ["miramo_town_a", ""]:
		for mode in ["original","all"]:
			var reference = start_pair(1,2,map,mode)
			for vehicle in range(1,17):
				for side in 2:
					var model = start_pair(vehicle if side==0 else 2,2 if side==0 else vehicle,map,mode)
					check(model.weather.get("is_native")==true,"Native calendar vehicle%d side%d %s %s"%[vehicle,side,map,mode])
					check(model.weather.thor.get("present",false) and model.weather.thor.get("native",false),"Thor exists before any Thor climate regardless of roster")
					check(not model.terrain.native_cells.is_empty(),"Global Thor terrain consumer has mask before prediction")
					if model.weather.get("is_native")!=true:continue
					check(model.weather.calendar==reference.weather.calendar and model.weather.random_table==reference.weather.random_table,"Calendar/table depend only on offline inputs")
					check(model.weather.spawn_ranges==reference.weather.spawn_ranges and model.weather.weights==reference.weather.weights,"Stage ranges and weights independent of roster")
					check(model.weather.thor==reference.weather.thor and model.wind==reference.wind and model.weather.columns==reference.weather.columns,"Initial Thor, wind and columns independent of roster")
					for turn in range(1,18):
						var expected = reference.weather.copy()
						# Advance each independent copy sequentially, including slot7→0.
						for tick in range(1,turn+1):expected.advance_turn(tick,reference.rng)
						model.total_turns=turn
						model.begin_turn()
						check(model.weather.queue==expected.queue and model.wind==expected.wind_vector() and model.weather.columns==expected.columns and model.weather.random_cursor==expected.random_cursor and model.weather.crt_seed==expected.crt_seed,"Period/slot boundary roster%d side%d turn%d"%[vehicle,side,turn])
	# Independent arithmetic fixture from PE ASM; Match consumes turn0 at start.
	var fixtures: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/mage_weather_native.json"))
	var model = start_pair(2,4,"miramo_town_a","original",0)
	if model.weather.get("is_native")==true:
		check(model.weather.calendar==fixtures[0].calendar.map(func(x):return int(x)),"Match without Mage uses independent31-swap fixture seed0")
		check(model.weather.wind_force==0 and model.weather.wind_angle==154 and model.weather.random_cursor==3,"Independent native turn0 wind and table cursor")
		_test_global_effects(model)
		_test_snapshot(model)
	# Mask readiness and selection of native projectile contact are separate.
	for vehicle in range(1,17):
		check(Contact.active({"vehicle":vehicle})==(vehicle in [1,2,6,8,13,16]),"Preparing global mask does not change contact physics vehicle%d"%vehicle)
	finish("NATIVE WEATHER ROSTER CHECKS")

func _test_global_effects(model) -> void:
	model.weather.calendar.fill(5)
	model.actors[0].hp=500
	model.actors[1].hp=500
	model.active=0
	model.begin_turn()
	check(model.actors[0].hp==533 and model.actors[1].hp==500,"Moon without Mage heals only active Bigfoot3%")
	model.actors[0].hp=model.actors[0].max_hp-1
	model.begin_turn()
	check(model.actors[0].hp==model.actors[0].max_hp,"Moon caps final health")
	model.actors[0].hp=0
	check(model.weather.moon_heal(model.actors[0])==0,"Moon cannot revive")
	model.actors[0].hp=500
	model.actors[0].active=false
	check(model.weather.moon_heal(model.actors[0])==0,"Moon skips inactive actor")
	model.actors[0].erase("active")
	var grub = start_pair(13,2,"","all")
	grub.weather.calendar.fill(5)
	grub.actors[0].hp=500
	grub.begin_turn()
	check(grub.actors[0].hp==580 and grub.actors[1].hp==grub.actors[1].max_hp,"Moon heals eligible Grub8%, no passive turn cure")
	model.weather.calendar.fill(6)
	model.actors[0].turn_item="dual"
	model.actors[1].turn_item="dual_plus"
	var inventory: Array=model.actors[0].items.duplicate(true)
	model.begin_turn()
	check(model.items_locked() and model.actors.all(func(actor):return actor.turn_item=="") and model.actors[0].items==inventory,"Eclipse clears both Dual modes without spending stock")
	check(model.can_use_special(0),"Eclipse adds no SS lock")
	model.weather.calendar.fill(4)
	model.weather.thor.pos.y=980
	model.weather.thor.xp=1000
	model.total_turns=2
	model.begin_turn()
	check(model.weather.thor.active and model.weather.thor.pos.y==1000 and model.weather.thor.level==3,"Thor boundary capsY and refreshes level")
	model.weather.calendar.fill(3)
	model.begin_turn()
	check(model.weather.thor.active,"Thor remains active between period boundaries")
	model.begin_turn()
	check(not model.weather.thor.active and model.weather.thor.pos.y==1000 and model.weather.thor.xp==1000,"Leaving Thor preserves position andXP")

func _test_snapshot(model) -> void:
	model.weather.calendar.fill(4)
	model.total_turns=6
	model.begin_turn()
	model.weather.add_column("force",500,1)
	var before = model.weather.copy()
	var rng_state: int=model.rng.state
	var sim = Snapshot.capture(model)
	sim.weather.calendar[0]=6
	sim.weather.random_table[0]=123
	sim.weather.spawn_ranges.force[0]=Vector2i(5,6)
	sim.weather.columns[0].x=200
	sim.weather.thor.xp=9000
	sim.weather.advance_turn(9,sim.rng)
	check(model.weather.calendar==before.calendar and model.weather.random_table==before.random_table and model.weather.spawn_ranges==before.spawn_ranges and model.weather.columns==before.columns and model.weather.thor==before.thor and model.rng.state==rng_state,"Snapshot mutation isolates calendar/table/ranges/columns/Thor and RNG")
	var actors: Array=model.actors.duplicate(true)
	var terrain: PackedByteArray=model.terrain.native_cells.duplicate()
	model.predict_shot(0,45,30,0)
	check(model.actors==actors and model.terrain.native_cells==terrain and model.weather.thor==before.thor and model.weather.crt_seed==before.crt_seed and model.rng.state==rng_state,"CPU shot search leaves live global climate and terrain untouched")
	model.weather.columns.clear()
	model.events.clear()
	check(model.fire(45,30,0),"Non-native-contact shot under Thor launches")
	sim=Snapshot.capture(model)
	Snapshot.arm(sim,0,0,model.projectiles.duplicate(true))
	# arm intentionally clears attribution for a proposed shot; this fixture
	# starts from the same already-fired action, including its Gold tracker.
	sim.shot_gold=model.shot_gold.duplicate(true)
	model.events.clear()
	var identical:=true
	var thor_events:=0
	for tick in 1000:
		# Two fractional calls must equal one fixed step.
		model.advance_projectiles(0.025)
		model.advance_projectiles(0.025)
		sim.advance_projectiles(0.05)
		identical=identical and model.events==sim.events and model.actors==sim.actors and model.weather.thor==sim.weather.thor and model.terrain.native_cells==sim.terrain.native_cells and model.shot_gold==sim.shot_gold
		for event in model.events:
			if event.type=="thor":thor_events+=1
		model.events.clear()
		sim.events.clear()
		if model.phase!=Match.PHASE_FLIGHT:break
	check(identical and thor_events==4,"Bigfoot4 components snapshot parity=%s Thor requests=%d"%[identical,thor_events])
