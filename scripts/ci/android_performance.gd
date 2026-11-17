extends RefCounted
## Diagnostic APK only; fixed simulation steps make before/after comparable.
## These emulator samples are observations, never physical-device acceptance.
static func summary(values: Array) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in values:total+=float(value)
	return {"samples":values.size(),"mean":total/maxi(1,values.size()),"p95":sorted[mini(sorted.size()-1,int(ceil(sorted.size()*0.95))-1)] if not sorted.is_empty() else 0.0,"max":sorted.back() if not sorted.is_empty() else 0.0}

static func run(view) -> Array:
	var results: Array=[]
	view.set_process(false)
	view.sound.muted=true
	view.opening=0
	view.match_seed=57057
	for scenario in ["solo","volley","jewel"]:
		view.room_mode="jewel" if scenario=="jewel" else "solo"
		view.room_map_id="nirvana_a"
		view.vehicle=13 if scenario=="jewel" else 2
		view.cpu_vehicle=8 if scenario=="jewel" else 1
		view.start_match()
		view.elapsed=0.0
		view.lifecycle.resume()
		view.confirm_platform_resume()
		var frame_ms: Array=[]
		var process_ms: Array=[]
		var draws: Array=[]
		var previous := Time.get_ticks_usec()
		for frame in 240:
			if scenario=="volley" and frame==60:view.model.fire(65,70,1)
			var started := Time.get_ticks_usec()
			view._process(1.0/60.0)
			var cost := (Time.get_ticks_usec()-started)/1000.0
			await view.get_tree().process_frame
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			if frame>=60:
				frame_ms.append((now-previous)/1000.0)
				process_ms.append(cost)
				draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			previous=now
		var row := {"scenario":scenario,"viewport":str(view.get_viewport_rect().size),"frame_ms":summary(frame_ms),"process_ms":summary(process_ms),"draw_calls":summary(draws),"static_bytes":OS.get_static_memory_usage(),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
		row.image_sha256=view.get_viewport().get_texture().get_image().get_data().hex_encode().sha256_text()
		print("ANDROID PERFORMANCE JSON: ",JSON.stringify(row))
		results.append(row)
	view.show_lobby()
	return results
