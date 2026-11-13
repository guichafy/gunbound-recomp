extends SceneTree
## GPU oracle: compare the actual room/loading renderer against explicit
## battle-default equipment, at identical pixel coordinates and clock.
const OUT := "res://.tools/room-rider/"
const PROFILE := OUT+"capture-profile.json"
var scene
func _initialize() -> void: call_deferred("run")
func expected(canvas: Node2D) -> void:
	for sprite in scene.sprites.values():
		if sprite.has_method("begin_hull_glow"): sprite.begin_hull_glow(canvas)
	var a: int = scene.loading_player if scene.screen == "loading" else scene.vehicle
	var b: int = scene.loading_cpu if scene.screen == "loading" else scene.resolved_cpu_id()
	scene.draw_figure(canvas,a,scene.menu.player_anchor,1,scene.profile.equipped_set())
	scene.draw_figure(canvas,b,scene.menu.cpu_anchor,-1,scene.profile.catalog.defaults(0))
func snap(path: String) -> Image:
	scene.menu.figures.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	return image
func run() -> void:
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.scale = Vector2.ONE*1.35
	scene.position = Vector2(96,0)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_menu()
	var tag := "capture"
	if not OS.get_cmdline_user_args().is_empty(): tag = OS.get_cmdline_user_args()[0]
	var report: Array = []
	for gender in [0,1]:
		scene.profile.gender = gender
		var equipped: Dictionary = scene.profile.catalog.defaults(gender)
		if gender == 1: equipped["0"] = scene.profile.catalog.key_for(1,0,1)
		scene.profile.equipped[str(gender)] = equipped
		for id in [1,2,3,4,13,16]:
			scene.select_vehicle(id)
			scene.select_cpu_vehicle(id)
			for mode in ["menu","loading"]:
				scene.screen = mode
				scene.loading_player = id
				scene.loading_cpu = id
				scene.elapsed = 0.35
				var name := "%s-%s-%d-%d" % [tag,mode,gender,id]
				scene.menu.figures.paint = scene.draw_room_figures
				var actual := await snap(OUT+name+"-actual.png")
				scene.menu.figures.paint = expected
				var wanted := await snap(OUT+name+"-expected.png")
				report.append({"case":name,"equal":actual.get_data()==wanted.get_data()})
	# Exercise the real Start transition and battle view, with both genders.
	for gender in [0,1]:
		scene.profile.gender = gender
		for id in [1,2,3,4,13,16]:
			scene.show_menu()
			scene.select_vehicle(id)
			scene.select_cpu_vehicle(id)
			scene.elapsed = 0.35
			scene.menu.figures.paint = scene.draw_room_figures
			scene.begin_loading()
			await snap(OUT+"%s-live-loading-%d-%d.png" % [tag,gender,id])
			scene.opening = 0
			# Two legal Miramo spawn columns keep both actors inside one view.
			scene.start_match(id,id,[Vector2(743,0),Vector2(1041,0)])
			scene.menu.figures.paint = scene.draw_room_figures
			scene.queue_redraw()
			await snap(OUT+"%s-battle-%d-%d.png" % [tag,gender,id])
	var file := FileAccess.open(OUT+tag+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	scene.free()
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var passed := report.filter(func(r): return r.equal).size()
	print("ROOM RIDER GPU: ",passed,"/",report.size()," exact comparisons")
	quit(0 if passed == report.size() else 1)
