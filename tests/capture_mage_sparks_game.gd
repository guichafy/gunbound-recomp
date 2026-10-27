extends SceneTree
const OUT:="res://docs/mage-sparks/"
var scene
func _initialize() -> void:call_deferred("run")
func snap(name: String) -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	image.save_png(OUT+name+".png")
	return image
func run() -> void:
	root.size=Vector2i(1920,1080);root.content_scale_size=Vector2i.ZERO;root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/mage-sparks/isolated-gpu-profile.json")
	root.add_child(scene);scene.set_process(false);scene.sound.muted=true
	scene.scale=Vector2.ONE*1.35;scene.position=Vector2(96,0)
	scene.show_menu();scene.select_vehicle(1);scene.select_cpu_vehicle(2)
	var report: Array=[]
	for climate in ["force","electricity"]:
		scene.opening=0;scene.match_seed=42;scene.start_match();scene.select_weapon(1)
		scene.aim.angle=35;scene.aim.power=30
		scene.model.weather.columns.clear();scene.model.weather.queue[0].type="wind";scene.model.weather.thor.active=false
		scene.model.wind=Vector2.ZERO
		var shells: Array=scene.model.shot_shells(0,35,30,1)
		scene.model.weather.add_column(climate,shells[0].pos.x,2.0)
		assert(scene.model.fire(35,30,1))
		for frame in 30:
			scene._process(1.0/60)
			await process_frame
		var alive: int=scene.weather_art.mage_sparks.particles.size()
		assert(alive>0)
		scene.paused=true
		var reference:=await snap("arena-"+climate)
		for frame in 30:
			scene._process(1.0/60)
			var image:=await snap("pause-last")
			assert(image.get_data()==reference.get_data())
		scene.paused=false
		for frame in 12:scene._process(1.0/60);await process_frame
		await snap("arena-"+climate+"-resumed")
		scene.show_menu()
		assert(scene.weather_art.mage_sparks.particles.is_empty())
		report.append({"climate":climate,"visible_particles":alive,"pause_frames_identical":30,"menu_clear":true})
	var file=FileAccess.open(OUT+"game-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[1920,1080],"cases":report},"\t"));file.close()
	print("MAGE SPARKS REAL ARENA:Force/Electric,T2,30frame pauses identical,resume/menuclear,isolated profile")
	scene.free();quit()
