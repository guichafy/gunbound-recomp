extends SceneTree
## REQ-27..30: original OpenBound battle HUD (layout, buttons, strength bar,
## keyboard, crosshair, compass, timer, Delayboard, life bar, damage counter).

var failures := 0
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func key(scene, code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	scene._unhandled_key_input(event)

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
		check(is_equal_approx(factor, 3.0), "%s uses the 3× HD sprite" % name)
	scene.select_vehicle(2)
	scene.start_match()
	player_turn(scene)
	var s1: TextureButton = scene.weapon_buttons[0]
	check(s1.size.is_equal_approx(Vector2(37, 37) * 1.6) and (s1.position + s1.size * 0.5).is_equal_approx(HudArt.bar_point(Vector2(-371, -4))), "S1 button sits at the original (−371, −4)")
	check((scene.weapon_buttons[2].position + scene.weapon_buttons[2].size * 0.5).is_equal_approx(HudArt.bar_point(Vector2(-285, -4))), "SS button sits at the original (−285, −4)")
	check((scene.pass_button.position + scene.pass_button.size * 0.5).is_equal_approx(HudArt.bar_point(Vector2(-296, 26))), "SkipTurn button sits at the original (−296, 26)")
	check(s1.get_meta("activated") and not scene.weapon_buttons[1].get_meta("activated"), "S1 starts activated like HUD.cs")
	check(scene.weapon_buttons[2].disabled, "SS stays disabled until the special is unlocked")

	# Tab cycles the shots and skips a disabled SS (ShotButton.UpdateKeyboard).
	key(scene, KEY_TAB, true)
	check(scene.weapon == 1 and scene.weapon_buttons[1].get_meta("activated"), "Tab selects S2")
	key(scene, KEY_TAB, true)
	check(scene.weapon == 0, "Tab skips the locked SS back to S1")
	scene.model.actors[0].turns = 3
	scene.update_hud()
	key(scene, KEY_TAB, true)
	key(scene, KEY_TAB, true)
	check(scene.weapon == 2 and not scene.weapon_buttons[2].disabled, "Unlocked SS joins the Tab cycle")
	scene.select_weapon(0)

	# REQ-28 strength bar: starts empty, +2 every 0.04 s, release fires once.
	check(scene.power == 0.0, "Strength bar starts the player turn empty")
	key(scene, KEY_SPACE, true)
	scene._process(0.1)
	scene._process(0.1)
	check(scene.charging and is_equal_approx(scene.power, 10.0), "0.2 s of charge = 5 steps of 2")
	hud.set_selector_from_screen(HudArt.bar_point(Vector2(100, 17)).x)
	check(is_equal_approx(hud.selector_x, 100.0) and is_equal_approx(scene.power, 10.0), "Dragging the selector marks the bar without changing power")
	hud.set_selector_from_screen(5000.0)
	check(hud.selector_x == 240.0, "Selector is clamped to the bar like the original")
	var expected_angle: int = hud.hud_angle(scene.model, scene.angle, scene.weapon)
	key(scene, KEY_SPACE, false)
	check(scene.model.phase == "flight", "Releasing Space fires")
	check(is_equal_approx(hud.previous_power, 10.0) and hud.previous_angle == expected_angle, "Previous shot marker and LAST angle record the shot")
	key(scene, KEY_SPACE, false)
	check(scene.model.projectiles.size() <= 1 or scene.model.shot_weapon == 0, "A second release cannot fire again")

	# Pause cancels a charge without firing.
	scene.start_match()
	player_turn(scene)
	key(scene, KEY_SPACE, true)
	scene._process(0.1)
	scene.show_pause()
	check(not scene.charging and scene.model.phase == "aim", "Pause cancels the charge without firing")
	scene.close_overlay()

	# REQ-29 crosshair keys: one whole degree per press, accelerating repeat.
	scene.angle = 30.0
	var up := InputEventKey.new()
	up.physical_keycode = KEY_UP
	up.pressed = true
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	scene.update_aim_keys(0.01)
	check(scene.angle == 31.0, "Pressing ↑ changes the aim by exactly one degree")
	scene.update_aim_keys(0.1)
	check(scene.angle == 31.0, "No repeat before 0.15 s")
	var steps := 0
	for frame in range(40):
		var previous: float = scene.angle
		scene.update_aim_keys(0.02)
		if scene.angle != previous:
			steps += 1
	check(steps >= 6 and scene.aim_limit < 0.15 and fmod(scene.angle, 1.0) == 0.0, "Holding ↑ repeats faster in whole degrees")
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	scene.update_aim_keys(0.01)
	check(scene.aim_direction == 0, "Releasing ↑ stops the repeat")
	var limits: Vector2 = scene.model.aim_limits(0, scene.weapon)
	scene.angle = limits.y
	scene.step_angle(1)
	check(scene.angle == limits.y, "Aim stays inside the legal range")
	check(hud.crosshair_name(scene.model, 0, 1) == "CrosshairBigfootS2Ally.png" and hud.crosshair_name(scene.model, 1, 0) == "CrosshairMageS1Enemy.png", "Crosshair range sprite per mobile, shot and side (CPU is the other mobile)")
	scene.model.events.append({"type": "turn", "actor": 0})
	scene.consume_events()
	check(hud.crosshair_age == 0.0, "Each player turn replays the crosshair intro")
	var direction: Vector2 = scene.model.shot_velocity(0, scene.angle, 100.0, scene.weapon).normalized()
	check(hud.hud_angle(scene.model, scene.angle, scene.weapon) == roundi(rad_to_deg(atan2(-direction.y, absf(direction.x)))), "HUD angle is the real shot direction over the horizon")

	# F8 passes; the Options button opens the pause menu.
	player_turn(scene)
	key(scene, KEY_F8, true)
	check(scene.model.active == 1 or scene.model.phase != "aim", "F8 passes the turn")
	scene.options_button.pressed.emit()
	check(scene.overlay_kind == "pause", "Options (ESC) opens the pause menu")
	scene.close_overlay()

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

	# Delayboard data never invents a CPU weapon before the CPU chooses.
	scene.start_match()
	player_turn(scene)
	scene.update_hud()
	check(scene.displayed_queue().size() == 2, "Delayboard lists both players")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/hud-test-profile.json"))
	print("HUD CHECKS: ", checks, " | FAILURES: ", failures)
	scene.queue_free()
	quit(1 if failures > 0 else 0)
