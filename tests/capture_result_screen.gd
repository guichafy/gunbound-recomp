extends SceneTree
## Result window (REQ-50/ADR-139) at 1280×800 over a real battle: player win,
## CPU win and draw, plus the OK button in hover and push states.

const PROFILE := "res://.tools/result-port/capture-profile.json"
const OUT := "res://docs/result-screen/"

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	for _i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(OUT + name + ".png")
	print("CAPTURE ", name, " ", image.get_width(), "x", image.get_height())

func finish(scene, loser: int) -> void:
	scene.opening = 0
	scene.start_match()
	scene.model.turn_time = 30.0
	if loser < 0:
		scene.model.actors[0].hp = 0
		scene.model.actors[1].hp = 0
	else:
		scene.model.actors[loser].hp = 0
	scene.model.check_end()
	scene.consume_events()
	scene.show_result()
	scene.update_hud()

func run() -> void:
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	scene.profile.nickname = "testusername"
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	finish(scene, 1)
	await shot("result-player-win")
	var ok: TextureButton = scene.overlays.layer.find_child("ResultOK", true, false)
	var hover := InputEventMouseMotion.new()
	hover.position = ok.get_global_rect().get_center()
	hover.global_position = hover.position
	root.push_input(hover)
	await shot("result-ok-hover")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = hover.position
	press.global_position = hover.position
	root.push_input(press)
	await shot("result-ok-push")
	press.pressed = false
	press.button_mask = 0
	root.push_input(press)
	await process_frame
	print("OK_TO_ROOM ", scene.screen)
	finish(scene, 0)
	await shot("result-cpu-win")
	finish(scene, -1)
	await shot("result-draw")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	scene.queue_free()
	await process_frame
	quit(0)
