extends SceneTree
## GPU evidence with isolated profile; impact/death are controlled visual fixtures.
var view
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mage-" + name + ".png")
func run() -> void:
	view = load("res://scenes/main.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.profile = load("res://scripts/profile.gd").new("res://.tools/mage-capture-profile.json")
	view.profile.nickname = "Piloto"
	view.show_menu()
	view.select_vehicle(1)
	await snap("menu")
	view.opening = 0
	view.start_match()
	view.model.start(1, 1, 42)
	view.art.reset(view.model.actors)
	view.consume_events()
	view.update_hud()
	await snap("arena")
	view.select_weapon(1)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	view._unhandled_key_input(key)
	for frame in range(7):
		view._process(0.1)
	await snap("charge")
	key.pressed = false
	view._unhandled_key_input(key)
	view.consume_events()
	for frame in range(4):
		view._process(0.1)
	await snap("s2")
	view.opening = 0
	view.start_match()
	view.model.actors[0].turns = 3
	view.select_weapon(2)
	view.shoot()
	view.consume_events()
	view._process(0.1)
	await snap("ss")
	view.model.explode(view.model.actors[1].pos)
	view.consume_events()
	view._process(0.1)
	await snap("impact")
	view.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/mage-capture-profile.json"))
	print("MAGE GPU CAPTURES SAVED")
	quit()
