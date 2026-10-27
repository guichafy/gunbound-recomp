extends SceneTree
## Histórico (pré-ADR-130): usa a loja vetorial/HD substituída; não executar
## contra a loja atual. Evidência vigente: capture_shop_original(_pck).gd.
var scene
var output := "res://docs/avatar-shop-classic/"
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/classic-frames"))
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/classic-capture.json")
	scene.profile.xp = 2200
	scene.vehicle = 1
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE*1.35
	scene.position = Vector2(96,0)
	for key in ["0:0:1","0:0:2","0:0:3","0:1:1","0:1:2","0:1:3","0:2:1","2:3:1"]:
		assert(scene.profile.purchase(key,"gold") == "ok")
	for key in ["0:0:1","0:1:1","0:2:1","2:3:1"]:
		assert(scene.profile.equip(key))
	scene.show_shop()
	scene.shop.elapsed = 0.0
	await snap("shop")
	scene.shop.refresh(1,0)
	await snap("body")
	scene.shop.switch_tab(true)
	await snap("inventory")
	scene.shop.open_attributes()
	await snap("attributes")
	scene.shop.close_attributes()
	scene.shop.switch_tab(false)
	scene.shop.refresh(0,0)
	# GPU sequence, deterministic 60Hz clock; rigid approved pieces remain unchanged.
	scene.shop.set_process(false)
	for frame in range(0 if "--static" in OS.get_cmdline_user_args() else 120):
		scene.shop.elapsed = frame/60.0
		scene.shop.painter.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://.tools/classic-frames/%04d.png" % frame) == OK)
	scene.queue_free()
	await process_frame
	for path in ["res://.tools/classic-capture.json","res://.tools/classic-capture-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CLASSIC SHOP GPU: 1920x1080; 120 frames at 60Hz; shop/body/inventory/attributes")
	quit()
