extends RefCounted
## Conservative4× artwork. Native metadata owns geometry; invalid HD falls back.
const ROOT := "res://assets/hd/classic/lobby_smooth_4x/"
const DENSITY := 4.0
var catalog: Dictionary = {}
var _cache: Dictionary = {}

func _init() -> void:
	if FileAccess.file_exists(ROOT + "catalog.json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "catalog.json"))
		catalog = parsed if parsed is Dictionary else {}

func texture(key: String, native: Dictionary) -> Texture2D:
	if catalog.get("version") != 1 or catalog.get("scale") != DENSITY:
		return null
	var records = catalog.get("assets")
	if not records is Dictionary:
		return null
	var info = records.get(key)
	if not info is Dictionary or not info.get("source") is Dictionary:
		return null
	var relative := str(native.get("file", ""))
	if relative.is_empty() or info.get("file") != relative or info.source.get("record") != native or info.source.get("file") != "assets/classic/" + relative:
		return null
	var size := Vector2(native.size[0], native.size[1]) * DENSITY
	if info.get("size") != [size.x,size.y] or info.get("columns") != native.get("frames", 1) or info.get("rows") != 1:
		return null
	var path := ROOT + relative
	if not ResourceLoader.exists(path):
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	var sheet: Texture2D = _cache[path]
	return sheet if sheet != null and sheet.get_size() == size else null
