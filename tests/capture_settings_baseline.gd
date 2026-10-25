extends SceneTree
const OUT := "res://docs/settings-baseline/"
const PROFILE := "res://.tools/room-contact/settings-baseline-profile.json"
var view
func _initialize() -> void:call_deferred("run")
func snap(name: String) -> Image:
	view.menu.figures.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	shot.save_png(OUT+name+".png")
	return shot
func mouse(point: Vector2, down: int = -1) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	if down>=0:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down==1 else 0
		event.pressed = down==1
		root.push_input(event)
func run() -> void:
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(view)
	view.scale = Vector2.ONE*1.35
	view.position = Vector2(96,0)
	view.set_process(false)
	view.sound.muted = true
	view.show_menu()
	view.elapsed = 0
	mouse(Vector2.ZERO)
	var first := await snap("room-corrected")
	var previous := Image.load_from_file("res://docs/room-settings-classic/room-corrected.png")
	var approved := Image.load_from_file("res://docs/room-button-alpha/room-corrected.png")
	var stage: Node = view.menu.figures.get_parent()
	var start: TextureButton = stage.get_node("Start")
	var bounds := start.get_global_rect()
	var text_bounds := Rect2(start.get_global_transform()*Vector2(29,14), Vector2(49,19)*start.get_global_transform().get_scale())
	var rect := Rect2i(Vector2i(text_bounds.position.ceil()),Vector2i(text_bounds.size.floor()))
	var start_identical := previous.get_region(rect).get_data()==first.get_region(rect).get_data()
	var full_rect := Rect2i(Vector2i(bounds.position.floor()),Vector2i(bounds.size.ceil()))
	var button_identical := approved.get_region(full_rect).get_data()==first.get_region(full_rect).get_data()
	var settings: TextureButton = stage.get_node("Settings")
	settings.hide()
	start.hide()
	var background := await snap("background")
	settings.show()
	start.show()
	var normal := await snap("room-transparent")
	var corners_clear := true
	for button in [settings,start]:
		var box: Rect2 = button.get_global_rect()
		for point in [box.position+Vector2(1,1),Vector2(box.end.x-2,box.position.y+1),Vector2(box.position.x+1,box.end.y-2),box.end-Vector2(2,2)]:
			if normal.get_pixelv(Vector2i(point))!=background.get_pixelv(Vector2i(point)):corners_clear=false
	mouse(settings.get_global_rect().get_center())
	await snap("settings-hover")
	mouse(settings.get_global_rect().get_center(),1)
	await snap("settings-pressed")
	mouse(settings.get_global_rect().get_center(),0)
	await process_frame
	var opens: bool = view.menu.popup_open()
	view.menu.cancel_popup()
	mouse(Vector2.ZERO)
	settings.disabled = true
	await snap("settings-disabled")
	settings.disabled = false
	var art = view.menu.room_art
	var saved: Dictionary = art.settings_art.catalog.duplicate(true)
	art.settings_art.catalog = {}
	for state in 4:settings.word_frames[state] = art.frame("room_settings_word",state)
	await snap("settings-native")
	art.settings_art.catalog = saved
	var report := {"size":[1920,1080],"start_approved_lettering_identical":start_identical,"start_button_approved_pixels_identical":button_identical,"outside_corners_show_live_background":corners_clear,"settings_opens_modal":opens,"states":4,"native_fallback":true}
	var file := FileAccess.open(OUT+"render.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("SETTINGS WORD RENDER ",report)
	view.free()
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(0 if start_identical and button_identical and opens and corners_clear else 1)
