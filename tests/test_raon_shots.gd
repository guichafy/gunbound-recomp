extends "res://tests/support/suite.gd"
## Raon T1/T2/SS shot contracts from Mobile06_MainAction 0x49c120 (ADR-116).
## Expected powers/phases come from the PE (RAON_CLASSIC_FIX.md), not from
## the catalog under test: P is the quantized native power, offsets are integers.
const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Raon = preload("res://scripts/raon_effect.gd")
const RAON := 7
## WinMain 0x40d9d2 stores 15 in 0x794bf0; S2 adds/subtracts it, SS adds it.
const NATIVE_OFFSET := 15

func run() -> void:
	test_t1_phases()
	for facing in [1,-1]:
		for native in [1,15,16,440]:
			test_powers(facing,native)
	test_mine_shells_cross_mobiles()
	test_t1_still_hits_mobiles()
	test_supermine_direction()
	test_mine_under_target_detonates()
	test_prediction_matches(1)
	test_prediction_matches(2)
	finish("RAON SHOTS CHECKS")

func fresh(facing: int = 1):
	var model = Match.new()
	model.start(RAON,1,42,"")
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.terrain.cells.fill(0)
	for y in range(220,model.terrain.HEIGHT):
		for x in model.terrain.WIDTH:
			model.terrain.cells[y*model.terrain.WIDTH+x] = 1
	# Feet (pos+stance) on the ground row y=440, the native mobile anchor.
	model.actors[0].pos = Vector2(200 if facing > 0 else 1000,440-float(Mobiles.definition(RAON).stance))
	model.actors[0].facing = facing
	model.actors[1].pos = Vector2(640,440-float(Mobiles.definition(int(model.actors[1].vehicle)).stance))
	model.actors[1].hp = 2000
	model.actors[1].max_hp = 2000
	model.actors[0].ss_lock = 0
	return model

## Percent whose quantized native power is exactly `native` for Raon.
func percent_for(native: int) -> float:
	return (float(native)+0.5)*10.0/float(Mobiles.force_max(RAON))

func test_t1_phases() -> void:
	var model = fresh()
	var shells: Array = model.shot_shells(0,45,50,0)
	check(shells.size() == 3,"T1 has the three native spawner calls")
	# idx0 common, idx2 phase0, idx3 phase180 (0x42c295/0x42c2af).
	check(not Raon.active(shells[0]) or int(shells[0].get("raon_component",0)) == 0,"T1 first emission is the common idx0 projectile")
	check(int(shells[1].get("raon_phase",-1)) == 0,"T1 second emission is idx2: phase0")
	check(int(shells[2].get("raon_phase",-1)) == 180,"T1 third emission is idx3: phase180")
	for shell in shells:
		check(shell.launch_velocity_fp == shells[0].launch_velocity_fp,"T1 components share power and angle")

func test_powers(facing: int, native: int) -> void:
	var model = fresh(facing)
	var percent := percent_for(native)
	check(Physics.native_power(percent,Mobiles.force_max(RAON)) == native,"fixture quantizes to P%d" % native)
	var theta := 45 if facing > 0 else 135
	var t2: Array = model.shot_shells(0,45,percent,1)
	check(t2.size() == 2,"T2 emits two shells P%d facing%d" % [native,facing])
	if t2.size() == 2:
		check(t2[0].launch_velocity_fp == Physics.launch_velocity_fp(theta,native+NATIVE_OFFSET),"T2 first shell is P+15 at P%d facing%d" % [native,facing])
		check(t2[1].launch_velocity_fp == Physics.launch_velocity_fp(theta,native-NATIVE_OFFSET),"T2 second shell is P-15 at P%d facing%d" % [native,facing])
		check(Vector2(t2[0].pos) == Vector2(t2[1].pos),"T2 shells share the muzzle: no angular spread")
	var ss: Array = model.shot_shells(0,45,percent,2)
	check(ss.size() == 1,"SS emits one shell")
	if ss.size() == 1:
		check(ss[0].launch_velocity_fp == Physics.launch_velocity_fp(theta,native+NATIVE_OFFSET),"SS is P+15 at P%d facing%d" % [native,facing])
	var t1: Array = model.shot_shells(0,45,percent,0)
	check(t1[0].launch_velocity_fp == Physics.launch_velocity_fp(theta,native),"T1 keeps the unmodified P%d" % native)

## Place a launched shell above the target moving straight down through its box.
func drop_through_target(model, weapon: int) -> Dictionary:
	model.fire(45,50,weapon)
	model.events.clear()
	var shell: Dictionary = model.projectiles[0]
	model.projectiles = [shell]
	var start := Vector2(640,340)
	shell.launched = true
	shell.pos = start; shell.hit_pos = start
	shell.previous_draw_pos = start; shell.previous_hit_pos = start
	shell.velocity = Vector2(0,400)
	shell.trail = [start]
	shell.age = 1.0
	shell.fp_ready = false
	shell.erase("launch_velocity_fp")
	var log: Array = []
	for tick in 20:
		model.advance_projectiles(0.05)
		log.append_array(model.events)
		model.events.clear()
		if model.projectiles.is_empty():
			break
	return {"events":log,"mines":model.mines.duplicate(true)}

