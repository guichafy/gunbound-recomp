extends SceneTree
## ADR-130 GPU evidence: the original-asset Avatar Shop at 1920×1080, staged
## like gb-avatar.png (girl set, Space Marine body/Battle Goggle/Violet Flag),
## plus native fallback, purchase, other categories, room and battle avatars.
## Writes docs/avatar-shop-original/*.png and a 60 Hz frame sequence in .tools.
var scene
var output := "res://docs/avatar-shop-original/"
var frames := "res://.tools/shop-original-frames/"
const PROFILE := "res://.tools/shop-original-capture.json"
func _initialize() -> void:
	call_deferred("run")
func snap(name: String, folder: String = "") -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var image := root.get_texture().get_image()
	# The shop owns the window at 1920×1080; room/battle use the game canvas.
	assert(image.get_size() == Vector2i(1920,1080) or not name in ["shop","shop-native","purchase"])
	assert(image.save_png((output if folder.is_empty() else folder)+name+".png") == OK)
func run() -> void:
	for path in [output,frames]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size = Vector2i(1920,1080)
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	scene.profile.gender = 1
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	for key in ["xfs:1:0:1","xfs:1:1:1","xfs:1:2:1","xfs:2:3:1","xfs:2:3:3"]:
		assert(scene.profile.purchase(key,"gold") == "ok")
	for key in ["xfs:1:1:1","xfs:1:2:1","xfs:2:3:3"]:
		assert(scene.profile.equip(key))
	scene.show_shop()
	var shop = scene.shop
	shop.set_process(false)
	shop.model.select("xfs:1:1:1")
	shop.refresh(0,0)
	shop.elapsed = 0.0
	await snap("shop")
	shop.use_hd = false
	shop.refresh(0,0)
	await snap("shop-native")
	shop.use_hd = true
	shop.model.select("xfs:1:0:2")
	shop.refresh(0,0)
	shop.open_buy()
	await snap("purchase")
	shop.close_buy()
	for category in [1,2,3]:
		shop.refresh(category,0)
		await snap(["","body","goggles","flags"][category])
	shop.toggle_gender()
	await snap("male")
	shop.toggle_gender()
	shop.refresh(0,0)
	# 60 Hz sequence: avatar idle in the preview, 120 frames.
	shop.set_process(true)
	for i in range(120):
		shop.elapsed = i/60.0
		shop.painter.queue_redraw()
		await snap("%03d" % i,frames)
	shop.set_process(false)
	scene.leave_shop()
	await process_frame
	scene.show_menu()
	await process_frame
	await snap("room")
	scene.opening = 0
	scene.set_process(true)
	scene.start_match()
	for i in range(90):
		await process_frame
	await snap("battle")
	scene.queue_free()
	await process_frame
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit()
