extends Node
## Small pooled audio player; originals for Mage, synthesized fallback for others.

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var muted := false
var next_player := 0
# PopupGameOptions SFX slider (0–100 → 0–1), linear over the base −19 dB.
const BASE_DB := -19.0
var volume := 1.0

func _exit_tree() -> void:
	for player in players:
		player.stop()
		player.stream = null
	streams.clear()

func _ready() -> void:
	for i in range(5):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	set_volume(volume)
	for kind in ["fire", "explosion", "turn", "result"]:
		streams[kind] = synthesize(kind)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	for player in players:
		player.volume_db = BASE_DB + linear_to_db(maxf(volume, 0.0001))

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