func test_mine_shells_cross_mobiles() -> void:
	for weapon in [1,2]:
		var model = fresh()
		var target_top: float = float(model.actors[1].pos.y)-25.0
		var result := drop_through_target(model,weapon)
		var plants: Array = result.events.filter(func(event): return event.type == "mine_plant")
		check(plants.size() == 1,"W%d shell plants exactly one mine" % weapon)
		if plants.size() == 1:
			check(float(plants[0].position.y) >= 439.0,"W%d mine shell crosses the mobile and plants on the ground below (y=%.1f)" % [weapon,float(plants[0].position.y)])
			check(float(plants[0].position.y) > target_top+20.0,"W%d does not stop on the mobile box" % weapon)

## User acceptance: the shell crosses the body, plants under the feet and the
## AnimateMine radius (8px to the anchor) detonates it on the next ticks.
func test_mine_under_target_detonates() -> void:
	for weapon in [1,2]:
		var model = fresh()
		var before := int(model.actors[1].hp)+int(model.actors[1].shield)
		var result := drop_through_target(model,weapon)
		var log: Array = result.events
		for tick in 3:
			if model.mines.is_empty():
				break
			if model.phase == Match.PHASE_FLIGHT:
				model.advance_projectiles(0.05)
			else:
				model.tick(0.05)
			log.append_array(model.events)
			model.events.clear()
		var blasts: Array = log.filter(func(event): return event.type == "explosion" and bool(event.get("raon_mine",false)))
		check(blasts.size() == 1,"W%d mine under the target's feet detonates" % weapon)
		check(model.mines.is_empty(),"W%d detonated mine leaves the field" % weapon)
		check(int(model.actors[1].hp)+int(model.actors[1].shield) < before,"W%d mine blast damages the mobile standing on it" % weapon)
		if weapon == 2:
			for tick in 40:
				if model.phase != Match.PHASE_FLIGHT:
					break
				model.advance_projectiles(0.05)
			check(model.phase != Match.PHASE_FLIGHT,"SS turn leaves FLIGHT after its mine detonates")

func test_t1_still_hits_mobiles() -> void:
	var model = fresh()
	var result := drop_through_target(model,0)
	var hits: Array = result.events.filter(func(event): return event.type == "explosion" and int(event.collided_actor) == 1)
	check(not hits.is_empty(),"T1 keeps the common mobile hit test")

func test_supermine_direction() -> void:
	# DetonateSuperShot 0x49c064: SETG on [obj+0x488] (vx); zero goes left.
	var cases := [[Vector2i(256,0),1.0],[Vector2i(0,512),-1.0],[Vector2i(-256,0),-1.0]]
	for entry in cases:
		for facing in [1.0,-1.0]:
			var mine := Raon.create_mine({"weapon":2,"fp_ready":true,"fp_velocity":entry[0],"mine_damage":400,"mine_radius":21.0},Vector2(100,100),0,RAON,facing)
			check(float(mine.dir) == float(entry[1]),"Supermine vx_fp%d facing%d walks %d" % [entry[0].x,facing,entry[1]])
	# An unseeded shell (fp_velocity still zero) falls back to its float velocity.
	var unseeded := Raon.create_mine({"weapon":2,"fp_ready":false,"fp_velocity":Vector2i.ZERO,"velocity":Vector2(200,-50)},Vector2(100,100),0,RAON)
	check(float(unseeded.dir) == 1.0,"Unseeded supermine reads the float velocity")
	# Real path: the planted mine walks by the sign of vx_fp at the impact tick.
	for facing in [1,-1]:
		var model = fresh(facing)
		model.fire(45,percent_for(150),2)
		var seen := false
		for tick in 400:
			var before: Array = model.projectiles.map(func(shell): return Vector2i(shell.fp_velocity).x)
			model.advance_projectiles(0.05)
			var planted: Array = model.events.filter(func(event): return event.type in ["mine_plant","miss"])
			model.events.clear()
			if not planted.is_empty():
				check(planted[0].type == "mine_plant","Fired supermine lands on the fixture facing%d" % facing)
				# The impact tick leaves the velocity read by the mine unchanged.
				var expected := 1.0 if int(before[0]) > 0 else -1.0
				check(not model.mines.is_empty() and float(model.mines[0].dir) == expected,"Fired supermine facing%d walks with its impact vx" % facing)
				seen = true
				break
		check(seen,"Fired supermine is planted facing%d" % facing)

func test_prediction_matches(weapon: int) -> void:
	for facing in [1,-1]:
		var model = fresh(facing)
		var percent := percent_for(300)
		var predicted: Dictionary = model.predict_shot(0,45,percent,weapon)
		model.fire(45,percent,weapon)
		var plants: Array = []
		for tick in 400:
			model.advance_projectiles(0.05)
			for event in model.events:
				if event.type in ["mine_plant","explosion","miss"]:
					plants.append(event)
			model.events.clear()
			if model.phase != Match.PHASE_FLIGHT:
				break
		var best := INF
		for event in plants:
			best = minf(best,Vector2(event.position).distance_to(model.actors[1].pos))
		check(not predicted.is_empty() and is_equal_approx(Vector2(predicted.position).distance_to(model.actors[1].pos),best),"W%d facing%d prediction equals execution" % [weapon,facing])
