extends "res://tests/support/suite.gd"
const PATH := "res://.tools/room-polish/test-profile.json"
func run() -> void:
	for p in [PATH,PATH.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PATH)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_menu()
	await process_frame
	var panel = scene.menu
	for b in panel.item_grid_buttons:
		check(b.size==Vector2(64,43) and b.texture_normal.get_size()==Vector2(256,172),"Catalog uses uniform native64x43 tiles with slot markers")
	check(panel.item_up.position==Vector2(750,404) and panel.item_down.position==Vector2(750,487),"Scroll arrows fit original background wells")
	check(panel.player_anchor+Vector2(0,panel.NATIVE_GROUND)==Vector2(101,144),"Mobile contact rests on top of team floor")
	var stage: Node = panel.figures.get_parent()
	check(panel.figures.get_index()>stage.get_node("TeamA0").get_index() and panel.figures.get_index()<panel.player_name.get_index(),"Mobile draws above opaque team strip and below its name")
	var duplicate := false
	for n in stage.get_children():
		if n is Label and n.text=="Miramo Town A":duplicate=true
	check(not duplicate,"Only original preview title names the map")
	var arrows := []
	for n in stage.get_children():
		if n is TextureButton and n.texture_normal is AtlasTexture and n.texture_normal.atlas.resource_path.contains("b_ready_map"):arrows.append(n)
	check(arrows.is_empty(),"Duplicate bottom map arrows removed")
	check(stage.get_node_or_null("MapPrevious")!=null and stage.get_node_or_null("MapNext")!=null,"Map controls use original side-arrow locations")
	var rng_state: int = scene.room_rng.state
	scene.select_vehicle(-2)
	scene.select_cpu_vehicle(-2)
	check(not panel.player_random_preview.visible and not panel.cpu_random_preview.visible,"Random uses a real mobile and rider instead of a flat icon")
	check(scene.get("room_random_sprite")!=null,"Random has its original mobile renderer")
	check(scene.room_rng.state==rng_state and scene.player_random and scene.cpu_random,"Random avatar preview preserves pending selection without drawing RNG")
	var random = scene.room_random_sprite
	check(random.texture.get_size()==Vector2(336,47) and random.cell==Vector2(28,47) and random.pivot==Vector2(14,23.5),"Random body keeps source frame and original pivot")
	check(random.rider_offset(0)==Vector2(15,-5) and random.contact_y==45.0,"Random rider uses original mount above source ground contact")
	check(random.density==4 and random.frame_rect(11)==Rect2(1232,0,112,188),"Random4x preserves all twelve windows")
	var random_catalog: Dictionary = random.art.catalog.duplicate(true)
	random.art.catalog = {}
	random.refresh_art()
	check(random.density==1 and random.frame_rect(11)==Rect2(308,0,28,47),"Missing RandomHD catalog falls back to original body with same registration")
	random.art.catalog = random_catalog
	random.refresh_art()
	var art = panel.room_art
	var baseline: Dictionary = art.polish_art.catalog.duplicate(true)
	for info in baseline.assets.values():
		var png := Image.load_from_file(art.POLISH_ROOT+str(info.file))
		var imported: Image = load(art.POLISH_ROOT+str(info.file)).get_image()
		png.convert(Image.FORMAT_RGBA8)
		imported.convert(Image.FORMAT_RGBA8)
		png.premultiply_alpha()
		imported.premultiply_alpha()
		check(png.get_data()==imported.get_data(),"Native item image imports losslessly")
	art.polish_art.catalog = {}
	for id in panel.Items.ORDER:
		var width := 71 if panel.Items.slots(id)==2 else 35
		for catalog in [false,true]:
			var size := Vector2(64,43) if catalog else Vector2(width,31)
			for state in [0,3]:
				var texture: AtlasTexture = art.item_frame(id,state,catalog)
				check(texture.atlas.resource_path.begins_with("res://assets/classic/room/polish/") and texture.region==Rect2(Vector2(size.x if state==3 else 0.0,0),size),"Item native fallback keeps role, slot width and disabled state")
	art.polish_art.catalog = baseline
	scene.free()
	for p in [PATH,PATH.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	finish("ROOM POLISH CHECKS")
