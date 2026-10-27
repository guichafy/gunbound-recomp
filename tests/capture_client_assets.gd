extends SceneTree
## REQ-48: full-HD temporal rendering of the active map, HUD, native weather,
## Thor, item sprites and declared gaps. Controlled presentation contacts do
## not prove native weather rules. Source-frame equality has separate tests.
const OUT := "res://docs/client-assets/"
const FRAMES := "res://.tools/client-assets/gpu-frames/"
const PROFILE := "res://.tools/client-assets/capture-profile.json"
var scene
var serial := 0

func _initialize() -> void:
	call_deferred("run")

func picture() -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	return root.get_texture().get_image()

func digest(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()

func run() -> void:
	for path in [OUT, FRAMES]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	for path in [PROFILE, PROFILE.get_basename()+"-options.json"]:
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
	var report: Array = []
	for mode in ["generic", "mage", "teleport"]:
		scene.show_menu()
		scene.select_vehicle(1 if mode == "mage" else 2)
		scene.select_cpu_vehicle(2 if mode == "mage" else 4)
		scene.options.items = ["dual", "teleport", "power_up", "energy_up_1"]
		scene.opening = 0
		scene.match_seed = 42
		scene.start_match()
		var model = scene.model
		model.weather.columns.clear()
		var at: Vector2 = model.actors[0].pos
		for pair in [["force",100],["electricity",270],["tornado",430]]:
			model.weather.add_column(pair[0], at.x+pair[1], 1.0)
		model.weather.thor.active = true
		model.weather.thor.pos = at+Vector2(160,-210)
		if model.weather.thor.has("display_pos"):
			model.weather.thor.display_pos = model.weather.thor.pos
			model.weather.thor.previous_display_pos = model.weather.thor.pos
		model.wind = Vector2.ZERO
		var paused_hash := ""
		var pause_frames := 0
		var resumed := false
		for frame in 120:
			if frame == 26:
				# Repeatable visible contacts, without touching damage/physics.
				scene.weather_art.react({"type":"thor", "from":at+Vector2(160,-210), "position":at+Vector2(110,5), "level":2, "removed":80, "native":mode=="mage", "ttl":0.6, "contact":false}, model, scene.sound)
				scene.item_art.add_flame(at+Vector2(80,-30), false)
				scene.item_art.add_flame(at+Vector2(180,-30), true)
			if frame == 65 and mode == "teleport":
				assert(scene.use_item(1))
				scene.aim.angle = 28
				scene.aim.power = 30
				scene.shoot()
			scene.paused = frame >= 30 and frame < 60
			scene._process(1.0/60)
			var image := await picture()
			assert(image.get_size() == Vector2i(1920,1080))
			if frame == 30:
				paused_hash = digest(image)
			if frame >= 30 and frame < 60:
				assert(digest(image) == paused_hash, "Pixels changed while paused: " + mode)
				pause_frames += 1
			if frame == 61:
				resumed = digest(image) != paused_hash
			image.save_jpg(FRAMES+"frame%04d.jpg"%serial, 0.9)
			serial += 1
			if frame in [0,26,30,59,75,119]:
				image.save_png(OUT+"%s-%03d.png"%[mode,frame])
		assert(resumed)
		report.append({"case":mode, "frames":120, "paused_identical":pause_frames, "pause_rgba_sha256":paused_hash, "resumed":resumed})
		scene.paused = false
		scene.show_menu()
		await process_frame
	scene.start_match()
	scene.show_options()
	(await picture()).save_png(OUT+"options.png")
	var output := FileAccess.open(OUT+"capture.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"size":[1920,1080],"fps_clock":60,"frames":serial,"cases":report,"sound":"muted; no listening validation","fixture":"controlled visual contacts; teleport fired through game"},"\t")+"\n")
	output.close()
	scene.queue_free()
	await process_frame
	for path in [PROFILE, PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CLIENT ASSETS GPU: ",serial," frames; 3x30 pause frames identical; resume verified")
	quit()
