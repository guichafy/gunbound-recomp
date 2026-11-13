extends "res://tests/support/suite.gd"
const Maps = preload("res://scripts/maps.gd")
func run() -> void:
	root.size=Vector2i(1280,800)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/maps-implementation/scene-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.show_menu()
	await process_frame
	check(not scene.menu.stage.get_node("MapNext").disabled,"Map selector active")
	for name in ["MapNext","MapSide","RoomMapPreview"]:
		var point: Vector2 = scene.menu.stage.get_node(name).get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position=point
		motion.global_position=point
		root.push_input(motion)
		await process_frame
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position=point
			event.global_position=point
			event.button_index=MOUSE_BUTTON_LEFT
			event.pressed=pressed
			root.push_input(event)
			await process_frame
		check(scene.room_map_id==({"MapNext":"nirvana_a","MapSide":"nirvana_b","RoomMapPreview":"random"}[name]),"Actual pointer reaches "+name)
	for id in Maps.available_ids():
		scene.select_map(id)
		if Maps.get_map(id).type=="B":
			check(scene.menu.stage.get_node("RoomMapSide").texture.resource_path.ends_with("bside.png"),"Native sideB plaque "+id)
		var cave_name = scene.menu.map_preview.get_node_or_null("MapFixedName")
		check(cave_name!=null and cave_name.visible==(int(Maps.get_map(id).stage_index)%11==0),"Fixed Cave name distinct from Random "+id)
		scene.begin_loading()
		check(scene.screen=="loading" and scene.loading_context.map_id==id,"Loading context "+id)
		check(scene.sound.music_request=="ready","Room music through loading "+id)
		var spawns: Array = scene.loading_context.spawns.duplicate()
		var state: int = scene.room_rng.state
		scene.start_match(scene.loading_player,scene.loading_cpu,spawns)
		check(scene.model.map_id==id and scene.room_rng.state==state,"Resolved map no reroll "+id)
		var row := Maps.get_map(id)
		for category in 7:
			check(int(scene.model.weather.weights[category])==int(row.native_weather[category]),"Native preset "+id)
		check(scene.sound.music_request in ["stage1","stage2","stage3","stage4","stage5","stage6"],"Stage or native fallback music "+id)
		for i in 2:check(scene.model.actors[i].pos.x==spawns[i].x,"Shown spawn reaches battle "+id)
		scene.show_menu()
	scene.select_map("random")
	var cave_name = scene.menu.map_preview.get_node_or_null("MapFixedName")
	check(cave_name!=null and not cave_name.visible,"Random keeps its original name")
	check(scene.menu.stage.get_node("MapSide").disabled,"Random side pending, plaque disabled")
	scene.begin_loading()
	var chosen: String = scene.loading_context.map_id
	var random_state: int = scene.room_rng.state
	scene.select_map(Maps.DEFAULT)
	check(scene.room_map_id=="random" and scene.loading_context.map_id==chosen,"Loading blocks map changes")
	scene.start_match(scene.loading_player,scene.loading_cpu,scene.loading_spawns)
	check(scene.model.map_id==chosen and scene.room_rng.state==random_state,"Random resolved exactly once")
	scene.show_menu()
	scene.room_map_id="unknown"
	scene.begin_loading()
	check(scene.screen=="menu","Invalid resources keep room open")
	var playbacks := audio_playbacks(scene.sound)
	scene.queue_free()
	await process_frame
	await await_audio_release(playbacks)
	finish("CLASSIC MAPS SCENE CHECKS")
