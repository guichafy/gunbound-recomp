extends Node
## Pooled audio. Original client music and proven turn sounds, with validated fallback.
const ClientAudio = preload("res://scripts/client_audio.gd")
# Random scheduling is a declared offline adaptation; resources are native.
# sudden.mp3 is preserved, but there is no sudden-death rule in this training.
const BATTLE_MUSIC := ["stage1", "stage2", "stage3", "stage4", "stage5", "stage6"]
const LEGACY_MUSIC := ["ThemeBeta-1", "ThemeBeta-2", "ThemeS1-1", "ThemeS1-2", "ThemeS1-3", "ThemeS1-4"]
var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
# Test/global mute silences effects and music.
var muted := false:
	set(value):
		muted = value
		update_music()
var next_player := 0
# Native option attenuation is converted to linear amplitude by Options.
# The existing master −19dB normalization remains a declared adaptation.
const BASE_DB := -19.0
var volume := 1.0
var music: AudioStreamPlayer
var music_volume := 0.5
var music_wanted := false
var music_track := ""
var music_rng := RandomNumberGenerator.new()

func _exit_tree() -> void:
	for player in players:
		player.stop()
		player.stream = null
	if music != null:
		music.stop()
		music.stream = null
	streams.clear()

func _ready() -> void:
	for i in range(5):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	set_volume(volume)
	music = AudioStreamPlayer.new()
	music.finished.connect(next_song)
	add_child(music)
	set_music_volume(music_volume)
	music_rng.randomize()
	for kind in ["fire", "explosion", "turn", "result"]:
		streams[kind] = synthesize(kind)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	for player in players:
		player.volume_db = BASE_DB + (linear_to_db(volume) if volume>0.0 else -100.0)
		if volume<=0.0:
			player.stop()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if music != null:
		music.volume_db = BASE_DB + (linear_to_db(music_volume) if music_volume>0.0 else -100.0)
	update_music()

## Battle starts the music; the menu stops it.
func play_music() -> void:
	music_wanted = true
	update_music()

func stop_music() -> void:
	music_wanted = false
	update_music()

func update_music() -> void:
	if music == null:
		return
	var audible := music_wanted and not muted and music_volume > 0.0
	if audible and not music.playing:
		next_song()
	elif not audible and music.playing:
		music.stop()
		music.stream = null
		music_track = ""

func next_song() -> void:
	if not music_wanted or muted or music_volume <= 0.0:
		return
	music_track = BATTLE_MUSIC[music_rng.randi_range(0, BATTLE_MUSIC.size() - 1)]
	music.stream = music_stream(music_track)
	if music.stream == null:
		return
	music.play()

func music_stream(track: String) -> AudioStream:
	var index := BATTLE_MUSIC.find(track)
	if index < 0:
		return null
	return ClientAudio.preferred(track + ".mp3", "res://assets/openbound/music/%s.mp3" % LEGACY_MUSIC[index])

## Native 0x4ce1da compares the new actor with the local player before playback:
## turn2.xes for local; turn.xes for the other actor. No pitch transposition.
func play_turn(local_player: bool) -> void:
	var original := ClientAudio.native_stream("turn2.xes" if local_player else "turn.xes")
	play("turn", original)

func play(kind: String, original: AudioStream = null, pitch: float = 1.0) -> void:
	if muted or volume <= 0.0 or (original == null and not streams.has(kind)):
		return
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = original if original != null else streams[kind]
	player.pitch_scale = pitch
	player.play()

func synthesize(kind: String) -> AudioStreamWAV:
	var duration := 0.5 if kind == "explosion" or kind == "result" else 0.18
	var samples := int(22050.0 * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 19
	for i in range(samples):
		var time := float(i) / 22050.0
		var progress := time / duration
		var value := 0.0
		if kind == "explosion":
			value = (noise.randf_range(-1.0, 1.0) * 0.65 + sin(time * TAU * 65.0) * 0.35) * exp(-progress * 7.0)
		elif kind == "fire":
			value = sin(TAU * (480.0 * time - 900.0 * time * time)) * (1.0 - progress) * 0.7
		elif kind == "turn":
			value = (sin(time * TAU * 660.0) + sin(time * TAU * 990.0)) * sin(progress * PI) * 0.25
		else:
			var frequency := 440.0 * pow(2.0, floor(progress * 4.0) / 4.0)
			value = sin(time * TAU * frequency) * sin(progress * PI) * 0.5
		var sample := int(clampf(value, -1.0, 1.0) * 32767.0) & 0xffff
		data[i * 2] = sample & 0xff
		data[i * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream
