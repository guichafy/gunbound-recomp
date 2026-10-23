extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	var args:=OS.get_cmdline_user_args()
	var destination: String=args[0] if not args.is_empty() else "res://docs/shop-test-funds"
	DirAccess.make_dir_recursive_absolute(destination)
	var path:="/private/tmp/shop-test-funds-pck-profile.json"
	DirAccess.remove_absolute(path)
	var Profile=load("res://scripts/profile.gd")
	var legacy=Profile.new(path)
	legacy.gold=123
	legacy.cash=456
	legacy.xp=600
	legacy.nickname="Carteira teste"
	var data: Dictionary=legacy.snapshot()
	data.shop.erase("test_funds_granted")
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=Profile.new(path)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	assert(scene.profile.gold==999999999 and scene.profile.cash==999999999,"Game startup upgrades the existing wallet once")
	assert(scene.profile.xp==600 and scene.profile.nickname=="Carteira teste")
	scene.show_shop()
	await process_frame
	RenderingServer.force_draw()
	assert(root.get_texture().get_image().save_png(destination+"/wallet.png")==OK)
	var purchases:=[{"key":"xfs:0:0:71","currency":"gold"},{"key":"xfs:0:1:1","currency":"cash"}]
	for purchase in purchases:
		assert(scene.profile.purchase(purchase.key,purchase.currency)=="ok")
		assert(scene.profile.equip(purchase.key))
	assert(scene.profile.gold==999679999 and scene.profile.cash==999997999)
	var equipment: Dictionary=scene.profile.equipped_set()
	scene.queue_free()
	await process_frame
	var reopened=load("res://scenes/main.tscn").instantiate()
	reopened.profile=Profile.new(path)
	root.add_child(reopened)
	reopened.set_process(false)
	reopened.sound.muted=true
	assert(reopened.profile.gold==999679999 and reopened.profile.cash==999997999,"Reopening the actual game does not refill spent currency")
	assert(reopened.profile.equipped_set()==equipment and reopened.profile.xp==600)
	reopened.start_match()
	assert(reopened.actor_avatars[0]==equipment,"Purchased equipment is used in battle")
	reopened.queue_free()
	await process_frame
	for target in [path,path.get_basename()+"-options.json"]:DirAccess.remove_absolute(target)
	print("TEST WALLET PCK: startup999999999 / Gold+Cash purchases / equip / reopen / battle PASS")
	quit()
