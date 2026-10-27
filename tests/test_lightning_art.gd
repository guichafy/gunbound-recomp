extends "res://tests/support/suite.gd"
func run() -> void:
	var art=load("res://scripts/lightning_beam_art.gd")
	check(art!=null,"Native Lightning raster exists")
	if art==null:
		finish("LIGHTNING ART CHECKS")
		return
	var sprite=preload("res://scripts/mobile_looks.gd").look(8).sprite
	check(str(sprite)=="res://scripts/lightning_sprite.gd","Lightning uses native glow/Facing renderer")
	var renderer=load(sprite).new()
	renderer.setup("lightning")
	for weapon in 3:
		for velocity in [Vector2(200,-30),Vector2(-200,-30)]:
			var layers: Array=renderer.projectile_layers({"pos":Vector2.ZERO,"velocity":velocity,"age":0.0},weapon)
			check(layers.size()==1 and layers[0].additive==(weapon==2) and not bool(layers[0].flip_y),"Native alpha/glow and Facing weapon%d velocity%s"%[weapon,velocity])
	check(renderer.has_method("rider_visible"),"Native dead-state avatar suppression exists")
	if renderer.has_method("rider_visible"):
		check(not renderer.rider_visible("destroyed") and renderer.rider_visible("recoil"),"Native dead hides all avatar slots without changing living mounts")
	var expected: Array=[PackedVector2Array([Vector2(-32,-256),Vector2(31,-256),Vector2(31,0),Vector2(-32,0)]),PackedVector2Array([Vector2(-279,-233),Vector2(-234,-278),Vector2(22,-22),Vector2(-23,23)]),PackedVector2Array([Vector2(233,-279),Vector2(278,-234),Vector2(22,22),Vector2(-23,-23)])]
	for index in 3:
		var direction: int=[0,1,-1][index]
		for tick in range(0,12):
			var quads: Array=art.quads({"position":Vector2(500,600),"direction":direction},tick)
			check(quads.is_empty()==(tick>=10),"Alpha removal at10 ticks")
			if quads.is_empty():continue
			var points: PackedVector2Array=expected[index].duplicate()
			for vertex in 4:points[vertex]+=Vector2(500,600)
			check(quads[0].points==points,"Exact native raster offsets/direction%s"%direction)
			check(is_equal_approx(quads[0].alpha,float(255-24*tick)/255.0),"Alpha255−24×tick")
			check(quads[0].uv[1].x-quads[0].uv[0].x==0.25,"Lightning uses one of four UV quarters")
	finish("LIGHTNING ART CHECKS")
