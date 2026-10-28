extends SceneTree
## Real scene presentation with native EPA state and isolated profile.
const OUT := "res://docs/boomer-native-poses/"
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
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/boomer-native-poses/profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(6)
	scene.select_cpu_vehicle(1)
	var results: Array = []
	for facing in [1,-1]:
		for pose in ["hurt","hurt_2","using_item","destroyed"]:
			scene.opening = 0
			scene.match_seed = 42
			scene.start_match()
			scene.model.actors[0].facing = facing
			scene.model.weather.columns.clear()
			scene.model.weather.thor.active = false
			if pose == "destroyed":
				scene.model.actors[0].hp = 0
			elif pose == "using_item":
				scene.model.events.append({"type":"item","actor":0,"item":"power_up"})
			else:
				scene.art.motion[0].hurt_flip = pose == "hurt_2"
				scene.model.events.append({"type":"damage","actor":0,"amount":1})
			scene.consume_events()
			var pause: PackedByteArray
			var frozen := 0.0
			for frame in 90:
				scene.paused = frame >= 10 and frame < 40
				scene._process(1.0/60)
				var image := await picture()
				if frame == 10:
					pause = image.get_data()
					frozen = float(scene.art.motion[0].dead if pose == "destroyed" else scene.art.motion[0].pose_age)
					image.save_png(OUT+"%s-facing%d.png"%[pose,facing])
				if scene.paused:
					assert(image.get_data() == pause)
				if frame == 40:
					var resumed: float = scene.art.motion[0].dead if pose == "destroyed" else scene.art.motion[0].pose_age
					assert(resumed > frozen)
				if frame == 50 and pose == "destroyed":
					assert(not scene.art.visual_style(0,scene.model.actors[0],0).visible or float(scene.art.motion[0].dead) < 0.5)
					image.save_png(OUT+"destroyed-resume-facing%d.png"%facing)
			scene.paused = false
			results.append({"pose":pose,"facing":facing,"pause_frames_identical":30,"resumed":true})
	var file := FileAccess.open(OUT+"gpu-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"clock_hz":60,"frames":720,"cases":results,"controlled_events":true},"\t"))
	file.close()
	print("BOOMER NATIVE POSES GPU: 720 frames, 8 cases, pause/resume")
	scene.free()
	quit()
