extends "res://tests/support/suite.gd"
## Real scene + Sound pool: counts actual stream allocations, including mute.
var view

func fresh(vehicle: int = 4, items: Array = []) -> void:
	view.model.start(vehicle,1,42,"","original",null,items)
	view.art.reset(view.model.actors)
	view.consume_events()
	view.paused = false
	view.sound.muted = false
	view.sound.next_player = 0
	view.cpu.begin_turn()

func advance(seconds: float, fps: int = 60) -> void:
	for frame in roundi(seconds*fps):
		view._process(1.0/fps)
	# The model clock is simulated above, but AudioServer processes play/stop
	# commands on its own real mixer clock. Let each assertion boundary drain
	# before the next scenario reuses the same five AudioStreamPlayers.
	await create_timer(0.1).timeout

func run() -> void:
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/classic-timing-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.opening = 0
	view.start_match()
	view.sound.stop_music()
	for fps in [30,60,120]:
		fresh(4)
		view.model.fire(40,60,1)
		view.consume_events()
		await advance(0.5,fps)
		var elapsed: float = view.model.flight_elapsed
		var pose: float = view.art.motion[0].pose_age
		view.paused = true
		await advance(0.5,fps)
		check(view.model.flight_elapsed == elapsed and view.art.motion[0].pose_age == pose and view.sound.next_player == 0,"%dFPS pause before tick14 freezes pose/model/audio" % fps)
		view.paused = false
		await advance(0.2,fps)
		check(view.sound.next_player == 1,"%dFPS source tick14 emits exactly one sound" % fps)
		view.paused = true
		await advance(0.5,fps)
		check(view.sound.next_player == 1,"%dFPS pause at emission does not repeat sound" % fps)
		view.paused = false
		await advance(0.2,fps)
		check(view.sound.next_player == 1,"%dFPS after emission does not repeat sound" % fps)
	fresh(1)
	view.model.fire(40,60,1)
	view.consume_events()
	await advance(0.1)
	check(view.sound.next_player == 1,"MageS2 two components allocate one Sound player")
	fresh(2)
	view.model.fire(30,60,1)
	view.consume_events()
	view.sound.muted = true
	await advance(0.35)
	check(view.sound.next_player == 0,"Mute suppresses first BigfootS2 group")
	view.sound.muted = false
	await advance(0.2)
	check(view.sound.next_player == 1,"Unmute only plays next group, never replays skipped emission")
	fresh(4,["teleport"])
	view.model.use_item(0)
	view.model.fire(40,60,1)
	view.consume_events()
	await advance(0.15)
	check(view.sound.next_player == 1,"Teleport plays beacon sound once with no mobile shot duplicate")
	fresh(4,["dual_plus"])
	view.model.use_item(0)
	view.model.fire(40,60,1)
	view.consume_events()
	await advance(1.7)
	check(view.art.motion[0].pose == "recoil" and int(view.art.motion[0].recoil_weapon) == 0,"Dual+ replays S1 pose at1.7 before source spawn1.8")
	check(view.art.motion[0].pose_age < 0.05,"Second pose starts at salvo offset, not second emission")
	# AudioServer owns playback asynchronously; stop it before freeing the scene
	# so headless runs cannot quit with live streams from the last assertion.
	view.sound.stop_music()
	for player in view.sound.players:
		player.stop()
		player.stream = null
	await create_timer(0.1).timeout
	view.queue_free()
	await process_frame
	finish("CLASSIC TIMING SCENE CHECKS")
