extends "res://tests/support/suite.gd"
## ADR-130: Avatar Shop drawn from the original client frames. Expected values
## are written from the client routines (0x44a000, 0x44c460, 0x4ed9f0) and the
## gb-avatar.png measurements, independently of the shop implementation.
const PATH := "res://.tools/shop-original-test.json"
const ShopArt = preload("res://scripts/classic_shop_art.gd")
func click(node: Control) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed=pressed
		event.position=node.get_global_rect().get_center()
		event.global_position=event.position
		root.push_input(event)
func textures(node: Node, found: Array) -> Array:
	for property in ["texture","texture_normal","texture_hover","texture_pressed","texture_disabled"]:
		if property in node and node.get(property) is Texture2D:
			var paint: Texture2D = node.get(property)
			found.append(paint.atlas.resource_path if paint is AtlasTexture and paint.atlas else paint.resource_path)
	for child in node.get_children():
		textures(child,found)
	return found
func run() -> void:
	var art = ShopArt.new()
	# Every frame of the native catalog loads and has a valid 4× derivative.
	var missing: Array = []
	for key in art.frames:
		if art.native_texture(key) == null or art.hd_texture(key) == null:
			missing.append(key)
	check(art.frames.size() == 171 and missing.is_empty(),"171 original frames load natively and as BICUBIC4×: %s" % str(missing))
	for entry in ["store_back","store_avatar","store_myavatar","store_icon","b_store_buy","b_store_puton","b_myavatar_dry","b_store_cashcharge","b_scroll_up"]:
		check(art.frame_count(entry) > 0 and art.has(entry+":0"),"Client entry extracted: "+entry)
	check(art.size("store_back:0") == Vector2(800,600) and art.pivot("store_myavatar:0") == Vector2(0,104),"Native sizes and IMG pivots are preserved")
	check(art.size("font:0") == Vector2(128,96),"font.fnt half-width table becomes a 16×8 glyph atlas")
	# Fallback: a damaged derivative catalog keeps the native frame.
	var broken = ShopArt.new(ShopArt.NATIVE,"res://.tools/no-shop-hd/")
	check(broken.texture("store_back:0") == broken.native_texture("store_back:0"),"Missing 4× catalog falls back to the native frame")
	art.use_hd = false
	check(art.texture("b_store_buy:0") == art.native_texture("b_store_buy:0") and art.density("b_store_buy:0") == 1.0,"Native mode never samples the derivative")
	art.use_hd = true
	# 0x44c460 with "%8d": 1000 → '1' at +44, comma at +54, zeros at +58/+68/+78.
	var cash: Array = ShopArt.price_layout(50,279,1000,Vector2(14,110))
	check(cash == [["numfont:51",Vector2(58,110)],["numfont:279",Vector2(68,110)],["numfont:50",Vector2(72,110)],["numfont:50",Vector2(82,110)],["numfont:50",Vector2(92,110)]],"Cash price follows the client advance and comma rule: %s" % str(cash))
	var gold: Array = ShopArt.price_layout(60,280,10000,Vector2(14,126))
	check(gold.size() == 6 and gold[0] == ["numfont:61",Vector2(48,126)] and gold[2] == ["numfont:280",Vector2(68,126)] and gold[5] == ["numfont:60",Vector2(92,126)],"Gold price uses the cyan digits and comma 280")
	var large: Array = ShopArt.price_layout(50,279,1234567,Vector2.ZERO)
	check(large.map(func(e): return e[0]) == ["numfont:51","numfont:279","numfont:52","numfont:53","numfont:54","numfont:279","numfont:55","numfont:56","numfont:57"],"Seven digits draw both group commas")
	check(ShopArt.digits_layout(40,"%02d" % 3,Vector2(123,35),6,2) == [["numfont:40",Vector2(123,35)],["numfont:43",Vector2(129,35)]],"Status digits use %02d, base 40, advance 6")
	check(ShopArt.digits_layout(0,"%3d" % 6,Vector2(745,16),8,3) == [["numfont:6",Vector2(761,16)]],"LCD skips leading blanks and keeps the last cell at 761")
	# Scene: original composition, no search/extras, real interaction.
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size=Vector2i(1920,1080)
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(PATH)
	scene.profile.gender=1
	scene.profile.gold=50000
	scene.profile.cash=5000
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.show_shop()
	await process_frame
	var shop=scene.shop
	shop.set_process(false)
	var Shop = shop.get_script()
	# shot_delay shows "+" for ≤0 (negated); others "−" only below zero.
	check(Shop.stat_icon(4,8,-3) == [9,3] and Shop.stat_icon(4,8,2) == [8,2] and Shop.stat_icon(4,8,0) == [9,0],"Shot delay sign rule from SETLE+NEG")
	check(Shop.stat_icon(1,16,-5) == [16,5] and Shop.stat_icon(1,16,3) == [17,3] and Shop.stat_icon(7,10,0) == [11,0],"Other stats sign rule from SETL+NEG")
	var catalog = shop.model.catalog
	check(shop.stat_entries(catalog.find("xfs:1:0:9")) == [[9,3],[11,3],[19,3]],"Rabbit Hair: shot delay, popularity, item delay (gb-avatar.png)")
	check(shop.stat_entries(catalog.find("xfs:1:0:6")) == [[11,3],[17,3]],"Pucca Hair: popularity before health (gb-avatar.png)")
	check(shop.stat_entries(catalog.find("xfs:1:1:1")) == [[13,3],[15,3]],"Space Marine body: attack then defense")
	check(shop.stat_entries(catalog.find("xfs:1:2:1")) == [[11,6],[21,3]],"Battle Goggle: popularity then bunge")
	check(not ("search" in shop),"No search field in the original store")
	var line_edits := root.find_children("*","LineEdit",true,false).filter(func(node): return shop.is_ancestor_of(node))
	check(line_edits.is_empty(),"Shop has no text input")
	for i in range(shop.cards.get_child_count()):
		var card = shop.cards.get_child(i)
		check(card.position == Vector2(21+(i%3)*163,69+int(i/3)*161) and card.size == Vector2(160,156),"Card %d at the 0x44a000 grid" % i)
	var first = shop.cards.get_child(0)
	check(first.get_node("Portrait").texture.resource_path == first.item.portrait and first.item.portrait.begins_with("res://assets/xfs/avatars/s"),"Card portrait is the original s*.img thumbnail")
	check(first.get_node("AvatarName").text == "Space Marine" and first.get_node("AvatarName").position == Vector2(24,5),"Name uses the measured bitmap-font slot")
	var used: Array = textures(shop,[])
	var generated := used.filter(func(path): return str(path).begins_with("res://assets/hd/shop/") or str(path).begins_with("res://assets/hd/avatars/"))
	check(generated.is_empty(),"No GPT shop/avatar HD texture in the shop tree: %s" % str(generated))
	check(shop.try_button.texture_normal == shop.art.texture("b_store_puton:0") and shop.try_button.texture_disabled == shop.art.texture("b_store_puton:3"),"Try uses b_store_puton ready/disable frames")
	check(shop.category_buttons[0].texture_normal == shop.art.texture("b_store_cap:4") and shop.category_buttons[1].texture_normal == shop.art.texture("b_store_cloth:0"),"Active category shows EPA frame 4")
	var expected := {"b_store_puton":Vector2(359,556),"b_store_buy":Vector2(448,556),"b_myavatar_sell":Vector2(566,513),"b_myavatar_dry":Vector2(639,513),"b_myavatar_gift":Vector2(712,513),"b_store_exit":Vector2(562,550),"b_store_buddygame":Vector2(680,550),"b_store_cashcharge":Vector2(485,7),"b_store_up":Vector2(517,80),"b_store_down":Vector2(517,488),"b_scroll_up":Vector2(759,117),"b_scroll_down":Vector2(759,326)}
	for entry in expected:
		var node = shop.content.get_node_or_null(entry)
		check(node != null and node.position == expected[entry] and node.size == shop.art.size(entry+":0"),"Measured position of "+entry)
	for i in range(4):
		check(shop.category_buttons[i].position == Vector2(35+53*i,556),"Category %d at gb-avatar.png slot" % i)
	check(shop.content.get_global_rect().size.distance_to(Vector2(1440,1080)) < 0.01,"800×600 stage fills Full HD height")
	check(shop.gender_button.get_global_rect().position.x >= shop.content.get_global_rect().end.x and shop.attributes_button.get_global_rect().position.x >= shop.content.get_global_rect().end.x,"Non-original controls stay in the letterbox")
	root.size=Vector2i(1280,800)
	await process_frame
	await process_frame
	var stage: Rect2=shop.content.get_global_rect()
	for node in [shop.gender_button,shop.attributes_button,shop.status_label]:
		var rect: Rect2=node.get_global_rect()
		check(not rect.intersects(stage) and Rect2(Vector2.ZERO,Vector2(1280,800)).encloses(rect),"1280×800 letterbox control never covers the stage: "+str(node.name))
	root.size=Vector2i(1920,1080)
	await process_frame
	await process_frame
	# Interaction: select, Try preview, Laundry restore, buy once.
	var equipped: Dictionary = scene.profile.equipped_set().duplicate(true)
	click(first)
	await process_frame
	check(shop.model.selected_key == "xfs:1:0:1" and shop.cards.get_child(0).selected,"Card click selects with store_avatar frame 1")
	click(shop.try_button)
	await process_frame
	check(shop.model.preview["0"] == "xfs:1:0:1" and scene.profile.equipped_set() == equipped and shop.try_state == "Experimentar","Try previews without equipping")
	click(shop.laundry_button)
	await process_frame
	check(shop.model.preview == equipped and shop.model.selected_key.is_empty(),"Laundry restores the dressed set and clears the selection")
	click(shop.cards.get_child(0))
	await process_frame
	click(shop.buy_button)
	await process_frame
	check(is_instance_valid(shop.modal) and shop.modal.get_node("PurchasePanel").texture == shop.art.texture("store_window_back:1"),"Buy opens the original BUY ITEM window")
	if is_instance_valid(shop.modal):
		var panel: Control = shop.modal
		check(panel.get_node("GoldPurchase").texture_normal == shop.art.texture("b_storewindow_gold:0") and panel.get_node("CashPurchase") != null,"Both priced currencies use the original buttons")
		click(panel.get_node("GoldPurchase"))
		await process_frame
		check(scene.profile.owns("xfs:1:0:1") and scene.profile.gold == 40000 and scene.profile.cash == 5000,"Gold purchase debits once")
	check(shop.inventory_rows.get_node_or_null("Owned_xfs_1_0_1") != null,"Bought item appears in the original inventory list")
	click(shop.inventory_rows.get_node("Owned_xfs_1_0_1"))
	await process_frame
	check(scene.profile.equipped_set()["0"] == "xfs:1:0:1","Inventory row click equips")
	check(shop.sell_button.disabled and shop.gift_button.disabled and shop.buddy_button.disabled and shop.charge_button.disabled,"Network/money actions keep the original disable frame")
	# Avatars everywhere use the native XFS pieces (user decision 1).
	var pieces: Array = shop.avatar_art.sample(scene.profile.equipped_set(),0.0)
	check(not pieces.is_empty() and pieces.all(func(piece): return not piece.hd),"Preview avatar uses native XFS pieces")
	check(not load("res://scripts/avatar_art.gd").new().use_hd and not load("res://scripts/mobile_rig.gd").new("bigfoot").avatars.use_hd,"Room/battle rig defaults to native avatar pieces")
	scene.queue_free()
	await process_frame
	for path in [PATH,PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("ORIGINAL SHOP CHECKS")
