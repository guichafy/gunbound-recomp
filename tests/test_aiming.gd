extends SceneTree
## REQ-34: Aiming Mode Drag/Slice. Slice keeps Space; Drag shoots with a
## left-button drag in the world (power = distance / 640 px), fires on release.

var failures := 0
var checks := 0
var scene

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	scene._unhandled_key_input(event)

func button(point: Vector2, pressed: bool, index: int = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.button_mask = (MOUSE_BUTTON_MASK_LEFT if index == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if pressed else 0
	event.position = point
	event.global_position = point
	root.push_input(event)

func motion(point: Vector2, relative: Vector2, mask: int = MOUSE_BUTTON_MASK_LEFT) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = relative
	event.button_mask = mask
	root.push_input(event)

func player_turn() -> void:
	for frame in range(400):
		if scene.model.phase == "aim" and scene.model.active == 0:
			return
		if scene.model.phase == "aim" and scene.model.active == 1:
			scene.model.pass_turn()
			scene.consume_events()
		scene._process(0.05)

func fresh_turn() -> void:
	scene.opening = 0
	scene.start_match()
	player_turn()

func run() -> void:
	root.size = Vector2i(1280, 800)
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/aiming-test-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.select_vehicle(2)
	fresh_turn()
	var start := Vector2(300, 300)

	# Slice (default, original AimType 1): the left button only looks around.
	check(scene.options.aiming == 1 and not scene.options.drag_aiming(), "Aiming Mode starts on Slice")
	button(start, true)
	check(not scene.charging and scene.dragging, "Slice: a left press in the world pans the camera")
	button(start, false)

	# The popup radio switches the mode and Accept saves it.
	scene.show_options()
	var popup = scene.options_popup
	popup.pointer_down(popup.radio_rect("aiming", 0).get_center())
	popup.pointer_up()
	check(scene.options.aiming == 0 and scene.options.drag_aiming(), "Radio Drag turns the Drag mode on")
	popup.accepted.emit()
	var saved = load("res://scripts/options.gd").new(scene.options.path)
	saved.load_options()
	check(saved.aiming == 0, "Accept saves the Drag mode")

	# Drag: press in the world, drag 320 px right = 50, release fires once.
	button(start, true)
	check(scene.charging and scene.drag_aiming and scene.power == 0.0, "Drag: a left press in the world starts the shot with an empty bar")
	motion(start + Vector2(320, 0), Vector2(320, 0))
	check(is_equal_approx(scene.power, 50.0), "Dragging the bar width (640 px) / 2 sets power 50")
	motion(start + Vector2(160, 0), Vector2(-160, 0))
	check(is_equal_approx(scene.power, 25.0), "Dragging back lowers the power")
	motion(start + Vector2(320, 0), Vector2(160, 0))
	button(start + Vector2(320, 0), false)
	check(scene.model.phase == "flight" and is_equal_approx(scene.hud.previous_power, 50.0), "Releasing fires with the shown power")
	var shells: int = scene.model.projectiles.size()
	button(start + Vector2(320, 0), false)
	check(scene.model.projectiles.size() == shells and not scene.charging, "A second release cannot fire again")

	# A click without a drag cancels.
	fresh_turn()
	button(start, true)
	button(start, false)
	check(scene.model.phase == "aim" and not scene.charging, "A click without dragging does not shoot")

	# Letting go over the action bar still ends (and fires) the drag.
	button(start, true)
	motion(Vector2(620, 720), Vector2(320, 420))
	button(Vector2(620, 720), false)
	check(scene.model.phase == "flight" and not scene.charging, "Releasing over the HUD bar fires instead of leaving the drag stuck")

	# A lost release (motion without the button) ends the drag too.
	fresh_turn()
	button(start, true)
	motion(start + Vector2(160, 0), Vector2(160, 0))
	motion(start + Vector2(170, 0), Vector2(10, 0), 0)
	check(scene.model.phase == "flight" and is_equal_approx(scene.hud.previous_power, 25.0), "A motion without the button ends the drag with its power")

	# Space and Drag are exclusive: only one shot.
	fresh_turn()
	button(start, true)
	motion(start + Vector2(320, 0), Vector2(320, 0))
	key(KEY_SPACE, true)
	check(scene.drag_aiming and is_equal_approx(scene.power, 50.0), "Space does not reset a drag in progress")
	key(KEY_SPACE, false)
	check(scene.model.phase == "aim", "Releasing Space does not fire a drag")
	button(start + Vector2(320, 0), false)
	check(scene.model.phase == "flight", "The drag fires on its own release")
	fresh_turn()
	key(KEY_SPACE, true)
	button(start, true)
	check(not scene.drag_aiming and scene.charging, "A left press during a Space charge does not start a drag")
	button(start, false)
	key(KEY_SPACE, false)
	check(scene.model.phase == "flight", "Space still fires in the Drag mode")

	# The bar quivers while the cursor stops, within ±2 every 0.04 s; no auto-fire at 100.
	fresh_turn()
	button(start, true)
	motion(start + Vector2(320, 0), Vector2(320, 0))
	scene.drag_rng.seed = 7
	scene._process(0.2)
	check(scene.power != 50.0 and absf(scene.power - 50.0) <= 10.0, "Holding still makes the bar quiver (%.2f)" % scene.power)
	motion(start + Vector2(2000, 0), Vector2(1680, 0))
	scene._process(0.02)
	check(scene.power == 100.0 and scene.model.phase == "aim" and scene.charging, "Drag clamps at 100 without firing by itself")

	# Overlays and turn changes cancel without firing.
	scene.show_options()
	check(not scene.charging and not scene.drag_aiming and scene.model.phase == "aim", "Opening the options cancels the drag without firing")
	scene.close_overlay()
	button(start + Vector2(2000, 0), false)
	check(scene.model.phase == "aim", "A release after the cancel does not fire")
	button(start, true)
	motion(start + Vector2(200, 0), Vector2(200, 0))
	scene.show_pause()
	check(not scene.charging and scene.model.phase == "aim", "The pause cancels the drag without firing")
	scene.close_overlay()
	button(start, false)
	button(start, true)
	motion(start + Vector2(200, 0), Vector2(200, 0))
	scene.model.pass_turn()
	scene.consume_events()
	check(not scene.charging and not scene.drag_aiming, "A turn change (or timeout) cancels the drag")
	button(start, false)

	# The right button looks around in both modes; the left one shoots in Drag.
	fresh_turn()
	scene.camera = Vector2(100, 100)
	button(Vector2(640, 300), true, MOUSE_BUTTON_RIGHT)
	motion(Vector2(630, 300), Vector2(-10, 0), MOUSE_BUTTON_MASK_RIGHT)
	button(Vector2(630, 300), false, MOUSE_BUTTON_RIGHT)
	check(scene.camera.is_equal_approx(Vector2(110, 100)) and not scene.charging, "Drag mode: the right button pans the camera")
	scene.options.aiming = 1
	scene.camera = Vector2(100, 100)
	button(Vector2(640, 300), true)
	motion(Vector2(630, 300), Vector2(-10, 0))
	button(Vector2(630, 300), false)
	check(scene.camera.is_equal_approx(Vector2(110, 100)) and not scene.charging and scene.model.phase == "aim", "Slice mode: the left button pans and never shoots")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.options.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/aiming-test-profile.json"))
	print("AIMING CHECKS: ", checks, " | FAILURES: ", failures)
	scene.queue_free()
	quit(1 if failures > 0 else 0)
