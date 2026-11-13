extends "res://tests/support/suite.gd"
const Art = preload("res://scripts/map_art.gd")
const Maps = preload("res://scripts/maps.gd")
func run() -> void:
	var map := Maps.get_map(Maps.DEFAULT)
	var art = Art.new()
	art.prepare(map)
	check(art.textures.is_empty(),"Normal native boot leaves optional numbered scenery disabled")
	var a: Array = Art.sample(map,0.0)
	var b: Array = Art.sample(map,0.1)
	check(a.size()==5 and a[0].frame==0 and b[0].frame==1,"Miramo EPA two ticks per frame")
	check(a[0].position==Vector2(89,375),"Original registered scenery position")
	check(Art.sample(map,0.0)==a,"Paused visual sample stable")
	for id in Maps.available_ids():
		for frame in Art.sample(Maps.get_map(id),10.0):
			check(frame.frame>=0 and frame.position.is_finite(),"Valid scene sample "+id)
	finish("MAP ART CHECKS")
