extends SceneTree
## Actual Game renderer, isolated profile, original textures in both calendars.
## Controlled presentation events exercise art without claiming native combat.
const OUT := "res://docs/client-weather-assets/"
const FRAMES := "res://.tools/client-weather-assets/frames/"
var scene
var number := 0

func _initialize() -> void:call_deferred("run")

func picture() -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	return root.get_texture().get_image()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/client-weather-assets/profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.scale=Vector2.ONE*1.35
	scene.position=Vector2(96,0)
	var cases: Array=[]
	for native in [false,true]:
		for facing in [1,-1]:
			scene.show_menu()
			scene.select_vehicle(1 if native else 2)
			scene.select_cpu_vehicle(2 if native else 4)
			scene.opening=0
			scene.match_seed=42
			scene.start_match()
			var model=scene.model
			model.actors[0].facing=facing
			model.weather.columns.clear()
			var at: Vector2=model.actors[0].pos
			for pair in [["force",70],["electricity",230],["tornado",390]]:
				model.weather.add_column(pair[0],at.x+pair[1],1.0)
			model.weather.thor.active=true
			model.weather.thor.pos=at+Vector2(230,-260)
			if native:
				model.weather.thor.display_pos=model.weather.thor.pos
				model.weather.thor.previous_display_pos=model.weather.thor.pos
			scene.weather_art.thor_position=model.weather.thor.pos
			scene.weather_art.emit_ground(at+Vector2(150,0),320,-PI*0.5,model)
			var pause: PackedByteArray
			var after: PackedByteArray
			var resume_changes := false
			var mode := "native" if native else "adapter"
			for frame in 90:
				if frame==15:
					scene.weather_art.react({"type":"thor","from":model.weather.thor.pos,"position":at+Vector2(280,0),"removed":0,"level":2,"native":native,"ttl":1.0 if native else 0.6,"period":1000,"rgb":0x00ff00,"contact":false},model,scene.sound)
					if native:
						scene.weather_art.react({"type":"mobile_lightning","position":at+Vector2(140,0),"direction":0},model,scene.sound)
					else:
						scene.weather_art.react({"type":"lightning","top":at+Vector2(80,-500),"position":at+Vector2(80,0),"removed":0},model,scene.sound)
				scene.paused=frame>=30 and frame<60
				scene._process(1.0/60)
				var image := await picture()
				if frame in [15,30,59,75]:image.save_png(OUT+"%s-facing%d-frame%d.png"%[mode,facing,frame])
				if frame==30:pause=image.get_data()
				if scene.paused:assert(image.get_data()==pause,"Weather textures freeze for thirty identical paused frames")
				if frame==59:after=image.get_data()
				if frame==75:resume_changes=image.get_data()!=after
				number+=1
			assert(resume_changes,"Weather animation resumes after pause")
			cases.append({"calendar":mode,"facing":facing,"frames":90,"pause30_identical":true,"resume_changes_pixels":resume_changes})
			scene.paused=false
	var report := {"size":[1920,1080],"frames":number,"simulation_clock_hz":60,"cases":cases,"controlled_presentation_events":true,"client_original_executed":false,"audio":"muted; no listening","performance_fps_measured":false}
	var file := FileAccess.open(OUT+"gpu-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("CLIENT WEATHER GPU: ",number,"frames,4cases,30frame pauses identical,resume changes pixels")
	scene.free()
	quit()
