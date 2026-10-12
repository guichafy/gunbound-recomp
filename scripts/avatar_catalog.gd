extends RefCounted
## OpenBound identifiers remain gender/category/ID, including shared Unissex.
var entries: Dictionary = {}
func _init(rows: Array = []) -> void:
	if rows.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/avatars/catalog.json"))
		if parsed is Array:
			rows = parsed
	for row in rows:
		entries[str(row.key)] = row.duplicate(true)
func find(key: String) -> Dictionary:
	return entries.get(key, {})
func key_for(gender: int, category: int, id: int) -> String:
	for kind in [gender, 2]:
		var key := "%d:%d:%d" % [kind, category, id]
		if entries.has(key):
			return key
	return ""
func items(gender: int, category: int) -> Array:
	var result: Array = []
	for item in entries.values():
		if int(item.category) == category and int(item.gender) in [gender, 2]:
			result.append(item)
	result.sort_custom(func(a, b): return int(a.id) < int(b.id))
	return result
func defaults(gender: int) -> Dictionary:
	var result := {}
	for category in range(4):
		result[str(category)] = key_for(gender, category, 0)
	return result
func compatible(key: String, gender: int) -> bool:
	var item := find(key)
	return not item.is_empty() and int(item.gender) in [gender, 2]
