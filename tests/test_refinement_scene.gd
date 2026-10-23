extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func key(scene, pressed: bool, code: Key = KEY_SPACE) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	scene._unhandled_key_input(event)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/refinement-profile.json")
	root.add_child(scene)
	scene.sound.muted = true
	scene.opening = 0
	scene.start_match()
	key(scene, true)
	for i in range(22):
		scene._process(0.1)
	check(scene.model.phase == "flight", "Full charge fires automatically")
	check(not scene.charging and scene.power == 100.0, "Automatic shot clears charge at maximum")
	check(not scene.model.last_shots[0].is_empty(), "Full charge records a real shot")
	var count: int = scene.model.projectiles.size()
	key(scene, false)
	check(scene.model.projectiles.size() == count, "Late release does not create a second shot")
	scene.opening = 0
	scene.start_match()
	key(scene, true)
	scene._process(0.1)
	scene.show_pause()
	var animation_time: float = scene.elapsed
	var power: float = scene.power
	var timer: float = scene.model.turn_time
	scene._process(1.0)
	check(scene.elapsed == animation_time, "Pause freezes combat animation time")
	check(scene.power == power and scene.model.turn_time == timer, "Pause freezes power and decision clock")
	key(scene, false)
	scene.close_overlay()
	scene._process(0.1)
	check(scene.model.phase == "aim" and not scene.charging, "Pause cancels charge and resume cannot fire unexpectedly")
	key(scene, true)
	scene._process(0.1)
	key(scene, false)
	check(scene.model.phase == "flight", "Release before full charge still fires")
	scene.consume_events()
	check(scene.has_method("animation_state"), "Presentation exposes distinct animation states")
	if scene.has_method("animation_state"):
		check(scene.animation_state(0) == "recoil", "Shot gives immediate recoil feedback")
	scene.opening = 0
	scene.start_match()
	key(scene, true)
	if scene.has_method("animation_state"):
		check(scene.animation_state(0) == "charging", "Charge changes visual state")
	scene.model.turn_time = 0.01
	scene._process(0.1)
	check(not scene.charging and scene.model.active == 1, "Timeout cancels pending player charge")
	scene.opening = 0
	scene.start_match()
	scene.model.actors[0].pos = Vector2(235, 510)
	scene.update_hud()
	# The old opaque turn panel is gone: no Panel may cover the world above the bar.
	var covered := false
	for node in scene.root.get_children():
		if node is Panel and node.get_rect().intersects(Rect2(Vector2.ZERO, scene.VIEW_SIZE)):
			covered = true
	check(not covered, "No opaque panel covers the battlefield during combat")
	scene.opening = 0
	scene.start_match()
	check(scene.has_method("displayed_queue"), "HUD exposes displayed turn prediction")
	if scene.has_method("displayed_queue"):
		scene.model.pass_turn()
		scene.consume_events()
		scene.update_hud()
		var cpu_entry: Dictionary = scene.displayed_queue().filter(func(entry): return entry.actor == 1)[0]
		check(is_equal_approx(cpu_entry.delay, maxf(0.0, scene.model.actors[1].ready - scene.model.clock)), "HUD does not invent a CPU weapon before it is chosen")
		scene.opening = 0
		scene.start_match()
		scene.model.actors[0].ready = 100.0
		scene.model.actors[1].ready = 215.0
		scene.model.clock = 100.0
		scene.select_weapon(0)
		scene.update_hud()
		check(scene.displayed_queue()[0].actor == 0, "HUD predicts player next with light shot")
		scene.select_weapon(1)
		scene.update_hud()
		check(scene.displayed_queue()[0].actor == 1, "HUD predicts CPU next with heavy shot")
	scene.model.events.append({"type": "damage", "actor": 0, "amount": 50, "position": scene.model.actors[0].pos})
	scene.consume_events()
	if scene.has_method("animation_state"):
		check(scene.animation_state(0) == "hurt", "Damage triggers reaction feedback")
	scene.model.actors[0].hp = 0
	scene.model.check_end()
	scene.consume_events()
	if scene.has_method("animation_state"):
		check(scene.animation_state(0) == "destroyed", "Elimination remains visible as destruction")
	scene.opening = 0
	scene.start_match()
	if scene.has_method("animation_state"):
		check(scene.animation_state(0) == "idle", "Restart clears previous animation states")
	check(scene.profile.xp == 45, "Presentation refinement preserves single defeat reward")
	scene.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/refinement-profile.json"))
	print("REFINEMENT SCENE CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
