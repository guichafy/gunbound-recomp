extends "res://tests/support/suite.gd"
const Water = preload("res://scripts/classic_projectile_art.gd")
const Timing = preload("res://scripts/classic_shot_timing.gd")
const Flight = preload("res://scripts/classic_flight.gd")
const Shell = preload("res://scripts/shell_state.gd")
const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Sprite = preload("res://scripts/classic_sprite.gd")

func test_opening_state(vehicle: int, sprite) -> void:
	var info: Dictionary = sprite.sheet("Bullet3.png")
	var shot: Dictionary = Shell.create(Vector2(100,100),Vector2(80,-20),0,Mobiles.weapon(vehicle,2),2,0)
	shot.age = float(shot.transform_at)-0.05
	Flight.open_shell(shot)
	check(not bool(shot.get("opened",false)) and info.states.normal.has(float(sprite.projectile_frame(info,shot))),"%d remains normal before existing open_shell threshold" % vehicle)
	shot.age = float(shot.transform_at)
	var damage_before := int(shot.damage)
	Flight.open_shell(shot)
	check(bool(shot.opened) and shot.hold == 0.73 and int(shot.damage) == damage_before+int(shot.extra_damage),"%d keeps existing opening damage/hold" % vehicle)
	check(sprite.projectile_frame(info,shot) == int(info.states.change[0]),"%d opening starts in first EPA change frame at the machine transition" % vehicle)
	var frozen: Vector2 = shot.pos
	for tick in 7:
		Flight.hold(shot,0.05)
	check(info.states.change.has(float(sprite.projectile_frame(info,shot))),"%d remains in change while existing hold is active" % vehicle)
	check(sprite.projectile_frame(info,shot) == int(info.states.change[7]),"%d held change advances from state-local clock" % vehicle)
	var rendered: int = sprite.projectile_frame(info,shot)
	shot.age += 90.0
	check(sprite.projectile_frame(info,shot) == rendered,"%d changing flight age cannot override active transformation state" % vehicle)
	shot.age -= 90.0
	for tick in 8:
		Flight.hold(shot,0.05)
	check(shot.hold == 0.0 and shot.pos == frozen,"%d completes same hold without changing physical position" % vehicle)
	if info.states.has("cnormal"):
		check(sprite.projectile_frame(info,shot) == int(info.states.cnormal[0]),"%d hold exit enters first cnormal frame" % vehicle)
		Flight.open_shell(shot)
		check(sprite.projectile_frame(info,shot) == int(info.states.cnormal[1]),"%d opened animation advances after hold" % vehicle)
	else:
		check(sprite.projectile_frame(info,shot) == int(info.states.change[-1]),"%d with no cnormal retains terminal EPA change frame after hold" % vehicle)
	check(int(shot.damage) == damage_before+int(shot.extra_damage),"%d opening damage remains idempotent" % vehicle)

func test_opening_flight(vehicle: int, sprite) -> void:
	var model = Match.new()
	model.start(vehicle,1,42,"","original")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.cells.fill(0)
	model.actors[0].pos = Vector2(100,650)
	model.actors[1].pos = Vector2(1200,700)
	model.actors[0].ss_lock = 0
	model.fire(45,50,2)
	var info: Dictionary = sprite.sheet("Bullet3.png")
	var started := false
	var held := false
	var completed := false
	var frozen := Vector2.ZERO
	for step in 100:
		model.tick(0.05)
		if model.projectiles.is_empty():
			break
		var shot: Dictionary = model.projectiles[0]
		if not started and bool(shot.get("opened",false)):
			started = true
			frozen = shot.pos
			check(sprite.projectile_frame(info,shot) == int(info.states.change[0]),"%d real flight begins change exactly at open_shell event" % vehicle)
		if started and not held and float(shot.get("hold",0)) < 0.5 and float(shot.get("hold",0)) > 0:
			held = true
			check(shot.pos == frozen and info.states.change.has(float(sprite.projectile_frame(info,shot))),"%d real flight remains frozen in change during existing hold" % vehicle)
		if started and float(shot.get("hold",0)) == 0 and not completed:
			completed = true
			var expected: int = int(info.states.cnormal[0]) if info.states.has("cnormal") else int(info.states.change[-1])
			check(shot.pos == frozen and sprite.projectile_frame(info,shot) == expected,"%d real flight hold exit renders opened EPA state without moving early" % vehicle)
			break
	check(started and held and completed,"%d real flight traverses all three opening visual boundaries" % vehicle)

func run() -> void:
	var turtle = Sprite.new()
	turtle.setup("turtle")
	var armor = Sprite.new()
	armor.setup("armor")
	check(turtle.meta.get("projectile_composition", [""])[0] == "water_ribbon", "Turtle T1 composition is WaterEffect, not shared Armor head")
	test_opening_state(4,armor)
	test_opening_flight(4,armor)
	# Turtle has no cnormal flight: test_turtle_projectiles covers its native
	# tick44 ->10 EPA ticks ->six children/removal, including prediction.
	var boomer = Sprite.new()
	boomer.setup("boomer")
	var info: Dictionary = boomer.sheet("Bullet3.png")
	var shell := {"age":0.01, "ss_state":"cnormal", "ss_state_tick":0}
	check(boomer.has_method("projectile_frame"),"Boomer renderer accepts model ss_state rather than elapsed-age heuristic")
	if boomer.has_method("projectile_frame"):
		check(boomer.projectile_frame(info,shell) == int(info.states.cnormal[0]), "Young converted SS renders cnormal from simulation")
	for id in ["armor","trico","boomer","raon","lightning","jd","asate","ice","turtle","grub","dragon","knight","aduka"]:
		var sprite = Sprite.new()
		sprite.setup(id)
		check(sprite.meta.has("contact_feet"), "%s imported contact does not require raw PNG in PCK" % id)
	var history: Array = []
	for i in 30:
		history.append(Vector2(i*10,0))
	var water_shell := {"pos":history[-1],"hit_pos":history[-1],"trail":history,"age":0.599999999,"flight_ticks":12}
	var quads := Water.water_segments(water_shell)
	check(quads.size() == 15,"WaterEffect uses 16 historical points / 15 quads")
	check(is_equal_approx(quads[0].points[0].distance_to(quads[0].points[1]),32),"WaterEffect transverse width is ±16 source pixels")
	check(is_equal_approx(quads[0].uv[0].x,4.0/8),"WaterEffect phase uses tick12 modulo8 across eight full columns")
	check(quads[0].alpha == 1.0 and is_equal_approx(quads[-1].alpha,31.0/255),"WaterEffect preserves the native decreasing alpha nibble with low nibble F")
	check(str(quads) == str(Water.water_segments(water_shell)),"Paused snapshot retains identical water quads and UV")
	check(Timing.frame([3,8],[2,3],0.05) == 3 and Timing.frame([3,8],[2,3],0.10) == 8,"EPA durations hold frames for their source ticks")
	finish("CLASSIC ASSETS CHECKS")
