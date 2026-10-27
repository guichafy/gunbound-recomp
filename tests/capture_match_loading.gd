extends SceneTree
## One frame of the room loading screen at 1280×800.

const PROFILE := "res://.tools/match-loading/capture-profile.json"
const OUT := "res://docs/match-loading/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.opening = 0
	scene.show_menu()
	scene.profile.nickname = "testusername"
	if is_instance_valid(scene.menu.nickname_input):
		scene.menu.nickname_input.text = "testusername"
	scene.room_rng.seed = 7
	scene.select_vehicle(-2)
	scene.select_cpu_vehicle(-2)
	scene.begin_loading()
	scene.loading_view.progress = 0.72
	scene.loading_view.queue_redraw()
	scene.menu.figures.queue_redraw()
	scene.queue_redraw()
	for _i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	shot.save_png(OUT + "loading-random.png")
	print("CAPTURE ", shot.get_width(), "x", shot.get_height(), " player=", scene.loading_player, " cpu=", scene.loading_cpu)
	quit(0)
