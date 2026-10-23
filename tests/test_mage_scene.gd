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
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/mage-scene-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.select_vehicle(1)
	scene.opening = 0
	scene.start_match()
	check(scene.model.aim_limits(0, scene.weapon) == Vector2(15, 50) and scene.hud.crosshair_name(scene.model, 0, 0) == "CrosshairMageS1Ally.png", "Mage HUD uses legal aim range and Mage crosshair")
	check(scene.weapon_buttons[0].tooltip_text.begins_with("Laser"), "HUD uses Mage weapon names")
	var full: Vector2 = scene.hud.health_segments(scene.model.actors[0])
	check(full.y > 0.0 and full.x + full.y == 76.0, "Mage shield is visible in the original life bar")
	check(scene.actor_frame(0) < 20, "Mage idle uses Mage atlas")
	scene.select_weapon(1)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	scene._unhandled_key_input(key)
	scene._process(0.1)
	check(scene.actor_frame(0) == 303, "Mage charges second shot with original frame")
	scene.show_pause()
	var age: float = scene.art.motion[0].pose_age
	scene._process(0.5)
	check(scene.art.motion[0].pose_age == age, "Pause freezes Mage animation")
	scene.close_overlay()
	scene.opening = 0
	scene.start_match()
	scene.model.shot_actor = 1
	scene.model.shot_weapon = 0
	scene.model.explode(load("res://scripts/combat.gd").full_hit(scene.model.actors[0], 25.0))
	scene.consume_events()
	scene.update_hud()
	check(scene.animation_state(0) == "hurt", "Shield impact animates Mage hurt pose")
	check(scene.model.actors[0].shield == 130 and scene.hud.health_segments(scene.model.actors[0]).y < full.y, "HUD life bar shrinks the shield after real impact")
	scene.opening = 0
	scene.start_match()
	check(scene.model.actors[0].shield == 220 and scene.effects.is_empty(), "Restart resets shield and effects")
	scene.select_weapon(1)
	scene.shoot()
	scene.consume_events()
	check(scene.actor_frame(0) == 100, "Mage firing uses its original atlas")
	scene.art.tick(scene.model, 0.2)
	scene.model.projectiles.clear()
	scene.model.schedule(0, 120)
	scene.consume_events()
	check(scene.actor_frame(0) >= 100 and scene.actor_frame(0) <= 119, "Turn change preserves Mage recoil")
	scene.opening = 0
	scene.start_match()
	scene.model.actors[0].hp = 0
	scene.model.check_end()
	scene.consume_events()
	for frame in range(13):
		scene._process(0.1)
	check(scene.overlay == null, "Full Mage death animation precedes result")
	scene.select_vehicle(2)
	scene.opening = 0
	scene.start_match()
	scene.model.active = 1
	scene.model.begin_turn()
	scene.consume_events()
	scene.cpu_plan = {"weapon": 1, "angle": 40, "power": 65}
	scene._process(0.1)
	check(scene.animation_state(1) == "charging", "CPU exposes its actual Mage charge pose")
	check(scene.actor_frame(1) == 303, "CPU charge selects original Mage S2 frames")
	scene.model.fire(40, 65, 1)
	scene.cpu_plan.clear()
	scene.consume_events()
	scene._process(0.1)
	var shells: Array = scene.model.projectiles.duplicate(true)
	scene.show_pause()
	scene._process(0.5)
	check(scene.model.projectiles == shells, "Pause freezes both helix colliders and trails")
	scene.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/mage-scene-profile.json"))
	print("MAGE SCENE CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
