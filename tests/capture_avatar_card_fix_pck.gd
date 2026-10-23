extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event)
func run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var path := "/private/tmp/card-fix-pck-profile.json"
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path.get_basename()+"-options.json")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(path)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_shop()
	await process_frame
	var shop = scene.shop
	var ok: bool = shop.cards.get_child(3).position == Vector2(260,178) and shop.cards.get_child(0).size == Vector2(166,147)
	ok = ok and shop.search.size.y <= 21 and shop.try_caption.position.y == 57
	ok = ok and shop.avatar_art.hd.pieces.size() == 13
	ok = ok and shop.hd.sprites.size() == 20
	ok = ok and shop.cards.get_child(0).get_node("AvatarEffect").text == "Cosmético · sem bônus"
	ok = ok and shop.cards.get_child(0).get_node("Portrait").size == Vector2(126,66)
	for key in shop.hd.sprites:
		ok = ok and shop.hd.texture(key) != null
	ok = ok and not FileAccess.file_exists("res://assets/hd/shop/source/layout.json")
	ok = ok and not ResourceLoader.exists("res://assets/hd/shop/source/gen_controls.png")
	shop.model.select("0:0:1")
	shop.refresh(0,0)
	shop.open_buy()
	await process_frame
	ok = ok and shop.modal.get_node("PurchasePanel").size.is_equal_approx(Vector2(228,286)*1.6)
	ok = ok and shop.modal.get_node("PurchasePortrait").texture != null
	shop.close_buy()
	for key in ["0:0:1","0:1:1","0:2:1","2:3:1"]:
		var bought: String = scene.profile.purchase(key,"gold")
		ok = (bought == "ok") and ok
		shop.refresh(int(shop.model.catalog.find(key).category),0)
		await process_frame
		var row = shop.inventory_rows.get_node_or_null("Owned_"+key.replace(":","_"))
		if row == null:
			printerr("Missing exported owned row: ",key)
			quit(1)
			return
		# Make the equipped row visible before sending actual viewport input.
		shop.inventory_rows.get_parent().ensure_control_visible(row)
		await process_frame
		click(row.get_global_rect().get_center())
		await process_frame
		ok = ok and scene.profile.equipped_set().get(str(int(shop.model.catalog.find(key).category))) == key
	var gear: Dictionary = scene.profile.equipped_set().duplicate(true)
	var loaded = load("res://scripts/profile.gd").new(path)
	loaded.load_profile()
	ok = ok and loaded.equipped_set() == gear
	shop.open_attributes()
	ok = ok and shop.attributes_panel.visible and not shop.search.editable
	shop.close_attributes()
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	ok = ok and screenshot.get_size() == Vector2i(1280,800)
	assert(screenshot.save_png("/private/tmp/card-fix-pck.png") == OK)
	scene.set("opening", 0)
	scene.start_match()
	ok = ok and scene.actor_avatars[0] == gear
	scene.queue_free()
	await process_frame
	for file in [path,path.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(file)
	print("AVATAR CARD FIX EXPORTED PCK / GPU / INVENTORY / RELOAD / BATTLE: ","PASS" if ok else "FAIL")
	quit(0 if ok else 1)
