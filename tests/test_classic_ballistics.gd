extends "res://tests/support/suite.gd"
const Aim = preload("res://scripts/aim_control.gd")
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Boomer = preload("res://scripts/boomer_flight.gd")
const ShellState = preload("res://scripts/shell_state.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const CpuPlanner = preload("res://scripts/cpu_planner.gd")
const Combat = preload("res://scripts/combat.gd")
func run() -> void:
	check(is_equal_approx(Combat.STEP, 0.05), "native 20 Hz")
	var model = Match.new()
	model.start(6, 1, 42, "", "off")
	model.actors[0].pos = Vector2(200, 300)
	model.actors[0].facing = 1
	var v85: Vector2 = model.shot_velocity(0, 85, 100, 0)
	var v88: Vector2 = model.shot_velocity(0, 88, 100, 0)
	var v90: Vector2 = model.shot_velocity(0, 90, 100, 0)
	check(v85 != v88 and v88 != v90, "catalog has one aim clamp, distinct 85/88/90")
	check(absf(v90.x) < 0.0001, "Boomer vertical90")
	check(model.shot_velocity(0, 45, 0, 0) == Vector2.ZERO, "native minimum diagonal P1 is zero")
	reference_fixtures()
	bounds()
	integration()
	charge()
	tornado_bridge()
	launch_boundaries()
	impact_order()
	finish("CLASSIC BALLISTICS CHECKS")

func pair(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func reference_fixtures() -> void:
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/classic_physics_fixtures.json"))
	for row in reference.wind_cases:
		check(Physics.acceleration_fp(int(row.G), int(row.W), int(row.phi)) == pair(row.a), "oracle wind " + str(row))
	for row in reference.angle_cases:
		check(Physics.velocity_angle(pair(row.v)) == int(row.angle), "oracle angle " + str(row))
	for row in reference.fixtures:
		var args: Dictionary = row.input
		var shell := ShellState.create(Vector2.ZERO, Vector2.ZERO, 0.0, {"damage":350,"radius":23.0,"boomer_ss":args.ss}, 2, 0)
		Physics.seed(shell, Vector2i.ZERO, Physics.launch_velocity_fp(int(args.theta), int(args.P)), Physics.acceleration_fp(int(args.G), int(args.W), int(args.phi)))
		check(shell.fp_velocity == pair(row.initial.v), row.name + " initial velocity")
		check(shell.fp_acceleration == pair(row.initial.a), row.name + " initial acceleration")
		if bool(args.boomer):
			Boomer.seed(shell)
			check(bool(shell.boomer_curve) == bool(row.curved), row.name + " spawn flag")
		var checkpoint := 0
		for tick in range(1,81):
			var moving := Boomer.begin_tick(shell) if bool(args.boomer) else true
			if moving:
				Physics.move(shell)
				Physics.finish_tick(shell)
				if bool(args.boomer):
					Boomer.finish_tick(shell)
			if tick != int(row.ticks[checkpoint].tick):
				continue
			var expected: Dictionary = row.ticks[checkpoint]
			var label := str(row.name) + " tick" + str(tick)
			check(shell.fp_pos == pair(expected.p), label + " position")
			check(shell.fp_velocity == pair(expected.v), label + " velocity")
			check(Physics.integer_position(shell) == pair(expected.pixel), label + " integer position")
			if bool(args.boomer):
				check(int(shell.boomer_angle) == int(expected.curve_angle), label + " angle")
				check(int(shell.boomer_direction) == int(expected.direction), label + " direction")
				check(str(shell.ss_state) == str(expected.state), label + " state")
				if bool(args.ss):
					check(int(shell.damage) == int(expected.damage), label + " SS damage")
					check(is_equal_approx(float(shell.blast_radius)*2, float(expected.diameter)), label + " SS diameter")
			checkpoint += 1
		for vehicle in Mobiles.PLAYABLE:
			var maximum := Mobiles.force_max(vehicle)
			check(Physics.native_power(0, maximum) == 1, "minimum P1 " + str(vehicle))
			check(Physics.native_power(100, maximum) == 10*maximum, "maximum P " + str(vehicle))
			check(Physics.native_power(Mobiles.minimum_power(vehicle), maximum) == 1, "percent bridge minimum " + str(vehicle))

func bounds() -> void:
	var world := Vector2i(1800,1800)
	check(not Physics.outside(Vector2i(0,-1000*256),world), "native top/left inclusive")
	check(Physics.outside(Vector2i(-1,0),world), "negative fp uses arithmetic shift")
	check(Physics.outside(Vector2i(1800*256,0),world), "right excluded")
	check(Physics.outside(Vector2i(0,-1000*256-1),world), "above top excluded")
	check(Physics.outside(Vector2i(0,1800*256),world), "bottom excluded")
	check(CpuPlanner.legal_angles(Vector2(13,88)) == [13,18,23,28,33,38,43,48,53,58,63,68,73,78,83,88], "CPU exact legal extremes")
	check(CpuPlanner.legal_angles(Vector2(10,87))[-1] == 87, "CPU includes non-grid upper extreme")

func integration() -> void:
	var model = Match.new()
	model.start(6,1,77,"","off")
	model.actors[0].pos = Vector2(200,100)
	model.actors[1].pos = Vector2(1000,400)
	model.wind = Vector2(-26,0)
	model.fire(45,100,0)
	for _i in 10:
		model.tick(Combat.STEP)
	check(not model.projectiles.is_empty(), "Boomer launched integration")
	var shell: Dictionary = model.projectiles[0]
	check(shell.fp_ready, "actual launch seeded")
	var before: Dictionary = shell.duplicate(true)
	var old_acceleration: Vector2i = shell.fp_acceleration
	model.wind = Vector2(26,0)
	model.tick(Combat.STEP)
	check(shell.fp_acceleration == old_acceleration, "in-flight wind stays frozen")
	check(shell.fp_pos != before.fp_pos, "native integration moved")
	var vx := int(shell.fp_velocity.x)
	model.weather_interact(shell, {"type":"mirror","id":100})
	check(shell.fp_velocity.x == -vx, "mirror fixed x exact")
	check(shell.velocity == Vector2(shell.fp_velocity)/(256.0*Combat.STEP), "mirror publishes float")
	check(shell.fp_acceleration == old_acceleration, "mirror does not recompute frozen acceleration")
	var child := ShellState.create(Vector2(311,123),Vector2(100,-50),0,{"damage":1,"radius":1},0,0)
	child.launched = true
	model.seed_projectile(child)
	check(child.fp_pos == Vector2i(311*256,123*256), "child position seeded after mutation")
	check(child.fp_velocity == Vector2i(1280,-640), "child velocity seeded after mutation")
	Physics.import_external_motion(child, Vector2(350.125,130.125),Vector2(-101,53))
	check(child.fp_pos == Vector2i(89632,33312), "external tornado position quantization")
	check(child.fp_velocity == Vector2i(-1292,678), "external tornado velocity truncation")


class ChargeHost extends RefCounted:
	var model = Match.new()
	var aim = Aim.new()
	var shots := 0
	func _init(vehicle: int = 1) -> void:
		model.start(vehicle,1,7,"","original")
	func player_can_act() -> bool:
		return model.phase == "aim"
	func shoot() -> void:
		shots += 1
		model.fire(aim.angle,aim.power,aim.weapon)
		aim.charging = false

func charge() -> void:
	for fps in [30,60,120]:
		var host := ChargeHost.new()
		host.aim.begin_charge(host)
		for _i in fps * 3:
			host.aim.tick(host,1.0/fps)
		check(host.shots == 1 and host.aim.power == 100.0,"auto-charge exactly100 at3s fps" + str(fps))
		check(host.model.projectiles[0].launch_velocity_fp == host.model.shot_velocity_fp(0,45,100,0),"auto-charge native maximum fps" + str(fps))
		host.aim.tick(host,1.0)
		check(host.shots == 1,"auto-charge fires once fps" + str(fps))
	var host := ChargeHost.new(6)
	host.aim.begin_charge(host)
	host.aim.tick(host,1.0)
	host.aim.charging = false
	host.aim.tick(host,3.0)
	check(host.shots == 0,"pause cancellation never shoots")
	host.aim.begin_drag(host,100)
	host.aim.update_drag(90,-10)
	host.aim.release_drag(host)
	check(host.shots == 1,"Drag releases native P1")
	check(host.model.projectiles[0].launch_velocity_fp == Vector2i.ZERO,"Drag native diagonal P1, no15percent floor")

func tornado_bridge() -> void:
	var model = Match.new()
	model.start(2,1,7,"","original")
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.add_column("tornado",600,1)
	model.phase = "flight"
	var shell := ShellState.create(Vector2(570,300),Vector2(300,-100),0,{"damage":90,"radius":25},0,0)
	shell.launched = true
	model.projectiles = [shell]
	model.advance_projectiles(0.05)
	check(shell.fp_pos == Vector2i(585*256,295*256),"tornado external position imported once")
	check(shell.fp_velocity == Vector2i(3840,-1280),"tornado suppresses native acceleration in column")
	for _i in 100:
		if shell.tornado.is_empty():
			break
		model.advance_projectiles(0.05)
	check(shell.tornado.is_empty(),"tornado exits through existing C# adapter")
	var exit_velocity: Vector2i = shell.fp_velocity
	var exit_position: Vector2i = shell.fp_pos
	model.weather.columns.clear()
	model.advance_projectiles(0.05)
	check(shell.fp_pos == exit_position + exit_velocity,"native step resumes at imported exit position")
	check(shell.fp_velocity == exit_velocity + Vector2i(0,250),"native frozen acceleration resumes after tornado")

func launch_boundaries() -> void:
	# Regression: canonicalizing72% Bigfoot P302 back to percent and quantizing
	# twice formerly launchedP301 while prediction usedP302.
	for vehicle in [1,2,6]:
		var model = Match.new()
		model.start(vehicle,1,7,"","original")
		for percent in [5.2,10.3,72.0,99.999,100.0]:
			var expected: Vector2i = model.projectile_parameters(0,45,percent,0)[0].launch_velocity_fp
			check(model.fire(45,percent,0),"fire accepts raw UI boundary")
			check(model.projectiles[0].launch_velocity_fp == expected,"fire/predict quantize raw power once vehicle" + str(vehicle) + " power" + str(percent))
			model.phase = "aim"
	# The same fixed-angle conversion serves both facing directions and support.
	for facing in [-1,1]:
		for support in [-10.0,10.0]:
			var theta := int((45.0 if facing > 0 else 135.0)-support)
			check(Combat.launch_velocity_fp(45,100,facing,deg_to_rad(support),0,35) == Physics.launch_velocity_fp(theta,350),"native support conversion facing" + str(facing) + " slope" + str(support))

func impact_order() -> void:
	var model = Match.new()
	model.start(2,1,7,"","original")
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.actors[0].pos.x = 80
	model.actors[1].pos.x = 1200
	var at := Vector2(640,model.terrain.surface_at(640)-2)
	var shell := ShellState.create(at,Vector2(0,300),0,{"damage":90,"radius":25},0,0)
	shell.launched = true
	model.projectiles = [shell]
	model.phase = "flight"
	model.events.clear()
	model.advance_projectiles(0.05)
	var exploded := false
	for event in model.events:
		exploded = exploded or event.type == "explosion"
	check(exploded and model.projectiles.is_empty(),"first segment terrain impact resolves")
	check(shell.fp_velocity == Vector2i(0,3840),"impact precedes acceleration, impact speed stays300")
