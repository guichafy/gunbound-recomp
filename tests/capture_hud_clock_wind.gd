extends "res://tests/capture_battle_hud_layout.gd"
## Native indicator proof: all four wind cardinals, calm and fractional clock.
const CLOCK_OUT := "res://docs/battle-hud-layout/clock-wind/"
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CLOCK_OUT))
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(PROFILE)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.scale=Vector2.ONE*1.35
	scene.position=Vector2(96,0)
	var cases: Array=[]
	for entry in [["right",0,26],["up",90,26],["left",180,26],["down",270,26],["calm",0,0]]:
		scene.show_menu()
		scene.select_vehicle(2)
		scene.select_cpu_vehicle(1)
		scene.opening=0
		scene.match_seed=42
		scene.start_match()
		scene.model.weather.wind_angle=entry[1]
		scene.model.weather.wind_force=entry[2]
		scene.model.wind=scene.model.weather.wind_vector()
		scene.model.turn_time=12.7
		(await picture()).save_png(CLOCK_OUT+str(entry[0])+"-12.7.png")
		var pause_hash := ""
		var count := 0
		var resumed := false
		for frame in 120:
			scene.paused=frame>=30 and frame<60
			scene._process(1.0/60)
			var image := await picture()
			assert(image.get_size()==Vector2i(1920,1080))
			if frame==30:pause_hash=digest(image)
			if frame>=30 and frame<60:
				assert(digest(image)==pause_hash)
				count+=1
			if frame==75:resumed=digest(image)!=pause_hash
			if frame in [30,59,75]:image.save_png(CLOCK_OUT+"%s-%03d.png"%[entry[0],frame])
		assert(resumed and count==30)
		cases.append({"case":entry[0],"angle":entry[1],"force":entry[2],"frames":120,"pause_frames":count,"rgba_sha256":pause_hash,"resumed":resumed})
		scene.paused=false
	for value in [30.0,9.9,0.0]:
		scene.model.turn_time=value
		(await picture()).save_png(CLOCK_OUT+"time-%.1f.png"%value)
	scene.hud.client_assets.files.erase("NativeWindTexture.png")
	scene.hud.client_assets._cache.erase("NativeWindTexture.png")
	scene.hud.client_assets.files.erase("NativeTimerFraction.png")
	scene.hud.client_assets._cache.erase("NativeTimerFraction.png")
	(await picture()).save_png(CLOCK_OUT+"fallback.png")
	var file := FileAccess.open(CLOCK_OUT+"capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"clock_hz":60,"frames":600,"cases":cases},"\t")+"\n")
	file.close()
	scene.queue_free()
	await process_frame
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CLOCK WIND GPU:600 frames,5x30paused identical,resume verified")
	quit()
