extends "res://tests/support/suite.gd"
const PATH := "res://.tools/shop-parity-profile.json"
func animation(shop, name: String) -> Dictionary:
	for entry in shop.animated:
		if str(entry.path).get_file()==name:
			return entry
	return {}
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
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://tests/legacy_profile.gd").new(PATH)
	root.size = Vector2i(1280,800)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_shop()
	await process_frame
	var shop = scene.shop
	# Same "+" store_icon the client draws for each status (ADR-130).
	var expected := [13,17,15,23,9,19,21,11]
	for i in range(8):
		var graphic = shop.attributes_panel.get_node_or_null("AttributeBox/AttributeIcon%d" % i)
		check(graphic != null and graphic.texture == shop.art.texture("store_icon:%d" % expected[i]),"Attribute icon %d is the client status glyph" % i)
	check(shop.category_buttons.size()==4,"Four XFS category controls")
	for node in [shop.try_button,shop.buy_button,shop.left_button,shop.right_button]:
		check(node.texture_normal!=node.texture_hover and node.texture_pressed!=node.texture_disabled,"Client buttons have distinct ready mouse push and disable frames")
	# A middle-page arrow stays enabled after release, allowing the source's queued
	# Clicked→Normal sequence to be observed through real viewport input.
	var original_entries: Dictionary = shop.model.catalog.entries.duplicate(true)
	for id in range(5,25):
		var item: Dictionary = original_entries["0:0:1"].duplicate(true)
		item.key = "0:0:%d" % id
		item.id = id
		shop.model.catalog.entries[item.key] = item
	shop.refresh(0,0)
	await process_frame
	shop.set_process(false)
	click(shop.right_button.get_global_rect().get_center())
	check(shop.model.page==1 and not shop.left_button.disabled and not shop.right_button.disabled,"Released XFS arrow advances exactly one page")
	click(shop.left_button.get_global_rect().get_center())
	check(shop.model.page==0 and shop.left_button.disabled,"Reverse arrow restores first page and disables at boundary")
	shop.model.catalog.entries = original_entries
	shop.refresh(0,0)
	# Select without equipping, then buy with a visual confirmation as in PopupBuyAvatar.
	check(shop.model.select("0:0:1"),"Shop selects source avatar")
	shop.refresh(0,0)
	shop.open_buy()
	await process_frame
	var portrait = shop.modal.get_node_or_null("PurchasePortrait")
	check(portrait is TextureRect and portrait.texture != null,"Purchase shows the selected avatar portrait")
	var panel = shop.modal.get_node("PurchasePanel") if shop.modal.has_node("PurchasePanel") else shop.modal.get_child(1)
	check(is_equal_approx(panel.size.x/panel.size.y,313.0/187.0),"HD popup preserves source aspect ratio")
	check(Rect2(Vector2.ZERO,shop.modal.size).encloses(panel.get_rect()),"HD purchase panel fits completely inside screen")
	check(scene.profile.gold == 1000 and not scene.profile.owns("0:0:1"),"Opening/canceling popup never debits or grants avatar")
	shop.close_buy()
	# Single-currency fixture exercises original centered layout and authoritative transaction.
	scene.profile.catalog.entries["0:0:1"].cash_price = 0
	shop.model.catalog.entries["0:0:1"].cash_price = 0
	shop.refresh(0,0)
	shop.open_buy()
	await process_frame
	var gold_button = shop.modal.get_node("GoldPurchase")
	var row: Rect2 = gold_button.get_rect().merge(shop.modal.get_node("CancelPurchase").get_rect())
	check(is_equal_approx(row.get_center().x,shop.modal.size.x*0.5),"Single Gold payment and Cancel are centered")
	check(shop.modal.get_node_or_null("CashPurchase") == null,"Zero-price currency has no purchase button")
	gold_button.pressed.emit()
	await process_frame
	check(scene.profile.gold == 900 and scene.profile.owns("0:0:1"),"Purchase atomically debits source price and grants ownership")
	check(scene.profile.equipped_set()["0"] == "0:0:0","Purchase does not equip automatically")
	check(shop.model.confirm_buy("0:0:1","gold") == "owned" and scene.profile.gold == 900,"Repeated transaction cannot debit twice")
	scene.queue_free()
	await process_frame
	for file in [PATH,"res://.tools/shop-parity-profile-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	finish("SHOP PARITY CHECKS")
