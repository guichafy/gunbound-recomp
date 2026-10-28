extends SceneTree
## GPU regression: selected map/title and both complete room figures survive Start.
## Native 800×600 room at uniform 1.8× inside a real 1920×1080 viewport.
const PROFILE := "res://.tools/match-loading/capture-profile.json"
const OUT := "res://docs/match-loading/"
const Choice = preload("res://scripts/room_choice.gd")
var scene
var failures := 0
var records: Array = []

func _initialize() -> void:
	call_deferred("run")

func picture() -> Image:
	scene.menu.figures.queue_redraw()
	scene.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	var pixels := root.get_texture().get_image()
	assert(pixels.get_size() == Vector2i(1920, 1080))
	return pixels

func digest(pixels: Image) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(pixels.get_data())
	return hash.finish().hex_encode()

func crop(pixels: Image, rect: Rect2) -> Image:
	var physical: Rect2 = scene.menu.stage.get_global_transform() * rect
	return pixels.get_region(Rect2i(physical.position.round(), physical.size.round()))

func compare(before: Image, after: Image, rect: Rect2, label: String) -> Dictionary:
	var first := digest(crop(before, rect))
	var second := digest(crop(after, rect))
	if first != second:
		failures += 1
		printerr("FAIL GPU: ", label)
	return {"before": first, "after": second, "equal": first == second}

func run_case(id: int, random_pick := false, native_map := false) -> void:
	scene.show_menu()
	scene.elapsed = 0.0
	scene.room_rng.seed = 7
	var player := id
	var cpu := id
	if random_pick:
		var mirror := RandomNumberGenerator.new()
		mirror.state = scene.room_rng.state
		player = Choice.roll(mirror)
		cpu = Choice.roll(mirror)
	scene.select_vehicle(player)
	scene.select_cpu_vehicle(cpu)
	if native_map:
		scene.menu.room_art.art.catalog = {}
		scene.menu.map_preview.texture = scene.menu.room_art.frame("room_maps", 1)
	var before := await picture()
	if random_pick:
		scene.select_vehicle(Choice.RANDOM)
		scene.select_cpu_vehicle(Choice.RANDOM)
	scene.begin_loading()
	scene.loading_view.progress = 0.72
	var after := await picture()
	var label := "random" if random_pick else "mobile-%02d" % id
	if native_map:
		label += "-native-map"
	var row := {"case": label, "player": scene.loading_player, "cpu": scene.loading_cpu}
	row.map = compare(before, after, Rect2(332, 51, 136, 84), label + " map and embedded title")
	# Skip the intentionally empty header; include rider, hull and ground contact.
	row.player_figure = compare(before, after, Rect2(39, 82, 124, 80), label + " complete player figure")
	row.cpu_figure = compare(before, after, Rect2(497, 82, 124, 80), label + " complete CPU figure")
	row.slot_headers = compare(before, after, Rect2(39, 63, 582, 18), label + " empty slot headers")
	assert(after.save_png(OUT + "loading-" + label + ".png") == OK)
	if id == 1 and not random_pick:
		assert(before.save_png(OUT + "room-before-start.png") == OK)
	records.append(row)

func run_timeline() -> Dictionary:
	scene.show_menu()
	scene.select_vehicle(1)
	scene.select_cpu_vehicle(15)
	scene.elapsed = 0.0
	scene.begin_loading()
	# An empty-slot reference makes disappearance observable in every frame.
	scene.menu.figures.visible = false
	var empty := await picture()
	scene.menu.figures.visible = true
	var reference := await picture()
	var map_hash := digest(crop(reference, Rect2(332, 51, 136, 84)))
	var empty_player := digest(crop(empty, Rect2(39, 82, 124, 80)))
	var empty_cpu := digest(crop(empty, Rect2(497, 82, 124, 80)))
	var changes := {}
	var absent := 0
	var wrong_map := 0
	for frame in 295:
		scene._process(1.0 / 60.0)
		var pixels := await picture()
		var player := digest(crop(pixels, Rect2(39, 82, 124, 80)))
		var cpu := digest(crop(pixels, Rect2(497, 82, 124, 80)))
		changes[player + cpu] = true
		if player == empty_player or cpu == empty_cpu:
			absent += 1
		if digest(crop(pixels, Rect2(332, 51, 136, 84))) != map_hash:
			wrong_map += 1
		if frame in [0, 120, 240, 294]:
			assert(pixels.save_png(OUT + "loading-timeline-%03d.png" % frame) == OK)
	var held: bool = scene.screen == "loading"
	scene._process(0.1)
	var entered: bool = scene.screen == "match"
	if absent > 0 or wrong_map > 0 or not held or not entered or changes.size() < 2:
		failures += 1
		printerr("FAIL GPU: loading timeline")
	return {"frames": 295, "step": 1.0 / 60.0, "absent_figures": absent,
		"wrong_map": wrong_map, "distinct_poses": changes.size(),
		"held_until_4_916s": held, "entered_after_5s": entered}

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE.get_base_dir()))
	for path in [PROFILE, PROFILE.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96, 0)
	scene.opening = 0
	scene.profile.nickname = "testusername"
	for id in range(1, 17):
		await run_case(id)
		if "--regression-only" in OS.get_cmdline_user_args():
			break
	if not "--regression-only" in OS.get_cmdline_user_args():
		await run_case(15, true)
		await run_case(2, false, true)
	var timeline := {}
	if not "--regression-only" in OS.get_cmdline_user_args():
		timeline = await run_timeline()
	var report := FileAccess.open(OUT + "room-loading-proof.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"viewport": [1920, 1080], "cases": records, "timeline": timeline, "failures": failures}, "\t") + "\n")
	report.close()
	scene.free()
	for path in [PROFILE, PROFILE.get_basename() + "-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("LOADING GPU: ", records.size(), " cases | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
