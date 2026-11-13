extends "res://tests/support/suite.gd"

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/jewel-scene-profile.json")
	scene.sound=load("res://scripts/sound.gd").new()
	scene.sound.muted=true
	root.add_child(scene)
	scene.set_process(false)
	scene.show_menu()
	check(scene.get("room_mode") == "solo", "Room defaults to SOLO independently of mobile IDs")
	check(scene.has_method("set_room_mode"), "Room exposes an offline mode selector")
	if scene.has_method("set_room_mode"):
		scene.menu.mode_button.pressed.emit()
		check(scene.room_mode == "jewel", "Native mode button selects JEWEL")
		var old_button: WeakRef = weakref(scene.menu.mode_button)
		scene.opening = 0
		scene.begin_loading()
		check(scene.screen == "loading" and scene.loading_mode == "jewel", "Start freezes the selected mode through loading")
		scene.set_room_mode("solo")
		check(scene.room_mode == "jewel", "Loading blocks changes to the selected mode")
		scene._tick_loading(10.0)
		await process_frame
		check(scene.screen == "match" and scene.model.mode == "jewel", "Loading starts the JEWEL model")
		check(old_button.get_ref() == null, "Starting destroys the previous room mode control")
		check(scene.hud.mode_scores(scene.model) == [0, 0], "JEWEL HUD reads team scores rather than Gold")
		scene.model.jewel_state.scores = [25, 10]
		check(scene.hud.mode_scores(scene.model) == [25, 10], "HUD preserves each team's score")
		scene.show_pause()
		var clock: float = scene.model.turn_time
		scene._process(0.5)
		check(scene.model.turn_time == clock, "Pause freezes JEWEL battle")
		scene.model.actors[0].jewel_waiting = true
		scene.model.actors[0].jewel_respawn_turn = -1
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = Vector2(400,200)
		scene._unhandled_input(click)
		check(scene.model.actors[0].jewel_respawn_turn == -1, "Pause blocks a respawn map choice")
		scene.close_overlay()
		check(not scene.player_can_act(), "A waiting pilot cannot charge or fire")
		click.position.y = 20
		scene._unhandled_input(click)
		check(scene.model.actors[0].jewel_respawn_turn == -1, "Header clicks do not select a respawn")
		click.position.y = 200
		var expected_x := floorf(click.position.x+scene.rig.position.x)
		scene._unhandled_input(click)
		check(scene.model.actors[0].jewel_respawn_turn == scene.model.total_turns+2 and scene.model.actors[0].jewel_respawn_x == expected_x, "World click selects the waiting pilot's world X")
		check(not scene.aim.charging and not scene.dragging, "Respawn click does not begin shooting or camera dragging")
		scene.model.jewel_state.scores = [100,10]
		scene.model.check_end()
		scene.consume_events()
		scene.show_result()
		check(scene.overlays.kind == "result" and scene.model.winner == 0, "JEWEL score victory opens the existing result window")
		var awarded: int = scene.profile.xp
		scene.show_result()
		check(scene.profile.xp == awarded, "Reopening JEWEL result does not duplicate XP")
		scene.show_menu()
		check(scene.room_mode == "jewel", "Returning to the room preserves its mode")
		check(scene.root.find_children("RoomMode","",true,false).size() == 1, "Returning builds one fresh mode control without stale room controls")
		scene.menu.mode_button.pressed.emit()
		check(scene.room_mode == "solo", "Native mode button returns to SOLO")
		scene.start_match()
		check(scene.model.mode == "solo" and scene.hud.mode_scores(scene.model).is_empty(), "SOLO keeps its original Gold panel")
		scene.show_menu()
	scene.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/jewel-scene-profile.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/jewel-scene-profile-options.json"))
	finish("JEWEL SCENE CHECKS")
