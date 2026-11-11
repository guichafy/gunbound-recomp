extends SceneTree
## Issue26: native transitions without Mage, swapped sides, pause and resume.
## Run with --disable-vsync --always-on-top; raw frames stay outside exports.
var view
var frames := 0
var pause_checks := 0
var samples: Array = []
var thor_only := "--thor-only" in OS.get_cmdline_user_args()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/issue26-gpu"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/native-weather"))
	view=load("res://scenes/main.tscn").instantiate()
	view.profile=load("res://scripts/profile.gd").new("res://.tools/issue26-capture-profile.json")
	root.add_child(view)
	view.scale=Vector2(1.35,1.35)
	view.position=Vector2(96,0)
	view.set_process(false)
	view.sound.muted=true
	view.opening=0
	view.start_match()
	for side in 2:
		view.model.start(2 if side==0 else 4,1,42,"miramo_town_a","all",null,[],[],[],0,4 if side==0 else 2)
		view.art.reset(view.model.actors)
		view.weather_art.reset(view.Maps.get_map(view.model.map_id))
		# Controlled calendar exercises all seven native category transitions.
		view.model.weather.calendar=[0,1,2,3,4,5,6,0]
		view.model.weather.last_turn=-1
		view.model.weather.columns.clear()
		view.model.weather.thor.transition_turn=-1
		view.paused=false
		for category in ([4] if thor_only else range(7)):
			view.model.total_turns=category*2
			view.model.begin_turn()
			view.consume_events()
			# Grant-turn events reset manual panning; frame the satellite afterwards.
			view.rig.manual=category==4
			if category==4:
				view.rig.position=view.rig.fit(view.model.terrain,view.model.weather.thor.pos-Vector2(640,150))
			view.update_hud()
			for frame in 30:
				if category==4 and frame==10:
					view.model.thor_strike(view.model.actors[1].pos+Vector2(0,30))
					view.consume_events()
				view._process(1.0/60)
				view.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var picture: Image=root.get_texture().get_image()
				picture.save_png("res://.tools/issue26-gpu/%sframe-%04d.png"%["thor-" if thor_only else "",frames])
				frames+=1
				if frame==15:
					var path: String="res://docs/native-weather/side%d-%s.png"%[side,view.model.weather.queue[0].type]
					picture.save_png(path)
					samples.append({"side":side,"category":category,"type":view.model.weather.queue[0].type,"columns":view.model.weather.columns.duplicate(true),"thor_y":view.model.weather.thor.pos.y,"path":path})
			# Pause electric animation, then verify every rendered pixel and model.
			if category==2:
				view.paused=true
				var frozen: Image=root.get_texture().get_image()
				var thor: Dictionary=view.model.weather.thor.duplicate(true)
				var column_age: Dictionary=view.weather_art.column_age.duplicate(true)
				for frame in 30:
					view._process(1.0/60)
					view.queue_redraw()
					await process_frame
					await RenderingServer.frame_post_draw
					var picture: Image=root.get_texture().get_image()
					if picture.get_data()!=frozen.get_data() or view.model.weather.thor!=thor or view.weather_art.column_age!=column_age:
						printerr("FAIL: Native weather changed while paused")
						quit(1)
						return
					pause_checks+=1
					picture.save_png("res://.tools/issue26-gpu/%sframe-%04d.png"%["thor-" if thor_only else "",frames])
					frames+=1
				view.paused=false
	var manifest: FileAccess=FileAccess.open("res://docs/native-weather/thor-gpu.json" if thor_only else "res://docs/native-weather/gpu.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"frames":frames,"pause_identical_frames":pause_checks,"size":[1920,1080],"fps":60,"pairs":[[2,4],[4,2]],"controlled_calendar":[0,1,2,3,4,5,6,0],"thor_camera":"manual at satellite for category4; explicit strike at frame10","samples":samples},"\t")+"\n")
	manifest.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/issue26-capture-profile.json"))
	print("NATIVE WEATHER GPU CHECKS: ",frames," | PAUSE IDENTICAL: ",pause_checks)
	quit()
