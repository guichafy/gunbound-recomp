extends "res://tests/support/suite.gd"
## REQ-53/ADR-153: the client's track per screen (CLIENT_MUSIC_SCREENS.md).
## Expected names come from the 0x4eea30 callers: gamelist/store channel.mp3,
## room ready.mp3, battle stage%d.mp3 of stage.dat % 11, nothing at the result.

const ClientAudio = preload("res://scripts/client_audio.gd")
const Match = preload("res://scripts/match.gd")
const Options = preload("res://scripts/options.gd")
const PROFILE := "res://.tools/music-screens/test-profile.json"

func finish_match(scene, loser: int) -> void:
	if loser < 0:
		scene.model.actors[0].hp = 0
		scene.model.actors[1].hp = 0
	else:
		scene.model.actors[loser].hp = 0
	scene.model.check_end()
	scene.consume_events()
	scene.show_result()

func enter_battle(scene) -> void:
	scene.show_menu()
	scene.begin_loading()
	check(scene.screen == "loading" and scene.sound.music_request == "ready", "Loading keeps the room's ready.mp3")
	scene._tick_loading(10.0)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/music-screens"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE.get_basename() + "-options.json"))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PROFILE)
	scene.sound = load("res://scripts/sound.gd").new()
	scene.sound.muted = true
	root.add_child(scene)
	scene.set_process(false)
	scene.opening = 0
	var sound = scene.sound

	# Native resources: exact MP3 payloads, finite (the restart comes from finished).
	for track in [sound.LOBBY_MUSIC, sound.ROOM_MUSIC, "stage1"]:
		var stream = sound.music_stream(track)
		check(stream is AudioStreamMP3 and not stream.loop and stream == ClientAudio.native_stream(track + ".mp3"), "%s.mp3 is the validated sound.xfs entry" % track)
	for track in ["sudden", "title", "logo", "result", "win", "lose"]:
		check(sound.music_stream(track) == null, "No screen track named %s" % track)
	check(sound.battle_music(1) == "stage1" and sound.battle_music(12) == "stage1", "Miramo A (1) and B (12) play stage1.mp3")
	check(sound.battle_music(6) == "stage6", "Stage index maps straight to stage%d.mp3")
	for stage in [0, 7, 10, 11]:
		check(sound.BATTLE_MUSIC.has(sound.battle_music(stage)), "Stage %d without its own file draws one of stage1..6" % stage)

	# Muted suites: every screen still asks for its track, nothing plays.
	check(scene.screen == "lobby" and sound.music_request == "channel", "Lobby asks for channel.mp3")
	check(not sound.music.playing and not sound.music.has_stream_playback() and sound.music_track.is_empty(), "Muted lobby has no playback")
	scene.show_shop()
	check(scene.screen == "shop" and sound.music_request == "channel", "Store asks for channel.mp3")
	scene.leave_shop()
	check(scene.screen == "lobby" and sound.music_request == "channel", "Back to the lobby keeps channel.mp3")
	scene.show_menu()
	check(scene.screen == "menu" and sound.music_request == "ready", "Room asks for ready.mp3")
	scene.menu.open_settings()
	check(scene.menu.popup_open() and sound.music_request == "ready", "Room settings popup keeps ready.mp3")
	scene.menu.cancel_popup()
	scene.menu.choose_player_side()
	scene.menu.pick_vehicle(4)
	scene.menu.add_item("dual")
	check(sound.music_request == "ready", "Mobile grid and item panel keep ready.mp3")
	scene.show_shop()
	check(sound.music_request == "channel", "Store from the room drops ready.mp3")
	scene.leave_shop()
	check(scene.screen == "menu" and sound.music_request == "ready", "Back to the room asks for ready.mp3 again")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_key_input(escape)
	check(scene.screen == "lobby" and sound.music_request == "channel", "EXIT to the lobby leaves no room track")

	# Battle and the three results: the stage track stays under the window.
	for loser in [Match.CPU, Match.PLAYER, -1]:
		enter_battle(scene)
		check(scene.screen == "match" and sound.music_request == "stage1", "Start plays Miramo's stage1.mp3, not Theme*")
		finish_match(scene, loser)
		check(scene.overlays.kind == "result" and sound.music_request == "stage1", "Result %d keeps the battle track (no result music in the client)" % loser)
		check(not sound.music.playing and not sound.music.has_stream_playback(), "Muted result has no playback")
		scene.overlays.layer.find_child("ResultWindow", true, false).ok_button.pressed.emit()
		check(scene.screen == "menu" and sound.music_request == "ready", "OK returns to the room and to ready.mp3")
	enter_battle(scene)
	scene.quit_battle_options()
	check(scene.screen == "menu" and sound.music_request == "ready", "QUIT from the battle returns to ready.mp3")

	# Audible: same track carries on, another restarts, the end repeats it.
	scene.show_lobby()
	sound.muted = false
	check(sound.music.playing and sound.music_track == "channel", "Unmuted lobby plays channel.mp3")
	var playback = sound.music.get_stream_playback()
	scene.show_shop()
	check(sound.music.playing and sound.music.get_stream_playback() == playback, "Lobby→store does not restart channel.mp3 (0x4eea30)")
	scene.leave_shop()
	check(sound.music.get_stream_playback() == playback, "Store→lobby does not restart it either")
	scene.show_menu()
	check(sound.music.playing and sound.music_track == "ready" and sound.music.stream == ClientAudio.native_stream("ready.mp3"), "Room switches to ready.mp3")
	sound.music.stop()
	sound.music.finished.emit()
	check(sound.music.playing and sound.music_track == "ready", "ready.mp3 starts again when it ends")
	scene.options.bgm = 0
	scene.apply_options()
	check(not sound.music.playing and sound.music_request == "ready", "BGM 0 silences the room and keeps its request")
	scene.begin_loading()
	scene._tick_loading(10.0)
	check(not sound.music.playing and sound.music_request == "stage1", "BGM 0 silences the battle")
	finish_match(scene, Match.CPU)
	check(not sound.music.playing, "BGM 0 silences the result")
	scene.options.bgm = 50
	scene.apply_options()
	check(sound.music.playing and sound.music_track == "stage1" and sound.music.stream == ClientAudio.native_stream("stage1.mp3"), "BGM back on resumes stage1.mp3 under the result")
	check(is_equal_approx(sound.music_volume, Options.volume_gain(50)), "The BGM slider is the only music volume")
	sound.music.stop()
	sound.music.finished.emit()
	check(sound.music_track == "stage1", "stage1.mp3 repeats instead of drawing another stage")
	scene.overlays.layer.find_child("ResultWindow", true, false).ok_button.pressed.emit()
	check(sound.music.playing and sound.music_track == "ready", "OK switches the result to ready.mp3")

	sound.muted = true
	check(not sound.music.playing and not sound.music.has_stream_playback(), "Mute stops the screen track")
	var playbacks: Array[WeakRef] = []
	for player in sound.players + [sound.music]:
		if player.has_stream_playback():
			playbacks.append(weakref(player.get_stream_playback()))
	scene.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 5000
	while playbacks.any(func(ref: WeakRef) -> bool: return ref.get_ref() != null) and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE.get_basename() + "-options.json"))
	ClientAudio.cache.clear()
	finish("MUSIC SCREENS CHECKS")
