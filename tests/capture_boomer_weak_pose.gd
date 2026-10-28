extends SceneTree
## Real-scene EPA threshold, wind variation, pause/resume; isolated profile.
const OUT := "res://docs/boomer-weak-pose-20261028/"
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
	root.size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/boomer-weak-pose/profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96, 0)
	scene.show_menu()
	scene.select_vehicle(6)
	scene.select_cpu_vehicle(1)
	var results: Array = []
	for facing in [-1, 1]:
		for hp in [332, 333]:
			for force in [0, 26]:
				scene.opening = 0
				scene.match_seed = 42
				scene.start_match()
				var actor: Dictionary = scene.model.actors[0]
				actor.facing = facing
				actor.max_hp = 1000
				actor.hp = hp
				scene.model.weather.columns.clear()
				scene.model.weather.thor.active = false
				scene.model.weather.wind_force = force
				scene.model.weather.wind_angle = 0
				scene.model.wind = scene.model.weather.wind_vector()
				var freeze: PackedByteArray
				var age := 0.0
				for frame in 80:
					scene.paused = frame >= 20 and frame < 50
					scene._process(1.0 / 60.0)
					var img := await picture()
					if frame == 20:
						freeze = img.get_data()
						age = float(scene.art.motion[0].pose_age)
						var native_frame: int = scene.actor_frame(0)
						assert((native_frame >= 40 and native_frame < 60) if hp == 332 else (native_frame >= 0 and native_frame < 20))
						img.save_png(OUT + "hp%d-wind%d-facing%d.png" % [hp, force, facing])
					if scene.paused:
						assert(img.get_data() == freeze)
					if frame == 50:
						assert(float(scene.art.motion[0].pose_age) > age)
				scene.paused = false
				results.append({"hp":hp, "wind":force, "facing":facing, "pause":30, "resumed":true})
	var file := FileAccess.open(OUT + "gpu-validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080], "frames":640, "cases":results}, "\t"))
	file.close()
	print("BOOMER WEAK POSE GPU: 640 frames, 8 cases, pause/resume")
	scene.free()
	quit()
