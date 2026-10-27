extends RefCounted
## Original client resources. The historical paths below are proved native
## imports with identical RGBA, never substitutes from another game version.
## PNG provenance/pixel equality is checked by test_client_weather_source.py;
## runtime checks the imported dimensions and resource type (also in a PCK).
const ARCHIVE_SHA := "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
const FILES := {
	"FirewallTexture": ["weather/FirewallTexture.png", "weather/native/FirewallTexture.png", Vector2(256,256)],
	"LightningTexture": ["weather/LightningTexture.png", "weather/native/LightningTexture.png", Vector2(256,256)],
	"TornadoTexture": ["weather/TornadoTexture.png", "weather/native/TornadoTexture.png", Vector2(256,256)],
	"CrashTexture": ["weather/CrashTexture.png", "mage/original/CrashTexture.png", Vector2(256,256)],
	"Lightning": ["weather/Lightning.png", "lightning/Lightning.png", Vector2(256,256)],
	"LaserEffect": ["thor/LaserEffect.png", "aduka/ThorEffect.png", Vector2(256,256)],
	"ThorBody": ["thor/ThorBody.png", "aduka/ThorBody.png", Vector2(2198,600)],
	"ThorLight": ["thor/ThorLight.png", "aduka/ThorLight.png", Vector2(2450,504)],
}

static func valid_texture(path: String, size: Vector2) -> bool:
	if path.is_empty() or not ResourceLoader.exists(path):return false
	var value = load(path)
	return value is Texture2D and value.get_size()==size

## Optional candidate lets tests exercise missing/wrong-resource fallbacks.
static func path(key: String, candidate: String = "") -> String:
	if not FILES.has(key):return ""
	var record: Array = FILES[key]
	var primary := "res://assets/xfs/"+str(record[0]) if candidate.is_empty() else candidate
	if valid_texture(primary,record[2]):return primary
	var fallback := "res://assets/openbound/"+str(record[1])
	return fallback if valid_texture(fallback,record[2]) else ""

static func texture(key: String) -> Texture2D:
	var selected := path(key)
	return load(selected) if not selected.is_empty() else null

static func thor_metadata(candidate: String = "res://assets/xfs/thor/thor_native.json") -> Dictionary:
	for selected in [candidate,"res://assets/openbound/aduka/thor_native.json"]:
		if not FileAccess.file_exists(selected):continue
		var meta = JSON.parse_string(FileAccess.get_file_as_string(selected))
		if not meta is Dictionary or meta.get("archive_sha256")!=ARCHIVE_SHA:continue
		if meta.get("columns")!=14 or not meta.get("sheets") is Dictionary or not meta.get("states") is Dictionary:continue
		if meta.sheets.size()!=2:continue
		var valid := true
		for name in ["ThorBody.png","ThorLight.png"]:
			var info = meta.sheets.get(name)
			var expected_cell := [157.0,150.0] if name=="ThorBody.png" else [175.0,126.0]
			var expected_origin := [104.0,75.0] if name=="ThorBody.png" else [100.0,68.0]
			if not info is Dictionary or info.get("cell")!=expected_cell or info.get("origin")!=expected_origin or info.get("frames")!=56:
				valid=false
		for state in ["normal","active","fire"]:
			var sequence = meta.states.get(state)
			var first := 0 if state=="normal" else (20 if state=="active" else 40)
			var count := 16 if state=="fire" else 20
			if not sequence is Dictionary or not sequence.get("frames") is Array or not sequence.get("durations") is Array:
				valid=false
				continue
			if sequence.frames.size()!=count or sequence.durations.size()!=count:
				valid=false
				continue
			for index in count:
				if int(sequence.frames[index])!=first+index or int(sequence.durations[index])!=1:valid=false
		if valid:return meta
	return {}
