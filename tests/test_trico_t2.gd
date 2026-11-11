extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Trico = preload("res://scripts/trico_flight.gd")
const Sprite = preload("res://scripts/classic_sprite.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func vec(a: Array) -> Vector2i:
	return Vector2i(int(a[0]),int(a[1]))

func fresh(facing: int = 1):
	var model = Match.new()
	model.start(5,2,42,"","original")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.image=null
	model.terrain.texture=null
	model.terrain.WIDTH=900
	model.terrain.cells.resize(900*model.terrain.HEIGHT)
	model.terrain.native_cells.resize(1800*model.terrain.HEIGHT*2)
	model.terrain.cells.fill(0)
	model.terrain.native_cells.fill(0)
	model.actors[0].pos = Vector2(100 if facing>0 else 1700,500)
	model.actors[0].facing = facing
	model.actors[1].pos = Vector2(3000,1500)
	return model

func run() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/trico_native.json"))
	for scenario in fixture.t2:
		var theta := int(scenario.theta)
		var facing := 1 if theta<91 else -1
		var model = fresh(facing)
		var shells: Array = model.shot_shells(0,45,60,1)
		var shell: Dictionary = shells[int(scenario.index)]
		# Exact theta cell is supplied at this boundary to cover90/91 independently
		# of the offline HUD's supported aiming range.
		shell.trico_phase = theta + int(scenario.index)*180
		shell.trico_step = -8 if theta<91 else 8
		Physics.seed(shell,vec(scenario.position)*256,vec(scenario.velocity),vec(scenario.acceleration))
		shell.hit_pos = shell.pos
		shell.launched = true
		Snapshot.arm(model,0,1,[shell])
		for row in scenario.ticks:
			model.advance_projectiles(0.05)
			check(model.projectiles.is_empty()==bool(row.removed),"T2 bounds use published coordinate, not carrier")
			check(Vector2i(shell.fp_pos)==vec(row.center_fp),"T2 carrier matches native center tick%d" % int(row.tick))
			check(Physics.position_fp(shell.hit_pos)==vec(row.published_fp),"T2 published position matches PE tick%d" % int(row.tick))
			check(Vector2i(shell.fp_velocity)==vec(row.velocity_fp),"T2 ballistic velocity restored after displaced contact")
			if int(scenario.index)==2:
				continue
			check(int(shell.get("trico_phase",-999))==int(row.phase_after),"T2 Animate phase follows tick")
			check(int(shell.get("trico_radius",-999))==int(row.radius_after),"T2 radius grows after tick to30")
			check(int(shell.get("trico_heading",-999))==int(row.contact.heading),"T2 contact publishes phase heading")
	var model = fresh()
	var shells: Array = model.shot_shells(0,45,60,1)
	check(shells.size()==3,"T2 retains three components")
	var common: Dictionary = shells[2]
	Physics.seed(common,Vector2i(128000,102400),Vector2i(1800,-1600),Vector2i.ZERO)
	common.hit_pos=common.pos
	common.launched=true
	Snapshot.arm(model,0,1,[common])
	model.advance_projectiles(0.05)
	check(Physics.position_fp(common.hit_pos)==Vector2i(129800,100800),"idx2 is common, no orbit displacement")
	for scenario in fixture.contacts:
		var hit_model = fresh(1 if int(scenario.theta)<91 else -1)
		var hit_shell: Dictionary = hit_model.shot_shells(0,45,60,1)[int(scenario.index)]
		hit_shell.trico_phase=int(scenario.theta)+int(scenario.index)*180
		hit_shell.trico_step=-8 if int(scenario.theta)<91 else 8
		Physics.seed(hit_shell,vec(scenario.start_fp),vec(scenario.velocity),Vector2i.ZERO)
		hit_shell.hit_pos=hit_shell.pos
		hit_shell.launched=true
		var width := int(hit_model.terrain.world_size().x)
		for y in range(int(scenario.floor),int(hit_model.terrain.world_size().y)):
			for x in width:
				hit_model.terrain.native_cells[y*width+x]=1
		Snapshot.arm(hit_model,0,1,[hit_shell])
		hit_model.advance_projectiles(0.05)
		var hits: Array = hit_model.events.filter(func(e):return e.type=="explosion")
		check(not hits.is_empty()==bool(scenario.hit),"T2 contact presence matches real455cc0")
		if not hits.is_empty():
			check(Vector2(hits[0].position)==Vector2(vec(scenario.point)),"T2 displaced sweep contacts native terrain pixel")
	for facing in [1,-1]:
		for angle in [25.0,42.9,50.0]:
			var initial = fresh(facing)
			var emitted: Array = initial.shot_shells(0,angle,60,1)
			var theta := int(angle if facing>0 else 180.0-angle)
			for index in 3:
				check(int(emitted[index].trico_component)==index,"T2 owns correct component at creation")
				check(int(emitted[index].trico_phase)==theta+180*index,"T2 starts with MainAction theta before velocity quantization")
				check(int(emitted[index].trico_step)==(-8 if theta<91 else 8),"T2 spin is selected by native theta")
	var sprite = Sprite.new()
	sprite.setup("trico")
	var sample: Dictionary = fresh().shot_shells(0,45,60,1)[0]
	sample.trico_heading=135
	check(is_equal_approx(sprite.projectile_angle(sample),-deg_to_rad(135.0)),"T2 draws phase+90 heading, independent of ballistic velocity")
	var isolated = fresh()
	var originals: Array = isolated.shot_shells(0,45,60,1)
	var owned: Array = originals.duplicate(true)
	owned[0].trico_phase=-70
	check(originals[0].trico_phase!=owned[0].trico_phase,"T2 shell snapshots own phase/radius")
	finish("TRICO T2 CHECKS")
