extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",description)
func _initialize() -> void:
	check(ResourceLoader.exists("res://scripts/shop_hd.gd"),"Registered HD interface loader exists")
	if failures == 0:
		var type = load("res://scripts/shop_hd.gd")
		var hd = type.new()
		check(hd.sprites.size()==20,"All twenty consumed raster textures have HD derivatives")
		for key in hd.sprites:
			var tex = hd.texture(key)
			check(tex is Texture2D,"HD sprite loads "+key)
			if tex != null:
				check(tex.get_size()==Vector2(hd.sprites[key].native_size[0],hd.sprites[key].native_size[1])*4,"Native windows remain registered at four times density "+key)
		var missing = type.new("res://.tools/missing-shop-hd.json")
		check(missing.texture("AnimatedButtons/Exit")==null,"Missing catalog requests complete native fallback")
		var data: Dictionary = hd.sprites["AnimatedButtons/Exit"].duplicate(true)
		hd.sprites["AnimatedButtons/Exit"].size = [1,1]
		check(hd.texture("AnimatedButtons/Exit")==null,"Texture dimension mismatch requests native fallback even after caching")
		hd.sprites["AnimatedButtons/Exit"] = data
		hd.sprites["AnimatedButtons/Exit"].native_size = [0,66]
		check(hd.texture("AnimatedButtons/Exit")==null,"Invalid native registration requests fallback")
		hd.sprites["AnimatedButtons/Exit"] = data
		hd.sprites["AnimatedButtons/Exit"].file = "res://assets/hd/shop/missing.png"
		check(hd.texture("AnimatedButtons/Exit")==null,"Absent raster requests fallback")
	print("SHOP HD CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
