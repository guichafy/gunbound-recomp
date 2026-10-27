extends SceneTree
## ADR-130 smoke for an exported pack. Copy outside the project and run with
## --main-pack <PCK> --script <copy>. Prints SHOP ORIGINAL PCK: OK/FAIL.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	var path := "/private/tmp/shop-original-pck-profile.json"
	for file in [path,path.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(file)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(path)
	scene.profile.gold = 50000
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_shop()
	await process_frame
	var shop = scene.shop
	var art = shop.art
	var failures: Array = []
	if art.frames.size() != 171:
		failures.append("frame count %d" % art.frames.size())
	for key in art.frames:
		if art.native_texture(key) == null or art.hd_texture(key) == null:
			failures.append("frame "+key)
	var catalog_rows: Array = shop.model.catalog.entries.values().filter(func(item): return item.get("source")=="xfs")
	if catalog_rows.size() != 562:
		failures.append("catalog %d" % catalog_rows.size())
	for item in catalog_rows:
		if not str(item.portrait).is_empty() and not ResourceLoader.exists(item.portrait):
			failures.append("portrait "+str(item.key))
	if shop.cards.get_child(3).position != Vector2(21,230):
		failures.append("card grid")
	if shop.avatar_art.use_hd or shop.avatar_art.sample(scene.profile.equipped_set(),0.0).any(func(piece): return piece.hd):
		failures.append("avatar not native")
	shop.model.select("xfs:0:0:1")
	shop.refresh(0,0)
	shop.open_buy()
	await process_frame
	if not is_instance_valid(shop.modal):
		failures.append("purchase window")
	else:
		shop.modal.get_node("GoldPurchase").pressed.emit()
		await process_frame
		if not scene.profile.owns("xfs:0:0:1") or scene.profile.gold != 40000:
			failures.append("purchase")
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("/private/tmp/shop-original-pck.png")
	print("SHOP ORIGINAL PCK: ", "OK" if failures.is_empty() else "FAIL "+str(failures))
	scene.queue_free()
	await process_frame
	for file in [path,path.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(file)
	quit(0 if failures.is_empty() else 1)
