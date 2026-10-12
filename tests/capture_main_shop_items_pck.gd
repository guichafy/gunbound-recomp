extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var view = load("res://scenes/main.tscn").instantiate()
	var path := "/private/tmp/main-shop-items-pck-profile.json"
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path.get_basename()+"-options.json")
	view.profile = load("res://scripts/profile.gd").new(path)
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.profile.xp = 3600
	var ok: bool = view.profile.commit_attributes([30,0,0,0,10,40,50,0])
	view.options.items = ["power_up"]
	view.show_shop()
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var brown := 0
	for y in range(270,390):
		for x in range(130,380):
			var color := screenshot.get_pixel(x,y)
			if color.r>color.b+0.12 and color.g>color.b+0.02:
				brown += 1
	ok = ok and brown>30 and view.profile.catalog.entries.size()==15 and view.shop.avatar_art.hd.pieces.size()==13
	view.start_match()
	await process_frame
	ok = ok and view.item_bar.buttons.size()==1 and view.use_item(0) and is_equal_approx(float(view.model.actors[0].ready),12.0)
	ok = ok and view.item_art.textures["ItemPowerUp.png"].get_width()>view.item_art.originals["ItemPowerUp.png"].get_width()
	print("MAIN PCK SHOP+HD+ITEMS: ","PASS" if ok else "FAIL", " | avatar pixels: ",brown)
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path.get_basename()+"-options.json")
	quit(0 if ok else 1)
