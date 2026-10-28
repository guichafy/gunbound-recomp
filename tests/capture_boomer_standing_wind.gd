extends SceneTree
## Real scene, supported Boomer, Change Wind, isolated profile.
const OUT := "res://docs/boomer-standing-wind/"
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
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/boomer-standing-wind/profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(6)
	scene.select_cpu_vehicle(1)
	scene.options.items = ["change_wind"]
	var report: Array = []
	for facing in [1,-1]:
		for setting in [[0,0],[26,0],[26,90],[26,180],[26,270]]:
			scene.opening = 0
			scene.match_seed = 42
			scene.start_match()
			var model = scene.model
			model.actors[0].facing = facing
			model.weather.columns.clear()
			model.weather.thor.active = false
			model.weather.wind_force = int(setting[0])
			model.weather.wind_angle = int(setting[1])
			model.wind = model.weather.wind_vector()
			var start_pos: Vector2 = model.actors[0].pos
			var before := int(model.weather.wind_angle)
			var pause: PackedByteArray
			var frozen := 0.0
			for frame in 100:
				if frame == 20:
					assert(model.use_item(0))
					scene.consume_events()
					assert(int(model.weather.wind_angle) == posmod(before + 180,360))
				scene.paused = frame >= 30 and frame < 60
				scene._process(1.0/60)
				var image := await picture()
				if frame == 30:
					pause = image.get_data()
					frozen = float(scene.art.motion[0].pose_age)
					assert(str(scene.art.motion[0].pose) == "using_item")
					if int(setting[0]) > 0 and int(setting[1]) in [0,180]:
						image.save_png(OUT+"facing%d-angle%d-item.png"%[facing,int(setting[1])])
				if scene.paused:
					assert(image.get_data() == pause)
				if frame == 60:
					assert(float(scene.art.motion[0].pose_age) > frozen)
				assert(Vector2(model.actors[0].pos) == start_pos)
			scene.paused = false
			report.append({"facing":facing,"force":setting[0],"before":before,"after":model.weather.wind_angle,"stationary":true,"pause_frames_identical":30,"resumed":true})
	var file := FileAccess.open(OUT+"gpu-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"clock_hz":60,"frames":1000,"cases":report,"model_poses_are_port_adaptation":true},"\t"))
	file.close()
	print("BOOMER STANDING WIND GPU: 1000 frames, 10 cases, change wind, pause/resume")
	scene.free()
	quit()
