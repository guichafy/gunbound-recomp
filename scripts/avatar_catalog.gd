extends RefCounted
## XFS catalog plus legacy identities retained for saved equipment and fixtures.
var entries: Dictionary = {}
var xfs_active := false
const LEGACY_ALIASES := {
	"0:0:0":"xfs:0:0:0","0:0:1":"xfs:0:0:1","0:0:2":"xfs:0:0:2","0:0:3":"xfs:0:0:3",
	"1:0:0":"xfs:1:0:0","0:1:0":"xfs:0:1:0","0:1:1":"xfs:0:1:1","0:1:2":"xfs:0:1:2",
	"0:1:3":"xfs:0:1:3","1:1:0":"xfs:1:1:0","0:2:1":"xfs:0:2:2",
	"2:3:0":"xfs:2:3:0","2:3:1":"xfs:2:3:1"
}
static func legacy():
	var rows = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/avatars/catalog.json"))
	return load("res://scripts/avatar_catalog.gd").new(rows)
func _init(rows: Array = []) -> void:
	if rows.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/avatars/catalog.json"))
		if parsed is Array:
			rows = parsed
		var path := "res://assets/xfs/avatars/catalog.json"
		if FileAccess.file_exists(path):
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if data is Dictionary and data.get("version")==1 and data.get("records") is Array:
				rows = rows+data.records
				xfs_active = true
	for row in rows:
		entries[str(row.key)] = row.duplicate(true)
		if row.get("bonuses") is Array:
			entries[str(row.key)].bonuses=row.bonuses.map(func(value): return int(value))
func canonical_key(key: String, gender: int = 0) -> String:
	if not xfs_active:
		return key
	if key=="2:2:0":
		return "xfs:%d:2:0" % gender
	return LEGACY_ALIASES.get(key,key)
func find(key: String) -> Dictionary:
	return entries.get(key, {})
func key_for(gender: int, category: int, id: int) -> String:
	for kind in [gender, 2]:
		var key := ("xfs:" if xfs_active else "")+"%d:%d:%d" % [kind, category, id]
		if entries.has(key):
			return key
	return ""
func items(gender: int, category: int) -> Array:
	var result: Array = []
	for item in entries.values():
		if xfs_active and item.get("source")!="xfs":
			continue
		if int(item.category) == category and int(item.gender) in [gender, 2]:
			result.append(item)
	result.sort_custom(func(a, b): return int(a.id) < int(b.id))
	return result
func inventory_items(gender: int, category: int) -> Array:
	var result := items(gender,category)
	if xfs_active:
		for item in entries.values():
			if item.get("source")!="xfs" and canonical_key(item.key,gender)==item.key and int(item.category)==category and int(item.gender) in [gender,2]:
				result.append(item)
	return result
func bonuses(equipment: Dictionary) -> Array:
	var total: Array=[0,0,0,0,0,0,0,0]
	for category in range(4):
		var item := find(str(equipment.get(str(category),"")))
		var values: Array=item.get("bonuses",[])
		if int(item.get("category",-1))!=category or values.size()!=8:
			continue
		for i in range(8):
			total[i]+=int(values[i])
	return total
func defaults(gender: int) -> Dictionary:
	var result := {}
	for category in range(4):
		result[str(category)] = key_for(gender, category, 0)
	return result
func compatible(key: String, gender: int) -> bool:
	var item := find(key)
	return not item.is_empty() and int(item.gender) in [gender, 2]
