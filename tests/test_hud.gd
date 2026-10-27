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
	check(HudArt.bar_point(Vector2.ZERO).is_equal_approx(Vector2(640, 764.8)), "Footer centre follows native44px band at y456")
	check(scene.VIEW_SIZE.is_equal_approx(Vector2(1280,665.6)) and HudArt.Layout.WORLD.end.is_equal_approx(HudArt.Layout.FOOTER.position + Vector2(1280,0)), "World is between native header64 and footer70.4")
	for name in hud.textures:
		var factor: float = hud.density(name)
		check(is_equal_approx(factor, 1.0), "%s uses native pixels or the declared 1x fallback" % name)
		if hud.client_assets.has(name):
			check(hud.textures[name] == hud.client_assets.texture(name), "%s selects the validated client atlas" % name)
		else:
			check(hud.textures[name] == hud.originals[name], "%s retains declared 1x fallback" % name)

	scene.select_vehicle(2)
	scene.opening = 0
	scene.start_match()
	player_turn(scene)
	var s1: TextureButton = scene.weapon_buttons[0]
	check(s1.size.is_equal_approx(Vector2(35, 34) * 1.6) and (s1.position + s1.size * 0.5).is_equal_approx(Vector2(23.5,479)*1.6), "S1 uses native footer6,462")
	check((scene.weapon_buttons[2].position + scene.weapon_buttons[2].size * 0.5).is_equal_approx(Vector2(105.5,479)*1.6), "SS uses native footer88,462")
	check((scene.pass_button.position + scene.pass_button.size * 0.5).is_equal_approx(Vector2(770,18)*1.6), "SkipTurn uses native header750,3")
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

	# REQ-28/ADR-084: continuous 3 s charge, native quantization only at launch.
	check(scene.aim.power == 0.0, "Strength bar starts the player turn empty")
	key(scene, KEY_SPACE, true)
	scene._process(0.1)
	scene._process(0.1)
	check(scene.aim.charging and is_equal_approx(scene.aim.power, 100.0 / 15.0), "0.2 s of the 3 s charge = 6.6667 percent")
	hud.set_selector_from_screen((244+260)*1.6)
	check(is_equal_approx(hud.selector_x, 100.0) and is_equal_approx(scene.aim.power, 100.0 / 15.0), "Dragging the selector marks the bar without changing power")
	hud.set_selector_from_screen(5000.0)
	check(hud.selector_x == 240.0, "Selector is clamped to the bar like the original")
	var expected_angle: int = hud.hud_angle(scene.model, scene.aim.angle, scene.aim.weapon)
	key(scene, KEY_SPACE, false)
	check(scene.model.phase == "flight", "Releasing Space fires")
	check(is_equal_approx(hud.previous_power, 100.0 / 15.0) and hud.previous_angle == expected_angle, "Previous shot marker and LAST angle record the shot")
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

	# ADR-137 owns native menu geometry/input/OK/cancellation/QUIT tests.
	# Here retain integration with existing combat and camera contracts.
	scene.options_button.pressed.emit()
	check(scene.overlays.kind == "options" and scene.paused and not scene.aim.charging, "Native menu cancels charging and freezes offline training")
	scene.options.sfx = 80
	scene.options.bgm = 90
	scene.options.scroll = 70
	scene.apply_options()
	check(is_equal_approx(scene.sound.volume,0.1) and is_equal_approx(scene.sound.music_volume,0.31622776601683794), "Native selections drive SFX and BGM")
	scene.accept_options()
	check(not scene.paused and not scene.options_button.disabled, "OK restores battle input")
	scene.rig.position = Vector2(100,100)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(640,300)
	scene._unhandled_input(press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.relative = Vector2(-10,-5)
	scene._unhandled_input(motion)
	check(scene.rig.position.is_equal_approx(Vector2(100,100)+Vector2(10,5)*pow(2.0,0.4)), "Native scroll70 uses declared Godot camera response")
	press.pressed = false
	scene._unhandled_input(press)
	scene.options.sfx = 100
	scene.options.background = true
	scene.apply_options()
	var options_file: String = scene.options.path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(options_file))
	for track in scene.sound.BATTLE_MUSIC:
		var stream = scene.sound.music_stream(track)
		check(stream is AudioStreamMP3 and not stream.loop, "%s is an original client stage theme that ends (then a random one follows)" % track)
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
	scene.model.weather.wind_force = 26
	scene.model.weather.wind_angle = 90
	for frame in range(80):
		hud.tick(0.05, scene.model, null)
	check(is_equal_approx(wrapf(hud.compass_rotation + PI * 0.5, -PI, PI), 0.0), "Compass turns to the wind angle")
	check(is_equal_approx(hud.yellow_alpha, 0.0) and is_equal_approx(hud.red_alpha, 1.0), "Strong wind fades the yellow arrow into the red one")
	for cardinal in [0,90,180,270]:
		scene.model.weather.wind_angle = cardinal
		for _frame in 80:
			hud.tick(0.05,scene.model,null)
		check(Vector2.from_angle(hud.compass_rotation).dot(scene.model.weather.wind_vector().normalized()) > 0.99999,"Compass agrees with physical wind cardinal" + str(cardinal))
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
					# Native theta and velocity components are truncated, while the
					# original wedge is rasterized: cover the containing pixel's 1px
					# neighbourhood, not a mathematically infinitesimal alpha edge.
					for dx in range(-1,2):
						for dy in range(-1,2):
							hit = hit or image.get_pixelv(point + Vector2(dx,dy)).a > 0.1
				inside = inside and hit
			check(inside, "%s covers the legal aim %s at both ends" % [wedge, legal])

	# Quantization error is bounded independently of the raster coverage test.
	# A linear support fixture checks both facing directions without changing
	# the shared conversion used by muzzle, CPU and HUD.
	var maximum_error := 0.0
	for vehicle in [1,2,3,6]:
		var supported = Match.new()
		supported.start(vehicle,1,4,"")
		for support in [-10.0,0.0,10.0]:
			supported.terrain = AimSlope.new(deg_to_rad(support))
			supported.actors[0].pos = Vector2(640,400-supported.stance_of(0))
			for facing in [-1,1]:
				supported.actors[0].facing = facing
				for shot in range(3):
					var legal: Vector2 = supported.aim_limits(0,shot)
					for aim in [legal.x,(legal.x+legal.y)*0.5,legal.y]:
						var native: Vector2 = supported.shot_velocity(0,aim,100,shot).normalized()
						var ideal := Vector2(cos(deg_to_rad(aim))*facing,-sin(deg_to_rad(aim))).rotated(supported.body_rotation(0))
						var error := absf(rad_to_deg(native.angle_to(ideal)))
						maximum_error = maxf(maximum_error,error)
						check(error <= 1.25,"HUD shared physical aim quantization within1.25deg vehicle" + str(vehicle) + " facing" + str(facing) + " support" + str(support))
	# theta truncation <1deg plus two component truncations <0.24deg
	# at the smallest full-power P350; the 40px raster error remains <1px.
	check(40.0*sin(deg_to_rad(maximum_error)) < 1.0,"Native wedge endpoints differ by less than one raster pixel")
	print("Maximum native aim vs continuous wedge error degrees: ",maximum_error)

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

class AimSlope extends RefCounted:
	var rotation: float
	func _init(value: float) -> void:
		rotation = value
	func surface_at(x: float, _from_y: float = 0.0) -> float:
		return 400.0+tan(rotation)*(x-640.0)
	func is_void(_height: float) -> bool:
		return false
