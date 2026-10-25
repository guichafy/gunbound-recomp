extends "res://tests/support/suite.gd"
const Choice = preload("res://scripts/room_choice.gd")
const PATH := "res://.tools/room-reference/test-profile.json"
const ROOT := "res://assets/hd/classic/room_reference_4x/"
func click(point: Vector2, key: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = key
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
	check(panel.grid_buttons.size()==15,"Room has5x3 choices")
	var expected := [4,1,3,5,2,6,7,8,9,10,11,12,13,16,-2]
	for index in 15:
		var button: TextureButton = panel.grid_buttons[index]
		check(int(button.get_meta("vehicle_id"))==expected[index],"Cell%d follows reference ordering"%index)
		check(button.position==Vector2(33+(index%5)*66,396+int(index/5.0)*44) and button.size==Vector2(63,44),"Cell%d aligns in5x3 grid"%index)
		check(panel.GRID_PANEL.encloses(Rect2(button.position,button.size)),"Cell%d stays inside panel"%index)
	check(panel.grid_buttons.all(func(b):return not int(b.get_meta("vehicle_id")) in [14,15]),"Knight/Dragon have no direct buttons")
	check(panel.item_grid_buttons.size()==11 and panel.item_tab_buttons.is_empty(),"All items share one catalog without tabs")
	for team in ["A","B"]:
		for index in 4:
			var node = scene.root.find_child("Team%s%d"%[team,index],true,false)
			check(node!=null and node.texture.resource_path == ROOT+"room/reference/room_team_%s.png"%team.to_lower(),"All eight slots carry original team identification")
	check(panel.player_name.position.y==172 and panel.player_anchor.y+panel.NATIVE_GROUND==155,"Nameplate remains below the native room composition point")
	await process_frame
	check(panel.item_catalog.get_v_scroll_bar().max_value>panel.item_catalog.get_v_scroll_bar().page,"Unified catalog contains scrollable overflow")
	check(panel.item_up.disabled and not panel.item_down.disabled,"Native scroll arrows reflect first row")
	click(panel.item_down.get_global_rect().get_center())
	await process_frame
	check(panel.item_catalog.scroll_vertical>0,"Real arrow click scrolls unified catalog")
	click(panel.item_down.get_global_rect().get_center())
	await process_frame
	check(panel.item_down.disabled and not panel.item_up.disabled,"Native arrows disable at lower boundary")
	panel.item_catalog.scroll_vertical = 0
	await process_frame
	click(panel.item_catalog.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
	await process_frame
	check(panel.item_catalog.scroll_vertical>0,"Actual mouse wheel reaches all items")
	var ids := {}
	for button in panel.item_grid_buttons:
		ids[button.get_meta("item_id")] = true
	check(ids.size()==11 and panel.catalog_inside_panel() and panel.icons_inside_slots(),"Mixed-size catalog and six-slot equipment remain valid")
	panel.item_slot_buttons[0].pressed.emit()
	check(scene.options.items==["teleport","power_up","energy_up_1"],"Removing a two-slot item frees both positions")
	for id in ["blood","change_wind"]:
		for button in panel.item_grid_buttons:
			if button.get_meta("item_id")==id:button.pressed.emit()
	check(scene.options.items==["teleport","power_up","energy_up_1","blood","change_wind"] and panel.icons_inside_slots(),"Both slot sizes are selectable in the same list and persist")
	var rng_state: int = scene.room_rng.state
	panel.open_settings()
	check(panel.item_up.disabled and panel.item_down.disabled,"Settings modal blocks scrolling arrows")
	panel.cancel_popup()
	click(panel.grid_buttons[14].get_global_rect().get_center())
	await process_frame
	check(scene.player_random and not scene.cpu_random and scene.vehicle==2,"Random is pending selection, never a premature or invalid mobile ID")
	check(panel.portrait.visible and panel.portrait.texture.region==Rect2(0,0,452,584) and not panel.player_random_preview.visible,"PendingRandom uses original portrait and a composed mobile/rider")
	check(panel.grid_buttons[14].texture_normal.region==Rect2(1008,0,252,188),"Random retains active state4")
	scene.show_menu()
	await process_frame
	panel = scene.menu
	check(scene.player_random and panel.player_random and scene.room_rng.state==rng_state,"Reopening room preservesRandom and does not consume RNG")
	panel.choose_cpu_side()
	click(panel.grid_buttons[14].get_global_rect().get_center())
	await process_frame
	check(scene.cpu_random and panel.cpu_random and panel.cpu_mobile.text=="Random","SameRandom cell can independently select CPU")
	check(scene.room_rng.state==rng_state,"Changing side or UI never performs the draw")
	var equipment: Dictionary = scene.profile.equipped_set()
	scene.opening = 0
	scene.match_seed = 917
	for seed_value in [2,7,13,41,91,123]:
		scene.room_rng.seed = seed_value
		var reference := RandomNumberGenerator.new()
		reference.seed = seed_value
		var wanted_player: int = [14,15][reference.randi_range(0,1)]
		var wanted_cpu: int = [14,15][reference.randi_range(0,1)]
		scene.start_match()
		check(scene.model.actors[0].vehicle==wanted_player and scene.model.actors[1].vehicle==wanted_cpu,"Actual match receives independent Dragon/Knight draws")
		check(scene.room_rng.state==reference.state,"Exactly two RNG draws happen only at match start")
		check(scene.model.actors[0].vehicle in [14,15] and scene.model.actors[1].vehicle in [14,15],"Random cannot choose another mobile")
		scene.show_menu()
	check(scene.profile.equipped_set()==equipment and scene.profile.xp==0,"Random start preserves profile/equipment and never awards progress")
	scene.select_vehicle(1)
	check(not scene.player_random and scene.cpu_random and scene.menu.portrait.texture.region.position.x==904,"Ordinary pick cancels only playerRandom")
	scene.select_cpu_vehicle(4)
	check(not scene.cpu_random and scene.cpu_vehicle==4,"Ordinary CPU pick cancels itsRandom")
	scene.select_vehicle(0)
	check(scene.vehicle==2 and not scene.player_random,"ID0 remains invalid, notRandom or a removed mobile")
	var sampler := RandomNumberGenerator.new()
	sampler.seed = 2026
	var drawn := {}
	for i in 100:
		var id := Choice.roll(sampler)
		drawn[id] = true
		check(id in [14,15],"RestrictedRandom pool sample stays legal")
	check(drawn.has(14) and drawn.has(15) and drawn.size()==2,"Both special mobiles can be drawn")
	test_assets(scene.menu.room_art)
	scene.free()
	for p in [PATH,PATH.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	finish("ROOM REFERENCE CHECKS")
func test_assets(art) -> void:
	for info in art.reference_art.catalog.assets.values():
		var imported: Image = load(ROOT+str(info.file)).get_image()
		var png := Image.load_from_file(ROOT+str(info.file))
		imported.convert(Image.FORMAT_RGBA8)
		png.convert(Image.FORMAT_RGBA8)
		imported.premultiply_alpha()
		png.premultiply_alpha()
		check(imported.get_data()==png.get_data(),str(info.file)+" imports without visible loss")
	var baseline: Dictionary = art.reference_art.catalog.duplicate(true)
	art.reference_art.catalog = {}
	check(art.frame("room_random",4).region==Rect2(252,0,63,47),"Random fallback keeps active source window")
	check(art.image("room_team_a").get_size()==Vector2(127,71) and art.image("room_team_b").get_size()==Vector2(127,72),"Team fallback preserves unequal native heights")
	check(art.image("room_item_up_2").get_size()==Vector2(17,48) and art.image("room_item_up_0").get_size()==Vector2(16,48),"Unequal arrow windows stay intact without padding")
	art.reference_art.catalog = baseline
