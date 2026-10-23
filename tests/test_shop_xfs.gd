extends "res://tests/support/suite.gd"
const PATH := "res://.tools/shop-xfs-test.json"
func click(node: Control) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed=pressed
		event.position=node.get_global_rect().get_center()
		event.global_position=event.position
		root.push_input(event)
func run() -> void:
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size=Vector2i(1920,1080)
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(PATH)
	scene.profile.gold=50000
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.show_shop()
	await process_frame
	var shop=scene.shop
	shop.set_process(false)
	check(shop.xfs_background != null and shop.backdrop.texture==shop.xfs_background,"Generated XFS landscape is used by the actual backdrop")
	check(shop.backdrop.size==Vector2(1920,1080),"Landscape fills the full window beyond the 4:3 interface")
	check(shop.search.position.y+shop.search.size.y<=44,"Search field leaves the balance text unobstructed")
	check(shop.xfs_portraits.size()==18 and shop.portrait_for(shop.model.catalog.find("xfs:0:0:1")) is AtlasTexture,"Regenerated XFS portraits load separately from equipped rig pieces")
	check(shop.cards.get_child(0).get_node("AvatarEffect").get_child_count()==4,"Marine card displays the two real bonuses as icons and values")
	var equipped: Dictionary=scene.profile.equipped_set().duplicate(true)
	var balance: int=scene.profile.gold
	click(shop.cards.get_child(0))
	await process_frame
	click(shop.try_button)
	await process_frame
	check(shop.model.preview["0"]=="xfs:0:0:1" and scene.profile.equipped_set()==equipped,"Actual Try previews an unowned item without persisting equipment")
	var restore: Button
	for node in shop.content.get_children():
		if node is Button and node.text=="Restaurar":
			restore=node
	check(restore!=null,"Restore action is available on the inventory panel")
	if restore!=null:
		click(restore)
		await process_frame
		check(shop.model.preview==equipped and scene.profile.gold==balance,"Restore returns to equipped set without currency changes")
	shop.use_hd=false
	shop.refresh(0,0)
	await process_frame
	click(shop.cards.get_child(0))
	await process_frame
	var normal=shop.cards.get_child(1).get_theme_stylebox("normal")
	var selected=shop.cards.get_child(0).get_theme_stylebox("normal")
	check(normal is StyleBoxTexture and selected is StyleBoxTexture and normal.texture!=selected.texture,"Native fallback visibly distinguishes the selected item")
	check(shop.chrome_labels.all(func(node): return not node.visible),"Native baked headings are not duplicated")
	check(shop.xfs_texture("store_myavatar")!=null,"Native fallback includes the inventory panel")
	click(shop.buy_button)
	await process_frame
	check(is_instance_valid(shop.modal),"Native fallback selected card opens purchase")
	if is_instance_valid(shop.modal):
		click(shop.modal.get_node("GoldPurchase"))
		await process_frame
		check(scene.profile.owns("xfs:0:0:1") and scene.profile.gold==balance-10000,"Fallback purchase buys the selected item exactly once")
	check(shop.gift_button.disabled,"Gift remains unavailable without account/server support")
	shop.use_hd=true
	shop.model.query="Great Devil Clothing"
	shop.refresh(1,0)
	await process_frame
	var name_label: Label=shop.cards.get_child(0).get_node("AvatarName")
	check(name_label.clip_text and name_label.position.x+name_label.size.x<129,"Longest real XFS name cannot overlap the gender badge")
	shop.model.query=""
	shop.refresh(0,0)
	var hd_portrait: Texture2D=shop.portrait_for(shop.model.catalog.find("xfs:0:0:1"))
	shop.xfs_portraits.clear()
	check(not shop.portrait_for(shop.model.catalog.find("xfs:0:0:1")) is AtlasTexture,"Missing generated portrait falls back to the exact original XFS thumbnail")
	check(hd_portrait.get_width()>200,"Regenerated thumbnail contains measured detail rather than a larger empty canvas")
	scene.queue_free()
	await process_frame
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("XFS SHOP CHECKS")
