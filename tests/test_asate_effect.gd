extends "res://tests/support/suite.gd"
const Ion = preload("res://scripts/asate_effect.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Art = preload("res://scripts/asate_art.gd")
class Fixture extends RefCounted:
	var actors: Array = [{"pos":Vector2(100,700),"vehicle":10}]
	var satellites: Dictionary = {}
	var projectiles: Array = []
	var shot_actor := 0
	var satellite_ceiling = null
	var launches: Array = []
	func weapon_rules(_owner: int, weapon: int) -> Dictionary:
		return {"damage":0,"radius":[27,23,22][weapon]}
	func launch_projectile(shot: Dictionary) -> void:
		shot.launched = true
		launches.append(shot.duplicate(true))

func run() -> void:
	Physics.warmup()
	for sample in [[0,1,2,1],[0,-1,2,-1],[4,21,8,7],[4,-13,8,1],[9,9,2,9]]:
		check(Ion.approach(sample[0],sample[1],sample[2]) == sample[3],"integer signed approach %s"%[sample])
	for weapon in 3:
		var model := Fixture.new()
		var effect := Ion.begin(model,{"weapon":weapon,"owner":0,"volley":7,"electric":true,"thor":false},Vector2(600,800))
		var alive := true
		var elapsed := 0
		while alive and elapsed < 250:
			alive = Ion.step(effect,model)
			elapsed += 1
		check(not alive,"Ion concludes and returns idle %d"%weapon)
		check(model.projectiles.size() == [1,3,6][weapon],"machine emission1/3/6 %d"%weapon)
		check(model.launches.size() == model.projectiles.size(),"each child launches once")
		check(model.satellites[0].pos == Vector2i(100,150 if weapon == 1 else 500) and not model.satellites[0].busy,"return to last selected weapon altitude")
		for shot in model.projectiles:
			check(shot.child and shot.flight == "asate_child" and shot.owner == 0 and shot.weapon == weapon,"child identity")
			check(shot.damage == [190,160,140][weapon] and shot.blast_radius == [27,23,22][weapon],"guide zero does not erase real child power")
			check(shot.volley == 7 and shot.electric and not shot.thor,"source attachments")
			check(shot.fp_ready and shot.launched and shot.fp_acceleration != Vector2i.ZERO,"seeded native directional acceleration")
			check(shot.pos.y == [500,150,300][weapon],"native source altitude")
		if weapon == 1:
			var angles := model.projectiles.map(func(shot): return shot.asate_angle)
			check(angles[1] == angles[0]+1 and angles[2] == angles[1]+1,"T2 central−1/0/+1")
		if weapon == 2:
			var xs := model.projectiles.map(func(shot): return shot.pos.x)
			# tan(PE double)*400 =>27; initial600−13−27=560.
			check(xs == [560.0,587.0,614.0,614.0,587.0,560.0],"SS native two sweeps with shared turning endpoint")
		var copy: Dictionary = effect.duplicate(true)
		copy.rules.radius = 999
		check(effect.rules.radius != 999,"effect nested rules copy isolated")
	var descriptor := {"rules":{"damage":0,"radius":27},"weapon":0,"owner":0,"volley":0,"electric":false,"thor":false}
	var down := Ion.child(descriptor,Vector2i(9,12),270,0)
	check(down.fp_velocity == Vector2i(0,7680),"PE velocity LUT270 exact")
	check(down.fp_acceleration == Vector2i(0,1024),"PE directional acceleration LUT270 exact")
	Physics.move(down)
	Physics.finish_tick(down)
	check(down.fp_pos == Vector2i(2304,10752) and down.fp_velocity == Vector2i(0,8704),"first native step position then acceleration")
	var beam := {"pos":Vector2(0,60),"hit_pos":Vector2(0,60),"trail":[Vector2(0,0),Vector2(0,30),Vector2(0,60)],"fp_velocity":Vector2i(0,7680),"flight_ticks":2,"age":0.1}
	beam.laser_sides = [Vector2(6,0),Vector2(6,0),Vector2(6,0)]
	var before := beam.duplicate(true)
	var green := Art.triangle_data(beam,0)
	var yellow := Art.triangle_data(beam,1)
	check(green.points.size() == 8 and green.indices.size() == 12,"Ion ribbon explicit triangles")
	check(green.colors[0].r == 0 and green.colors[0].g == 1 and yellow.colors[0].r == 1,"native green/yellow RGB")
	check(beam == before,"render does not mutate model")
	var sections: Array = down.laser_sides.duplicate()
	down.trail.append(down.pos)
	Ion.finish_child_tick(down)
	check(down.laser_sides.size() == 2 and down.laser_sides[0] == sections[0],"native section history keeps previous endpoint")
	down.fp_velocity = Vector2i(7680,0)
	down.trail.append(down.pos+Vector2(30,0))
	Ion.finish_child_tick(down)
	check(down.laser_sides[0] == sections[0] and down.laser_sides[-1] != sections[0],"heading change affects only new section")
	finish("ASATE EFFECT CHECKS")
