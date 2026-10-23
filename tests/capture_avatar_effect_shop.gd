extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	var args:=OS.get_cmdline_user_args()
	var destination: String=args[0] if not args.is_empty() else "res://docs/avatar-effects"
	DirAccess.make_dir_recursive_absolute(destination)
	var path:="/private/tmp/avatar-effect-shop-profile.json"
	DirAccess.remove_absolute(path)
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(path)
	scene.profile.gold=1000000000
	scene.profile.cash=1000000000
	assert(scene.profile.purchase("xfs:0:0:71","gold")=="ok")
	assert(scene.profile.equip("xfs:0:0:71"))
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.show_shop()
	await process_frame
	var shop=scene.shop
	var horn: Dictionary=shop.avatar_art.xfs_hd.piece("xfs:0:0:71",1)
	assert(not horn.is_empty() and horn.source.size.x/horn.source.size.y<1.1)
	shop.set_process(false)
	shop.search.text="Great Devil"
	shop.model.query=shop.search.text
	shop.refresh(0,0)
	for mobile in [false,true]:
		shop.set_preview_mode(mobile)
		shop.elapsed=.3
		shop.painter.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		var image:=root.get_texture().get_image()
		assert(image.get_size()==Vector2i(1920,1080))
		assert(image.save_png(destination+"/shop-%s.png" % ("mobile" if mobile else "avatar"))==OK)
	DirAccess.remove_absolute(path)
	print("GREAT DEVIL SHOP GPU: actual equipped preview in1920x1080")
	quit()
