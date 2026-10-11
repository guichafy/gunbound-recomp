extends SceneTree

var failures := 0
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

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
	check(scene.screen == "menu" and scene.nickname_input != null, "Menu shows nickname and vehicle controls")
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
	scene.angle = 45.0
	scene.power = 70.0
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	scene._unhandled_key_input(space)
	scene._process(0.1)
	check(scene.charging and is_equal_approx(scene.power, 4.0), "Holding Space charges from 0 in steps of 2 every 0.04 s (original)")
	space.pressed = false
	scene._unhandled_key_input(space)
	check(scene.model.phase == "flight", "HUD fire command launches a real projectile")
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
	check(scene.overlay_kind == "result", "Closing help after match restores result actions")
	scene.show_menu()
	check(scene.screen == "menu" and scene.model.phase == "menu", "Return to menu leaves combat inactive")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/smoke-profile.json"))
	print("SCENE CHECKS: ", checks, " | FAILURES: ", failures)
	scene.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
