extends "res://tests/support/suite.gd"

const ClientAudio = preload("res://scripts/client_audio.gd")
const Sound = preload("res://scripts/sound.gd")

func run() -> void:
	await exercise_audio()
	await create_timer(0.2).timeout
	finish("CLIENT AUDIO CHECKS")

func exercise_audio() -> void:
	ClientAudio.load_catalog()
	check(ClientAudio.records.size() == 96, "Native archive catalog has 96 entries")
	for name in ClientAudio.records:
		var stream := ClientAudio.native_stream(name)
		check(stream != null, "%s loads and preserves original PCM/MP3 payload" % name)
		if stream != null:
			check(stream.get_length() > 0.0, "%s has a playable duration" % name)
	var turn := ClientAudio.native_stream("turn.xes") as AudioStreamWAV
	var local_turn := ClientAudio.native_stream("turn2.xes") as AudioStreamWAV
	check(turn != null and local_turn != null and turn.data != local_turn.data, "Local and remote turn use distinct original XES")
	check(ClientAudio.native_stream("itemblast.xes") == null, "Absent native teleport sound stays absent")
	check(ClientAudio.native_stream("lightningblast.xes") == null, "Archive does not silently alias the misspelled lightning filename")
	var fallback := ClientAudio.preferred("missing.xes", "res://assets/openbound/hud/ClockSecond.mp3")
	check(fallback is AudioStreamMP3, "Missing native entry retains an explicitly supplied fallback")
	check(ClientAudio.preferred("missing.xes") == null, "Missing entry has no arbitrary replacement")
	if turn != null:
		var damaged: AudioStreamWAV = turn.duplicate()
		damaged.data = PackedByteArray([0, 0, 0, 0])
		check(not ClientAudio.valid_stream(damaged, ClientAudio.records["turn.xes"]), "Corrupt PCM fails native validation")
		var old_record: Dictionary = ClientAudio.records["turn.xes"]
		var corrupt_record := old_record.duplicate(true)
		corrupt_record.pcm_sha256 = "incorrect"
		ClientAudio.records["turn.xes"] = corrupt_record
		ClientAudio.cache.erase("turn.xes")
		check(ClientAudio.preferred("turn.xes", "res://assets/openbound/hud/ClockSecond.mp3") is AudioStreamMP3, "Invalid native payload uses explicit fallback")
		ClientAudio.records["turn.xes"] = old_record
		ClientAudio.cache.erase("turn.xes")
	var sound := Sound.new()
	root.add_child(sound)
	sound.muted = true
	check(sound.BATTLE_MUSIC == ["stage1", "stage2", "stage3", "stage4", "stage5", "stage6"], "Battle playlist contains the six native stage songs")
	for track in sound.BATTLE_MUSIC:
		var stream := sound.music_stream(track)
		check(stream is AudioStreamMP3 and not stream.loop, "%s preserves random-next scheduling and finite playback" % track)
		check(stream == ClientAudio.native_stream(track + ".mp3"), "%s chooses the validated native source" % track)
	check(sound.music_stream("sudden") == null, "Sudden music is not inserted without a sudden-death rule")
	sound.play_music()
	check(sound.music_wanted and not sound.music.playing, "Mute silences native music")
	sound.muted = false
	check(sound.music.playing and sound.BATTLE_MUSIC.has(sound.music_track), "Battle start selects native music")
	sound.music.finished.emit()
	check(sound.music.playing and sound.BATTLE_MUSIC.has(sound.music_track), "Finished native music selects another stage track")
	sound.set_music_volume(0.0)
	check(not sound.music.playing, "BGM zero stops native music")
	sound.set_music_volume(0.5)
	check(sound.music.playing, "BGM positive resumes native scheduling")
	sound.stop_music()
	check(not sound.music.playing and sound.music_track.is_empty(), "Menu stop resets native music")
	sound.play_turn(true)
	check(sound.players[0].stream == local_turn and sound.players[0].pitch_scale == 1.0, "Player turn uses turn2 without pitch changes")
	sound.play_turn(false)
	check(sound.players[1].stream == turn and sound.players[1].pitch_scale == 1.0, "CPU turn uses turn without pitch changes")
	sound.muted = true
	var previous := sound.next_player
	sound.play_turn(true)
	check(sound.next_player == previous, "Mute suppresses native turn playback")
	var playbacks: Array[WeakRef] = []
	for player in sound.players + [sound.music]:
		if player.has_stream_playback():
			playbacks.append(weakref(player.get_stream_playback()))
	sound.queue_free()
	await process_frame
	# The audio server releases the playbacks stopped by _exit_tree on its mix
	# thread; a loaded CI runner needed more than a fixed 0.1 s, so wait for them.
	var deadline := Time.get_ticks_msec() + 5000
	while playbacks.any(func(ref: WeakRef) -> bool: return ref.get_ref() != null) and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	check(playbacks.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "The audio server releases every stopped playback")
	ClientAudio.cache.clear()

