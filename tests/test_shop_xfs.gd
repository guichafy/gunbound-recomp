extends "res://tests/support/suite.gd"
## XFS catalog in the original store (ADR-130): native fallback, Try/Laundry,
## purchase and name clipping. Composition oracle lives in test_shop_original.
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
	check(shop.backdrop is ColorRect and shop.backdrop.size==Vector2(1920,1080),"Letterbox fills the window beyond the 4:3 store, without generated art")
	check(shop.portrait_for(shop.model.catalog.find("xfs:0:0:1")).resource_path=="res://assets/xfs/avatars/smh00001_rle.png","XFS portrait is the original thumbnail with opaque RLE outline")
	check(shop.stat_entries(shop.cards.get_child(0).item).size()==2,"Marine card has its two real bonuses")
	var equipped: Dictionary=scene.profile.equipped_set().duplicate(true)
	var balance: int=scene.profile.gold
	click(shop.cards.get_child(0))
	await process_frame
	click(shop.try_button)
	await process_frame
	check(shop.model.preview["0"]=="xfs:0:0:1" and scene.profile.equipped_set()==equipped,"Actual Try previews an unowned item without persisting equipment")
	click(shop.laundry_button)
	await process_frame
	check(shop.model.preview==equipped and scene.profile.gold==balance,"Laundry returns to equipped set without currency changes")
	shop.use_hd=false
	shop.refresh(0,0)
	await process_frame
	click(shop.cards.get_child(0))
	await process_frame
	check(shop.cards.get_child(0).selected and not shop.cards.get_child(1).selected,"Native fallback marks only the selected card")
	check(shop.art.density("store_back:0")==1.0 and shop.buy_button.texture_normal==shop.art.native_texture("b_store_buy:0"),"Native fallback draws the original frames")
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
	var name_label=shop.cards.get_child(0).get_node("AvatarName")
	check(name_label.clip_contents and name_label.position.x+name_label.size.x<=125,"Longest real XFS name stops before the gender tag")
	shop.model.query=""
	shop.refresh(0,0)
	var broken: Dictionary=shop.model.catalog.find("xfs:0:0:1").duplicate(true)
	broken.portrait="res://assets/xfs/avatars/missing.png"
	check(shop.portrait_for(broken)==null,"Missing thumbnail leaves the window empty instead of borrowing other art")
	scene.queue_free()
	await process_frame
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("XFS SHOP CHECKS")
