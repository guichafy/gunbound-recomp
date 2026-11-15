extends SceneTree
## Real GPU scene with an isolated profile, muted audio and fixed fixtures.
const OUT := "res://.tools/jewel-hud-review/gpu/"
const PROFILE := "res://.tools/jewel-hud-review/gpu-profile.json"
var checks := 0
var failures := 0
var scene
var viewport: SubViewport
var records: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",label)
func picture() -> Image:
	scene.queue_redraw()
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func digest(image: Image) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(image.get_data())
	return hash.finish().hex_encode()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	viewport=SubViewport.new()
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game_view := SubViewport.new()
	game_view.size_2d_override=Vector2i(1280,800)
	game_view.size_2d_override_stretch=true
	game_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.add_child(game_view)
	var presentation := TextureRect.new()
	presentation.texture=game_view.get_texture()
	viewport.add_child(presentation)
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new(PROFILE)
	scene.sound=load("res://scripts/sound.gd").new()
	scene.sound.muted=true
	game_view.add_child(scene)
	scene.set_process(false)
	scene.opening=0
	scene.match_seed=46
	for resolution in [Vector2i(1280,800),Vector2i(1920,1080)]:
		viewport.size=resolution
		game_view.size=Vector2i(1280,800) if resolution.x==1280 else Vector2i(1728,1080)
		presentation.position=Vector2.ZERO if resolution.x==1280 else Vector2(96,0)
		presentation.size=game_view.size
		for team in 2:
			for scores in [[0,0],[5,10],[75,25],[99,95],[100,25],[124,99]]:
				scene.show_menu()
				scene.room_mode="jewel"
				scene.start_match()
				scene.rig.position=scene.clamp_camera(scene.camera_goal())
				scene.model.jewel_state.teams=[team,1-team]
				scene.model.jewel_state.scores=scores.duplicate()
				scene.model.active=1 if scores[0]==5 else 0
				if scores[0]==75:
					scene.hud.update_movement(true)
					scene.hud.update_movement(true)
					scene.aim.power=63
				if scores[0]==124:
					scene.model.actors[0].jewel_waiting=true
					scene.model.actors[0].jewel_respawn_turn=-1
				scene.update_hud()
				var buffer: Image=await picture()
				var tag := "%d-team%d-%d-%d" % [resolution.x,team,scores[0],scores[1]]
				buffer.save_png(OUT+tag+".png")
				var hash := digest(buffer)
				# Frozen presentation uses the same paused branch as the real scene;
				# no overlay here, so exactRGBA checks cover the exposed full HUD.
				scene.paused=true
				for frame in 30:
					scene._process(1.0/60.0)
					await process_frame
					await RenderingServer.frame_post_draw
					check(digest(viewport.get_texture().get_image())==hash,tag+": pauseRGBA")
				check(buffer.get_size()==resolution,tag+": native output resolution")
				check(scene.hud.jewel_panel_sample(scene.model).rect.end==Vector2(1280,800),tag+": panel bottom-right")
				scene.paused=false
				var tick: int=scene.model.spark_tick
				scene._process(0.05)
				check(scene.model.spark_tick>tick,tag+": resume tick")
				records.append({"tag":tag,"scores":scores,"team":team,"sha256_rgba":hash,"resolution":[resolution.x,resolution.y]})
				if scores[0]==100 and team==0:
					scene.model.check_end()
					scene.consume_events()
					scene.show_result()
					var result: Image=await picture()
					result.save_png(OUT+str(resolution.x)+"-result.png")
	# SOLO header/Gold should not change with objective code.
	scene.show_menu()
	scene.room_mode="solo"
	scene.start_match()
	var solo: Image=await picture()
	solo.save_png(OUT+"1920-solo.png")
	var record := {"checks":checks,"failures":failures,"paused_frames":records.size()*30,"records":records,"source":"49fdeaa9 plus local JEWEL HUD correction; source fixture only, no original client execution"}
	var file := FileAccess.open(OUT+"verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"\t")+"\n")
	file.close()
	scene.queue_free()
	await process_frame
	await process_frame
	viewport.queue_free()
	await process_frame
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("JEWEL HUD GPU CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
