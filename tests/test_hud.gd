extends "res://tests/support/suite.gd"
## REQ-27..30: original OpenBound battle HUD (layout, buttons, strength bar,
## keyboard, crosshair, compass, timer, Delayboard, life bar, damage counter) and
## REQ-31 PopupGameOptions (SFX, scroll speed, background, pause access).


func key(scene, code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	scene._unhandled_key_input(event)

## Mouse click through the viewport GUI (window 1:1 with the 1280×800 canvas).
func click(point: Vector2) -> void:
	root.size = Vector2i(1280, 800)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = point
		event.global_position = point
		root.push_input(event)

func player_turn(scene) -> void:
	for frame in range(400):
		if scene.model.phase == "aim" and scene.model.active == 0:
			return
		if scene.model.phase == "aim" and scene.model.active == 1:
			scene.model.pass_turn()
			scene.consume_events()
		scene._process(0.05)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/hud-test-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	var hud = scene.hud
	var HudArt = load("res://scripts/hud_art.gd")

	# REQ-27 layout: HUD.cs offsets on the 800×500 virtual screen, factor 1.6.
	check(HudArt.bar_point(Vector2.ZERO) == Vector2(640, 732), "Action bar centre follows origin = (0, (500 − 85) / 2) × 1.6")
	check(scene.VIEW_SIZE == Vector2(1280, 664) and is_equal_approx(732.0 - 85.0 * 1.6 * 0.5, 664.0), "World view ends where the 1280×136 action bar starts")
	for name in hud.textures:
		var factor: float = hud.density(name)
		# Mobiles without an approved HD sheet keep the original crosshair (Nak, and the classic roster).
		if ResourceLoader.exists("res://assets/hd/hud/" + name):
			check(is_equal_approx(factor, 3.0), "%s uses the 3× HD sprite" % name)
		else:
			check(is_equal_approx(factor, 1.0) and hud.textures[name] == hud.originals[name], "%s falls back to the original sprite" % name)
	scene.select_vehicle(2)
	scene.opening = 0
	scene.start_match()
	player_turn(scene)
	var s1: TextureButton = scene.weapon_buttons[0]
	check(s1.size.is_equal_approx(Vector2(37, 37) * 1.6) and (s1.position + s1.size * 0.5).is_equal_approx(HudArt.bar_point(Vector2(-371, -4))), "S1 button sits at the original (−371, −4)")
	check((scene.weapon_buttons[2].position + scene.weapon_buttons[2].size * 0.5).is_equal_approx(HudArt.bar_point(Vector2(-285, -4))), "SS button sits at the original (−285, −4)")
	check((scene.pass_button.position + scene.pass_button.size * 0.5).is_equal_approx(HudArt.bar_point(Vector2(-296, 26))), "SkipTurn button sits at the original (−296, 26)")
	check(s1.get_meta("activated") and not scene.weapon_buttons[1].get_meta("activated"), "S1 starts activated like HUD.cs")
	check(not scene.weapon_buttons[2].disabled, "SS is available on the first turn")

	# Tab cycles S1, S2 and SS, and skips SS after it has been fired.
	key(scene, KEY_TAB, true)
	check(scene.aim.weapon == 1 and scene.weapon_buttons[1].get_meta("activated"), "Tab selects S2")
	key(scene, KEY_TAB, true)
	check(scene.aim.weapon == 2, "Tab reaches SS on the first turn")
	scene.model.actors[0].ss_lock = 4
	scene.select_weapon(0)
	scene.update_hud()
	key(scene, KEY_TAB, true)
	key(scene, KEY_TAB, true)
	check(scene.aim.weapon == 0 and scene.weapon_buttons[2].disabled, "Tab skips SS while its lock is active")
	scene.select_weapon(0)

	# REQ-28 strength bar: starts empty, +2 every 0.04 s, release fires once.
	check(scene.aim.power == 0.0, "Strength bar starts the player turn empty")
	key(scene, KEY_SPACE, true)
	scene._process(0.1)
	scene._process(0.1)
	check(scene.aim.charging and is_equal_approx(scene.aim.power, 10.0), "0.2 s of charge = 5 steps of 2")
	hud.set_selector_from_screen(HudArt.bar_point(Vector2(100, 17)).x)
	check(is_equal_approx(hud.selector_x, 100.0) and is_equal_approx(scene.aim.power, 10.0), "Dragging the selector marks the bar without changing power")
	hud.set_selector_from_screen(5000.0)
	check(hud.selector_x == 240.0, "Selector is clamped to the bar like the original")
	var expected_angle: int = hud.hud_angle(scene.model, scene.aim.angle, scene.aim.weapon)
	key(scene, KEY_SPACE, false)
	check(scene.model.phase == "flight", "Releasing Space fires")
	check(is_equal_approx(hud.previous_power, 10.0) and hud.previous_angle == expected_angle, "Previous shot marker and LAST angle record the shot")
	var shot_before: Dictionary = scene.model.last_shots[0].duplicate()
	var shells_before: int = scene.model.projectiles.size()
	key(scene, KEY_SPACE, false)
	check(scene.model.last_shots[0] == shot_before and scene.model.projectiles.size() == shells_before, "A second release cannot fire again")

	# Pause cancels a charge without firing.
	scene.opening = 0
	scene.start_match()
	player_turn(scene)
	key(scene, KEY_SPACE, true)
	scene._process(0.1)
	scene.show_pause()
	check(not scene.aim.charging and scene.model.phase == "aim", "Pause cancels the charge without firing")
	scene.close_overlay()

	# REQ-29 crosshair keys: one whole degree per press, accelerating repeat.
	scene.aim.angle = 30.0
	var up := InputEventKey.new()
	up.physical_keycode = KEY_UP
	up.pressed = true
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	scene.update_aim_keys(0.01)
	check(scene.aim.angle == 31.0, "Pressing ↑ changes the aim by exactly one degree")
	scene.update_aim_keys(0.1)
	check(scene.aim.angle == 31.0, "No repeat before 0.15 s")
	var steps := 0
	for frame in range(40):
		var previous: float = scene.aim.angle
		scene.update_aim_keys(0.02)
		if scene.aim.angle != previous:
			steps += 1
	check(steps >= 6 and scene.aim.aim_limit < 0.15 and fmod(scene.aim.angle, 1.0) == 0.0, "Holding ↑ repeats faster in whole degrees")
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	scene.update_aim_keys(0.01)
	check(scene.aim.aim_direction == 0, "Releasing ↑ stops the repeat")
	var limits: Vector2 = scene.model.aim_limits(0, scene.aim.weapon)
	scene.aim.angle = limits.y
	scene.step_angle(1)
	check(scene.aim.angle == limits.y, "Aim stays inside the legal range")
	check(hud.crosshair_name(scene.model, 0, 1) == "CrosshairBigfootS2Ally.png" and hud.crosshair_name(scene.model, 1, 0) == "CrosshairMageS1Enemy.png", "Crosshair range sprite per mobile, shot and side (CPU is the other mobile)")
	scene.model.events.append({"type": "turn", "actor": 0})
	scene.consume_events()
	check(hud.crosshair_age == 0.0, "Each player turn replays the crosshair intro")
	var direction: Vector2 = scene.model.shot_velocity(0, scene.aim.angle, 100.0, scene.aim.weapon).normalized()
	check(hud.hud_angle(scene.model, scene.aim.angle, scene.aim.weapon) == roundi(rad_to_deg(atan2(-direction.y, absf(direction.x)))), "HUD angle is the real shot direction over the horizon")

	# F8 passes the turn.
	player_turn(scene)
	key(scene, KEY_F8, true)
	check(scene.model.active == 1 or scene.model.phase != "aim", "F8 passes the turn")

	# REQ-31 PopupGameOptions: Options/ESC open it; SFX, scroll and background apply.
	var Popup = load("res://scripts/options_popup.gd")
	var options_file: String = scene.options.path
	check(options_file == "res://.tools/hud-test-profile-options.json", "Options file sits next to the isolated test profile")
	player_turn(scene)
	key(scene, KEY_SPACE, true)
	scene._process(0.1)
	scene.options_button.pressed.emit()
	var popup = scene.overlays.options_popup
	check(scene.overlays.kind == "options" and popup != null and scene.paused, "Options opens the original options popup and pauses the training")
	check(not scene.aim.charging and scene.model.phase == "aim", "Opening the options cancels the charge without firing")
	check(scene.options_button.disabled, "Options stays disabled while its popup is open (HUD.cs)")
	check(popup.size.is_equal_approx(Vector2(323, 328) * 1.6) and (popup.position + popup.size * 0.5).distance_to(Vector2(640, 400)) <= 0.6, "Popup background 323×328 × 1.6 centred on the screen")
	for name in popup.textures:
		check(is_equal_approx(popup.density(name), 3.0), "Popup %s uses the 3× HD sprite" % name)
	check(popup.scaled("OptionsRadioButton.png", Rect2(12, 0, 11, 12)) == Rect2(36, 0, 33, 36), "Radio frames scale with the HD density")
	var fallback = Popup.new(scene.options)
	fallback.textures = fallback.originals.duplicate()
	check(fallback.density("OptionsBackground.png") == 1.0 and fallback.scaled("PopupAccept.png", Rect2(20, 0, 20, 25)) == Rect2(20, 0, 20, 25), "Without HD the popup falls back to the original pixels")
	fallback.free()
	var accept: TextureButton = popup.accept_button
	check(accept.size.is_equal_approx(Vector2(20, 25) * 1.6) and (accept.position + accept.size * 0.5).is_equal_approx(popup.point(Vector2(130, 144))), "Accept sits at the original (130, 144)")
	var sfx_area: Rect2 = popup.slider_rect("sfx")
	check(sfx_area.size.is_equal_approx(Vector2(145, 20) * 1.6) and sfx_area.get_center().is_equal_approx(popup.point(Vector2(60, 7))), "SFX slider area 145×20 at (60, 7)")
	popup.pointer_down(Vector2(sfx_area.position.x + 2.0, sfx_area.get_center().y))
	popup.pointer_up()
	check(scene.options.sfx == 0 and scene.sound.volume == 0.0, "Dragging SFX to the start silences the effects")
	popup.set_slider_from_local("sfx", popup.point(Vector2(60, 7)).x)
	check(scene.options.sfx == 50 and is_equal_approx(scene.sound.volume, 0.5), "SFX at the middle halves the effects volume")
	check(is_equal_approx(scene.sound.players[0].volume_db, -19.0 + linear_to_db(0.5)), "SFX scales the −19 dB players linearly")
	popup.pointer_down(popup.slider_rect("mouse").get_center() + Vector2(60, 0))
	popup.pointer_up()
	check(popup.value_of("mouse") == 50 and popup.value_of("interface") == 1, "Mouse speed and interface keep the original defaults, disabled")
	check(popup.value_of("aiming") == 1, "Aiming Mode starts on Slice like the original AimType")
	# REQ-33 BGM: the slider drives the battle music volume.
	check(scene.sound.music_wanted and not scene.sound.music.playing, "The battle wants music, but muted tests never play it")
	popup.pointer_down(Vector2(popup.slider_rect("bgm").position.x + 2.0, popup.slider_rect("bgm").get_center().y))
	popup.pointer_up()
	check(scene.options.bgm == 0 and scene.sound.music_volume == 0.0, "BGM at the start silences the music")
	popup.set_slider_from_local("bgm", popup.point(Vector2(60, -13)).x)
	check(scene.options.bgm == 50 and is_equal_approx(scene.sound.music.volume_db, -19.0 + linear_to_db(0.5)), "BGM at the middle sets half the music volume")
	popup.pointer_down(popup.radio_rect("background", 1).get_center())
	popup.pointer_up()
	check(not scene.options.background, "Background radio Off turns the map backdrop off")
	popup.set_slider_from_local("scroll", popup.slider_rect("scroll").end.x + 50.0)
	check(scene.options.scroll == 100 and is_equal_approx(scene.options.scroll_factor(), 2.0), "Scroll speed 100 doubles the drag")
	var start_pos: Vector2 = popup.position
	popup.pointer_down(Vector2(80, 10))
	popup.pointer_move(Vector2(130, 30))
	popup.pointer_up()
	check(popup.position == start_pos + Vector2(50, 20), "The title bar drags the popup")
	popup.pointer_down(Vector2(80, 10))
	popup.pointer_move(Vector2(5000, -5000))
	popup.pointer_up()
	check(popup.position.x == roundf(1280.0 - popup.size.x) and popup.position.y == 0.0 and popup.position.x + popup.size.x <= 1280.0, "The dragged popup stays on the screen")
	key(scene, KEY_ESCAPE, true)
	check(scene.overlays.layer == null and not scene.paused and not scene.options_button.disabled, "ESC accepts and closes the popup, re-enabling Options")
	var saved = load("res://scripts/options.gd").new(options_file)
	saved.load_options()
	check(saved.sfx == 50 and saved.bgm == 50 and saved.scroll == 100 and not saved.background, "Accept saves the options next to the profile")
	# Scroll speed scales the manual camera drag; 50 keeps the original 1×.
	scene.rig.position = Vector2(100, 100)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(640, 300)
	scene._unhandled_input(press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.relative = Vector2(-10, -5)
	scene._unhandled_input(motion)
	check(scene.rig.position.is_equal_approx(Vector2(120, 110)), "Scroll speed 100 moves the camera twice the drag")
	scene.options.scroll = 50
	scene._unhandled_input(motion)
	check(scene.rig.position.is_equal_approx(Vector2(130, 115)), "Scroll speed 50 keeps the 1:1 drag")
	press.pressed = false
	scene._unhandled_input(press)
	# The pause stays reachable: P from the match, P or "PAUSA" from the popup.
	key(scene, KEY_ESCAPE, true)
	check(scene.overlays.kind == "options", "ESC opens the options popup")
	scene.overlays.options_popup.set_slider_from_local("sfx", scene.overlays.options_popup.slider_rect("sfx").position.x)
	key(scene, KEY_P, true)
	check(scene.overlays.kind == "pause" and not scene.options_button.disabled, "P opens the pause from the popup")
	saved.load_options()
	check(saved.sfx == 0, "Leaving the popup for the pause keeps its values like Accept")
	key(scene, KEY_ESCAPE, true)
	check(scene.overlays.layer == null, "ESC closes the pause")
	key(scene, KEY_P, true)
	check(scene.overlays.kind == "pause", "P opens the pause during the match")
	scene.close_overlay()
	scene.show_options()
	var pause_button: Button = null
	for child in scene.overlays.options_popup.get_children():
		if child is Button and child.text == "PAUSA":
			pause_button = child
	check(pause_button != null and Rect2(Vector2.ZERO, scene.overlays.options_popup.size).encloses(Rect2(pause_button.position, pause_button.size)), "Discreet PAUSA extra sits inside the popup")
	pause_button.pressed.emit()
	check(scene.overlays.kind == "pause", "PAUSA opens the pause menu")
	scene.close_overlay()
	# Real mouse clicks routed by the viewport reach the slider and Accept.
	scene.show_options()
	var sfx_point: Vector2 = scene.overlays.options_popup.global_position + scene.overlays.options_popup.slider_rect("sfx").get_center()
	click(sfx_point + Vector2(40, 0))
	check(scene.options.sfx > 50 and scene.options.sfx < 80, "A real click on the SFX bar sets the volume (%d)" % scene.options.sfx)
	var accept_point: Vector2 = scene.overlays.options_popup.accept_button.global_position + scene.overlays.options_popup.accept_button.size * 0.5
	click(accept_point)
	check(scene.overlays.layer == null, "A real click on Accept closes the popup")
	scene.options.sfx = 100
	scene.options.background = true
	scene.apply_options()
	check(scene.sound.volume == 1.0, "SFX 100 restores the original effects volume")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(options_file))
	check(Popup.ENABLED == ["aiming", "scroll", "sfx", "bgm", "background"], "Aiming, scroll, SFX, BGM and background are live; mouse speed and skin stay disabled")
	for track in scene.sound.BATTLE_MUSIC:
		var stream = load("res://assets/openbound/music/%s.mp3" % track)
		check(stream is AudioStreamMP3 and not stream.loop, "%s is an original LevelScene theme that ends (then a random one follows)" % track)
	scene.show_menu()
	check(not scene.sound.music_wanted, "The menu stops the battle music")
	scene.opening = 0
	scene.start_match()
	player_turn(scene)

	# REQ-30 timer, damage counter, life bar, compass, weather roulette.
	scene.model.phase = "aim"
	scene.model.turn_time = 30.0
	check(hud.display_seconds(scene.model) == 30, "Turn timer starts at 30")
	scene.model.turn_time = 12.3
	check(hud.display_seconds(scene.model) == 13, "Timer shows the HUD.cs rounding (time + 0.9)")
	hud.floats.clear()
	hud.add_damage(1, 100, scene.model)
	hud.add_damage(1, 50, scene.model)
	check(hud.floats.size() == 1 and hud.floats[0].target == -150.0, "Hits on one actor accumulate in one floating counter")
	for frame in range(25):
		hud.tick(0.05, scene.model, null)
	check(hud.floats[0].value == -150.0, "Counter reaches the total in 20 steps of 0.05 s")
	for frame in range(60):
		hud.tick(0.05, scene.model, null)
	check(hud.floats.is_empty(), "Floating damage expires after 3 s")
	var actor: Dictionary = {"hp": 300, "max_hp": 1000, "shield": 0, "max_shield": 0}
	check(HudArt.health_segments(actor) == Vector2(22, 0), "Life bar fills floor(76 × hp / total)")
	scene.model.weather.wind_force = 30
	scene.model.weather.wind_angle = 90
	for frame in range(80):
		hud.tick(0.05, scene.model, null)
	check(is_equal_approx(wrapf(hud.compass_rotation - PI * 0.5, -PI, PI), 0.0), "Compass turns to the wind angle")
	check(is_equal_approx(hud.yellow_alpha, 1.0 - 12.5 / 17.5) and is_equal_approx(hud.red_alpha, 12.5 / 17.5), "Strong wind fades the yellow arrow into the red one")
	hud.weather_shown = ["force", "tornado", "wind", "random"]
	scene.model.weather.queue = [{"type": "tornado"}, {"type": "wind"}, {"type": "random"}, {"type": "mirror"}]
	hud.sync_weather(scene.model)
	check(hud.weather_previous == "force" and hud.weather_slide == 24.0 and hud.weather_shown[0] == "tornado", "Weather roulette slides one 24 px slot when a round ends")

	# Pause freezes HUD animations because game.gd stops ticking.
	hud.add_damage(0, 10, scene.model)
	scene.show_pause()
	var age: float = hud.floats[0].age
	scene._process(0.5)
	check(hud.floats[0].age == age, "Pause freezes the HUD animations")
	scene.close_overlay()

	# The original range wedges cover exactly the legal aim of every shot.
	var Match = load("res://scripts/match.gd")
	for vehicle in [1, 2, 3]:
		var aim_model = Match.new()
		aim_model.start(vehicle, 1, 4)
		for shot in range(3):
			var wedge: String = hud.crosshair_name(aim_model, 0, shot)
			var image: Image = hud.originals[wedge].get_image()
			if image.is_compressed():
				image.decompress()
			var legal: Vector2 = aim_model.aim_limits(0, shot)
			var inside := true
			for aim in [legal.x, (legal.x + legal.y) * 0.5, legal.y]:
				var world: Vector2 = aim_model.shot_velocity(0, aim, 100.0, shot).normalized().rotated(-aim_model.body_rotation(0))
				var local := Vector2(-world.x, world.y) if aim_model.actors[0].facing == 1 else world
				var hit := false
				for radius in range(28, 41):
					var point := Vector2(41.5, 41.5) + local * radius
					hit = hit or image.get_pixelv(point).a > 0.1
				inside = inside and hit
			check(inside, "%s covers the legal aim %s at both ends" % [wedge, legal])

	# Delayboard data never invents a CPU weapon before the CPU chooses.
	scene.opening = 0
	scene.start_match()
	player_turn(scene)
	scene.update_hud()
	check(scene.displayed_queue().size() == 2, "Delayboard lists both players")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/hud-test-profile.json"))
	report("HUD CHECKS")
	scene.queue_free()
	quit(exit_code())
