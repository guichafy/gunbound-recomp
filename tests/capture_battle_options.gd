extends SceneTree
## ADR-137: real GPU1920x1080, native menu/input, pause/resume and fallback.
const OUT := "res://docs/battle-options/"
const PROFILE := "res://.tools/battle-menu/capture-profile.json"
var scene
func _initialize() -> void:
	call_deferred("run")
func picture() -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	var pixels:=root.get_texture().get_image()
	assert(pixels.get_size()==Vector2i(1920,1080))
	return pixels
func digest(pixels: Image) -> String:
	var hash:=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(pixels.get_data())
	return hash.finish().hex_encode()
func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=true
	scene._unhandled_key_input(event)
func click(point: Vector2) -> void:
	var physical:=Vector2(96,0)+point*1.35
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position=physical
		event.global_position=physical
		root.push_input(event)
func snap(name: String) -> String:
	var pixels:=await picture()
	assert(pixels.save_png(OUT+name+".png")==OK)
	return digest(pixels)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE.get_base_dir()))
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
	var cases:Array=[]
	for mode in ["slice","drag","flight"]:
		scene.show_menu()
		scene.select_vehicle(2)
		scene.select_cpu_vehicle(1)
		scene.opening=0
		scene.match_seed=42
		scene.options.aiming=0 if mode=="drag" else 1
		scene.options.bgm=100
		scene.options.sfx=100
		scene.options.scroll=50
		scene.start_match()
		if mode=="flight":
			scene.aim.angle=75
			scene.aim.power=100
			scene.shoot()
		var pause_hash: String
		var pause_clock: float
		var resumed:=false
		for frame in 120:
			if frame==30:
				# Header click uses the viewport path, not the popup methods.
				click(Vector2(31,18)*1.6)
				assert(scene.overlays.kind=="options" and scene.paused)
				pause_clock=scene.model.turn_time
			if frame==60:
				key(KEY_ESCAPE)
				assert(not scene.paused)
			scene._process(1.0/60)
			var pixels:=await picture()
			if frame==30: pause_hash=digest(pixels)
			if frame>=30 and frame<60:
				assert(digest(pixels)==pause_hash,"Menu changed during pause:"+mode)
				assert(scene.model.turn_time==pause_clock)
			if frame==75: resumed=digest(pixels)!=pause_hash
			if frame in [0,29,30,59,75,119]:
				assert(pixels.save_png(OUT+"%s-%03d.png"%[mode,frame])==OK)
		assert(resumed)
		cases.append({"case":mode,"frames":120,"identical_paused_frames":30,"pause_sha256":pause_hash,"resume":resumed})
	# Actual choices, persistence, cancellation, QUIT and whole-group fallback.
	scene.show_menu()
	scene.opening=0
	scene.start_match()
	click(Vector2(31,18)*1.6)
	click(Vector2(125,254)*1.6)
	click(Vector2(185,280)*1.6)
	click(Vector2(245,174)*1.6)
	assert(scene.options.bgm==80 and scene.options.sfx==95 and scene.options.scroll==70)
	await snap("selections")
	click(Vector2(220,420)*1.6)
	assert(not scene.paused)
	key(KEY_P)
	assert(scene.paused and scene.overlays.kind=="options")
	var active_hash:=await snap("native")
	var popup=scene.overlays.options_popup
	var missing=load("res://scripts/client_hud_assets.gd").new("res://.tools/battle-menu/no-catalog.json")
	popup.art=load("res://scripts/classic_battle_options_art.gd").new(missing)
	assert(popup.art.using_fallback)
	for button in [popup.accept_button,popup.cancel_button,popup.quit_button]:
		button.art=popup.art
		button.queue_redraw()
	popup.queue_redraw()
	var fallback_hash:=await snap("fallback")
	assert(active_hash==fallback_hash,"Fallback changes native menu pixels")
	click(Vector2(100,280)*1.6)
	assert(scene.options.sfx==0)
	await snap("effect-off")
	click(Vector2(255,60)*1.6)
	assert(not scene.paused and scene.options.sfx==95)
	await snap("cancelled")
	key(KEY_ESCAPE)
	var xp: int=scene.profile.xp
	click(Vector2(60,420)*1.6)
	assert(scene.screen=="menu" and scene.profile.xp==xp)
	await snap("quit-room")
	var file:=FileAccess.open(OUT+"capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"frames":360,"clock_hz":60,"cases":cases,"input":"viewport clicks header/options/levels/OK/X/QUIT; ESC/P keys","fallback_identical":active_hash==fallback_hash,"native_sha256":active_hash,"audio":"muted","native_windows_client":"not executed"},"\t")+"\n")
	file.close()
	scene.queue_free()
	await process_frame
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("BATTLE OPTIONS GPU:360 frames1920x1080,3x30 paused identical,resume,input,fallback")
	quit()
