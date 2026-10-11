extends SceneTree
## Native Full HD GPU captures, unchanged1280x800 world with pillarboxing.
var view
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/hd/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1920, 1080)
	# Window stretch captures only1728x1080 content, excluding its side bars.
	# Render an actual1920x1080 framebuffer; transform the same1280x800 scene.
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/hd"))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/hd-capture-profile.json")
	root.add_child(view)
	view.scale = Vector2(1.35, 1.35)
	view.position = Vector2(96, 0)
	view.set_process(false)
	view.sound.muted = true
	view.profile.nickname = "Piloto"
	view.show_menu()
	view.select_vehicle(2)
	await snap("bigfoot-menu")
	view.select_vehicle(1)
	await snap("mage-menu")
	for mobile in [2, 1]:
		for weapon in [0, 1, 2]:
			view.start_match()
			view.model.start(mobile, 1, 42)
			view.art.reset(view.model.actors)
			view.model.actors[0].turns = 3
			view.consume_events()
			view.select_weapon(weapon)
			view.angle = 30
			view.power = 65 if mobile == 1 else 75
			view.update_hud()
			var name: String = ("bigfoot" if mobile == 2 else "mage") + "-" + ["t1", "t2", "ss"][weapon]
			if mobile == 2 and weapon == 0:
				await snap("arena")
			view.shoot()
			view.consume_events()
			for frame in range(19 if weapon == 2 and mobile == 2 else 13):
				view._process(0.05)
			await snap(name)
			var captured_impact := false
			for frame in range(100):
				view._process(0.05)
				for effect in view.effects:
					if int(effect.get("vehicle", -1)) == mobile and int(effect.weapon) == weapon:
						captured_impact = true
				if captured_impact or view.model.shot_actor != 0 or view.model.phase != "flight":
					break
			if captured_impact:
				await snap(name + "-impact")
			else:
				printerr("FAIL: no natural impact captured for ", name)
				view.queue_free()
				await process_frame
				quit(1)
				return
	# Same scene/pose, original renderer only, for honest visual comparison.
	for mobile in [view.bigfoot, view.mage]:
		mobile.hd_rig.sheet.texture = null
		for sheet in [mobile.hd_shots, mobile.hd_effects]:
			sheet.texture = null
		if mobile.get("hd_emp") != null:
			mobile.hd_emp.texture = null
	view.show_menu()
	view.select_vehicle(2)
	await snap("original-bigfoot-menu")
	view.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/hd-capture-profile.json"))
	print("FULL HD ASSET GPU CAPTURES SAVED")
	quit()
