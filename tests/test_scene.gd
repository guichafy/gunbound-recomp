extends "res://tests/support/suite.gd"


func tree_has_buddy(node: Node) -> bool:
	var blob := node.name.to_lower()
	if node is Button:
		blob += " " + node.text.to_lower()
	if blob.contains("buddy"):
		return true
	for child in node.get_children():
		if tree_has_buddy(child):
			return true
	return false

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
	check(scene.screen == "lobby" and scene.lobby != null and scene.lobby.create_button != null, "Entry opens the classic lobby")
	check(not tree_has_buddy(scene.root), "Lobby has no Buddy button")
	check(scene.root.find_child("Join", true, false).disabled and scene.root.find_child("Ranking", true, false).disabled, "Join and ranking stay disabled without network rooms")
	scene.lobby.create_button.pressed.emit()
	check(scene.screen == "menu" and scene.menu.nickname_input != null and not tree_has_buddy(scene.root), "Create opens the 1×1 room without a Buddy button")
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
	scene.menu.choose_player_side()
	scene.menu.pick_vehicle(1)
	for button in scene.menu.grid_buttons:
		if int(button.get_meta("vehicle_id")) == 1:
			button.pressed.emit()
	check(scene.vehicle == 1 and not scene.menu.popup_open() and scene.menu.portrait_name.text == "Mage" and scene.menu.choice_label.text == "Escolhendo: piloto", "O clique na grade aplica o Mage no piloto, sem popup")
	scene.select_vehicle(2)
	check(scene.opening == -1, "Real matches draw who opens (ADR-076)")
	scene.opening = 0
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	var shows_version := false
	for node in scene.root.get_children():
		shows_version = shows_version or (node is Label and node.text.ends_with("/   " + version))
	check(not version.is_empty() and shows_version, "Menu shows the single-source project version")
	check(scene.cpu_vehicle < 0 and scene.resolved_cpu_id() == 1, "Until a pick, Bigfoot still trains against Mage")
	scene.menu.choose_cpu_side()
	scene.menu.pick_vehicle(4)
	for button in scene.menu.grid_buttons:
		if int(button.get_meta("vehicle_id")) == 4:
			button.pressed.emit()
	check(scene.cpu_vehicle == 4 and scene.vehicle == 2 and not scene.menu.popup_open() and scene.menu.cpu_mobile.text == "Armor" and scene.menu.choice_label.text == "Escolhendo: máquina", "O clique na grade aplica o Armor na CPU, sem popup")
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
	check(scene.hud.textures["ActionBar.png"].resource_path == "res://assets/xfs/hud/ActionBar.png" and scene.hud.textures["ActionBar.png"].get_width() == 800, "Action bar uses client pixels in the preserved 800 px layout")
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
