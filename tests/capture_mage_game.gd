extends SceneTree
const OUT := "res://docs/mage-review/"
var scene
func _initialize() -> void:call_deferred("run")
func snap(name: String) -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	picture.save_png(OUT+name+".png")
	return picture
func run() -> void:
	root.size=Vector2i(1920,1080);root.content_scale_size=Vector2i.ZERO;root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/mage-audit/game-profile.json")
	root.add_child(scene);scene.set_process(false);scene.sound.muted=true
	scene.scale=Vector2.ONE*1.35;scene.position=Vector2(96,0)
	scene.show_menu();scene.select_vehicle(1);scene.select_cpu_vehicle(2)
	await snap("room-mage")
	for weapon in 3:
		scene.opening=0;scene.match_seed=42;scene.start_match();scene.select_weapon(weapon)
		scene.model.weather.columns.clear();scene.model.weather.thor.active=false
		scene.model.wind=Vector2(27,-12)
		var at: Vector2=scene.model.shot_shells(0,35,25,weapon)[0].pos
		scene.model.weather.add_column("tornado",at.x+45,1.0)
		assert(scene.model.fire(35,25,weapon));scene.consume_events()
		var hit:=false
		for frame in 300:
			scene._process(1.0/60)
			if frame in [20,55]:await snap("arena-%d-flight-%d"%[weapon,frame])
			if not hit and not scene.effects.is_empty():
				hit=true
				await snap("arena-%d-impact"%weapon)
				break
			await process_frame
		assert(hit,"Actual Mage shot must impact")
		scene.paused=true
		var reference:=await snap("arena-%d-paused"%weapon)
		for frame in 30:
			scene._process(1.0/60)
			var picture:=await snap("pause-check")
			assert(picture.get_data()==reference.get_data(),"Actual Mage arena pause must be stable")
		scene.paused=false
		for frame in 12:scene._process(1.0/60);await process_frame
		await snap("arena-%d-resumed"%weapon)
	print("MAGE ACTUAL GAME GPU: room,3weapons,wind/tornado,30frame pauses identical,HUD and resume")
	scene.free();quit()
