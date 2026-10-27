extends "res://tests/support/suite.gd"
const Native=preload("res://scripts/aduka_weather.gd")
const Physics=preload("res://scripts/classic_ballistics.gd")
const Match=preload("res://scripts/match.gd")
const Snapshot=preload("res://scripts/flight_snapshot.gd")
const Lightning=preload("res://scripts/lightning_combat.gd")
func run() -> void:
	# Same branch instructions as Aduka; independent Python integer oracle.
	var fixtures: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/aduka_tornado_native.json"))
	for fixture in fixtures:
		var shell: Dictionary={"vehicle":8,"fp_pos":Vector2i(25600,51200),"fp_velocity":Vector2i(fixture.velocity[0],fixture.velocity[1]),"fp_acceleration":Vector2i(fixture.acceleration[0],fixture.acceleration[1]),"tornado":{"native":true,"column":1,"center":100,"half":32,"turns":0}}
		check(Native.active(shell),"Lightning selects native tornado")
		for tick in fixture.trace.size():
			Physics.move(shell)
			Physics.finish_tick(shell,Native.finish(shell))
			var expected: Array=fixture.trace[tick]
			check(shell.fp_pos==Vector2i(expected[0],expected[1]) and shell.fp_velocity==Vector2i(expected[2],expected[3]) and not shell.tornado.is_empty()==bool(expected[4]),"Independent Lightning tornado%s tick%d"%[fixture.velocity,tick])
	for weapon in 3:
		for facing in [-1,1]:
			for wind in [Vector2(27,0),Vector2(-27,0),Vector2(0,27),Vector2(0,-27)]:
				var model=Match.new()
				model.start(8,1,42,"","original",null,[],[],[],0,4)
				model.wind=wind
				model.actors[0].facing=facing
				model.actors[0].ss_lock=0
				model.weather.columns.clear()
				var shells: Array=model.shot_shells(0,30,60,weapon)
				model.weather.add_column("tornado",shells[0].pos.x,1.0)
				var sim=Snapshot.capture(model)
				Snapshot.arm(sim,0,weapon,shells.duplicate(true))
				check(model.fire(30,60,weapon),"Live Lightning launches into tornado")
				model.events.clear()
				var entered:=false
				for tick in 100:
					if model.phase!=Match.PHASE_FLIGHT:break
					model.advance_projectile_tick(0.05)
					sim.advance_projectile_tick(0.05)
					for shot in model.projectiles:
						if not shot.tornado.is_empty():
							entered=true
							check(bool(shot.tornado.get("native",false)),"No C# normalized impulse")
					check(model.projectiles==sim.projectiles and model.events==sim.events,"Lightning weather execution equals CPU snapshot")
				check(entered,"Weapon%d facing%d wind%s exercises tornado"%[weapon,facing,wind])
	var model=Match.new()
	model.start(8,1,42,"","original",null,["dual_plus","teleport","thunder"])
	model.weather.columns.clear()
	model.weather.add_column("force",100,1.0)
	for weapon in 3:
		var shot: Dictionary=model.shot_shells(0,30,40,weapon)[0]
		var power:=int(shot.damage)
		var sampled:=Native.sample(model,shot,Vector2i(100,-30),false)
		Native.sample(model,shot,Vector2i(100,30),sampled)
		check(int(shot.native_force)==20 and int(shot.damage)==power,"Force once per tick, separate from power and shock")
		var sim=Snapshot.capture(model)
		Snapshot.arm(sim,0,weapon,[shot.duplicate(true)])
		sim.projectiles[0].native_force=99
		check(int(shot.native_force)==20,"Native Force is private per shell/snapshot")
	# Remaining authorized offline weather bridges must still agree with CPU.
	for kind in ["weakness","mirror","electricity","random","thor","ignorance","protection"]:
		model=Match.new()
		model.start(8,1,42,"","original",null,[],[],[],0,4)
		model.weather.columns.clear()
		model.actors[0].ss_lock=0
		var shells: Array=model.shot_shells(0,30,30,0)
		if kind in ["weakness","mirror","electricity","random"]:
			var column: Dictionary=model.weather.add_column(kind,shells[0].pos.x,1.0)
			if kind=="random":column.extra="force"
		elif kind=="thor":model.weather.thor.active=true
		else:
			model.weather.queue[0].type=kind
			model.apply_weather({"type":kind,"extra":""})
		var sim=Snapshot.capture(model)
		Snapshot.arm(sim,0,0,shells.duplicate(true))
		check(model.fire(30,30,0),"Bridge weather%s launches"%kind)
		for tick in 100:
			if model.phase!=Match.PHASE_FLIGHT:break
			model.advance_projectile_tick(0.05)
			sim.advance_projectile_tick(0.05)
		var same: bool=model.projectiles==sim.projectiles and model.weather.columns==sim.weather.columns
		for index in 2:
			for key in ["hp","shield","pos"]:same=same and model.actors[index][key]==sim.actors[index][key]
		check(same,"Offline weather%s execution equals prediction"%kind)
	finish("LIGHTNING WEATHER CHECKS")
