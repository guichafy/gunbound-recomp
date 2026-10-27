extends RefCounted
## Original sound.xfs resources. PCM/MP3 payload is checked after Godot import;
## a corrupt, missing or re-encoded native asset falls back to the declared source.
const CATALOG := "res://assets/xfs/audio/catalog.json"
const SOURCE_SHA := "081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023"
static var records: Dictionary = {}
static var loaded := false
static var cache: Dictionary = {}

static func load_catalog() -> void:
	if loaded:
		return
	loaded = true
	if not FileAccess.file_exists(CATALOG):
		return
	var document = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if not document is Dictionary or int(document.get("schema", 0)) != 1 or str(document.get("source_sha256", "")) != SOURCE_SHA:
		return
	for record in document.get("records", []):
		if record is Dictionary:
			records[str(record.get("entry", ""))] = record

static func sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

static func valid_stream(stream: AudioStream, record: Dictionary) -> bool:
	if stream is AudioStreamMP3:
		return str(record.get("encoding", "")) == "mp3_passthrough" and sha(stream.data) == str(record.get("entry_sha256", "")) and not stream.loop
	if stream is AudioStreamWAV:
		return str(record.get("encoding", "")) == "pcm_s16le" and stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.stereo and stream.mix_rate == 22050 and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED and sha(stream.data) == str(record.get("pcm_sha256", ""))
	return false

static func native_stream(entry: String) -> AudioStream:
	load_catalog()
	if cache.has(entry):
		return cache[entry]
	var stream: AudioStream = null
	var record: Dictionary = records.get(entry, {})
	var path := str(record.get("resource", ""))
	if path.begins_with("res://assets/xfs/audio/") and ResourceLoader.exists(path):
		var candidate = load(path)
		if candidate is AudioStream and valid_stream(candidate, record):
			stream = candidate
	cache[entry] = stream
	return stream

static func preferred(entry: String, fallback: String = "") -> AudioStream:
	var native := native_stream(entry)
	if native != null:
		return native
	return load(fallback) if not fallback.is_empty() and ResourceLoader.exists(fallback) else null
