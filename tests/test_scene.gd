extends "res://tests/support/suite.gd"


func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/smoke-profile.json")
	root.add_child(scene)
	if scene.get("sound") != null:
		scene.sound.muted = true
	check(scene.has_method("start_match"), "Main scene compiles and exposes playable match")
	if not scene.has_method("start_match"):
		quit(1)
		return
	check(scene.screen == "menu" and scene.menu.nickname_input != null, "Menu shows nickname and vehicle controls")
	var saved_name: String = scene.menu.nickname_input.text
	scene.menu.open_settings()
	scene.menu.nickname_input.text = "Sala Temp"
	scene.menu.choose_difficulty(0)
	scene.menu.choose_weather("all")
	scene.menu.cancel_popup()
	check(not scene.menu.popup_open() and scene.menu.nickname_input.text == saved_name and scene.cpu_difficulty == 1 and scene.weather_mode == "original", "Cancelar devolve apelido, dificuldade e clima sem iniciar")
	scene.menu.open_settings()
	scene.menu.choose_difficulty(2)
	scene.menu.choose_weather("all")
	scene.menu.accept_settings()
	check(scene.screen == "menu" and scene.cpu_difficulty == 2 and scene.weather_mode == "all" and scene.menu.weather_caption.text.begins_with("Clima:"), "Aceitar grava dificuldade e clima e permanece na sala")
	scene.cpu_difficulty = 1
	scene.weather_mode = "original"
	scene.menu.open_mobile()
	scene.menu.pick_vehicle(1)
	check(scene.vehicle == 1 and not scene.menu.popup_open() and scene.menu.portrait_name.text == "Mage", "Mobile aplica na hora e fecha o popup")
	scene.select_vehicle(2)
	check(scene.opening == -1, "Real matches draw who opens (ADR-076)")
	scene.opening = 0
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	var shows_version := false
	for node in scene.root.get_children():
		shows_version = shows_version or (node is Label and node.text.ends_with("/   " + version))
	check(not version.is_empty() and shows_version, "Menu shows the single-source project version")
	check(scene.cpu_vehicle < 0 and scene.resolved_cpu_id() == 1, "Until a pick, Bigfoot still trains against Mage")
	scene.menu.open_cpu_mobile()
	scene.menu.pick_vehicle(4)
	check(scene.cpu_vehicle == 4 and not scene.menu.popup_open() and scene.menu.cpu_mobile.text == "Armor", "CPU mobile applies on click and closes the popup")
	scene.opening = 0
	scene.start_match()
	check(int(scene.model.actors[1].vehicle) == 4 and int(scene.model.actors[0].vehicle) == 2, "The match drives the mobile chosen for the machine")
	scene.show_menu()
	scene.cpu_vehicle = -1
	scene.select_vehicle(2)
	scene.opening = 0
	scene.start_match()
	check(scene.model.phase == "aim" and scene.fire_button != null, "Starting opens combat HUD")
	check(scene.weapon_buttons.size() == 3 and scene.pass_button is TextureButton and scene.options_button is TextureButton, "Original S1/S2/SS, Options and SkipTurn sprite buttons")
	check(scene.hud.textures["ActionBar.png"].get_width() == 2400 and scene.hud.originals["ActionBar.png"].get_width() == 800, "Action bar uses the 3× HD remaster of the original 800 px bar")
	scene.show_pause()
	var before: float = scene.model.turn_time
	scene._process(1.0)
	check(is_equal_approx(before, scene.model.turn_time), "Pause freezes the actual turn clock")
	scene.close_overlay()
	scene._process(0.1)
	check(scene.model.turn_time < before, "Resuming restores turn clock")
	scene.aim.angle = 45.0
	scene.aim.power = 70.0
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	scene._unhandled_key_input(space)
	scene._process(0.1)
	check(scene.aim.charging and is_equal_approx(scene.aim.power, 100.0 / 30.0), "Holding Space charges continuously:0.1s of3s is3.333percent (ADR-084)")
	space.pressed = false
	scene._unhandled_key_input(space)
	check(scene.model.phase == "flight", "HUD fire command launches a real projectile")
	scene.opening = 0
	scene.start_match()
	check(scene.model.phase == "aim" and scene.model.projectiles.is_empty(), "Restart clears in-flight projectile and resets turn")
	scene.model.actors[1].hp = 0
	scene.model.check_end()
	scene.consume_events()
	check(scene.profile.xp == 120, "Scene awards victory XP")
	scene.show_result()
	scene.show_result()
	check(scene.profile.xp == 120, "Reopening result cannot duplicate reward")
	scene.show_help()
	scene.close_overlay()
	check(scene.overlays.kind == "result", "Closing help after match restores result actions")
	scene.show_menu()
	check(scene.screen == "menu" and scene.model.phase == "menu", "Return to menu leaves combat inactive")
	# ADR-076: the opening is drawn in play, so the CPU may own the very first turn.
	scene.opening = 1
	scene.start_match()
	check(scene.model.active == 1 and scene.model.phase == "aim", "CPU can open the match")
	var cpu_fired := false
	for _frame in range(600):
		scene._process(0.05)
		await process_frame
		while scene.cpu.task >= 0 and not WorkerThreadPool.is_task_completed(scene.cpu.task):
			await create_timer(0.005).timeout
		if scene.model.phase == "flight" and scene.model.shot_actor == 1:
			cpu_fired = true
			break
	check(cpu_fired, "The CPU plans and fires on the opening turn")
	scene.show_menu()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/smoke-profile.json"))
	report("SCENE CHECKS")
	scene.queue_free()
	await process_frame
	await process_frame
	quit(exit_code())
