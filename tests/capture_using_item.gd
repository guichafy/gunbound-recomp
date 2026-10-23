extends SceneTree
## ADR-065: 1920×1080 capture of the UsingItem aura. The 1280×800 game is
## scaled uniformly to the window height, so the aspect is not stretched.
var view

func _initialize() -> void:
	call_deferred("run")

func snap(name: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/items/" + name + ".png")

func run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/items"))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/using-item-capture-profile.json")
	root.add_child(view)
	var scale := 1080.0 / 800.0
	view.scale = Vector2(scale, scale)
	view.position = Vector2((1920.0 - 1280.0 * scale) * 0.5, 0)
	view.set_process(false)
	view.sound.muted = true
	view.options.items = ["dual", "teleport", "power_up", "energy_up_1"]
	view.select_vehicle(2)
	view.opening = 0
	view.start_match()
	if view.model.active != 0:
		view.model.pass_turn()
		view.consume_events()
	for _frame in range(20):
		view._process(1.0 / 60.0)
	view.item_bar.press(view, 0)
	view.consume_events()
	view.update_hud()
	var hidden: bool = not view.item_bar.buttons[0].visible
	for sample in [0, 4, 8, 12, 16]:
		view.art.motion[0].pose = "using_item"
		view.art.motion[0].pose_age = float(sample) / 19.0
		view.art.motion[0].using = 1.0
		await snap("using-item-%02d" % sample)
	print("USING ITEM CAPTURE | HIDDEN ", hidden, " | DENSITY ", view.item_art.using_density("bigfoot"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/using-item-capture-profile.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/using-item-capture-profile-options.json"))
	quit()
