extends "res://tests/support/suite.gd"
func run() -> void:
	check(FileAccess.file_exists("res://scripts/avatar_shop_model.gd"), "Shop model exists")
	if failures == 0:
		var p = load("res://tests/legacy_profile.gd").new("res://.tools/shop-test.json")
		var c = load("res://scripts/avatar_catalog.gd").legacy()
		var s = load("res://scripts/avatar_shop_model.gd").new(p,c)
		check(s.select("0:0:1") and not p.owns("0:0:1"), "Select not buy")
		check(s.try_selected() and s.preview["0"] == "0:0:1" and p.equipped_set()["0"] == "0:0:0", "Temporary try")
		check(s.filter(0,"missing",false,99).is_empty() and s.page == 0 and s.last_page == 1, "Empty search")
		check(s.filter(0,"MARINE",false).size() == 1, "Case-insensitive name")
		check(s.confirm_buy("0:0:1","gold") == "ok", "Buy selected")
		check(s.filter(0,"",true).size() == 2, "Owned inventory")
		check(s.select("0:0:1") and p.equipped_set()["0"] == "0:0:1", "Inventory equips")
		var rows: Array = []
		for i in range(60):
			rows.append({"key":"0:0:%d" % i,"gender":0,"category":0,"id":i,"name":"Item %d" % i})
		var f = load("res://scripts/avatar_shop_model.gd").new(p,load("res://scripts/avatar_catalog.gd").new(rows))
		check(f.filter(0,"",false,1).size() == 9 and f.last_page == 7, "Classic nine entries per page")
		check(f.filter(0,"Item 59",false,2).size() == 1 and f.page == 0, "Search clamps page")
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://tests/legacy_profile.gd").new("res://.tools/shop-scene.json")
	root.size = Vector2i(1280,800)
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.show_shop()
	await process_frame
	check(view.screen == "shop" and view.shop.cards.get_child_count() == 5, "Scene shop cards")
	var shop = view.shop
	var first = shop.cards.get_child(0)
	var fourth = shop.cards.get_child(3)
	check(first.position == Vector2(21,69) and fourth.position == Vector2(21,230), "Client card grid (0x44a000): 163×161 steps from 21,69")
	check(first.size == Vector2(160,156), "XFS card proportions")
	var thumb = shop.cards.get_child(1).get_node("Portrait")
	check(thumb.size == thumb.texture.get_size() and thumb.get_rect().get_center().is_equal_approx(Vector2(52,62)), "Legacy portrait keeps native size, centered on the client anchor")
	click(shop.cards.get_child(1).get_global_rect().get_center())
	await process_frame
	check(shop.model.selected_key == "0:0:1", "Real card click")
	click(shop.try_button.get_global_rect().get_center())
	await process_frame
	check(shop.model.preview["0"] == "0:0:1" and view.profile.equipped_set()["0"] == "0:0:0", "Real Try temporary")
	click(shop.buy_button.get_global_rect().get_center())
	await process_frame
	check(is_instance_valid(shop.modal), "Real Buy modal")
	if is_instance_valid(shop.modal):
		check(shop.try_button.disabled and shop.cards.get_child(0).disabled, "Modal blocks underlying interface")
		click(shop.modal.get_node("GoldPurchase").get_global_rect().get_center())
		await process_frame
		check(view.profile.gold == 900 and view.profile.owns("0:0:1"), "Real Gold button")
	click(shop.try_button.get_global_rect().get_center())
	await process_frame
	check(view.profile.equipped_set()["0"] == "0:0:1", "Owned Shop item can be dressed after temporary try and purchase")
	var reloaded = load("res://tests/legacy_profile.gd").new("res://.tools/shop-scene.json")
	reloaded.load_profile()
	check(reloaded.equipped_set()["0"] == "0:0:1", "Shop dress survives profile reload")
	shop.switch_tab(true)
	await process_frame
	click(shop.cards.get_child(1).get_global_rect().get_center())
	await process_frame
	check(view.profile.equipped_set()["0"] == "0:0:1", "Real inventory equip")
	shop.switch_tab(false)
	shop.model.select("0:0:2")
	shop.model.try_selected()
	shop.model.select("0:0:1")
	shop.refresh(0,0)
	check(not shop.try_button.disabled and shop.try_state == "Vestir", "Can restore dressed item over temporary unowned preview")
	click(shop.try_button.get_global_rect().get_center())
	await process_frame
	check(shop.model.preview["0"] == "0:0:1" and shop.try_state == "Vestido", "Dress clears temporary preview and confirms saved state")
	shop.model.draft_attributes = [1,0,0,0,0,0,0,0]
	view.show_menu()
	view.opening = 0
	view.start_match()
	check(view.actor_avatars[0]["0"] == "0:0:1" and view.model.actors[0].attributes[0] == 0, "Only confirmed set/attributes enter arena")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/shop-scene.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/shop-scene-options.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/shop-test.json"))
	finish("AVATAR SHOP CHECKS")

func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event)
