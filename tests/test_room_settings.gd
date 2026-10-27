extends "res://tests/support/suite.gd"
const PROFILE := "res://.tools/room-contact/test-settings-profile.json"
func click(point: Vector2) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event)
func run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_menu()
	await process_frame
	var menu = scene.menu
	var stage: Node = menu.figures.get_parent()
	var settings: TextureButton = stage.get_node("Settings")
	for name in ["Settings","Start"]:
		var button: TextureButton = stage.get_node(name)
		for texture in [button.texture_normal,button.texture_hover,button.texture_pressed,button.texture_disabled]:
			var skin: Image = texture.get_image()
			var transparent := true
			for point in [Vector2i.ZERO,Vector2i(skin.get_width()-1,0),Vector2i(0,skin.get_height()-1),Vector2i(skin.get_width()-1,skin.get_height()-1)]:
				if skin.get_pixelv(point).a!=0:transparent=false
			check(transparent,name+" actual TextureButton textures have transparent outside corners in every state")
	check(settings.get("word_frames") is Array and settings.get("word_frames").size()==4,"SETTINGS uses four complete transparent word textures, without individual crop rectangles")
	for word in settings.get("word_frames"):
		var image: Image = word.get_image()
		check(image.get_pixel(0,0).a==0 and image.get_pixel(image.get_width()/2,0).a==0 and image.get_pixel(image.get_width()-1,image.get_height()-1).a==0,"Word corners and top margin stay transparent, without rectangular blue mattes")
		var soft_edge := false
		for y in image.get_height():
			for x in image.get_width():
				var alpha := image.get_pixel(x,y).a
				if alpha>0 and alpha<1:soft_edge=true
		check(soft_edge,"SETTINGS word has a finished alpha edge instead of hard clipping around each letter")
	check(menu.settings_font.get_font_name()=="GunBound Classic ASCII","Modal primary font is the native bitmap subset, without system-font substitution")
	check(menu.nickname_input.get_theme_font("font")==menu.settings_font,"Nickname input shares the classic font and fallback")
	click(stage.get_node("Settings").get_global_rect().get_center())
	await process_frame
	check(menu.popup_open() and menu.settings_popup.visible and menu.dimmer.visible,"SETTINGS click opens classic modal with backdrop")
	check(root.gui_get_focus_owner()==menu.nickname_input,"Opening settings focuses nickname input")
	var nickname: String = menu.nickname_input.text
	var previous_vehicle: int = scene.vehicle
	click(menu.grid_buttons[0].get_global_rect().get_center())
	await process_frame
	check(scene.vehicle==previous_vehicle and menu.popup_open(),"Modal blocks selection behind its backdrop")
	click(menu.difficulty_buttons[2].get_global_rect().get_center())
	click(menu.weather_buttons[1].get_global_rect().get_center())
	await process_frame
	check(menu.draft_difficulty==2 and menu.draft_weather=="all","Classic radio hitboxes update draft choices")
	check(scene.cpu_difficulty==1 and menu.cpu_detail.text=="CPU · Normal","Draft does not alter confirmed difficulty")
	menu.nickname_input.text = "Rascunho"
	click(menu.settings_popup.get_node("SettingsCancel").get_global_rect().get_center())
	await process_frame
	check(not menu.popup_open() and menu.nickname_input.text==nickname and scene.cpu_difficulty==1,"Native Cancel discards nickname and choices")
	click(stage.get_node("Settings").get_global_rect().get_center())
	await process_frame
	click(menu.difficulty_buttons[0].get_global_rect().get_center())
	menu.nickname_input.text = "Piloto clássico"
	click(menu.settings_popup.get_node("SettingsAccept").get_global_rect().get_center())
	await process_frame
	check(not menu.popup_open() and scene.cpu_difficulty==0 and menu.cpu_detail.text=="CPU · Leve","Native OK applies difficulty to CPU card")
	check(menu.player_name.text=="Piloto clássico" and scene.screen=="menu","OK updates nickname and remains in room")
	click(stage.get_node("Settings").get_global_rect().get_center())
	await process_frame
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	root.push_input(esc)
	await process_frame
	check(not menu.popup_open() and scene.screen=="menu","ESC dismisses classic modal without leaving room")
	check(not stage.get_node("Start").disabled and not stage.get_node("Settings").disabled,"Closing restores room button input")
	var art = menu.room_art
	var saved: Dictionary = art.settings_art.catalog.duplicate(true)
	for key in art.settings_keys:
		var cell: Vector2 = Vector2(art.records[key].frame_size[0],art.records[key].frame_size[1])
		for index in int(art.records[key].frames):
			var frame: AtlasTexture = art.frame(key,index)
			check(frame.atlas.resource_path.begins_with(art.SETTINGS_ROOT) and frame.region==Rect2(index*cell.x*4,0,cell.x*4,cell.y*4),"Classic settings HD frame "+key+str(index))
	art.settings_art.catalog = {}
	var native_word: Image = art.frame("room_settings_word",0).get_image()
	var top_rows: Array[int] = []
	for span in [Vector2i(13,7),Vector2i(22,8),Vector2i(32,8)]:
		var first_row := native_word.get_height()
		for y in 8:
			for x in range(span.x,span.x+span.y):
				if native_word.get_pixel(x,y).r>=49.0/255.0:first_row=mini(first_row,y)
		top_rows.append(first_row)
	check(top_rows[1]==top_rows[0],"First T visible top bar aligns with E, including weaker native antialias row")
	check(top_rows[2]==top_rows[0],"Second T visible top bar aligns with E, including weaker native antialias row")
	for state in 4:
		var palette := {}
		for file in ["b_ready_startgame","b_ready_exit","b_ready_changeteam"]:
			var original: Image = load("res://assets/classic/room/"+file+".png").get_image()
			for y in 45:
				for x in 107:palette[original.get_pixel(state*107+x,y).to_rgba32()>>8] = true
		var word: Image = art.frame("room_settings_word",state).get_image()
		var copied := true
		for y in word.get_height():
			for x in word.get_width():
				var pixel := word.get_pixel(x,y)
				if pixel.a>0 and not palette.has(pixel.to_rgba32()>>8):copied=false
		check(copied,"SETTINGS native RGB retains original source colours per state while edge alpha is finished separately")
	for key in art.settings_keys:
		var frame: AtlasTexture = art.frame(key,0)
		check(frame.atlas.resource_path.begins_with("res://assets/classic/room/settings/"),"Missing settings HD falls back: "+key)
	art.settings_art.catalog = saved
	click(stage.get_node("Start").get_global_rect().get_center())
	await process_frame
	check(scene.screen=="loading","Arrowless START opens the loading screen before the match")
	scene._process(5.0)
	check(scene.screen=="match" and scene.model.difficulty==0,"Arrowless START keeps its action and committed difficulty")
	scene.free()
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("ROOM SETTINGS CHECKS")
