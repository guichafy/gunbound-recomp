extends SceneTree
## Real GPU captures of the integrated Bigfoot, with an isolated local profile.
var view

func _initialize() -> void:
	call_deferred("run")

func snap(name: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/bigfoot-" + name + ".png")

func run() -> void:
	view = load("res://scenes/main.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.profile = load("res://scripts/profile.gd").new("res://.tools/bigfoot-capture-profile.json")
	view.profile.nickname = "Piloto"
	view.show_menu()
	view.select_vehicle(2)
	await snap("menu")
	view.opening = 0
	view.start_match()
	view.model.start(2, 1, 42)
	view.art.reset(view.model.actors)
	view.consume_events()
	view.update_hud()
	await snap("arena")
	view.model.move_actor(1, 0.4)
	view._process(0.05)
	await snap("moving")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	view._unhandled_key_input(key)
	for i in range(7):
		view._process(0.1)
	await snap("charge")
	key.pressed = false
	view._unhandled_key_input(key)
	view.consume_events()
	view._process(0.1)
	await snap("firing")
	view.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/bigfoot-capture-profile.json"))
	print("BIGFOOT GPU CAPTURES SAVED")
	quit()
