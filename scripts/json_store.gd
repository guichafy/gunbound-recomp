extends RefCounted
## Local JSON files of the profile and the options (ADR-070): tolerant reading
## and atomic writing (temporary file, then rename). No game rules here.

## The saved object, or null when the file is missing, unreadable or not an
## object (callers then keep their defaults).
static func read_dict(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return null
	return parser.data

## Writes `data` next to `path` and renames it over the old file; false on failure.
static func write_atomic(path: String, data: Dictionary) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK

static func is_number(value) -> bool:
	return value is int or value is float

## Integer field clamped to [low, high]; `fallback` when absent or not a number.
static func read_int(data: Dictionary, key: String, low: int, high: int, fallback: int) -> int:
	return clampi(int(data[key]), low, high) if is_number(data.get(key)) else fallback
