extends SceneTree
## Scene/Match fall interpolation, controlled flat ground and isolated profile.
const OUT := "res://docs/boomer-fall-wind/"
var scene

func _initialize() -> void:
	call_deferred("run")

func picture() -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1920,1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/boomer-fall-wind/profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(6)
	scene.select_cpu_vehicle(1)
	var results: Array = []
	var frames := 0
	for facing in [1,-1]:
		for wind in [Vector2.ZERO,Vector2(26,0),Vector2(-26,0),Vector2(18,18),Vector2(-18,18),Vector2(-18,-18),Vector2(18,-18)]:
			scene.opening = 0
			scene.match_seed = 42
			scene.start_match()
			var model = scene.model
			var terrain = model.terrain
			terrain.WIDTH = 640
			terrain.HEIGHT = 400
			terrain.cells.resize(640*400)
			terrain.cells.fill(0)
			terrain.image = Image.create(640,400,false,Image.FORMAT_RGBA8)
			terrain.image.fill(Color.TRANSPARENT)
			for y in range(300,400):
				for x in 640:
					terrain.cells[y*640+x] = 1
					terrain.image.set_pixel(x,y,Color("685741"))
			terrain.native_cells.clear()
			terrain.enable_native()
			terrain.texture = ImageTexture.create_from_image(terrain.image)
			terrain.visual = null
			terrain.map_id = ""
			model.actors[0].pos = Vector2(500,475)
			model.actors[0].facing = facing
			model.actors[1].pos = Vector2(1000,575)
			model.wind = wind
			model.weather.columns.clear()
			model.weather.thor.active = false
			model.weather.wind_force = roundi(wind.length())
			model.weather.wind_angle = roundi(-rad_to_deg(wind.angle())) if wind.length() > 0 else 0
			scene.art.reset(model.actors)
			var before: Vector2 = model.actors[0].pos
			model.settle_actors()
			var after: Vector2 = model.actors[0].pos
			assert(signf(after.x-before.x) == signf(wind.x))
			var pause: PackedByteArray
			var pause_pos := Vector2.ZERO
			for frame in 80:
				scene.paused = frame >= 20 and frame < 50
				scene._process(1.0/60)
				var image := await picture()
				if frame == 20:
					pause = image.get_data()
					pause_pos = scene.art.motion[0].pos
				if scene.paused:
					assert(image.get_data() == pause)
				if frame == 65 and wind.y == 0 and absf(wind.x) == 26.0:
					image.save_png(OUT+"facing%d-wind%d.png"%[facing,int(wind.x)])
				if frame == 50:
					assert(Vector2(scene.art.motion[0].pos) != pause_pos)
				frames += 1
			scene.paused = false
			results.append({"facing":facing,"wind":[wind.x,wind.y],"before":[before.x,before.y],"after":[after.x,after.y],"pause_frames_identical":30,"resume":true})
	var output := FileAccess.open(OUT+"gpu-validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"size":[1920,1080],"frames":frames,"clock_hz":60,"cases":results,"adapted_interpolation":true},"\t"))
	output.close()
	print("BOOMER FALL WIND GPU: ",frames," frames, ",results.size()," cases, pause/resume")
	scene.free()
	quit()
