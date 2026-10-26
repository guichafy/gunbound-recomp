extends "res://tests/support/suite.gd"
const Raon = preload("res://scripts/raon_effect.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Mobiles = preload("res://scripts/mobiles.gd")

class FlatGround:
	extends RefCounted
	var edge := 10000.0
	func surface_at(x: float, _from: float = 0.0) -> float:
		return 700.0 if x < edge else 2000.0
	func is_void(y: float) -> bool:
		return y >= 2000.0

## Ground anchor (pos+stance) at `at.y`, the native mobile+0xb30 convention.
func actor(at: Vector2, hp: int = 100) -> Dictionary:
	return {"pos":at-Vector2(0,float(Mobiles.definition(7).stance)),"hp":hp,"vehicle":7,"tilt":0.0}

func shell(component: int) -> Dictionary:
	var shot := {"flight":"raon_orbit","weapon":0,"age":0.0,"velocity":Vector2(200,0),"fp_velocity":Vector2i(2560,0),"pos":Vector2(100,100)}
	Raon.prepare(shot,{"raon_component":component})
	return shot

func test_native_s1() -> void:
	# Independently hand-derived from PE phase+40, LUT float32, +/-13,
	# FPU truncation, SHL8. These are pixel offsets, not ideal float sines.
	var right_y := [-8,-12,-11,-4,4,11,12,8,0]
	# Components 1/2 are the 2nd/3rd MainAction calls: idx2 phase0, idx3 phase180.
	for component in [1,2]:
		var shot := shell(component)
		check(int(shot.raon_phase) == (0 if component == 1 else 180),"Spawner idx2/idx3 phases are0/180")
		for tick in 9:
			var at := Raon.hit_point(shot,Vector2(100,100))
			var expected := int(right_y[tick]) * (1 if component == 1 else -1)
			check(at == Vector2(100,100+expected),"Native phase/13px/truncate tick%d component%d" % [tick+1,component])
			check(shot.pos == Vector2(100,100),"Orbit never accumulates into carrier")
			Raon.finish_tick(shot)
	for heading in [0,90,180,270]:
		var expected: Vector2i = {0:Vector2i(2048,0),90:Vector2i(0,-2048),180:Vector2i(-2048,0),270:Vector2i(0,2048)}[heading]
		check(Raon.offset_fp(heading,40) == expected,"Cardinal geometry independent fixture heading%d" % heading)
	var straight := shell(0)
	check(Raon.hit_point(straight,Vector2(90,100)) == Vector2(90,100),"idx0 is common projectile")
	var beacon := shell(1)
	beacon.beacon = true
	check(not Raon.active(beacon),"Teleport beacon cannot inherit Raon orbit")

func test_mines() -> void:
	var ground := FlatGround.new()
	var projectile := {"weapon":1,"damage":200,"blast_radius":21.0,"velocity":Vector2.RIGHT}
	var mine := Raon.create_mine(projectile,Vector2(100,700),0,7)
	var mines: Array = [mine]
	var actors: Array = [actor(Vector2(-1000,700)),actor(Vector2(191,700))]
	check(mine.owner == 0 and mine.vehicle == 7 and mine.weapon == 1,"Mine freezes owner/mobile/weapon at creation")
	Raon.refresh_target(mine,actors)
	check(mine.target == -1 and Raon.visual_state(mine) == "normal","Outside90px mine remains dormant")
	actors[1].pos = Vector2(190,700)
	Raon.refresh_target(mine,actors)
	check(mine.target == -1,"Exactly90px is outside the strict fallback activation range")
	actors[1].pos = Vector2(189,700)
	Raon.refresh_target(mine,actors)
	check(mine.target == 1 and Raon.visual_state(mine) == "active","Inside strict90px mine activates")
	var copy: Dictionary = mine.duplicate(true)
	Raon.step_mines(mines,actors,ground,0.0)
	check(mine == copy,"Pause does not mutate mine state or clocks")
	Raon.begin_turn(mines,actors,1)
	check(int(mine.steps) == 0,"Other actor cannot grant movement to owned mine")
	Raon.begin_turn(mines,actors,0)
	check(int(mine.steps) == 90,"S2 gets fallback90px on owner turn")
	for tick in 10:
		Raon.step_mines(mines,actors,ground,0.05)
	check(mine.pos == Vector2(100,700),"S2 waits0.5s before walking")
	Raon.step_mines(mines,actors,ground,0.05)
	check(mine.pos.x == 103.0 and Raon.visual_state(mine) == "move","First movement progresses3px and plays move EPA")
	actors[1].pos = Vector2(250,700)
	Raon.step_mines(mines,actors,ground,0.05)
	check(mine.target == -1 and mine.steps == 0,"Target outside range stops S2 movement")
	projectile.weapon = 2
	var ss := Raon.create_mine(projectile,Vector2(100,700),0,7)
	mines = [ss]
	actors[1].pos = Vector2(5000,700)
	check(Raon.visual_state(ss) == "active","Native supermine begins active")
	for tick in 99:
		check(Raon.step_mines(mines,actors,ground,0.05).is_empty(),"SS remains alive before movement-call100")
	check(ss.pos.x == 397.0,"SS flat terrain advances native3px per call")
	check(Raon.step_mines(mines,actors,ground,0.05) == [0],"SS detonates exactly at movement-call100")
	check(ss.pos.x == 397.0,"SS terminal call does not move again")
	check(ss.owner == 0 and ss.vehicle == 7,"Delayed SS preserves owner/mobile")
	var wall_mine := Raon.create_mine({"weapon":2,"damage":400,"velocity":Vector2.RIGHT},Vector2(100,700),0,7)
	ground.edge = 102.0
	Raon.step_mines([wall_mine],actors,ground,0.05)
	check(wall_mine.pos.x == 101.0 and wall_mine.dir == -1.0,"SS turns at first invalid pixel without crossing the edge")
	ground.edge = 10000.0
	var mine_a := Raon.create_mine(projectile,Vector2(100,700),0,7)
	var mine_b := Raon.create_mine(projectile,Vector2(110,700),1,7)
	actors = [actor(Vector2(100,700)),actor(Vector2(110,700))]
	check(Raon.step_mines([mine_a,mine_b],actors,ground,0.05) == [1,0],"Contact returns reverse removal order and includes the owner")

func test_rates_and_copy() -> void:
	var ground := FlatGround.new()
	var actors: Array = [actor(Vector2(-1000,700))]
	var reference := {}
	for fps in [30,60,120]:
		var mine := Raon.create_mine({"weapon":2,"damage":400,"velocity":Vector2.RIGHT},Vector2(100,700),0,7)
		var copied: Dictionary = mine.duplicate(true)
		for frame in fps*2:
			Raon.step_mines([mine],actors,ground,1.0/fps)
			Raon.step_mines([copied],actors,ground,1.0/fps)
		check(mine == copied,"Execution and copied prediction use identical private clocks at%dFPS" % fps)
		check(int(mine.move_ticks) == 40 and mine.pos.x == 220.0,"Mine clock is physical20Hz at%dFPS" % fps)
		if reference.is_empty():
			reference = mine.duplicate(true)
		else:
			check(mine.pos == reference.pos and mine.state == reference.state and mine.move_ticks == reference.move_ticks,"Render rate does not alter position/state/ticks")

func run() -> void:
	Physics.warmup()
	test_native_s1()
	test_mines()
	test_rates_and_copy()
	finish("RAON EFFECT CHECKS")
