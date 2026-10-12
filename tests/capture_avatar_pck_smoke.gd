extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("/private/tmp/avatar-shop-pck-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.show_shop()
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var brown := 0
	for y in range(270,390):
		for x in range(130,380):
			var color := screenshot.get_pixel(x,y)
			if color.r > color.b+0.12 and color.g > color.b+0.02:
				brown += 1
	print("PCK AVATAR PREVIEW PIXELS: ",brown)
	var ok: bool = brown > 30 and view.profile.catalog.entries.size()==15
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute("/private/tmp/avatar-shop-pck-profile.json")
	print("PCK SHOP SMOKE: ","PASS" if ok else "FAIL")
	quit(0 if ok else 1)
