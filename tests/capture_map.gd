extends SceneTree
## REQ-21 GPU captures at 1920×1080: Miramo Town A arena, a live shot, craters.
var view
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/map/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/map"))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/map-capture-profile.json")
	root.add_child(view)
	view.scale = Vector2(1.35, 1.35)
	view.position = Vector2(96, 0)
	view.set_process(false)
	# The app viewport clips the 1280×800 world; mask the capture's pillarbox the same way.
	var bars := CanvasLayer.new()
	bars.layer = 10
	root.add_child(bars)
	for rect in [Rect2(0, 0, 96, 1080), Rect2(1824, 0, 96, 1080)]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = rect.position
		bar.size = rect.size
		bars.add_child(bar)
	view.sound.muted = true
	view.profile.nickname = "Piloto"
	view.show_menu()
	view.select_vehicle(2)
	view.opening = 0
	view.start_match()
	view.model.start(2, 1, 4)
	view.art.reset(view.model.actors)
	view.consume_events()
	view.angle = 35
	# Pick the power whose prediction (the real flight loop) lands on the map.
	view.power = 30.0
	for power in range(30, 80, 2):
		var landing: Dictionary = view.model.predict_shot(0, 35.0, float(power), 0)
		if bool(landing.get("hit", false)) and absf(Vector2(landing.position).x - view.model.actors[1].pos.x) < 260.0:
			view.power = float(power)
			break
	view.update_hud()
	for frame in range(30):
		view._process(0.05)
	await snap("miramo-arena")
	view.shoot()
	view.consume_events()
	for frame in range(22):
		view._process(0.05)
	await snap("miramo-shot")
	for frame in range(160):
		view._process(0.05)
		if view.model.phase == "settle":
			for settle in range(6):
				view._process(0.05)
			break
	await snap("miramo-craters")
	# Original vs HD terrain at native density, same crop, for review.
	var terrain = view.model.terrain
	var fresh = load("res://scripts/terrain.gd").texture_image("res://assets/hd/maps/miramo_town/foreground_a.png")
	var original = load("res://scripts/terrain.gd").texture_image("res://assets/openbound/maps/miramo_town/ForegroundA.png")
	if fresh != null and original != null:
		var crop: Image = original.get_region(Rect2i(17, 1344, 1766, 456))
		crop.resize(1280, 330, Image.INTERPOLATE_LANCZOS)
		var hd: Image = fresh.duplicate()
		hd.resize(1280, 330, Image.INTERPOLATE_LANCZOS)
		var sheet := Image.create(1280, 680, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("8a7fc0"))
		sheet.blend_rect(crop, Rect2i(0, 0, 1280, 330), Vector2i(0, 0))
		sheet.blend_rect(hd, Rect2i(0, 0, 1280, 330), Vector2i(0, 350))
		sheet.save_png("res://docs/map/miramo-original-vs-hd.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/map-capture-profile.json"))
	print("MAP CAPTURES: ", terrain.revision)
	quit()
