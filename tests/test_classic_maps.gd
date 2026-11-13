extends "res://tests/support/suite.gd"
const Maps = preload("res://scripts/maps.gd")
const Terrain = preload("res://scripts/terrain.gd")
func run() -> void:
	check(Maps.available_ids().size()==22,"All native sides available")
	for id in Maps.available_ids():
		var map: Dictionary = Maps.get_map(id)
		var terrain = Terrain.new()
		check(terrain.load_map(id,false),"Load "+id)
		check(terrain.world_size()==map.world_size,"Native dimensions "+id)
		terrain.enable_native()
		var copy = terrain.collision_copy()
		check(copy.native_cells==terrain.native_cells and copy.cells==terrain.cells,"Private masks "+id)
		var point := Vector2(terrain.world_size().x/2,terrain.surface_at(terrain.world_size().x/2)+20)
		terrain.carve(point,15)
		check(copy.revision!=terrain.revision,"Crater revision independent "+id)
		var limits = preload("res://scripts/camera_rig.gd").new().limits(terrain)
		check(limits.end.x<=terrain.world_size().x,"Camera bound "+id)
	var wrong := Maps.get_map("nirvana_a")
	var original: String = wrong.mask
	wrong.mask = Maps.get_map(Maps.DEFAULT).mask
	check(not Maps.is_available("nirvana_a"),"Wrong-sized resource blocks selection")
	wrong.mask = original
	check(not Maps.is_available("unknown"),"Invalid selection unavailable")
	finish("CLASSIC MAPS CHECKS")
