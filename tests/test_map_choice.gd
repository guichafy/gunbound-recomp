extends "res://tests/support/suite.gd"
const Choice = preload("res://scripts/map_choice.gd")
const Maps = preload("res://scripts/maps.gd")
const Terrain = preload("res://scripts/terrain.gd")
func run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	check(Choice.resolve("unknown",rng).is_empty(),"Unknown choice fails safely")
	for id in Maps.available_ids():
		var context: Dictionary = Choice.resolve(id,rng)
		check(not context.is_empty() and context.map_id==id,"Context identity "+id)
		if context.is_empty():continue
		var t = Terrain.new()
		t.load_map(id,false)
		for index in 2:
			var point: Vector2 = context.spawns[index]
			check((point.x<t.world_size().x/2)==(index==0),"Half-side spawn "+id)
			check(not t.is_void(t.surface_at(point.x,point.y)),"Spawn supported "+id)
	# Every eligible range point must be exposed, including source Y inside land.
	for id in Choice.candidates:
		var t = Terrain.new()
		t.load_map(id,false)
		for groups in Choice.candidates[id]:
			for points in groups:
				for point in points:
					check(t.is_solid(point) and not t.is_solid(point-Vector2(0,Terrain.SCALE)),"Exposed candidate "+id+str(point))
	for expected in [["adium_root_b",856,954],["dummy_slope_b",619,1124]]:
		var found := false
		for groups in Choice.candidates[expected[0]]:
			for points in groups:
				for point in points:
					if point.x==expected[1] and point.y==expected[2]:found=true
		check(found,"Buried source Y rises in same solid column "+str(expected))
	var first: Dictionary = Choice.resolve(Maps.DEFAULT,rng)
	var second := first.duplicate(true)
	second.spawns[0].x += 10
	check(second.spawns!=first.spawns,"Context copy independent")
	finish("MAP CHOICE CHECKS")
