extends "res://tests/support/suite.gd"
const PROFILE_PATH := "res://.tools/classic-shop-test.json"
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event)
func escape() -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = KEY_ESCAPE
	root.push_input(event)
func run() -> void:
	var profile = load("res://tests/legacy_profile.gd").new(PROFILE_PATH)
	profile.xp = 2200
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = profile
	root.size = Vector2i(1280,800)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_shop()
	await process_frame
	var shop = scene.shop
	check(shop.inventory_scroll.size == Vector2(176,17*14) and shop.inventory_rows.get_child_count() == shop.inventory_count(),"Fourteen 17 px client rows; only owned items become rows")
	check(shop.inventory_rows.get_node_or_null("Owned_0_0_0") != null and shop.inventory_rows.get_node_or_null("Owned_0_1_0") != null,"Owned head/body always visible independently of shop filter")
	check(not shop.attributes_panel.visible,"Attributes do not occupy main shop")
	check(profile.purchase("0:0:1","gold") == "ok","Test owns head")
	shop.refresh(1,0)
	await process_frame
	var head_row = shop.inventory_rows.get_node("Owned_0_0_1")
	click(head_row.get_global_rect().get_center())
	await process_frame
	check(profile.equipped_set()["0"] == "0:0:1" and shop.model.preview["0"] == "0:0:1","Lateral inventory equips and updates preview from different category")
	check(profile.gold == 900,"Lateral equip does not charge again")
	var reloaded = load("res://tests/legacy_profile.gd").new(PROFILE_PATH)
	reloaded.load_profile()
	check(reloaded.equipped_set()["0"] == "0:0:1","Lateral equip persists")
	var saved_preview: Dictionary = shop.model.preview.duplicate(true)
	profile.path = "res://.tools/missing-classic-path/profile.json"
	click(shop.inventory_rows.get_node("Owned_0_0_0").get_global_rect().get_center())
	await process_frame
	check(profile.equipped_set()["0"] == "0:0:1" and shop.model.preview == saved_preview,"Failed lateral equip preserves profile and preview")
	profile.path = PROFILE_PATH
	click(shop.attributes_button.get_global_rect().get_center())
	await process_frame
	check(shop.attributes_panel.visible,"Real attributes button opens separate panel")
	check(shop.try_button.disabled and shop.gender_button.disabled and shop.inventory_rows.get_node("Owned_0_0_0").disabled,"Attribute modal blocks all underlying shop and inventory controls")
	click(shop.add_buttons[0].get_global_rect().get_center())
	await process_frame
	check(shop.model.draft_attributes[0] == 1 and profile.attributes[0] == 0,"Attribute plus edits draft only")
	escape()
	await process_frame
	check(scene.screen == "shop" and not shop.attributes_panel.visible,"ESC closes attributes before leaving Shop")
	check(shop.model.draft_attributes[0] == 0 and profile.attributes[0] == 0,"ESC discards unconfirmed attribute draft")
	check(not shop.gender_button.disabled and not shop.inventory_rows.get_node("Owned_0_0_0").disabled,"Attribute cancel restores underlying controls")
	shop.open_attributes()
	click(shop.add_buttons[0].get_global_rect().get_center())
	await process_frame
	profile.path = "res://.tools/missing-classic-path/profile.json"
	click(shop.attributes_panel.get_node("AttributeBox/SaveAttributes").get_global_rect().get_center())
	await process_frame
	check(shop.attributes_panel.visible and profile.attributes[0] == 0 and not shop.attributes_feedback.text.is_empty(),"Failed attribute save stays open with visible error and rollback")
	profile.path = PROFILE_PATH
	click(shop.attributes_panel.get_node("AttributeBox/SaveAttributes").get_global_rect().get_center())
	await process_frame
	check(not shop.attributes_panel.visible and profile.attributes[0] == 1,"Confirmed attribute draft persists and closes panel")
	reloaded.load_profile()
	check(reloaded.attributes[0] == 1,"Attribute save survives reload")
	shop.toggle_gender()
	await process_frame
	check(profile.gender == 1 and shop.inventory_rows.get_node_or_null("Owned_1_0_0") != null and shop.inventory_rows.get_node_or_null("Owned_0_0_1") == null,"Gender refreshes compatible lateral inventory")
	shop.toggle_gender()
	shop.model.query = "missing"
	shop.refresh(0,0)
	await process_frame
	check(shop.cards.get_child_count() == 0 and shop.inventory_rows.get_node_or_null("Owned_0_0_1") != null,"Empty catalog page keeps owned inventory available")
	shop.model.query = ""
	shop.refresh(0,0)
	scene.show_menu()
	scene.opening = 0
	scene.start_match()
	check(scene.actor_avatars[0]["0"] == "0:0:1" and scene.model.actors[0].attributes[0] == 1,"Lateral outfit and committed attributes enter battle")
	scene.queue_free()
	await process_frame
	for path in [PROFILE_PATH,"res://.tools/classic-shop-test-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Pagination traverses every catalog entry once, retaining order with partial last page.
	var entries: Array = []
	for i in range(20):
		entries.append({"key":"0:0:%d" % i,"gender":0,"category":0,"id":i,"name":"Item %d" % i})
	var catalog = load("res://scripts/avatar_catalog.gd").new(entries)
	var model = load("res://scripts/avatar_shop_model.gd").new(profile,catalog)
	var keys: Array = []
	for page in range(3):
		var rows: Array = model.filter(0,"",false,page)
		check(rows.size() == (2 if page==2 else 9),"Nine-entry pages and partial final page")
		for entry in rows:
			keys.append(entry.key)
	check(keys.size() == 20 and keys == entries.map(func(item): return item.key),"Pagination never duplicates or skips avatars")
	finish("CLASSIC SHOP CHECKS")
