extends SceneTree
## Real GPU renders of temporal salvos; isolated profile, no player progress.
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
	view.profile = load("res://scripts/profile.gd").new("res://.tools/bigfoot-attacks-capture-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.profile.nickname = "Piloto"
	view.show_menu()
	view.select_vehicle(2)
	await snap("menu")
	for weapon in [0, 1, 2]:
		view.opening = 0
		view.start_match()
		view.model.start(2, 1, 42)
		view.art.reset(view.model.actors)
		view.model.actors[0].turns = 3
		view.consume_events()
		view.select_weapon(weapon)
		view.aim.angle = 30
		view.aim.power = 75
		view.update_hud()
		if weapon == 0:
			await snap("arena")
		view.shoot()
		view.consume_events()
		if weapon == 1:
			view._process(0.1)
			await snap("t2-pending")
		for frame in range(19 if weapon == 2 else (11 if weapon == 1 else 13)):
			view._process(0.05)
		await snap(["t1", "t2", "ss"][weapon])
		for frame in range(100):
			view._process(0.05)
			if not view.effects.is_empty():
				break
		await snap(["t1-impact", "t2-impact", "ss-impact"][weapon])
	view.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/bigfoot-attacks-capture-profile.json"))
	print("BIGFOOT T1/T2/SS GPU CAPTURES SAVED")
	quit()
