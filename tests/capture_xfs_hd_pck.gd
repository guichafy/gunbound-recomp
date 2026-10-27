extends SceneTree
## Histórico (pré-ADR-130): usa a loja vetorial/HD substituída; não executar
## contra a loja atual. Evidência vigente: capture_shop_original(_pck).gd.
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
	root.size = Vector2i(1920,1080)
	var path := "/private/tmp/avatar-hd-pck-profile.json"
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path.get_basename()+"-options.json")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(path)
	scene.profile.gold=1000000
	scene.profile.cash=1000000
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_shop()
	await process_frame
	var shop = scene.shop
	var ok: bool = shop.cards.get_child(3).position == Vector2(25,230) and shop.cards.get_child(0).size == Vector2(160,156)
	ok = ok and shop.search.size.y <= 24
	ok = ok and Rect2(Vector2.ZERO,shop.try_button.size).encloses(shop.try_caption.get_rect())
	ok = ok and shop.try_button.position.x<shop.buy_button.position.x and shop.gift_button.position.x>550
	shop.model.select("xfs:0:0:1")
	shop.model.query = "zzzz"
	shop.search.text = "zzzz"
	shop.refresh(0,0)
	ok = ok and shop.empty_label.visible and shop.model.selected_key.is_empty() and shop.try_button.disabled and shop.buy_button.disabled
	shop.model.query = ""
	shop.search.text = ""
	shop.refresh(0,0)
	ok = ok and not shop.empty_label.visible
	ok = ok and shop.content.get_global_rect().position.distance_to(Vector2(240,0))<0.01 and shop.content.get_global_rect().size.distance_to(Vector2(1440,1080))<0.01
	ok = ok and shop.xfs_background != null and shop.xfs_background.get_size()==Vector2(1672,941)
	ok = ok and shop.empty_slot_portrait is AtlasTexture and shop.empty_slot_portrait.get_height()>500
	ok = ok and shop.portrait_for(shop.model.catalog.find("2:3:0"))==shop.empty_slot_portrait
	ok = ok and shop.xfs_portraits.size()==18
	ok = ok and shop.portrait_for(shop.model.catalog.find("xfs:0:0:1")) is AtlasTexture
	var original_rows: Array=shop.model.catalog.entries.values().filter(func(item): return item.get("source")=="xfs")
	ok = ok and original_rows.size()==562 and original_rows.filter(func(item): return item.buyable).size()==479
	for item in original_rows:
		ok = ok and ResourceLoader.exists(item.portrait)
		for layer in item.get("layers",[]):
			ok = ok and ResourceLoader.exists(layer.atlas)
	ok = ok and shop.avatar_art.hd.pieces.size() == 13
	ok = ok and shop.avatar_art.xfs_hd.layers.size()==629 and shop.avatar_art.xfs_hd.portraits.size()==532
	var hd_records:=0
	for item in original_rows:
		if item.get("layers",[]).is_empty():
			continue
		hd_records+=1
		ok = ok and shop.avatar_art.xfs_hd.complete(item)
		var gender: int=0 if int(item.gender)==2 else int(item.gender)
		var equipment: Dictionary=shop.model.catalog.defaults(gender)
		equipment[str(int(item.category))]=item.key
		var actual: Array=shop.avatar_art.sample(equipment,0.5).filter(func(piece): return int(piece.category)==int(item.category))
		ok = ok and actual.size()==item.layers.size() and actual.all(func(piece): return piece.hd and piece.has("xfs_layer"))
		ok = ok and shop.portrait_for(item) is AtlasTexture
	ok = ok and hd_records==550
	ok = ok and not FileAccess.file_exists("res://assets/hd/avatars/xfs/source/jobs.json")
	ok = ok and shop.hd.sprites.size() == 20
	ok = ok and shop.cards.get_child(0).get_node("AvatarEffect").get_child_count() == 4
	ok = ok and shop.cards.get_child(0).get_node("Portrait").size == Vector2(84,76)
	ok = ok and shop.xfs_frames.size()==116
	for key in shop.xfs_frames:
		var entry: Dictionary=shop.xfs_frames[key]
		var texture=load(entry.file)
		ok = ok and texture is Texture2D and texture.get_size()==Vector2(entry.size[0],entry.size[1])
	ok = ok and not FileAccess.file_exists("res://assets/xfs/reference/avatar.xfs")
	ok = ok and not ResourceLoader.exists("res://assets/hd/shop/source/xfs_0_16/generated_landscape.png")
	ok = ok and not ResourceLoader.exists("res://assets/hd/shop/source/xfs_0_16/generated_portraits.png")
	for key in shop.hd.sprites:
		ok = ok and shop.hd.texture(key) != null
	ok = ok and not FileAccess.file_exists("res://assets/hd/shop/source/layout.json")
	ok = ok and not ResourceLoader.exists("res://assets/hd/shop/source/gen_controls.png")
	ok = ok and not ResourceLoader.exists("res://assets/hd/shop/source/video_0_15/generated_background.png")
	ok = ok and not ResourceLoader.exists("res://assets/hd/shop/source/video_0_15/generated_empty_slot.png")
	shop.model.select("xfs:0:0:1")
	shop.refresh(0,0)
	shop.open_buy()
	await process_frame
	ok = ok and shop.modal.get_node("PurchasePanel").size.is_equal_approx(Vector2(313,187)*1.3)
	ok = ok and shop.modal.get_node("PurchasePortrait").texture != null
	shop.close_buy()
	for key in ["xfs:0:0:1","xfs:0:1:1","xfs:0:2:2","xfs:2:3:1"]:
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
	RenderingServer.force_draw()
	var screenshot := root.get_texture().get_image()
	ok = ok and screenshot.get_size() == Vector2i(1920,1080)
	assert(screenshot.save_png("/private/tmp/avatar-hd-pck-fullhd.png") == OK)
	root.size = Vector2i(1280,800)
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var bounds: Rect2 = shop.content.get_global_rect()
	ok = ok and bounds.size.distance_to(Vector2(1066.6667,800))<0.01 and bounds.position.distance_to(Vector2(106.6667,0))<0.01
	assert(root.get_texture().get_image().save_png("/private/tmp/avatar-hd-pck-1280.png") == OK)
	scene.start_match()
	ok = ok and root.content_scale_size==Vector2i(1280,800) and root.content_scale_mode==Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	ok = ok and scene.actor_avatars[0] == gear
	ok = ok and scene.model.actors[0].attributes==load("res://scripts/player_attributes.gd").with_equipment(scene.profile.attributes,scene.profile.equipment_bonuses())
	scene.queue_free()
	await process_frame
	for file in [path,path.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(file)
	print("AVATAR HD EXPORTED PCK / 550 EQUIPPED / 629 LAYERS / SHOP / RELOAD / BATTLE: ","PASS" if ok else "FAIL")
	quit(0 if ok else 1)
