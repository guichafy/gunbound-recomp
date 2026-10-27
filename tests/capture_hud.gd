extends SceneTree
## REQ-27..30 GPU captures at 1920×1200 (1.5× the 1280×800 canvas): original
## OpenBound battle HUD with the HD remaster, the same frame with the original
## sprites, the options popup (REQ-31), charging, the CPU turn balloon and
## floating damage.
var view
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/hud/" + name + ".png")
func advance(seconds: float) -> void:
	for frame in range(int(seconds / 0.05)):
		view._process(0.05)
func run() -> void:
	root.size = Vector2i(1920, 1200)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/hud"))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/hud-capture-profile.json")
	root.add_child(view)
	view.scale = Vector2(1.5, 1.5)
	view.set_process(false)
	view.sound.muted = true
	view.profile.nickname = "Piloto"
	view.show_menu()
	view.select_vehicle(2)
	view.opening = 0
	view.start_match()
	view.model.start(2, 1, 4)
	view.art.reset(view.model.actors)
	view.weather_art.reset(view.Maps.get_map(view.model.map_id))
	view.hud.reset(view.model)
	view.consume_events()
	if view.model.active != 0:
		view.model.pass_turn()
		view.consume_events()
		advance(0.5)
	view.aim.angle = 32
	view.hud.selector_x = 60.0
	view.hud.previous_power = 72.0
	view.hud.previous_angle = 41
	advance(1.2)
	await snap("hud-player-turn")
	# Same frame with the original sprites, for a side-by-side check.
	var hd: Dictionary = view.hud.textures.duplicate()
	view.hud.textures = view.hud.originals.duplicate()
	await snap("hud-player-turn-original")
	view.hud.textures = hd
	# REQ-31: ESC/Options opens the original PopupGameOptions over the battle.
	view.show_options()
	await snap("hud-options-popup")
	# Same native popup with the independent native fallback group.
	var missing = load("res://scripts/client_hud_assets.gd").new("res://.tools/missing-options-catalog.json")
	view.overlays.options_popup.art = load("res://scripts/classic_battle_options_art.gd").new(missing)
	for button in [view.overlays.options_popup.accept_button,view.overlays.options_popup.cancel_button,view.overlays.options_popup.quit_button]:
		button.art = view.overlays.options_popup.art
		button.queue_redraw()
	view.overlays.options_popup.queue_redraw()
	await snap("hud-options-popup-original")
	view.close_overlay()
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	view._unhandled_key_input(space)
	advance(1.1)
	await snap("hud-charging")
	space.pressed = false
	view._unhandled_key_input(space)
	for frame in range(200):
		view._process(0.05)
		if view.model.phase == "aim" and view.model.active == 1:
			break
	view.model.turn_time = 12.4
	view.hud.add_damage(1, 187, view.model)
	advance(0.7)
	await snap("hud-cpu-turn")
	print("HUD CAPTURES: 6 | ACTIVE ", view.model.active, " | SECONDS ", view.hud.display_seconds(view.model))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/hud-capture-profile.json"))
	quit()
