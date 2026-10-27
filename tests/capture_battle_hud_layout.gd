extends SceneTree
## REQ-27/28/30/35/48: native header/footer, temporal charge/move, pause.
const OUT := "res://docs/battle-hud-layout/"
const PROFILE := "res://.tools/hud-layout/capture-profile.json"
var scene
func _initialize() -> void:
	call_deferred("run")
func picture() -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	return root.get_texture().get_image()
func digest(pixels: Image) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(pixels.get_data())
	return hash.finish().hex_encode()
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE*1.35
	scene.position = Vector2(96,0)
	var cases: Array = []
	for mode in ["slice","drag","move"]:
		scene.show_menu()
		scene.select_vehicle(2)
		scene.select_cpu_vehicle(1)
		scene.options.aiming = 0 if mode=="drag" else 1
		scene.options.items = ["dual","teleport","power_up","energy_up_1"]
		scene.opening = 0
		scene.match_seed = 42
		scene.start_match()
		scene.model.actors[0].gold_state.gold = 1234
		if mode=="move":
			key(KEY_RIGHT,true)
		elif mode=="slice":
			scene.begin_charge()
		else:
			scene.begin_drag(300)
			scene.update_drag(390,90)
		var pause_hash := ""
		var paused_frames := 0
		var resumed := false
		for frame in 120:
			scene.paused = frame>=30 and frame<60
			scene._process(1.0/60)
			var image := await picture()
			assert(image.get_size()==Vector2i(1920,1080))
			if frame==30: pause_hash=digest(image)
			if frame>=30 and frame<60:
				assert(digest(image)==pause_hash,"HUD changed while paused "+mode)
				paused_frames+=1
			if frame==75: resumed=digest(image)!=pause_hash
			if frame in [0,29,30,59,75,119]:
				assert(image.save_png(OUT+"%s-%03d.png"%[mode,frame])==OK)
		assert(resumed)
		cases.append({"case":mode,"frames":120,"pause_frames":paused_frames,"rgba_sha256":pause_hash,"resume":resumed})
		key(KEY_RIGHT,false)
		scene.paused=false
		scene.aim.charging = false
		scene.show_menu()
		await process_frame
	scene.options.aiming=1
	scene.start_match()
	scene.model.weather.queue[0].type="ignorance"
	scene.update_hud()
	(await picture()).save_png(OUT+"locked.png")
	scene.hud.client_assets.files.erase("NativeWeather.png")
	scene.hud.client_assets._cache.erase("NativeWeather.png")
	(await picture()).save_png(OUT+"weather-fallback.png")
	scene.show_options()
	(await picture()).save_png(OUT+"options.png")
	var file := FileAccess.open(OUT+"capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"frames":360,"clock_hz":60,"cases":cases,"audio":"muted"},"\t")+"\n")
	file.close()
	scene.queue_free()
	await process_frame
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("BATTLE HUD GPU:360 frames1920x1080,3x30 identical paused frames,resume verified")
	quit()
