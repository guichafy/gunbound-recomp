extends "res://tests/support/suite.gd"
const Native = preload("res://scripts/aduka_weather.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Match = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Combat = preload("res://scripts/aduka_combat.gd")
const Weather = preload("res://scripts/weather.gd")

func run() -> void:
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/aduka_tornado_native.json"))
	for fixture in fixtures:
		var shell := {"fp_pos":Vector2i(25600,51200),"fp_velocity":Vector2i(fixture.velocity[0],fixture.velocity[1]),
			"fp_acceleration":Vector2i(fixture.acceleration[0],fixture.acceleration[1]),"tornado":{"native":true,"column":1,"center":100,"half":32,"turns":0}}
		for index in fixture.trace.size():
			Physics.move(shell)
			var accelerate := Native.finish(shell)
			Physics.finish_tick(shell,accelerate)
			var row: Array = fixture.trace[index]
			check(shell.fp_pos==Vector2i(row[0],row[1]) and shell.fp_velocity==Vector2i(row[2],row[3]) and (not shell.tornado.is_empty())==bool(row[4]),"Native4aafd0 independent tornado trace%s tick%d"%[str(fixture.velocity),index])
	var model = Match.new()
	model.start(16,1,32,"")
	model.weather.columns.clear()
	model.weather.add_column("tornado",400,1.0)
	model.weather.add_column("force",600,1.0)
	var shot: Dictionary = model.shot_shells(0,35,60,1)[0]
	Native.sample(model,shot,Vector2i(368,-30),false)
	check(shot.tornado.is_empty(),"Native tornado left border is strict even above world")
	Native.sample(model,shot,Vector2i(369,-30),false)
	check(not shot.tornado.is_empty(),"Native tornado samples X above world, without adapter Y clipping")
	check(not shot.tornado.has("speed") and not shot.tornado.has("direction"),"Native tornado stores no normalized-speed impulse")
	for index in 15:
		Native.sample(model,shot,Vector2i(600,100),false)
		check(int(shot.native_force)==mini(100,20+index*8),"Native Force accumulation tick%d"%index)
	check(shot.damage==0,"Force never substitutes arbitrary damage for the T2 guide")
	var t1: Dictionary = model.shot_shells(0,35,60,0)[0]
	var base := int(t1.damage)
	Native.sample(model,t1,Vector2i(600,100),false)
	var data := Combat.t1_parameters(t1,model.actors[0])
	check(int(data.weather_bonus)==20 and int(t1.damage)==base,"Force is a separate native bonus pass, not base×1.2+10")
	for wind in [Vector2(27,0),Vector2(-27,0),Vector2(0,27),Vector2(0,-27)]:
		for facing in [-1,1]:
			model = Match.new()
			model.start(16,1,42,"")
			model.wind = wind
			model.weather.columns.clear()
			model.actors[0].facing = facing
			var shells: Array = model.shot_shells(0,35,60,1)
			var entry: Vector2 = shells[0].pos
			model.weather.add_column("tornado",entry.x,1.0)
			var sim = Snapshot.capture(model)
			Snapshot.arm(sim,0,1,shells.duplicate(true))
			model.fire(35,60,1)
			model.events.clear()
			var native_ticks := 0
			for index in 80:
				if model.phase!=Match.PHASE_FLIGHT:break
				model.advance_projectile_tick(0.05)
				sim.advance_projectile_tick(0.05)
				for projectile in model.projectiles:
					if not projectile.tornado.is_empty():
						native_ticks += 1
						check(bool(projectile.tornado.get("native",false)),"Actual Aduka never enters old tornado adapter")
				check(model.projectiles==sim.projectiles and model.events==sim.events,"Wind/tornado execution equals CPU %s facing%d tick%d"%[str(wind),facing,index])
			check(native_ticks>0,"Real three-creature T2 traverses native tornado for current wind%s facing%d"%[str(wind),facing])
	finish("ADUKA WEATHER CHECKS")
