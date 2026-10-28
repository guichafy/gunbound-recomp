extends SceneTree
## Fixed flat ground, real scene firing, pause/resume, isolated profile.
const OUT := "res://docs/boomer-muzzle-slope/"
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
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/boomer-muzzle-slope/profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(6)
	scene.select_cpu_vehicle(1)
	var results: Array = []
	for slope in [-1,1]:
		for facing in [1,-1]:
			var angle := 45
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
			for y in range(400):
				for x in 640:
					var floor_cell := clampi(300+int((x-250)*slope/5.0),0,399)
					if y >= floor_cell:
						terrain.cells[y*640+x] = 1
						terrain.image.set_pixel(x,y,Color("685741"))
			terrain.native_cells.clear()
			terrain.enable_native()
			terrain.texture = ImageTexture.create_from_image(terrain.image)
			terrain.visual = null
			terrain.map_id = ""
			model.actors[0].pos = Vector2(500,575)
			model.actors[0].facing = facing
			model.actors[1].pos = Vector2(1000,terrain.surface_at(1000)-model.stance_of(1))
			model.wind = Vector2.ZERO
			model.weather.columns.clear()
			model.weather.thor.active = false
			model.weather.wind_force = 0
			scene.art.reset(model.actors)
			scene.rig.position = Vector2.ZERO
			scene.rig.manual = true
			scene.aim.angle = angle
			assert(model.fire(angle,60,0))
			var shell: Dictionary = model.projectiles[0]
			var start: Vector2 = shell.pos
			assert(absf(model.body_rotation(0)) > 0.1)
			scene.consume_events()
			var pause: PackedByteArray
			var pause_age := 0.0
			for frame in 90:
				scene.paused = frame >= 25 and frame < 55
				scene._process(1.0/60)
				var image := await picture()
				if frame == 24:
					assert(bool(shell.launched))
					image.save_png(OUT+"slope%d-facing%d-launch.png"%[slope,facing])
				if frame == 25:
					pause = image.get_data()
					pause_age = float(shell.age)
				if scene.paused:
					assert(image.get_data() == pause)
				# Rendering is 60 Hz, but projectile age advances on the 20 Hz
				# physical tick; allow the first three resumed render frames.
				if frame == 57:
					assert(float(shell.age) > pause_age)
				if frame == 65:
					image.save_png(OUT+"slope%d-facing%d-flight.png"%[slope,facing])
			scene.paused = false
			results.append({"facing":facing,"slope":slope,"angle":angle,"muzzle":[start.x,start.y],"pause_frames_identical":30,"resumed":true})
	var file := FileAccess.open(OUT+"gpu-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"clock_hz":60,"frames":360,"cases":results,"sloped_fixture":true},"\t"))
	file.close()
	print("BOOMER MUZZLE SLOPE GPU: 360 frames, 4 cases, pause/resume")
	scene.free()
	quit()
