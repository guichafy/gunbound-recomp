extends SceneTree
const OUT:="res://docs/lightning-review/"
var scene
func _initialize() -> void:call_deferred("run")
func snap(name: String) -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw()
	var image:=root.get_texture().get_image()
	image.save_png(OUT+name+".png")
	return image
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/lightning-review/qa-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.scale=Vector2.ONE*1.35
	scene.position=Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(8)
	scene.select_cpu_vehicle(4)
	await snap("room")
	scene.opening=0
	scene.match_seed=42
	scene.start_match()
	scene.select_weapon(1)
	assert(scene.model.fire(35,25,1))
	scene.consume_events()
	var first:=-1
	for frame in 420:
		scene._process(1.0/60)
		if frame==15:await snap("arena-t2-flight")
		if scene.weather_art.beams.any(func(beam):return str(beam.kind)=="mobile_lightning"):
			first=frame
			break
		await process_frame
	assert(first>=0,"Actual Lightning T2 must reach native beam stage")
	scene.paused=true
	var frozen:=await snap("arena-t2-beam")
	var identical:=true
	for frame in 30:
		scene._process(1.0/60)
		scene.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		identical=identical and root.get_texture().get_image().get_data()==frozen.get_data()
	var saved: Array=scene.weather_art.beams
	scene.weather_art.beams=[]
	var without:=await snap("arena-without-beam")
	scene.weather_art.beams=saved
	var center: Vector2=scene.position+scene.hud.COMPASS_CENTER*scene.hud.K*scene.scale
	var bounds:=Rect2i(Vector2i(center)-Vector2i(24,24),Vector2i(48,48))
	var hud_above:=frozen.get_region(bounds).get_data()==without.get_region(bounds).get_data()
	scene.paused=false
	for frame in 3:scene._process(1.0/60)
	var resumed:=await snap("arena-resumed")
	var resume_changes:=resumed.get_data()!=frozen.get_data()
	scene.show_menu()
	await snap("room-after-battle")
	var report:={"resolution":[1920,1080],"first_beam_frame":first,"pause30_identical":identical,"resume_changes_pixels":resume_changes,"hud_above_beam":hud_above,"beams_after_exit":scene.weather_art.beams.size(),"audio":"muted; no human listening","client_original_executed":false}
	FileAccess.open(OUT+"game-qa.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("LIGHTNING GAME QA ",report)
	assert(identical and resume_changes and hud_above)
	assert(scene.weather_art.beams.is_empty())
	scene.queue_free()
	await process_frame
	quit()
