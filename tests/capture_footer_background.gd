extends "res://tests/capture_battle_hud_layout.gd"
## ADR-136: opaque footer, native scanline coverage and real HUD states.
const QA_OUT := "res://docs/footer-background/"
const QA_PROFILE := "res://.tools/footer-background/profile.json"
class BackdropProbe extends Node2D:
	var paint: Texture2D
	var backdrop := Color.MAGENTA
	func _draw() -> void:
		draw_rect(Rect2(0,0,800,44),backdrop)
		draw_texture(paint,Vector2.ZERO)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(QA_OUT))
	for path in [QA_PROFILE,QA_PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(QA_PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.scale=Vector2.ONE*1.35
	scene.position=Vector2(96,0)
	var cases: Array=[]
	for mode in ["slice","drag","left","right"]:
		scene.show_menu()
		scene.select_vehicle(2)
		scene.select_cpu_vehicle(1)
		scene.options.aiming=0 if mode=="drag" else 1
		scene.opening=0
		scene.match_seed=42
		scene.start_match()
		if mode=="slice":scene.begin_charge()
		if mode=="drag":
			scene.begin_drag(300)
			scene.update_drag(390,90)
		var pause_hash := ""
		var paused_frames := 0
		var resumed := false
		for frame in 120:
			if mode in ["left","right"]:
				key(KEY_LEFT if mode=="left" else KEY_RIGHT,frame<90)
			scene.paused=frame>=30 and frame<60
			scene._process(1.0/60)
			if mode in ["left","right"]:
				assert(scene.hud.move_active==(frame<90))
			var pixels := await picture()
			assert(pixels.get_size()==Vector2i(1920,1080))
			if frame==30:pause_hash=digest(pixels)
			if frame>=30 and frame<60:
				assert(digest(pixels)==pause_hash,"Pause changed: "+mode)
				paused_frames+=1
			if frame==75:resumed=digest(pixels)!=pause_hash
			if frame in [0,1,29,30,59,75,90,119]:pixels.save_png(QA_OUT+"%s-%03d.png"%[mode,frame])
		assert(paused_frames==30 and resumed)
		cases.append({"mode":mode,"frames":120,"paused_identical":30,"resumed":resumed,"pause_sha256":pause_hash})
		scene.paused=false
		scene.aim.charging=false
	# Native-pixel GPU probe: changing the background cannot affect frame1.
	var viewport := SubViewport.new()
	viewport.size=Vector2i(800,44)
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var probe := BackdropProbe.new()
	probe.paint=scene.hud.client_assets.texture("NativeFooter.png")
	probe.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(probe)
	var probe_hash := ""
	for color in [Color.MAGENTA,Color.GREEN]:
		probe.backdrop=color
		probe.queue_redraw()
		await process_frame
		RenderingServer.force_draw(false)
		var pixels := viewport.get_texture().get_image()
		if probe_hash.is_empty():probe_hash=digest(pixels)
		assert(digest(pixels)==probe_hash,"World background leaked through footer")
		pixels.save_png(QA_OUT+"probe-%s.png"%("magenta" if color==Color.MAGENTA else "green"))
	viewport.queue_free()
	# Failed native record draws the retained client-derived ActionBar fallback.
	scene.hud.client_assets.files.erase("NativeFooter.png")
	scene.hud.client_assets._cache.erase("NativeFooter.png")
	(await picture()).save_png(QA_OUT+"footer-fallback.png")
	var file := FileAccess.open(QA_OUT+"capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"frames":480,"clock_hz":60,"cases":cases,"probe_size":[800,44],"probe_background_independent":true,"probe_rgba_sha256":probe_hash,"sound":"muted"},"\t")+"\n")
	file.close()
	scene.queue_free()
	await process_frame
	for path in [QA_PROFILE,QA_PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("FOOTER GPU:480 frames1920x1080;4x30pause/resume;opaque native probe;fallback")
	quit()
