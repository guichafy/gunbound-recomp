extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(FileAccess.file_exists("res://scripts/avatar_shop_model.gd"), "Shop model exists")
	if failures == 0:
		var p = load("res://scripts/profile.gd").new("res://.tools/shop-test.json")
		var c = load("res://scripts/avatar_catalog.gd").new()
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
		check(f.filter(0,"",false,1).size() == 25 and f.last_page == 3, "25 entries per page")
		check(f.filter(0,"Item 59",false,2).size() == 1 and f.page == 0, "Search clamps page")
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/shop-scene.json")
	root.size = Vector2i(1280,800)
	root.add_child(view)
	view.set_process(false)
	view.sound.muted = true
	view.show_shop()
	await process_frame
	check(view.screen == "shop" and view.shop.cards.get_child_count() == 5, "Scene shop cards")
	var shop = view.shop
	for child in shop.cards.get_child(1).get_children():
		if child is TextureRect and child.texture is AtlasTexture:
			check(child.size == Vector2(87,45), "HD portrait remains inside original card window")
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
		check(shop.try_button.disabled and not shop.search.editable, "Modal blocks underlying interface")
		click(shop.modal.get_node("GoldPurchase").get_global_rect().get_center())
		await process_frame
		check(view.profile.gold == 900 and view.profile.owns("0:0:1"), "Real Gold button")
	shop.switch_tab(true)
	await process_frame
	click(shop.cards.get_child(1).get_global_rect().get_center())
	await process_frame
	check(view.profile.equipped_set()["0"] == "0:0:1", "Real inventory equip")
	shop.model.draft_attributes = [1,0,0,0,0,0,0,0]
	view.show_menu()
	view.start_match()
	check(view.actor_avatars[0]["0"] == "0:0:1" and view.model.actors[0].attributes[0] == 0, "Only confirmed set/attributes enter arena")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/shop-scene.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/shop-scene-options.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/shop-test.json"))
	print("AVATAR SHOP CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)

func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event)
