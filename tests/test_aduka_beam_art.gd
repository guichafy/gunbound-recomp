extends "res://tests/support/suite.gd"
const Art = preload("res://scripts/aduka_beam_art.gd")

func run() -> void:
	var beam := {"from":Vector2(100,100),"position":Vector2(300,100),"native_angle":0,
		"level":1,"period":1000,"rgb":0x00ff00,"age":0.0}
	var data := Art.triangle_data([beam])
	check(data.points.size() == 8 and data.indices.size() == 12,"Native beam emits two explicit triangle quads")
	check(data.points.slice(0,4) == PackedVector2Array([Vector2(100,84),Vector2(300,84),Vector2(300,116),Vector2(100,116)]),"Outer quad uses native integer16px half width")
	check(data.uv.slice(0,4) == PackedVector2Array([Vector2(0,1),Vector2(0,0),Vector2(0.0625,0),Vector2(0.0625,1)]),"Native helper0x4ed5a0 maps originv1 to targetv0 and1of16 columns")
	check(data.colors[0] == Color8(0,255,0,255) and data.colors[4] == Color8(255,255,255,255),"Two layers preserve native green and white")
	beam.age = 0.5
	data = Art.triangle_data([beam],Vector2(13,-7))
	check(data.points[0] == Vector2(113,67) and data.points[4] == Vector2(113,92),"Tick10 widths26/1 and camera offset affect presentation only")
	check(data.colors[0] == Color8(0,255,0,95) and data.colors[4] == Color8(255,255,255,255),"Tick10 uses distinct native layer alphas")
	check(data.uv[0] == Vector2(0.125,1),"Tick10 selects column2")
	check(Art.triangle_data([beam]) == Art.triangle_data([beam]),"Frozen clock gives identical geometry/UV/colors")
	beam.age = 0.95
	data = Art.triangle_data([beam])
	check(data.colors[0].a8 == 1 and data.colors[4].a8 == 75,"Tick19 retains alpha floors instead of linear fading")
	beam.age = 1.0
	check(Art.triangle_data([beam]).points.is_empty(),"Tick20 produces no visual quad")
	beam.age = 0.0
	check(Art.triangle_data([beam,beam]).points.size() == 16,"Multiple simultaneous guides retain independent beam data")
	var art = Art.new()
	check(art.texture != null and art.texture.get_size() == Vector2(256,256),"Renderer loads original full-height LaserEffect texture")
	check(art.material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD and art.material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED,"Private CanvasItem material is additive and unshaded")
	var view := Node2D.new()
	root.add_child(view)
	check(view.material == null and art.canvases.is_empty(),"Game view starts without a material mutation")
	art.draw(view,[beam])
	var first_canvas: RID = art.canvases[view.get_instance_id()]
	art.draw(view,[])
	check(art.canvases.size() == 1 and art.canvases[view.get_instance_id()] == first_canvas,"Repeated and empty draws reuse and clear one canvas")
	check(view.material == null,"Beam draw never changes parent view material")
	art.clear()
	art = null
	view.free()
	finish("ADUKA BEAM ART CHECKS")
