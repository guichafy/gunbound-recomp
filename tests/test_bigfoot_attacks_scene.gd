extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/bigfoot-attacks-scene-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.select_vehicle(2)
	view.start_match()
	check(view.angle <= 40 and view.model.aim_limits(0, view.weapon) == Vector2(18, 40) and view.hud.crosshair_name(view.model, 0, view.weapon) == "CrosshairBigfootS1Ally.png", "Bigfoot starts with legal T1 aim and its original range sprite")
	view.model.actors[0].turns = 3
	view.angle = 18
	view.select_weapon(2)
	view.update_hud()
	check(view.angle == 23 and view.model.aim_limits(0, view.weapon) == Vector2(23, 35) and view.hud.crosshair_name(view.model, 0, view.weapon) == "CrosshairBigfootSSAlly.png", "Selecting SS adjusts value, legal range and crosshair sprite")
	view.select_weapon(0)
	view.update_hud()
	check(view.model.aim_limits(0, view.weapon) == Vector2(18, 40) and view.weapon_buttons[0].get_meta("activated"), "Returning to T1 restores its wider aim range and active S1 button")
	view.start_match()
	view.select_weapon(1)
	view.shoot()
	view.consume_events()
	view._process(0.1)
	var shells: Array = view.model.projectiles.duplicate(true)
	var time: float = view.model.flight_elapsed
	view.show_pause()
	view._process(0.5)
	check(view.model.projectiles == shells and view.model.flight_elapsed == time, "Pause freezes pending and launched bombs")
	view.close_overlay()
	view._process(0.1)
	var launched := 0
	for bomb in view.model.projectiles:
		if bomb.launched:
			launched += 1
	check(launched == 3, "Continuing releases first T2 burst at its original time")
	view.start_match()
	check(view.model.projectiles.is_empty() and view.effects.is_empty() and view.model.flight_elapsed == 0, "Restart clears pending salvo and effects")
	check(view.bigfoot.get("shoot_sounds") != null and view.bigfoot.get("effects") != null, "Bigfoot original audio and explosions loaded")
	if view.bigfoot.get("shoot_sounds") != null:
		for stream in view.bigfoot.shoot_sounds + view.bigfoot.blast_sounds:
			check(stream != null and stream.get_length() > 0, "Original Bigfoot sound is playable")
	view.model.actors[0].turns = 3
	view.select_weapon(2)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	view._unhandled_key_input(key)
	# Original strength bar: 50 steps of 0.04 s = 2 s to fill.
	for frame in range(22):
		view._process(0.1)
	var count: int = view.model.projectiles.size()
	key.pressed = false
	view._unhandled_key_input(key)
	check(count == 8 and view.model.projectiles.size() == count, "Full charge and late release launch only one SS salvo")
	view.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/bigfoot-attacks-scene-profile.json"))
	print("BIGFOOT ATTACK SCENE CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
