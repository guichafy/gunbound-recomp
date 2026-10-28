extends SceneTree
var scene
const OUT = "res://docs/boomer-support-20261028/"
func _initialize():
	call_deferred("run")
func picture():
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1920,1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/boomer-idle-probe-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(6)
	scene.select_cpu_vehicle(1)
	for slope in [-1,1]:
		for facing in [1,-1]:
			scene.opening=0
			scene.match_seed=42
			scene.start_match()
			var model=scene.model
			var terrain=model.terrain
			terrain.WIDTH=640
			terrain.HEIGHT=400
			terrain.cells.resize(640*400)
			terrain.cells.fill(0)
			terrain.image=Image.create(640,400,false,Image.FORMAT_RGBA8)
			terrain.image.fill(Color.TRANSPARENT)
			for y in range(400):
				for x in 640:
					var floor_cell=clampi(300+int((x-250)*slope/5.0),0,399)
					if y>=floor_cell:
						terrain.cells[y*640+x]=1
						terrain.image.set_pixel(x,y,Color("685741"))
			terrain.native_cells.clear()
			terrain.enable_native()
			terrain.texture=ImageTexture.create_from_image(terrain.image)
			terrain.visual=null
			terrain.map_id=""
			model.actors[0].pos=Vector2(500,575)
			model.actors[0].facing=facing
			model.actors[1].pos=Vector2(1000,terrain.surface_at(1000)-model.stance_of(1))
			model.wind=Vector2.ZERO
			model.weather.wind_force=0
			model.weather.columns.clear()
			model.weather.thor.active=false
			scene.art.reset(model.actors)
			scene.rig.position=Vector2.ZERO
			scene.rig.manual=true
			for frame in 40:
				scene._process(1.0/60)
				var img=await picture()
				if frame==39:
					img.save_png(OUT+"idle-slope%d-facing%d.png"%[slope,facing])
					print("slope=",slope," facing=",facing," rotation=",model.body_rotation(0)," pose=",scene.art.motion[0].pose," age=",scene.art.motion[0].pose_age)
			model.weather.wind_force=26
			model.weather.wind_angle=0 if facing>0 else 180
			model.wind=model.weather.wind_vector()
			assert(model.fire(45,60,0))
			scene.consume_events()
			var pause: PackedByteArray
			for frame in 85:
				scene.paused=frame>=30 and frame<60
				scene._process(1.0/60)
				var img=await picture()
				if frame==24:
					img.save_png(OUT+"recoil-slope%d-facing%d.png"%[slope,facing])
				if frame==30:
					pause=img.get_data()
				if scene.paused:
					assert(img.get_data()==pause)
			scene.paused=false
	print("BOOMER SUPPORT GPU: 500 steps, 4 cases, slopes, both directions, wind, pause30")
	scene.free()
	quit()
