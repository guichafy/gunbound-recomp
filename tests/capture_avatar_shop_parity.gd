extends SceneTree
var scene
var output := "res://docs/avatar-shop-parity/"
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size() == Vector2i(1920,1080))
	assert(image.save_png(output+name+".png") == OK)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/parity-frames"))
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/parity-capture.json")
	scene.profile.xp = 2200
	scene.vehicle = 1
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE*1.35
	scene.position = Vector2(96,0)
	scene.show_shop()
	scene.shop.model.select("0:0:1")
	scene.shop.refresh(0,0)
	scene.shop.open_buy()
	await snap("purchase")
	scene.shop.close_buy()
	scene.shop.model.catalog.entries["0:0:1"].cash_price = 0
	scene.shop.refresh(0,0)
	scene.shop.open_buy()
	await snap("purchase-gold-only")
	scene.shop.close_buy()
	scene.shop.model.catalog.entries["0:0:1"].cash_price = 100
	for key in ["0:0:1","0:0:2","0:0:3","0:1:1","0:1:2","0:1:3","0:2:1","2:3:1"]:
		assert(scene.profile.purchase(key,"gold") == "ok")
	for key in ["0:0:1","0:1:1","0:2:1","2:3:1"]:
		assert(scene.profile.equip(key))
	scene.show_shop()
	scene.shop.elapsed = 0.0
	await snap("shop")
	scene.shop.use_hd = false
	scene.shop.refresh(0,0)
	await snap("native-ui")
	scene.shop.use_hd = true
	scene.shop.refresh(0,0)
	scene.vehicle = 2
	await snap("bigfoot")
	scene.vehicle = 1
	scene.shop.toggle_gender()
	await snap("female")
	scene.shop.toggle_gender()
	scene.shop.refresh(1,0)
	await snap("body")
	scene.shop.switch_tab(true)
	await snap("inventory")
	scene.shop.open_attributes()
	await snap("attributes")
	scene.shop.close_attributes()
	scene.shop.switch_tab(false)
	scene.shop.refresh(0,0)
	assert(scene.shop.model.select("0:0:138")) # Kappa's original ID, not roster slot4.
	scene.shop.refresh(0,0)
	# GPU sequence, deterministic 60Hz clock; rigid approved pieces remain unchanged.
	scene.shop.set_process(false)
	var frame_count := 0 if "--static" in OS.get_cmdline_user_args() else 120
	for frame in range(frame_count):
		var motion := InputEventMouseMotion.new()
		motion.position = scene.shop.try_button.get_global_rect().get_center() if frame<90 else Vector2(1800,100)
		motion.global_position = motion.position
		root.push_input(motion)
		scene.shop.elapsed = (frame-1)/60.0
		scene.shop._process(1.0/60.0)
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://.tools/parity-frames/%04d.png" % frame) == OK)
	scene.queue_free()
	await process_frame
	for path in ["res://.tools/parity-capture.json","res://.tools/parity-capture-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PARITY SHOP GPU: 1920x1080; ",frame_count," frames at 60Hz; shop/body/inventory/attributes/purchase/genders/mobiles")
	quit()
