extends "res://tests/support/suite.gd"
const Art = preload("res://scripts/jewel_art.gd")

func run() -> void:
	var art = Art.new()
	var jewel := {"kind": 0, "pos": Vector2(100, 200), "pose": "normal", "pose_tick": 0}
	check(art.frame(jewel) == 0, "normal begins at EPA frame0")
	jewel.pose_tick = 19
	check(art.frame(jewel) == 19, "EPA last normal tick")
	jewel.pose_tick = 20
	check(art.frame(jewel) == 0, "EPA normal loops after20ticks")
	jewel.pose = "damage"
	jewel.pose_tick = 20
	check(art.frame(jewel) == 79, "nonlooping damage clamps at finalEPAframe")
	check(art.layers(jewel, true).is_empty(), "EPAframe79 has no lightframe; never modulo50")
	jewel.pose = "shock"
	jewel.pose_tick = 9
	var body: Array = art.layers(jewel)
	var lights: Array = art.layers(jewel, true)
	check(body.size() == 1 and lights.size() == 1, "frame49 body and light exist")
	check(body[0].frame == 49 and lights[0].frame == 49, "body and light publish identicalEPAframe")
	check(lights[0].additive and not body[0].additive, "native alpha then additive pass")
	for layer in body + lights:
		check(Rect2(-32, -48, 63, 63).encloses(layer.target), "nativecell63exclusive clips registered art")
		check(layer.transform.origin == jewel.pos, "native registration remains at modelpos")
	jewel.pose_tick = 10
	check(art.layers(jewel, true).is_empty(), "EPAframe50 is absent from50framelight")
	var effect := {"kind":0,"pos":Vector2(10,20),"tick":6}
	check(art.effect_frame(effect) == 0, "jflame initialframe lasts7ticks")
	effect.tick = 7
	check(art.effect_frame(effect) == 1, "jflame advances at tick7")
	effect.tick = 26
	check(art.effect_layers(effect).is_empty(), "jflame expires at EPA26ticks")
	check(art.digit_layers(105, Vector2.ZERO).size() == 3, "nativeHUD digits preserve zero")
	check(art.room_frame("JEWEL") != null, "room mode plate is a native atlas texture")
	check(art.room_frame("SOLO") == null, "SOLO keeps its existing mode plate")
	check(body[0].texture != null and lights[0].texture != null, "imported body and light resources load")
	art.meta.sheets.probe = {"cell": [64, 64], "origin": [32, 48], "frames": 1}
	art.textures.probe = art.textures.jewel1
	var clip: Dictionary = art._layer("probe", 0, Transform2D.IDENTITY, false, true)
	check(clip.source == Rect2(0, 0, 63, 63) and clip.target == Rect2(-32, -48, 63, 63), "native64cell excludes texel63 on right and bottom")
	art.meta.sheets.probe.origin = [40, 50]
	clip = art._layer("probe", 0, Transform2D.IDENTITY, false, true)
	check(clip.source == Rect2(8, 2, 56, 62), "clipping negative registration advances source UV without scaling")
	for type in 4:
		var items: Array = art.layers({"type": type, "pos": Vector2.ZERO})
		check(items.size() == 1 and items[0].texture != null, "type%d keeps original native body" % type)
	art = null
	finish("JEWEL ART CHECKS")
