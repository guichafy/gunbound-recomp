extends "res://tests/support/suite.gd"
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Shell = preload("res://scripts/shell_state.gd")
const Boomer = preload("res://scripts/boomer_flight.gd")
const Mobiles = preload("res://scripts/mobiles.gd")

func model_with_item(item: String = ""):
	var model = Match.new()
	model.start(6,1,42,"","original",null,[] if item.is_empty() else [item])
	model.actors[0].pos = Vector2(500,100)
	model.actors[1].pos = Vector2(1100,400)
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	if not item.is_empty():
		model.use_item(0)
	return model

func launch_clock() -> void:
	var model = model_with_item()
	var shells: Array = model.shot_shells(0,45,60,1)
	check(shells.size() == 4,"S2 four shells")
	for index in 4:
		check(is_equal_approx(float(shells[index].spawn_at),[0.4,0.5,0.6,0.7][index]),"S2 native spawn tick" + str(index))
		check(shells[index].pos == shells[0].pos and shells[index].velocity == shells[0].velocity,"S2 same aim power muzzle " + str(index))
	model.fire(45,60,1)
	var launches: Array = []
	for tick in range(1,16):
		model.tick(0.05)
		for event in model.events:
			if event.type == "projectile_launch":
				launches.append(tick)
		model.events.clear()
	check(launches == [8,10,12,14],"S2 actual native ticks8/10/12/14")
	for weapon in [0,2]:
		check(is_equal_approx(float(model.shot_shells(0,45,60,weapon)[0].spawn_at),0.4),"S1/SS tick8 " + str(weapon))

func transformation() -> void:
	var model = model_with_item()
	model.fire(87,60,2)
	for _i in 8:
		model.tick(0.05)
	var shell: Dictionary = model.projectiles[0]
	check(int(shell.flight_ticks) == 0,"emission boundary before first flight tick")
	for _i in 35:
		model.tick(0.05)
	check(int(shell.flight_ticks) == 35 and shell.ss_state == "normal","SS normal through35")
	Physics.import_external_motion(shell,Vector2(shell.pos.x,300),shell.velocity)
	shell.hit_pos = shell.pos
	model.weather.add_column("mirror",shell.pos.x,1)
	var position: Vector2i = shell.fp_pos
	var velocity: Vector2i = shell.fp_velocity
	for index in 10:
		model.tick(0.05)
		check(shell.fp_pos == position and shell.fp_velocity == velocity,"SS frozen tick" + str(index+36))
		check(shell.ss_state == "change" and int(shell.ss_state_tick) == index,"SS model change tick" + str(index+36))
	model.weather.columns.clear()
	model.tick(0.05)
	check(int(shell.flight_ticks) == 46 and shell.ss_state == "cnormal","SS resumes46")
	check(shell.fp_pos != position and int(shell.damage) == 700,"SS doubles damage and moves at46")
	check(is_equal_approx(float(shell.blast_radius),27.5),"SS scales diameter46→55 before radius")
	model.tick(0.05)
	check(int(shell.damage) == 700 and is_equal_approx(float(shell.blast_radius),27.5),"SS transforms only once")
	for item in ["dual","dual_plus"]:
		var dual = model_with_item(item)
		var both: Array = dual.shot_shells(0,90,60,2)
		check(both.size() >= 2,"SS with " + item)
		dual.seed_projectile(both[0])
		dual.seed_projectile(both[-1])
		Boomer.begin_tick(both[0])
		check(int(both[0].flight_ticks) == 1 and int(both[-1].flight_ticks) == 0,"independent flight clocks " + item)

func parity() -> void:
	for wind in [Vector2.ZERO,Vector2(26,0),Vector2(-26,0)]:
		for item in ["","dual","dual_plus"]:
			var model = model_with_item(item)
			model.wind = wind
			var weapon := 2 if item.is_empty() else 1
			model.actors[1].pos = Vector2(900,model.terrain.surface_at(900)-30)
			var predicted: Dictionary = model.predict_shot(0,45,25,weapon)
			check(model.fire(45,25,weapon),"legal Boomer shot " + item)
			var simulation = Snapshot.capture(model)
			Snapshot.arm(simulation,0,weapon,model.projectiles.duplicate(true))
			model.events.clear()
			var outcomes: Array = []
			for _i in 300:
				if model.phase != "flight":
					break
				model.tick(0.05)
				simulation.advance_projectiles(0.05)
				for event in model.events:
					if event.type in ["explosion","miss","teleport"]:
						outcomes.append(event)
				model.events.clear()
			var found := false
			for event in outcomes:
				found = found or (Vector2(event.position).distance_to(Vector2(predicted.position)) < 0.0001 and int(event.get("collided_actor",-1)) == int(predicted.actor))
			check(found,"real/predict same outcome wind" + str(wind) + " item" + item)
			var reference_outcomes: Array = []
			for event in simulation.events:
				if event.type in ["explosion","miss","teleport"]:
					reference_outcomes.append(event)
			check(outcomes == reference_outcomes,"full outcome trace parity wind" + str(wind) + " item" + item)
			check(model.terrain.cells == simulation.terrain.cells,"crater mask parity wind" + str(wind) + " item" + item)
			check(model.actors == simulation.actors,"actor damage and attribution parity wind" + str(wind) + " item" + item)

func frame_rates() -> void:
	var states: Array = []
	for fps in [30,60,120]:
		var model = model_with_item()
		model.fire(90,60,2)
		for _i in fps*3:
			model.tick(1.0/fps)
		var shell: Dictionary = model.projectiles[0]
		states.append([model.flight_elapsed,shell.fp_pos,shell.fp_velocity,shell.flight_ticks,shell.ss_state])
	check(states[0] == states[1] and states[1] == states[2],"exact FP state3s at30/60/120Hz")

func run() -> void:
	launch_clock()
	transformation()
	parity()
	frame_rates()
	finish("BOOMER CHECKS")
