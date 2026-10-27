extends SceneTree
## README evidence (ADR-132): lobby, room, Avatar Shop and a real Bigfoot T1 in
## Miramo Town, all drawn with the active original assets at 1920×1080.
## Writes docs/readme/*.png and the shot frames in .tools/readme-frames; the
## GIF is assembled from those frames with ffmpeg (see docs/readme/README.md).
const OUT := "res://docs/readme/"
const FRAMES := "res://.tools/readme-frames/"
const PROFILE := "res://.tools/readme-capture.json"
var scene
func _initialize() -> void:
	call_deferred("run")
func snap(name: String, folder: String = OUT) -> Image:
	scene.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var image := root.get_texture().get_image()
	assert(image.get_size() == Vector2i(1920, 1080), "README capture must contain the complete1920x1080window")
	assert(image.save_png(folder + name + ".png") == OK)
	return image
func run() -> void:
	for path in [OUT, FRAMES]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	for path in [PROFILE, PROFILE.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size = Vector2i(1920, 1080)
	# Capture physical window pixels, including the16:10canvas fit.
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor = 1.0
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	scene.profile.gender = 1
	root.add_child(scene)
	scene.set_process(false)
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96, 0)
	scene.sound.muted = true
	# Same outfit as the ADR-130 shop evidence, bought with the test funds.
	for key in ["xfs:1:0:1", "xfs:1:1:1", "xfs:1:2:1", "xfs:2:3:1", "xfs:2:3:3"]:
		assert(scene.profile.purchase(key, "gold") == "ok")
	for key in ["xfs:1:1:1", "xfs:1:2:1", "xfs:2:3:3"]:
		assert(scene.profile.equip(key))
	scene.show_lobby()
	await snap("lobby")
	scene.show_shop()
	scene.shop.set_process(false)
	scene.shop.model.select("xfs:1:1:1")
	scene.shop.refresh(0, 0)
	await snap("shop")
	scene.leave_shop()
	await process_frame
	scene.show_menu()
	scene.select_vehicle(2)
	scene.select_cpu_vehicle(1)
	await snap("room")
	scene.opening = 0
	scene.match_seed = 42
	scene.start_match()
	for i in 60:
		scene._process(1.0 / 60)
		await process_frame
	scene.select_weapon(0)
	assert(scene.model.fire(50, 62, 0))
	scene.consume_events()
	var frame := 0
	for tick in 360:
		scene._process(1.0 / 60)
		if tick % 2 == 0:
			await snap("%03d" % frame, FRAMES)
			frame += 1
		else:
			await process_frame
		if tick > 30 and scene.model.phase != "flight" and scene.model.projectiles.is_empty():
			break
	await snap("battle-shot")
	print("README CAPTURE frames=", frame)
	scene.queue_free()
	await process_frame
	for path in [PROFILE, PROFILE.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit()
