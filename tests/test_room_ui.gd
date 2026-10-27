extends "res://tests/support/suite.gd"
const Art = preload("res://scripts/classic_room_art.gd")
const Items = preload("res://scripts/items.gd")
const HD := "res://assets/hd/classic/room_smooth_4x/"
const POLISH := "res://assets/hd/classic/room_polish_4x/"
const PATH := "res://.tools/room-ui/test-profile.json"

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
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PATH)
	root.add_child(scene)
	scene.sound.muted = true
	scene.set_process(false)
	scene.show_menu()
	await process_frame
	var panel = scene.menu
	check(panel.chrome.image("room_back").resource_path == HD + "room/back.png", "Room uses true4x conservative backdrop")
	for name in ["RoomTitle","RoomCapacity","RoomOwner","RoomMapPreview","RoomPortrait","RoomStatus","RoomRankIcon"]:
		check(scene.root.find_child(name,true,false) != null,name + " is implemented")
	check(panel.item_grid_buttons[0].texture_normal.atlas.resource_path.begins_with(POLISH),"Room item buttons use conservative classic originals")
	var preview: TextureRect = scene.root.find_child("RoomMapPreview",true,false)
	check(preview.position == Vector2(332,51) and preview.size == Vector2(136,84),"Map uses proven native window332,51")
	check(preview.mouse_filter == Control.MOUSE_FILTER_PASS and preview.tooltip_text.contains("Miramo"),"Fixed map remains discoverable by hover")
	check(panel.portrait.mouse_filter == Control.MOUSE_FILTER_PASS and panel.portrait.tooltip_text.contains("vida"),"Native portrait keeps stats available through tooltip")
	var motion := InputEventMouseMotion.new()
	motion.position = panel.portrait.get_global_rect().get_center()
	motion.global_position = motion.position
	root.push_input(motion)
	await process_frame
	check(root.gui_get_hovered_control() == panel.portrait,"Actual pointer can reach portrait tooltip control")
	check(preview.texture.region == Rect2(544,0,544,336),"MiramoA uses original map frame1")
	check(panel.portrait.position == Vector2(378,390) and panel.portrait.size == Vector2(113,146),"Portrait uses proven native position378,390")
	for i in 8:
		check(panel.climate_weights[i].text == str([2,1,2,1,0,0,0,2][i]),"Mage room shows native Miramo weights in existing icon slots")
	panel.open_settings()
	panel.choose_weather("all")
	check(panel.climate_weights[0].text == "2","Draft weather leaves committed display intact")
	panel.nickname_input.text = "WWWWWWWWWWWWWWWWWWWW"
	panel.accept_settings()
	await process_frame
	var owner: Label = scene.root.find_child("RoomOwner",true,false)
	check(owner.text.begins_with("WWWW") and owner.text.ends_with("GM") and owner.size == Vector2(155,17),"Header follows accepted name and stays in native window")
	check(owner.tooltip_text.contains("Administrador"),"GM remains assigned administrator")
	for i in 8:
		check(panel.climate_weights[i].text == str([1,1,1,1,0,1,1,1][i]),"Mage all-weather display includes seven native categories")
	panel.open_settings()
	panel.choose_weather("original")
	panel.cancel_popup()
	check(panel.climate_weights[0].text == "1" and scene.weather_mode == "all","Cancel preserves committed weather")
	var expected := {4:1,1:2,3:3,5:4,2:5,6:6,7:7,8:8,9:9,10:10,11:11,12:12,13:13,16:16}
	for id in range(1,17):
		scene.select_vehicle(id)
		if expected.has(id):
			check(panel.portrait.visible and panel.portrait.texture.region == Rect2(expected[id]*452,0,452,584),"Mobile%d has correct original portrait"%id)
		else:
			check(not panel.portrait.visible and panel.portrait_name.visible and not panel.portrait_name.text.is_empty(),"Special mobile never appears as Random placeholder")
	var portrait_before: Texture2D = panel.portrait.texture
	panel.choose_cpu_side()
	panel.pick_vehicle(4)
	check(scene.cpu_vehicle == 4 and panel.portrait.texture == portrait_before,"CPU choice preserves player portrait")
	panel.choose_player_side()
	var button: TextureButton = panel.grid_buttons[1]
	click(button.get_global_rect().get_center())
	await process_frame
	check(scene.vehicle == 1 and panel.portrait.texture.region.position.x == 904,"Actual grid click selects Mage and updates native portrait")
	check(panel.grid_buttons.size()==15 and button.size==Vector2(63,44) and button.position==Vector2(99,396),"Requested5x3 grid uses correctly aligned hitboxes")
	check(panel.icons_inside_slots() and panel.catalog_inside_panel(),"Item geometry stays in six slots and catalog")
	check(scene.item_art.textures["ItemDual.png"].resource_path == "res://assets/xfs/items/ItemDual.png","Battle item artwork uses the original client extraction (REQ-48)")
	test_resources(panel.room_art)
	scene.free()
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("ROOM UI CHECKS")

func test_resources(art) -> void:
	for key in ["room_maps","room_portraits"]:
		var count := 22 if key=="room_maps" else 17
		var cell := Vector2(136,84) if key=="room_maps" else Vector2(113,146)
		for index in count:
			var frame: AtlasTexture = art.frame(key,index)
			check(frame.atlas.resource_path.begins_with(HD) and frame.region == Rect2(Vector2(index*cell.x,0)*4,cell*4),key+" frame%d stays registered"%index)
	for id in Items.ORDER:
		var width := 71 if Items.slots(id)==2 else 35
		for state in 4:
			var texture: AtlasTexture = art.item_frame(id,state)
			check(texture.atlas.resource_path.begins_with(POLISH) and texture.region==Rect2((1 if state==3 else 0)*width*4,0,width*4,124),"%s state%d retains slot/state order"%[id,state])
	for info in art.art.catalog.assets.values():
		var imported: Image = load(HD+str(info.file)).get_image()
		var png := Image.load_from_file(HD+str(info.file))
		imported.convert(Image.FORMAT_RGBA8)
		png.convert(Image.FORMAT_RGBA8)
		imported.premultiply_alpha()
		png.premultiply_alpha()
		check(imported.get_data()==png.get_data(),str(info.file)+" imports without visible loss")
	var baseline: Dictionary = art.art.catalog.duplicate(true)
	for damaged in [{},{"version":1,"scale":3,"assets":baseline.assets},{"version":1,"scale":4,"assets":[]}]:
		art.art.catalog = damaged
		check(art.image("room_back").resource_path == "res://assets/classic/room/back.png","Invalid room catalog falls back to original backdrop")
		check(art.frame("room_maps",1).region == Rect2(136,0,136,84),"Native map fallback retains frame and window")
	art.art.catalog = baseline.duplicate(true)
	art.art.catalog.assets.room_portraits.columns = 16
	check(art.frame("room_portraits",5).region==Rect2(565,0,113,146),"Incomplete portrait atlas falls back")
	check(art.image("room_back").resource_path.begins_with(HD),"Invalid portrait leaves valid room art active")
	art.art.catalog = baseline
	art.polish_art.catalog = {}
	for id in Items.ORDER:
		var width := 71 if Items.slots(id)==2 else 35
		check(art.item_frame(id,3).atlas.resource_path.begins_with("res://assets/classic/room/polish/") and art.item_frame(id,3).region==Rect2(width,0,width,31),"Native item fallback keeps disabled state and span")
