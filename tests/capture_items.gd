extends SceneTree
## REQ-35..37 GPU captures at 1920×1200 (1.5× the 1280×800 canvas): item bar,
## an item in use, Ignorance lock, the Select Item popup (HD and original), the
## teleport beacon in flight and the teleport flames.
var view
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	view.queue_redraw()
	if view.items_popup != null:
		view.items_popup.redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/items/" + name + ".png")
func advance(seconds: float) -> void:
	for frame in range(int(seconds / 0.05)):
		view._process(0.05)
func restyle() -> void:
	for slot in range(view.item_bar.buttons.size()):
		var button: TextureButton = view.item_bar.buttons[slot]
		view.item_art.style_button(button, view.model.actors[0].items[slot].id, bool(button.get_meta("activated")))
	view.item_bar.lock_rect.texture = view.item_art.region("MatchStatus.png", Rect2(Vector2.ZERO, view.item_bar.STATUS_SIZE))
func run() -> void:
	root.size = Vector2i(1920, 1200)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/items"))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/items-capture-profile.json")
	root.add_child(view)
	view.scale = Vector2(1.5, 1.5)
	view.set_process(false)
	view.sound.muted = true
	view.profile.nickname = "Piloto"
	view.options.items = ["dual", "teleport", "power_up", "energy_up_1"]
	# PopupSelectItem in the menu, hovering Dual (HD, then the originals).
	view.show_menu()
	view.show_items()
	view.items_popup.hover("dual")
	await snap("select-item")
	var hd: Dictionary = view.item_art.textures.duplicate()
	view.item_art.textures = view.item_art.originals.duplicate()
	view.accept_items()
	view.show_items()
	view.items_popup.select_tab(1)
	view.items_popup.hover("change_wind")
	await snap("select-item-original")
	view.item_art.textures = hd
	view.accept_items()
	view.select_vehicle(2)
	view.start_match()
	if view.model.active != 0:
		view.model.pass_turn()
		view.consume_events()
	advance(1.2)
	await snap("items-bar")
	view.item_art.textures = view.item_art.originals.duplicate()
	restyle()
	await snap("items-bar-original")
	view.item_art.textures = hd
	restyle()
	# Dual in use: activated face, the rest of the bar disabled, SS locked.
	view.item_bar.press(view, 0)
	advance(0.3)
	await snap("items-dual-used")
	# Ignorance locks the bar with the original ITEM LOCKED panel.
	var previous: String = view.model.weather.queue[0].type
	view.model.weather.queue[0].type = "ignorance"
	advance(0.1)
	await snap("items-locked")
	view.model.weather.queue[0].type = previous
	# Teleport: beacon in flight, then both flames.
	view.model.actors[0].turn_item = ""
	view.item_bar.disabled_until_turn = false
	view.model.weather.wind_force = 0
	view.model.wind = Vector2.ZERO
	view.use_item(1)
	view.weapon = 1
	view.angle = 28.0
	view.power = 30.0
	view.shoot()
	advance(0.45)
	await snap("teleport-beacon")
	for frame in range(200):
		view._process(0.05)
		if not view.item_art.flames.is_empty():
			break
	advance(0.2)
	await snap("teleport-flames")
	print("ITEM CAPTURES: 8 | FLAMES ", view.item_art.flames.size(), " | HD ", view.item_art.textures["ItemDual.png"].get_width())
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/items-capture-profile.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/items-capture-profile-options.json"))
	quit()
