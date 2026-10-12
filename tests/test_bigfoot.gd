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
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/bigfoot-profile.json")
	root.add_child(scene)
	scene.sound.muted = true
	check(scene.vehicle_buttons.size() == 2, "Menu offers Bigfoot and Mage only")
	check(ResourceLoader.exists("res://scripts/bigfoot_sprite.gd"), "Original atlas animation renderer is available")
	if scene.vehicle_buttons.size() < 2 or not ResourceLoader.exists("res://scripts/bigfoot_sprite.gd"):
		scene.queue_free()
		await process_frame
		quit(1)
		return
	scene.select_vehicle(2)
	scene.start_match()
	check(scene.model.VEHICLES[scene.model.actors[0].vehicle].name == "Bigfoot", "Selection starts match with Bigfoot")
	check(scene.model.actors[1].vehicle == 1, "Bigfoot faces Mage")
	var atlas = load("res://scripts/bigfoot_sprite.gd").new()
	check(atlas.texture.get_size() == Vector2(2580, 3120), "Original atlas loaded with full dimensions")
	check(atlas.frame_index("idle", 0.0, 0, false) == 0, "Idle begins with original first frame")
	check(atlas.frame_index("moving", 0.0, 0, false) == 20, "Moving begins with movement sequence")
	check(atlas.frame_index("charging", 0.0, 0, false) == 212, "Shot 1 charge starts at its original sequence")
	check(atlas.frame_index("charging", 0.0, 1, false) == 254, "Shot 2 has its own charge sequence")
	check(atlas.frame_index("recoil", 0.0, 2, false) == 274, "Special fires using its original sequence")
	check(atlas.frame_index("idle", 0.0, 0, true) == 45, "Low health uses wounded idle sequence")
	check(atlas.frame_index("destroyed", 10.0, 0, false) == 211, "Death holds last frame instead of looping")
	check(atlas.has_method("rider_offset"), "Original rider follows per-frame mobile offsets")
	if atlas.has_method("rider_offset"):
		check(atlas.rider_offset(0) == Vector2(3, 5), "Pilot anchor matches original idle frame")
		check(atlas.rider_offset(254) == Vector2(4, 4), "Pilot anchor follows second-shot charge instead of staying fixed")
	for pose in ["idle", "moving", "charging", "recoil", "hurt", "destroyed"]:
		var index: int = atlas.frame_index(pose, 0.4, 0, false)
		check(Rect2(Vector2.ZERO, atlas.texture.get_size()).encloses(atlas.frame_rect(index)), "Frame stays within original atlas: " + pose)
	scene.model.move_actor(1.0, 0.1)
	scene._process(0.1)
	check(scene.animation_state(0) == "moving", "Bigfoot reacts to real displacement")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	scene._unhandled_key_input(key)
	scene._process(0.1)
	check(scene.animation_state(0) == "charging", "Keyboard charging animates Bigfoot")
	scene.show_pause()
	var age: float = scene.art.motion[0].pose_age
	scene._process(0.5)
	check(scene.art.motion[0].pose_age == age, "Pause freezes atlas animation time")
	scene.close_overlay()
	scene.start_match()
	check(scene.animation_state(0) == "idle", "Restart returns Bigfoot to idle")
	scene.shoot()
	scene.consume_events()
	check(scene.animation_state(0) == "recoil", "Firing enters original fire animation")
	scene.start_match()
	scene.model.actors[0].turns = 3
	scene.select_weapon(2)
	scene.shoot()
	scene.consume_events()
	scene.art.tick(scene.model, 0.3)
	scene.model.projectiles.clear()
	scene.model.schedule(0, 210.0)
	scene.consume_events()
	var rendered_frame: int = scene.actor_frame(0)
	check(rendered_frame >= 274 and rendered_frame <= 293, "Fast turn transition preserves special firing frames")
	scene.start_match()
	key.pressed = true
	scene._unhandled_key_input(key)
	scene._process(0.1)
	scene._process(0.1)
	scene.select_weapon(1)
	scene._process(0.1)
	check(scene.actor_frame(0) == 254, "Changing weapon while charging restarts the new sequence")
	scene.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/bigfoot-profile.json"))
	print("BIGFOOT CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
