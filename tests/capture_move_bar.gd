extends "res://tests/capture_battle_hud_layout.gd"
## ADR-135: move overlay in native footer, entry/expanded/release and pause.
const MOVE_OUT := "res://docs/move-bar/"
const MOVE_PROFILE := "res://.tools/move-bar/capture-profile.json"
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOVE_OUT))
	for path in [MOVE_PROFILE,MOVE_PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(MOVE_PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.scale=Vector2.ONE*1.35
	scene.position=Vector2(96,0)
	var cases: Array=[]
	for direction in [-1,1]:
		scene.show_menu()
		scene.select_vehicle(2)
		scene.select_cpu_vehicle(1)
		scene.opening=0
		scene.match_seed=42
		scene.start_match()
		var code := KEY_LEFT if direction<0 else KEY_RIGHT
		key(code,true)
		var paused_hash := ""
		var count := 0
		var resumed := false
		for frame in 120:
			# Keep injected input deterministic if the OS clears keys on focus.
			key(code,frame<90)
			scene.paused=frame>=30 and frame<60
			scene._process(1.0/60)
			if frame<90:assert(scene.hud.move_active,"MOVE must stay visible through pause/resume")
			if frame==0:assert(scene.hud.move_active and not scene.hud.move_expanded)
			if frame==1:assert(scene.hud.move_active and scene.hud.move_expanded)
			if frame>=90:assert(not scene.hud.move_active)
			var image := await picture()
			assert(image.get_size()==Vector2i(1920,1080))
			if frame==30:paused_hash=digest(image)
			if frame>=30 and frame<60:
				if digest(image)!=paused_hash:
					image.save_png("res://.tools/move-bar/pause-difference.png")
					push_error("Pause differs at frame %d direction %d"%[frame,direction])
					quit(1)
					return
				count+=1
			if frame==75:resumed=digest(image)!=paused_hash
			if frame in [0,1,29,30,59,75,90,119]:image.save_png(MOVE_OUT+"%s-%03d.png"%["left" if direction<0 else "right",frame])
		assert(resumed and count==30)
		cases.append({"direction":direction,"frames":120,"paused_identical":count,"pause_rgba_sha256":paused_hash,"resumed":resumed,"entry_stage":0,"next_stage":1,"released_hidden":true})
		scene.paused=false
	# Static visual fractions do not change the movement rule; these are fixtures.
	scene.hud.update_movement(true)
	scene.hud.update_movement(true)
	for fraction in [0.0,0.5,1.0]:
		scene.model.movement_left=scene.model.movement_budget()*fraction
		(await picture()).save_png(MOVE_OUT+"fill-%03d.png"%int(fraction*100))
	scene.model.movement_left=scene.model.movement_budget()*0.5
	scene.hud.move_expanded=false
	var reference := await picture()
	reference.save_png(MOVE_OUT+"compact-reference.png")
	var record: Dictionary=scene.hud.client_assets.files["NativeMoveExpanded.png"].duplicate(true)
	scene.hud.move_expanded=true
	scene.hud.client_assets.files.erase("NativeMoveExpanded.png")
	scene.hud.client_assets._cache.erase("NativeMoveExpanded.png")
	var missing := await picture()
	assert(digest(missing)==digest(reference),"Missing frame6 must draw compact native fallback")
	missing.save_png(MOVE_OUT+"fallback-missing.png")
	record.rgba_sha256="invalid"
	scene.hud.client_assets.files["NativeMoveExpanded.png"]=record
	scene.hud.client_assets._cache.erase("NativeMoveExpanded.png")
	var invalid := await picture()
	assert(digest(invalid)==digest(reference),"Invalid frame6 must draw compact native fallback")
	invalid.save_png(MOVE_OUT+"fallback-invalid.png")
	var file := FileAccess.open(MOVE_OUT+"capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"frames":240,"clock_hz":60,"cases":cases,"fallback_matches_compact":true,"fallback_rgba_sha256":digest(reference),"fill_samples":[0,50,100],"sound":"muted"},"\t")+"\n")
	file.close()
	scene.queue_free()
	await process_frame
	for path in [MOVE_PROFILE,MOVE_PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MOVE GPU:240frames1920x1080;2x30pause;entry/expand/release;2fallbacks exact")
	quit()
