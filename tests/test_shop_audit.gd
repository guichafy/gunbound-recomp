extends "res://tests/support/suite.gd"
const PROFILE_PATH := "res://.tools/shop-audit-profile.json"
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event)
func key(code: int, unicode: int = 0, ctrl: bool = false) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	event.physical_keycode = code
	event.unicode = unicode
	event.ctrl_pressed = ctrl and OS.get_name()!="macOS"
	event.meta_pressed = ctrl and OS.get_name()=="macOS"
	root.push_input(event)
func visible_bottom(node: TextureButton) -> float:
	var image := node.texture_normal.get_image()
	var bottom := 0
	for y in range(image.get_height()-1,-1,-1):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a>8.0/255.0:
				bottom = y+1
				break
		if bottom>0:
			break
	# AtlasTexture.get_image returns the raw frame without virtual margin;
	# drawing uses the texture's full logical size, including that margin.
	var size := node.texture_normal.get_size()
	var scale := minf(node.size.x/size.x,node.size.y/size.y)
	return (bottom+node.texture_normal.margin.position.y)*scale+(node.size.y-size.y*scale)*0.5
func run() -> void:
	for path in [PROFILE_PATH,"res://.tools/shop-audit-profile-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://tests/legacy_profile.gd").new(PROFILE_PATH)
	root.size = Vector2i(1280,800)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_shop()
	await process_frame
	var shop = scene.shop
	shop.set_process(false)
	# Hidden selection must not leave a purchase/try action for a different card.
	check(shop.model.select("0:0:1"),"Select visible Marine without purchasing")
	shop.refresh(0,0)
	shop.search.grab_focus()
	for letter in "kappa":
		key(letter.to_upper().unicode_at(0),letter.unicode_at(0))
	await process_frame
	check(shop.cards.get_child_count()==1 and shop.cards.get_child(0).tooltip_text.begins_with("Kappa"),"Real text input filters to Kappa")
	check(shop.model.selected_key.is_empty() and shop.try_button.disabled and shop.buy_button.disabled,"Filtered-out selection clears purchase and try actions")
	key(KEY_A,0,true)
	for letter in "zzzz":
		key(letter.to_upper().unicode_at(0),letter.unicode_at(0))
	await process_frame
	check(shop.cards.get_child_count()==0 and shop.empty_label.visible,"Empty search shows an explanation without a phantom card")
	key(KEY_A,0,true)
	key(KEY_BACKSPACE)
	await process_frame
	check(shop.model.query.is_empty(),"Real search clear restores full catalog")
	check(not shop.empty_label.visible,"Restoring results hides empty-search explanation")
	# Selection rolls back when a grid inventory click cannot persist equipment.
	check(scene.profile.purchase("0:0:1","gold")=="ok","Own Marine in isolated profile")
	shop.switch_tab(true)
	await process_frame
	click(shop.cards.get_child(0).get_global_rect().get_center())
	await process_frame
	var before: Dictionary = shop.model.preview.duplicate(true)
	var selection: String = shop.model.selected_key
	scene.profile.path = "res://.tools/nonexistent-shop-audit-%d/profile.json" % Time.get_ticks_usec()
	shop.status_label.text = "unchanged"
	click(shop.cards.get_child(1).get_global_rect().get_center())
	await process_frame
	check(shop.model.selected_key==selection and shop.model.preview==before and scene.profile.equipped_set()["0"]=="0:0:0","Failed grid equip preserves selection, preview and confirmed outfit")
	check(shop.status_label.text!="unchanged","Grid equip failure shows visible feedback")
	scene.profile.path = PROFILE_PATH
	click(shop.cards.get_child(1).get_global_rect().get_center())
	await process_frame
	check(scene.profile.equipped_set()["0"]=="0:0:1","Grid equip can be retried successfully")
	shop.switch_tab(false)
	await process_frame
	for node in shop.category_buttons:
		check(node.position.y>=shop.cards.get_child(3).get_rect().end.y,"XFS categories are below the catalog")
		check(not node.get_rect().intersects(shop.try_button.get_rect()),"Category and Try hitboxes do not overlap")
	check(shop.try_button.position.x<shop.buy_button.position.x and shop.gift_button.position.x>550,"XFS Try/Buy belong to catalog; Gift belongs to inventory")
	check(shop.inventory_rows.get_parent().position.x>shop.cards.get_child(2).get_rect().end.x,"XFS inventory is on the right of catalog")
	check(shop.has_method("preview_region"),"Preview supports a uniform source crop")
	if shop.has_method("preview_region"):
		for path in ["InGame/Scene/AvatarShop/InGamePreview/MiramoTown/Background","InGame/Scene/AvatarShop/InGamePreview/MiramoTown/Foreground2"]:
			var region: Rect2 = shop.preview_region(path)
			check(is_equal_approx(region.size.x/region.size.y,86.0/72.0),"Preview preserves aspect with uniform scaling: "+path)
			check(Rect2(Vector2.ZERO,shop.texture(path).get_size()).encloses(region),"Preview crop stays inside source: "+path)
	# Clicking text is the same category action as clicking the icon.
	click(shop.category_buttons[1].get_global_rect().get_center())
	await process_frame
	check(shop.model.category==1,"Category caption accepts real click")
	# ESC closes a modal even after the search held keyboard focus.
	shop.refresh(0,0)
	shop.model.select("0:0:2")
	shop.refresh(0,0)
	shop.search.grab_focus()
	shop.open_buy()
	key(KEY_ESCAPE)
	await process_frame
	check(scene.screen=="shop" and not is_instance_valid(shop.modal) and shop.search.editable,"ESC closes purchase before leaving shop and restores focused search")
	scene.queue_free()
	await process_frame
	for path in [PROFILE_PATH,"res://.tools/shop-audit-profile-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("SHOP AUDIT CHECKS")
