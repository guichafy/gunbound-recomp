extends SceneTree
var checks := 0
var failures := 0
const PATH := "res://.tools/shop-parity-profile.json"
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",description)
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
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PATH)
	root.size = Vector2i(1280,800)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_shop()
	await process_frame
	var shop = scene.shop
	var skin = shop.cards.get_child(0).get_theme_stylebox("normal")
	check(not skin is StyleBoxTexture or skin.texture_margin_top<=22,"HD card border is not enlarged by source texture density")
	var expected := [13,17,15,23,9,19,21,11] # AttributeMenu.AddAttributePoints C#.
	for i in range(8):
		var graphic = shop.attributes_panel.get_node_or_null("AttributeBox/AttributeIcon%d" % i)
		check(graphic != null,"Original attribute icon visible in edit panel %d" % i)
		if graphic != null:
			var source: Rect2 = graphic.texture.region
			var native_scale: float = graphic.texture.atlas.get_width()/156.0
			check(source.position/native_scale == Vector2(expected[i]%6,int(expected[i]/6))*Vector2(26,17),"Attribute icon identity matches C# %d" % i)
	check(shop.has_method("animation_frame"),"Animation intervals can be sampled consistently")
	if shop.has_method("animation_frame"):
		check(shop.animation_frame(shop.animated[1],1,2.0) == 0,"Body hover follows forward repeating source")
		check(shop.animation_frame(shop.animated[7],1,2.0) == 0,"Gift hover follows forward repeating source")
		check(shop.animation_frame(shop.animated[4],1,0.5) == 11,"Exit hover uses 23 FPS")
		check(shop.animation_frame(shop.animated[4],2,0.5) == 25,"Exit click uses 25 FPS")
		check(shop.animation_frame(shop.animated[5],1,0.0) == 1,"Left arrow hover starts at one")
		check(shop.animation_frame(shop.animated[5],1,0.5) == 15,"Left arrow hover uses 28 FPS")
		check(shop.animation_frame(shop.animated[8],1,1.0) == 17,"Buy hover returns backward like FlipbookAnimationCycle")
		check(shop.animation_frame(shop.animated[9],1,1.7) == 36,"Try hover returns backward like FlipbookAnimationCycle")
		check(shop.animation_frame(shop.animated[8],2,1.0) == 0,"Buy click completes then returns to queued normal")
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
	shop._process(0.15)
	check(shop.model.page==1 and shop.animated[6].state==2,"Release triggers arrow click animation and changes page")
	var cell: Vector2 = shop.animated[6].cell*shop.density(shop.animated[6].path)
	var source: Rect2 = shop.right_button.texture_normal.region
	check(source.position==Vector2(4,1)*cell,"Released arrow continues source click sequence at 28 FPS")
	shop._process(1.0)
	check(shop.animated[6].state==0,"Completed arrow click returns to queued normal")
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
	check(panel.get_rect().size.is_equal_approx(Vector2(228,286)*1.6),"HD popup keeps native logical dimensions")
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
	check(is_equal_approx(gold_button.get_rect().get_center().x,640.0),"Single Gold payment is centered")
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
	print("SHOP PARITY CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
