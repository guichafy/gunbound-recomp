extends SceneTree
## Native storefront and saved offline outfits; always an isolated profile.
const PROFILE := "res://.tools/avatar-offline-capture.json"
const OUTPUT := "res://docs/avatar-offline-access/"
var scene
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	# Leaving the shop restores the previous window size; capture all screens HD.
	if scene.screen!="shop":
		root.content_scale_size=Vector2i(1280,800)
		root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size=Vector2i(1920,1080)
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var image := root.get_texture().get_image()
	print("CAPTURE ",name," window=",root.size," image=",image.get_size()," mode=",root.content_scale_mode)
	# Canvas-items rendering excludes the window's 96px side letterboxes.
	var expected := Vector2i(1920,1080) if scene.screen=="shop" else Vector2i(1728,1080)
	assert(image.get_size()==expected)
	assert(image.save_png(OUTPUT+name+".png")==OK)
func run() -> void:
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	assert(scene.profile.owned.size()==74)
	scene.show_shop()
	await process_frame
	var shop=scene.shop
	shop.set_process(false)
	shop.elapsed=0.5
	shop.equip_inventory("xfs:0:0:73")
	shop.equip_inventory("xfs:0:1:74")
	shop.refresh(0,8)
	assert(shop.cards.get_children().any(func(card): return card.item.gender==0))
	assert(shop.cards.get_children().any(func(card): return card.item.gender==1))
	shop.model.select("xfs:0:0:73")
	shop.refresh(0,8)
	await snap("mixed-genders-male-skeleton")
	shop.equip_inventory("xfs:1:0:77")
	shop.equip_inventory("xfs:1:1:74")
	shop.model.select("xfs:1:0:77")
	shop.refresh(0,shop.model.page_for("xfs:1:0:77",0))
	assert(shop.buy_button.disabled)
	await snap("female-skeleton")
	shop.equip_inventory("xfs:2:3:170")
	await snap("offline-skeleton-sword")
	scene.leave_shop()
	scene.show_menu()
	await snap("room-skeleton")
	scene.opening=0
	scene.set_process(true)
	scene.begin_loading()
	await snap("loading-skeleton")
	var deadline := Time.get_ticks_msec()+10000
	while scene.screen!="match" and Time.get_ticks_msec()<deadline:
		await process_frame
	assert(scene.screen=="match")
	scene.set_process(false)
	assert(scene.actor_avatars[0]["0"]=="xfs:1:0:77")
	assert(scene.actor_avatars[0]["1"]=="xfs:1:1:74")
	await snap("battle-skeleton")
	scene.queue_free()
	await process_frame
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("OFFLINE AVATAR CAPTURE: 6 native viewport frames; 1920x1080 window; isolated profile removed")
	quit()
