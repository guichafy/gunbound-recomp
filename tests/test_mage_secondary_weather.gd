extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func run() -> void:
	var model = Match.new()
	model.start(1,1,42,"miramo_town_a")
	check(model.weather.get("is_native")==true,"Mage match uses native climate calendar")
	if model.weather.get("is_native")!=true:
		finish("MAGE SECONDARY WEATHER CHECKS")
		return
	check(model.weather.weights==[2,1,2,1,2,0,0],"Miramo native stage contains Thor, no Moon/Random")
	check(model.weather.thor.present and model.weather.thor.pos.y>=500,"Thor exists independently of climate")
	model.actors[0].hp=500
	model.actors[1].hp=900
	model.actors[0].shield=100
	model.weather.calendar.fill(5)
	model.active=0
	model.begin_turn()
	check(model.actors[0].hp==521 and model.actors[1].hp==900,"Moon heals only active Mage by21")
	check(model.actors[0].shield==130,"Moon leaves normal shield regen30 independent")
	model.active=1
	model.begin_turn()
	check(model.actors[0].hp==521 and model.actors[1].hp==933,"Moon heals Bigfoot33 on own turn")
	model.weather.calendar.fill(6)
	model.actors[0].turn_item="dual"
	model.actors[1].turn_item="dual_plus"
	model.begin_turn()
	check(model.items_locked() and model.actors.all(func(actor):return str(actor.turn_item).is_empty()),"Eclipse locks items and clears both Dual modes globally")
	check(model.can_use_special(model.active),"Eclipse has no extra SS lock")
	var shell: Dictionary=model.shot_shells(0,35,60,0)[0]
	var before:=shell.duplicate(true)
	for kind in ["weakness","mirror","random"]:
		model.weather_interact(shell,{"id":77,"type":kind,"x":500.0,"scale":1.0,"extra":"force","used":false})
	check(shell==before,"C#-only climates cannot modify Mage shell")
	# The same new state is copied deeply; no worker RNG/forecast aliases.
	var copy=model.weather.copy()
	copy.calendar[0]=0
	copy.random_table[0]=123
	copy.thor.xp=900
	check(model.weather.calendar[0]==6 and model.weather.thor.xp==0 and model.weather.random_table[0]!=123,"Independent native weather state copy")
	for weapon in 3:
		for electric in [false,true]:
			model=Match.new()
			model.start(1,1,42,"")
			model.weather.columns.clear()
			model.weather.queue[0].type="thor"
			model.weather.thor.active=true
			model.actors[0].pos=Vector2(600,350)
			model.actors[1].pos=Vector2(950,600)
			model.terrain.cells.fill(0)
			model.terrain.native_cells=PackedByteArray()
			model.terrain.enable_native()
			var shells: Array=model.shot_shells(0,35,30,weapon)
			for projectile in shells:projectile.electric=electric
			var sim=Snapshot.capture(model)
			Snapshot.arm(sim,0,weapon,shells.duplicate(true))
			# Use identical prepared shells to force the climate attachment fixture.
			model.projectiles=shells
			model.shot_actor=0
			model.shot_weapon=weapon
			model.phase=Match.PHASE_FLIGHT
			model.events.clear()
			for tick in 160:
				model.advance_projectiles(0.05)
				sim.advance_projectiles(0.05)
				check(model.events==sim.events and model.actors==sim.actors and model.projectiles==sim.projectiles,"Mage secondary climates real=prediction weapon%d electric%s tick%d"%[weapon,electric,tick])
				check(model.weather.thor==sim.weather.thor and model.terrain.native_cells==sim.terrain.native_cells,"Native Thor/electric state and crater parity")
				if model.phase!=Match.PHASE_FLIGHT:break
	# Scope guard: a pair without Mage keeps its existing weather model.
	model=Match.new()
	model.start(2,1,42,"", "original",null,[],[],[],0,4)
	check(model.weather.get("is_native")!=true,"Native climate replacement scoped to Mage matches")
	finish("MAGE SECONDARY WEATHER CHECKS")
