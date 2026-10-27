extends SceneTree
## Actual Game/HUD/map path, real launch geometry, isolated save, muted audio.
var output := "res://docs/aduka-audit/"
var scene

func _initialize() -> void:
	call_deferred("run")

func snap(name: String) -> Image:
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png(output+name+".png")
	return picture

func run() -> void:
	if "--combat" in OS.get_cmdline_user_args():
		output = "res://docs/aduka-combat/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/aduka-audit/game-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE*1.35
	scene.position = Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(16)
	scene.select_cpu_vehicle(4)
	await snap("room")
	scene.opening = 0
	scene.match_seed = 42
	scene.start_match()
	scene.select_weapon(1)
	scene.aim.angle = 35
	assert(scene.model.fire(35,25,1))
	scene.consume_events()
	var ray_frame := -1
	var three_visible := false
	for frame in 360:
		scene._process(1.0/60)
		if frame==15:
			await snap("arena-t2-flight")
		if frame==42:
			three_visible = scene.model.projectiles.filter(func(shot):return bool(shot.launched) and int(shot.weapon)==1).size()==3
			await snap("arena-t2-three")
		if ray_frame<0 and scene.weather_art.beams.any(func(beam):return bool(beam.get("native",false))):
			ray_frame = frame
		if ray_frame>=0 and frame==ray_frame+6:
			await snap("arena-t2-beam")
			break
		await process_frame
	assert(ray_frame>=0,"Actual T2 flight must reach its native Thor stage")
	scene.paused = true
	var with_beam := await snap("arena-t2-paused")
	var saved_beams: Array = scene.weather_art.beams
	scene.weather_art.beams = []
	var without_beam := await snap("arena-without-beam")
	scene.weather_art.beams = saved_beams
	# Entire48px square is inside the opaque compass disc at this scale.
	var compass_center: Vector2 = scene.position+scene.hud.COMPASS_CENTER*scene.hud.K*scene.scale
	var compass_box := Rect2i(Vector2i(compass_center)-Vector2i(24,24),Vector2i(48,48))
	var hud_above := with_beam.get_region(compass_box).get_data()==without_beam.get_region(compass_box).get_data()
	await snap("arena-t2-restored")
	# A legal manual-camera position can put Thor over the room's letterbox
	# after leaving. Keep that edge visible to expose stale child-canvas commands.
	var thor: Dictionary = scene.model.weather.thor
	thor.pos = scene.rig.position+Vector2(20,150)
	thor.display_pos = thor.pos
	thor.previous_display_pos = thor.pos
	thor.native_angle = 0
	thor.state = "fire"
	thor.state_tick = 4
	await snap("arena-thor-edge")
	scene.show_menu()
	scene.menu.figures.queue_redraw()
	var after_leave := await snap("room-after-battle")
	scene.weather_art.native_thor_art.clear()
	scene.sprite_for(16).glow.clear()
	scene.menu.figures.queue_redraw()
	var cleaned := await snap("room-explicit-clear")
	var no_residue := after_leave.get_data()==cleaned.get_data()
	var report := {"hud_above_beam":hud_above,"no_glow_residue_after_leaving":no_residue,"actual_first_ray_frame":ray_frame,"three_launched_t2_creatures":three_visible}
	var file := FileAccess.open(output+"game-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ADUKA LAYER REGRESSION: ",report)
	print("ADUKA ACTUAL GAME GPU: room + Miramo/T2 real flight/beam;first_ray_frame=",ray_frame)
	scene.free()
	quit(0 if hud_above and no_residue else 1)
