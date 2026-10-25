extends "res://tests/support/suite.gd"
const PATH := "res://.tools/room-polish/test-profile.json"
func click(point: Vector2) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
func run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
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
	check(panel.player_anchor+Vector2(0,panel.NATIVE_GROUND)==Vector2(105,155),"Mobile fits inside team floor at native room composition point")
	check(panel.cpu_anchor+Vector2(0,panel.NATIVE_GROUND)==Vector2(563,155),"CPU uses native mirrored-side room composition point")
	check(not panel.player_mobile.visible and not panel.cpu_mobile.visible,"Cards show player identity without mobile names")
	var stage: Node = panel.figures.get_parent()
	check(panel.cpu_detail.position==Vector2(503,172) and panel.cpu_detail.text=="CPU · Normal","Bot card names CPU and committed difficulty together")
	panel.open_settings()
	panel.choose_difficulty(2)
	check(panel.cpu_detail.text=="CPU · Normal","Difficulty draft does not change CPU card")
	panel.accept_settings()
	check(panel.cpu_detail.text=="CPU · Precisa","Accept updates difficulty on CPU card")
	panel.open_settings()
	panel.choose_difficulty(0)
	panel.cancel_popup()
	check(panel.cpu_detail.text=="CPU · Precisa","Cancel preserves confirmed CPU card difficulty")
	var start: TextureButton = stage.get_node("Start")
	check(start.get("text")=="START","START is presented as centered text without return icon")
	var settings: TextureButton = stage.get_node_or_null("Settings")
	check(settings!=null and settings.get("text")=="SETTINGS","SETTINGS replaces CHANGE and its circular arrow")
	check(panel.settings_popup.size==Vector2(560,470),"Settings uses the classic window layout")
	check(panel.settings_popup.get("texture")!=null,"Settings window uses native classic frame artwork")
	check(panel.settings_popup.find_child("SettingsAccept",true,false) is TextureButton and panel.settings_popup.find_child("SettingsCancel",true,false) is TextureButton,"Modal actions use classic OK and Cancel textures")
	check(panel.difficulty_buttons[1].icon!=null and panel.weather_buttons[0].icon!=null,"Settings choices use classic radio controls")
	check(start.position==Vector2(660,552) and start.size==Vector2(107,45),"START aligns with EXIT and CHANGE at their native size")
	check(start.texture_normal.atlas.resource_path.ends_with("room/settings/room_footer_shell_clear.png") and start.lettering_frames[0].atlas.resource_path.ends_with("room/b_ready_startgame.png"),"START combines alpha-clean native shell with original approved STARTGAME lettering")
	for i in 8:
		var restored: TextureRect = stage.get_node_or_null("WeatherBase%d"%i)
		check(restored!=null,"Weather counter has restored panel base%d"%i)
		if restored!=null:
			var sample: Image = restored.texture.get_image()
			check(sample.get_pixel(0,0)==Color8(238,153,65),"Counter backdrop uses native orange instead of black")
		check(panel.climate_weights[i].get_theme_color("font_color")==Color.WHITE,"Weather counter text stays white")
	for key in ["PlayerReady","CpuReady","RoomMasterKey","RoomMode","RoomSize","RoomMapSide","RoomDeath","RoomItems"]:
		check(stage.get_node_or_null(key)!=null,"Native room indicator exists: "+key)
	for key in ["PlayerReady","CpuReady"]:
		var marker: TextureRect = stage.get_node_or_null(key)
		if marker!=null:
			check(marker.size==Vector2(19,40) and marker.position.y==111 and marker.texture.region==Rect2(228,0,76,160),"Ready uses source frame6 at native dimensions and height")
	var master: TextureRect = stage.get_node_or_null("RoomMasterKey")
	if master!=null:
		check(master.position==Vector2(137,173) and panel.player_name.position.x+panel.player_name.size.x<=master.position.x,"Long player name cannot overlap the owner key")
	panel.choose_player_side()
	click(stage.get_node("CpuReady").get_global_rect().get_center())
	await process_frame
	check(panel.mobile_for=="cpu","Click on CPU Ready decoration still chooses CPU card")
	panel.choose_cpu_side()
	click(stage.get_node("PlayerReady").get_global_rect().get_center())
	await process_frame
	check(panel.mobile_for=="player","Click on player Ready decoration still chooses player card")
	for id in range(1,17):
		scene.select_vehicle(id)
		scene.select_cpu_vehicle(id)
		check(not panel.player_mobile.visible and not panel.cpu_mobile.visible,"Mobile names remain hidden after choosing mobile%d"%id)
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
	check(not panel.player_mobile.visible and not panel.cpu_mobile.visible,"Random also leaves the card headers empty")
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
	var status_baseline: Dictionary = art.status_art.catalog.duplicate(true)
	for damaged in [{},{"version":1,"scale":3,"assets":status_baseline.assets}]:
		art.status_art.catalog = damaged
		check(art.frame("room_status",3).region==Rect2(57,0,19,40) and art.frame("room_status",3).atlas.resource_path.begins_with("res://assets/classic/room/status/"),"Invalid ReadyHD falls back to native frame6")
		check(art.frame("room_death",0).region==Rect2(0,0,81,24),"Map plaque fallback keeps native window")
	art.status_art.catalog = status_baseline
	scene.free()
	for p in [PATH,PATH.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	finish("ROOM POLISH CHECKS")
