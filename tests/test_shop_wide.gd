extends SceneTree
var checks := 0
var failures := 0
const PATH := "res://.tools/shop-wide-test.json"
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)
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
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size=Vector2i(1920,1080)
	# Match the real application, not an artificially unscaled capture window.
	root.content_scale_size=Vector2i(1280,800)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://tests/legacy_profile.gd").new(PATH)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	# Menu/arena transformations must not leave bars around the widescreen shop.
	scene.scale=Vector2.ONE*1.35
	scene.position=Vector2(96,0)
	scene.show_shop()
	await process_frame
	var shop=scene.shop
	var bounds: Rect2=shop.content.get_global_rect()
	# Fractional virtual width produces subpixel float rounding at viewport edges.
	check(bounds.position.distance_to(Vector2(240,0))<0.01 and bounds.size.distance_to(Vector2(1440,1080))<0.01,"Full HD XFS layout preserves native 4:3 independently of host transform")
	check(is_equal_approx(shop.content.scale.x,shop.content.scale.y),"Uniform layout scaling")
	check(shop.try_button.position.x<shop.buy_button.position.x and shop.gift_button.position.x>550,"Footer matches XFS Try Buy and inventory Gift")
	check(shop.wide_background != null and shop.wide_background.get_size()==Vector2(1672,941),"Generated backdrop loads with its measured dimensions")
	check(shop.load_registered_texture("res://.tools/no-shop-background.json")==null,"Missing backdrop metadata requests native fallback")
	var metadata_path := "res://.tools/shop-wide-invalid-background.json"
	for value in ["invalid",{"version":1,"size":["bad",941]},{"version":1,"size":[1,1],"file":"res://assets/hd/shop/wide_background.png"}]:
		var file := FileAccess.open(metadata_path,FileAccess.WRITE)
		file.store_string(JSON.stringify(value))
		file.close()
		check(shop.load_registered_texture(metadata_path)==null,"Invalid backdrop metadata requests native fallback")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(metadata_path))
	for key in ["2:2:0","2:3:0"]:
		var item: Dictionary=shop.model.catalog.find(key)
		var portrait: Texture2D=shop.portrait_for(item)
		check(portrait is AtlasTexture and portrait.get_height()>500,"Empty accessory portrait uses regenerated HD detail: "+key)
		check(shop.avatar_art.hd.piece(key,0).is_empty(),"Portrait-only art never becomes an equipped rig piece: "+key)
	var registered_portrait: Texture2D=shop.empty_slot_portrait
	shop.empty_slot_portrait=null
	check(shop.portrait_for(shop.model.catalog.find("2:3:0"))!=null,"Missing empty-slot HD portrait preserves native fallback")
	shop.empty_slot_portrait=registered_portrait
	# Exercise all nine positions even though the real head catalog has five.
	var original_entries: Dictionary=shop.model.catalog.entries.duplicate(true)
	for id in range(5,9):
		var item: Dictionary=original_entries["0:0:1"].duplicate(true)
		item.key="0:0:%d" % id
		item.id=id
		shop.model.catalog.entries[item.key]=item
	shop.refresh(0,0)
	check(shop.cards.get_child_count()==9,"Nine-item fixture fills the 3x3 grid")
	var last_card: Rect2=shop.cards.get_child(8).get_global_rect()
	check(bounds.encloses(last_card) and last_card.end.y<shop.category_buttons[0].get_global_rect().position.y,"Third row fits above categories and footer")
	shop.model.catalog.entries=original_entries
	shop.refresh(0,0)
	check(shop.has_method("set_preview_mode"),"Avatar/mobile preview is selectable")
	if shop.has_method("set_preview_mode"):
		check(not shop.preview_mobile,"Video avatar-only preview is the default")
		var equipment: Dictionary=scene.profile.equipped_set().duplicate(true)
		click(shop.preview_buttons[1].get_global_rect().get_center())
		await process_frame
		check(shop.preview_mobile and scene.profile.equipped_set()==equipment,"Real mobile preview click is presentation only")
		click(shop.preview_buttons[0].get_global_rect().get_center())
		await process_frame
		check(not shop.preview_mobile,"Real avatar preview click restores standalone display")
	for node in [shop.cards.get_child(0),shop.cards.get_child(4),shop.search,shop.gift_button,shop.try_button,shop.inventory_rows.get_parent()]:
		check(bounds.encloses(node.get_global_rect()),"Control is contained in widescreen layout: "+str(node.name))
	var row=shop.inventory_rows.get_node("Owned_0_0_0")
	var style=row.get_theme_stylebox("normal")
	check(style is StyleBoxFlat and style.bg_color.r>0.8 and style.bg_color.g>0.6 and style.bg_color.b<0.55,"Equipped inventory row has video's yellow highlight")
	click(shop.cards.get_child(1).get_global_rect().get_center())
	await process_frame
	click(shop.buy_button.get_global_rect().get_center())
	await process_frame
	check(is_instance_valid(shop.modal),"Real Full HD purchase button opens modal")
	if is_instance_valid(shop.modal):
		check(shop.modal.get_global_rect().size.is_equal_approx(Vector2(1440,1080)),"Modal shields the complete viewport")
		check(shop.modal.get_node("PurchasePanel").get_global_rect().get_center().is_equal_approx(bounds.get_center()),"Purchase panel remains centered in Full HD")
		click(shop.modal.get_node("GoldPurchase").get_global_rect().get_center())
		await process_frame
		check(scene.profile.owns("0:0:1") and scene.profile.gold==900,"Full HD input reaches the correct Gold purchase")
	root.size=Vector2i(1280,800)
	await process_frame
	await process_frame
	bounds=shop.content.get_global_rect()
	check(is_equal_approx(bounds.size.x/bounds.size.y,4.0/3.0) and Rect2(0,0,1280,800).grow(0.01).encloses(bounds),"1280x800 centers a contained 4:3 shop without distortion")
	click(shop.inventory_rows.get_node("Owned_0_0_1").get_global_rect().get_center())
	await process_frame
	check(scene.profile.equipped_set()["0"]=="0:0:1","Inventory remains interactive after viewport resize")
	shop.open_attributes()
	await process_frame
	check(shop.attributes_panel.get_global_rect().size.is_equal_approx(bounds.size),"Attribute modal covers the resized composition")
	shop.close_attributes()
	var escape := InputEventKey.new()
	escape.pressed=true
	escape.keycode=KEY_ESCAPE
	escape.physical_keycode=KEY_ESCAPE
	root.push_input(escape)
	await process_frame
	check(scene.screen=="menu" and root.content_scale_size==Vector2i(1280,800) and root.content_scale_mode==Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,"ESC leaves shop and restores arena/menu stretch settings")
	root.size=Vector2i(1920,1080)
	scene.show_shop()
	await process_frame
	check(scene.shop.content.get_global_rect().size.distance_to(Vector2(1440,1080))<0.01,"Repeated entry uses the actual Full HD viewport")
	scene.opening = 0
	scene.start_match()
	await process_frame
	check(root.content_scale_size==Vector2i(1280,800) and root.content_scale_mode==Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,"Transition to battle restores the original viewport")
	scene.queue_free()
	await process_frame
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("WIDE SHOP CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
