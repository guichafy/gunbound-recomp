extends RefCounted
## Conservative4× sheets of a native mobile (ADR-104). frames.json owns the
## geometry; a sheet whose catalog record, grid or size disagrees stays native.
const DENSITY := 4.0
const ATLAS := "CharacterSpritesheet.png"

## Validated HD textures by sheet name. `native` maps each sheet name to the
## loaded native texture; only those names can be replaced.
static func load_sheets(root: String, kind: String, folder: String, meta: Dictionary, native: Dictionary) -> Dictionary:
	return validated(root, read_catalog(root), kind, folder, meta, native)

static func read_catalog(root: String) -> Dictionary:
	if root.is_empty() or not FileAccess.file_exists(root + "/catalog.json"):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(root + "/catalog.json"))
	return parsed if parsed is Dictionary else {}

static func validated(root: String, catalog: Dictionary, kind: String, folder: String, meta: Dictionary, native: Dictionary) -> Dictionary:
	var result := {}
	if catalog.get("version") != 1 or catalog.get("scale") != DENSITY or catalog.get("kind") != kind:
		return result
	var source_folder := folder.trim_prefix("res://")
	var frames = catalog.get("frames_json")
	# The derivative belongs to this exact native metadata.
	if not frames is Dictionary or frames.get("file") != source_folder + "/frames.json" or frames.get("sha256") != FileAccess.get_sha256(folder + "/frames.json"):
		return result
	var records = catalog.get("sheets")
	if not records is Dictionary:
		return result
	for name in native:
		var info = records.get(name)
		var texture: Texture2D = native[name]
		if not info is Dictionary or not info.get("source") is Dictionary or texture == null:
			continue
		var record = null if name == ATLAS else meta.get("sheets", {}).get(name)
		var cell = meta.get("cell") if name == ATLAS else (record.get("cell") if record is Dictionary else null)
		var size := texture.get_size()
		if info.source.get("file") != source_folder + "/" + name or info.source.get("record") != record or info.source.get("size") != [size.x, size.y]:
			continue
		if cell == null or info.get("cell") != cell or info.get("columns") != size.x / float(cell[0]) or info.get("rows") != size.y / float(cell[1]):
			continue
		if info.get("size") != [size.x * DENSITY, size.y * DENSITY]:
			continue
		var path: String = root + "/" + str(name)
		if not ResourceLoader.exists(path):
			continue
		var sheet: Texture2D = load(path)
		if sheet != null and sheet.get_size() == size * DENSITY:
			result[name] = sheet
	return result
