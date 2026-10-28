extends SceneTree
## Controlled native contacts through actual Game/Match, isolated profile.
const OUT := "res://docs/boomer-impact/"
const Lightning = preload("res://scripts/lightning_combat.gd")
var scene
var frame_number := 0

func _initialize() -> void:call_deferred("run")

func picture() -> Image:
	scene.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/boomer-impact/capture-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.scale=Vector2.ONE*1.35
	scene.position=Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(6)
	scene.select_cpu_vehicle(1)
	await picture()
	var report: Array=[]
	for facing in [1,-1]:
		for state in ["normal", "cnormal"]:
			var weapon := 2
			scene.opening=0
			scene.match_seed=42
			scene.start_match()
			scene.select_weapon(weapon)
			var model=scene.model
			model.weather.columns.clear()
			model.weather.calendar.fill(0)
			model.weather.queue[0].type="none"
			model.weather.thor.active=false
			model.actors[0].facing=facing
			var at: Vector2=model.actors[0].pos
			model.weather.thor.pos=at+Vector2(-180*facing,-200)
			model.weather.thor.display_pos=model.weather.thor.pos
			model.weather.thor.previous_display_pos=model.weather.thor.pos

			model.wind=Vector2.ZERO
			model.weather.wind_force=0
			model.weather.wind_angle=0
			assert(model.fire(35,25,weapon))
			scene.consume_events()
			var shell: Dictionary=model.projectiles[0].duplicate(true)
			shell.ss_state=state
			shell.electric=false
			shell.native_force=40
			var pause: PackedByteArray
			var electric_count:=0
			var thor_count:=0
			for frame in 90:
				if frame==20:
					# A repeatable terrain contact keeps effects on screen; the
					# full real/predicted trajectory is covered by model suites.
					model.projectiles.clear()
					model.events.clear()
					for component in (4 if weapon==1 else 1):
						model.explode(at+Vector2(facing*(75+component*6),20),-1,shell.duplicate(true))
					Lightning.resolve(model)
					for event in model.events:
						if event.type=="mobile_lightning":electric_count+=1
						if event.type=="thor":thor_count+=1
					scene.consume_events()
				scene.paused=frame>=30 and frame<60
				scene._process(1.0/60)
				var image:=await picture()
				if frame in [25,59]:
					image.save_png(OUT+"ss-%s-facing%d-frame%d.png"%[state,facing,frame])
				if frame==30:pause=image.get_data()
				if scene.paused:assert(image.get_data()==pause,"Native climate effects freeze during pause")
				frame_number+=1
			assert(electric_count==0 and thor_count==0)
			report.append({"weapon":weapon,"ss_state":state,"facing":facing,"electric":electric_count,"thor":thor_count,"pause_frames_identical":30})
			scene.paused=false
	var output=FileAccess.open(OUT+"gpu-validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"size":[1920,1080],"frames":frame_number,"clock_hz":60,"controlled_contacts":true,"cases":report},"\t"))
	output.close()
	print("BOOMER IMPACT GPU: ",frame_number,"frames,4cases,SS normal/transformed,30frame pauses identical")
	scene.free()
	quit()
