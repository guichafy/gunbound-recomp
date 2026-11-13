extends "res://tests/support/suite.gd"
## Combined scene contract after maps integration: mode and resolved map are
## independent room selections, frozen at Start. Profiles/audio stay isolated.
const Maps = preload("res://scripts/maps.gd")
const MapChoice = preload("res://scripts/map_choice.gd")
const Loading = preload("res://scripts/match_loading.gd")
const LoadingView = preload("res://scripts/loading_view.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Match = preload("res://scripts/match.gd")
const PROFILE := "res://.tools/jewel-maps-scene/profile.json"

func click_control(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	await process_frame
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame

func live_state(scene) -> Dictionary:
	return {"actors":scene.model.actors.duplicate(true),"jewels":scene.model.jewel_state.duplicate(true),
		"rng":scene.model.rng.state,"room_rng":scene.room_rng.state,"events":scene.model.events.duplicate(true),
		"terrain":scene.model.terrain.cells.duplicate(),"turn":scene.model.total_turns,
		"clock":scene.model.turn_time,"phase":scene.model.phase,"profile":scene.profile.snapshot(),
		"wind":scene.model.wind,"weather":scene.model.weather.weights.duplicate()}

func check_loading(scene, chosen: String, mode: String) -> void:
	var context: Dictionary = scene.loading_context
	var row: Dictionary = Maps.get_map(chosen)
	check(scene.screen == "loading" and scene.loading_mode == mode and context.map_id == chosen,
		"Start freezes mode/map: %s/%s" % [mode,chosen])
	check(scene.loading_width == int(context.world_width) and scene.loading_spawns == context.spawns,
		"Loading width and spawn list share the resolved context: " + chosen)
	check(scene.sound.music_request == "ready", "Loading retains ready music: " + chosen)
	check(scene.loading_view.get_node("MapHole").get_child(0).texture.resource_path == str(row.preview),
		"Loading preview follows the resolved side/fallback: " + chosen)
	check(scene.menu.mode_button.disabled and scene.menu.stage.get_node("MapNext").disabled
		and scene.menu.stage.get_node("MapSide").disabled, "Loading disables mode and map controls: " + chosen)
	var rows := Loading.ground_rows(chosen)
	for index in 2:
		var spawn := Vector2(context.spawns[index])
		var column := clampi(int(spawn.x)*748/int(context.world_width),0,747)
		var expected_y := LoadingView.STAGE_ORIGIN.y+int(rows[column])+5
		var mark: Label = scene.loading_view.get_node("SpawnName%d" % index)
		check(is_equal_approx(mark.position.y,expected_y), "Spawn marker uses this map's mask: %s/%d" % [chosen,index])
		var text_width := mark.get_theme_font("font").get_string_size(mark.text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		check(is_equal_approx(mark.position.x+text_width*0.5,LoadingView.STAGE_ORIGIN.x+column),
			"Spawn marker X projects the frozen world width: %s/%d" % [chosen,index])

func exercise(scene, selection: String, mode: String) -> void:
	scene.select_map(selection)
	scene.set_room_mode(mode)
	scene.room_rng.seed = 20261113
	var mirror := RandomNumberGenerator.new()
	mirror.state = scene.room_rng.state
	var expected := selection
	if selection == "random":
		var ids := Maps.available_ids()
		expected = str(ids[mirror.randi_range(0,ids.size()-1)])
	var expected_context := MapChoice.resolve(expected,mirror)
	check(not expected_context.is_empty(), "Selected map has a valid offline context: " + selection)
	if expected_context.is_empty():
		return
	scene.begin_loading()
	check_loading(scene,expected,mode)
	check(scene.loading_context == expected_context and scene.room_rng.state == mirror.state,
		"Map resolves once with only the expected selection/spawn draws: %s/%s" % [selection,mode])
	var frozen: Dictionary = scene.loading_context.duplicate(true)
	var rng_state: int = scene.room_rng.state
	scene.select_map("nirvana_b" if expected == Maps.DEFAULT else Maps.DEFAULT)
	scene.set_room_mode("solo" if mode == "jewel" else "jewel")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_key_input(escape)
	scene._tick_loading(0.1)
	check(scene.screen == "loading" and scene.room_map_id == selection and scene.room_mode == mode
		and scene.loading_context == frozen and scene.room_rng.state == rng_state,
		"Loading ignores map/mode/Escape changes without rerolling: %s/%s" % [selection,mode])
	scene._tick_loading(5.0)
	await process_frame
	check(scene.screen == "match" and scene.model.mode == mode and scene.model.map_id == expected,
		"Battle receives both frozen selections: %s/%s" % [selection,mode])
	check(scene.room_rng.state == rng_state and scene.loading_context == frozen,
		"Match start leaves resolved context and room RNG unchanged: " + expected)
	var row: Dictionary = Maps.get_map(expected)
	check(scene.model.terrain.map_id == expected and scene.model.terrain.world_size().x == frozen.world_width,
		"Battle collision uses selected world dimensions: " + expected)
	for index in 2:
		check(scene.model.actors[index].pos.x == frozen.spawns[index].x,
			"Battle starts at its displayed marker: %s/%d" % [expected,index])
	for category in 7:
		check(int(scene.model.weather.weights[category]) == int(row.native_weather[category]),
			"Selected map controls weather in either mode: %s/%d" % [expected,category])
	var native_track := "stage%d" % (int(row.client_stage)%11)
	check(scene.sound.music_request == native_track if scene.sound.music_stream(native_track) != null
		else scene.sound.music_request in ["stage1","stage2","stage3","stage4","stage5","stage6"],
		"Battle music follows the selected family or native fallback: " + expected)
	var before := live_state(scene)
	var snapshot = Snapshot.capture(scene.model)
	check(snapshot.mode == mode and snapshot.map_id == expected and snapshot.terrain.map_id == expected,
		"Scene prediction snapshot preserves mode/map: " + expected)
	snapshot.actors[0].pos += Vector2(17,0)
	snapshot.weather.weights[0] = int(snapshot.weather.weights[0])+1
	if mode == "jewel":
		snapshot.jewel_state.scores[0] = 99
		if not snapshot.jewel_state.entities.is_empty():
			snapshot.jewel_state.entities[0].owner = 1
	snapshot.terrain.cells[0] = 1 if int(snapshot.terrain.cells[0]) == 0 else 0
	check(live_state(scene) == before, "Mutating private prediction state leaves the live scene untouched: " + expected)
	if selection == "random":
		await check_pause_and_cpu(scene,mode)
	scene.show_menu()
	await process_frame
	check(scene.room_map_id == selection and scene.room_mode == mode and scene.menu.room_mode == mode,
		"Returning preserves map choice and mode independently: %s/%s" % [selection,mode])
	check(scene.root.find_children("RoomMode","",true,false).size() == 1
		and scene.root.find_children("RoomMapPreview","",true,false).size() == 1,
		"Returning rebuilds one mode/map control pair: " + expected)
	check(scene.sound.music_request == "ready", "Returning restores room music: " + expected)

func check_pause_and_cpu(scene, mode: String) -> void:
	scene.show_pause()
	var frozen := live_state(scene)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_SPACE
	press.pressed = true
	scene._unhandled_key_input(press)
	scene._process(0.5)
	check(live_state(scene) == frozen and not scene.aim.charging, "Pause blocks clock and fire input on a resolved Random map: " + mode)
	scene.close_overlay()
	scene.model.active = 1
	var plan: Dictionary = scene.model.begin_cpu_plan()
	check(plan.snapshot.mode == mode and plan.snapshot.map_id == scene.model.map_id,
		"CPU receives the same mode/map as the scene: " + mode)
	plan.best_score = INF
	var before := live_state(scene)
	var task := WorkerThreadPool.add_task(func(): Match.score_cpu_shot(plan,45,40))
	while not WorkerThreadPool.is_task_completed(task):
		await create_timer(0.005).timeout
	WorkerThreadPool.wait_for_task_completion(task)
	check(live_state(scene) == before and is_finite(float(plan.best_score)),
		"Worker evaluates a private shot without touching live scene/profile/RNG: " + mode)
	scene.model.finish_cpu_plan(plan)
	check(not scene.model.cpu_thinking and scene.model.projectiles.is_empty(),
		"Finishing a private CPU plan does not fire into the live scene: " + mode)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE.get_base_dir()))
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	scene.sound = load("res://scripts/sound.gd").new()
	scene.sound.muted = true
	root.add_child(scene)
	scene.set_process(false)
	scene.opening = 0
	scene.match_seed = 46
	scene.show_menu()
	await process_frame
	check(Maps.available_ids().size() == 22, "Combined scene covers all 22 classical sides")
	await click_control(scene.menu.mode_button)
	check(scene.room_mode == "jewel" and scene.room_map_id == Maps.DEFAULT, "Actual mode click preserves the selected map")
	await click_control(scene.menu.stage.get_node("MapNext"))
	check(scene.room_map_id == "nirvana_a" and scene.room_mode == "jewel", "Actual map arrow preserves JEWEL")
	await click_control(scene.menu.stage.get_node("MapSide"))
	check(scene.room_map_id == "nirvana_b" and scene.room_mode == "jewel", "Actual side toggle preserves JEWEL")
	await click_control(scene.menu.map_preview)
	check(scene.room_map_id == "random" and scene.room_mode == "jewel", "Actual Random preview click preserves JEWEL")
	for mode in ["solo","jewel"]:
		for id in Maps.available_ids():
			await exercise(scene,str(id),mode)
		await exercise(scene,"random",mode)
	var playbacks := audio_playbacks(scene.sound)
	var scene_ref: WeakRef = weakref(scene)
	scene.queue_free()
	await process_frame
	await process_frame
	check(scene_ref.get_ref() == null, "Combined scene is actually destroyed at teardown")
	await await_audio_release(playbacks)
	for path in [PROFILE,PROFILE.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("JEWEL MAPS SCENE CHECKS")
