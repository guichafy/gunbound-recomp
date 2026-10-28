extends SceneTree
## Captura o mixer real da cena; o impacto é provocado pela fixture.
const OUTPUT := "res://docs/boomer-audio/boomer-t2-mixer.wav"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var record := AudioEffectRecord.new()
	AudioServer.add_bus_effect(0, record)
	var view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/boomer-record-profile.json")
	root.add_child(view)
	view.set_process(false)
	view.opening = 0
	view.start_match()
	view.sound.stop_music()
	view.model.start(6, 1, 42, "", "original", null, [])
	view.art.reset(view.model.actors)
	view.consume_events()
	view.paused = false
	view.sound.muted = false
	view.sound.next_player = 0
	view.model.fire(60, 50, 1)
	view.consume_events()
	record.set_recording_active(true)
	for i in range(60):
		view._process(1.0 / 60.0)
		await create_timer(1.0 / 60.0).timeout
	var emissions: int = view.sound.next_player
	var fire_streams := true
	for i in range(4):
		fire_streams = fire_streams and view.sound.players[i].stream != null and view.sound.players[i].stream.resource_path.ends_with("62fire.wav")
	if emissions != 4 or not fire_streams or view.model.projectiles.is_empty():
		push_error("Esperadas quatro emissões T2 e projétil ativo; obtidas %d" % emissions)
		quit(1)
		return
	var shell: Dictionary = view.model.projectiles[0].duplicate(true)
	view.model.events.clear()
	view.model.explode(Vector2(500, 250), -1, shell)
	view.consume_events()
	var impacts: int = view.sound.next_player
	var blast_stream: bool = view.sound.players[4].stream != null and view.sound.players[4].stream.resource_path.ends_with("62blast.wav")
	for i in range(45):
		await create_timer(1.0 / 60.0).timeout
	record.set_recording_active(false)
	var recording: AudioStreamWAV = record.get_recording()
	var result := recording.save_to_wav(ProjectSettings.globalize_path(OUTPUT))
	print("BOOMER AUDIO: emissions=%d impact_pool=%d bytes=%d save=%d" % [emissions, impacts, recording.data.size(), result])
	for player in view.sound.players:
		player.stop()
	view.queue_free()
	await process_frame
	quit(0 if impacts == 0 and blast_stream and result == OK and recording.data.size() > 0 else 1)
