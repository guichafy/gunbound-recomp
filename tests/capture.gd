extends SceneTree
## Capture real rendered frames for visual QA, without OS input automation.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.sound.muted = true
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/capture-profile.json")
	scene.show_menu()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/menu.png")
	scene.opening = 0
	scene.start_match()
	scene.model.turn_time = 30.0
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/arena.png")
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	scene._unhandled_key_input(space)
	for i in range(7):
		scene._process(0.1)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/charge.png")
	# Restart before the controlled trajectory and result presentation.
	scene.opening = 0
	scene.start_match()
	scene.aim.angle = 43.0
	scene.aim.power = 66.0
	scene.shoot()
	for i in range(1600):
		await process_frame
		if scene.model.phase != "flight":
			break
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/impact.png")
	scene.model.actors[1].hp = 0
	scene.model.check_end()
	scene.consume_events()
	scene.show_result()
	scene.update_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/result.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/capture-profile.json"))
	scene.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("VISUAL CAPTURES SAVED")
	quit()
