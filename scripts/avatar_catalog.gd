extends RefCounted
## XFS catalog plus legacy identities retained for saved equipment and fixtures.
var entries: Dictionary = {}
var xfs_active := false
var classic: Dictionary = {}
const LEGACY_ALIASES := {
	"0:0:0":"xfs:0:0:0","0:0:1":"xfs:0:0:1","0:0:2":"xfs:0:0:2","0:0:3":"xfs:0:0:3",
	"1:0:0":"xfs:1:0:0","0:1:0":"xfs:0:1:0","0:1:1":"xfs:0:1:1","0:1:2":"xfs:0:1:2",
	"0:1:3":"xfs:0:1:3","1:1:0":"xfs:1:1:0","0:2:1":"xfs:0:2:2",
	"2:3:0":"xfs:2:3:0","2:3:1":"xfs:2:3:1"
}
static func legacy():
	var rows = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/avatars/catalog.json"))
	return load("res://scripts/avatar_catalog.gd").new(rows)
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

## Classic slot byte from jglim/gunbound-server: body, head, eye, flag.
## Our category stays head, body, eye, flag so saved keys do not move.
const SLOT_CATEGORY: Array = [1, 0, 2, 3]
const CATEGORY_SLOT: Array = [1, 0, 2, 3]
const MALE_BIT := 0x8000

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
	if xfs_active:
		_attach_classic()

func _attach_classic() -> void:
	var path := "res://assets/xfs/avatars/classic.json"
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.get("records") is Array:
		return
	classic = data
	for row in data.records:
		var item: Dictionary = entries.get(str(row.key), {})
		if item.is_empty():
			continue
		item["dat"] = str(row.dat)
		item["slot"] = int(row.slot)
		item["slot_name"] = str(row.slot_name)

func slot_of(item: Dictionary) -> int:
	if item.has("slot"):
		return int(item.slot)
	var category := int(item.get("category", 0))
	return int(CATEGORY_SLOT[category]) if category >= 0 and category < CATEGORY_SLOT.size() else -1

## WORD the Thor's Hammer client sends. Bit 15 is male. An empty flag is 0
## for both genders, matching /gender and the default equipped bytes.
## Returns -1 when a gendered piece is encoded for the other gender.
func classic_word(item: Dictionary, wearer_gender: int) -> int:
	if item.is_empty():
		return -1
	var piece_gender := int(item.get("gender", -1))
	if piece_gender in [0, 1] and piece_gender != wearer_gender:
		return -1
	var id := int(item.id) & 0x7FFF
	if slot_of(item) == 3 and id == 0:
		return 0
	return id | (MALE_BIT if wearer_gender == 0 else 0)

func classic_dword(item: Dictionary, wearer_gender: int) -> int:
	var word := classic_word(item, wearer_gender)
	var slot := slot_of(item)
	if word < 0 or slot < 0:
		return -1
	return word | (slot << 16)

## Resolves one extended DWORD (buy/equip inventory code). Unknown ids, such as
## avatars added after version 280, return an empty dictionary.
func find_classic(dword: int) -> Dictionary:
	if dword < 0 or (dword >> 24) != 0:
		return {}
	var slot := (dword >> 16) & 0xFF
	if slot < 0 or slot > 3:
		return {}
	var word := dword & 0xFFFF
	var id := word & 0x7FFF
	var wearer_gender := 0 if (word & MALE_BIT) != 0 else 1
	var category: int = SLOT_CATEGORY[slot]
	var key := key_for(2 if category == 3 else wearer_gender, category, id)
	var item := find(key)
	if item.is_empty() or int(item.get("id", -1)) != id or int(item.get("category", -1)) != category:
		return {}
	if category == 3:
		if int(item.gender) != 2:
			return {}
	elif int(item.gender) != wearer_gender:
		return {}
	return item

## Eight equipped bytes, in slot order: body, head, eye, flag.
func encode_equipped(equipment: Dictionary, wearer_gender: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(8)
	for slot in range(4):
		var category: int = SLOT_CATEGORY[slot]
		var item := find(str(equipment.get(str(category), "")))
		var word := classic_word(item, wearer_gender) if not item.is_empty() else -1
		if word < 0:
			word = 0 if slot == 3 else (MALE_BIT if wearer_gender == 0 else 0)
		out[slot * 2] = word & 0xFF
		out[slot * 2 + 1] = (word >> 8) & 0xFF
	return out

func decode_equipped(data: PackedByteArray) -> Dictionary:
	var result := {}
	for slot in range(4):
		var word := int(data[slot * 2]) | (int(data[slot * 2 + 1]) << 8)
		var item := find_classic(word | (slot << 16))
		result[str(SLOT_CATEGORY[slot])] = str(item.get("key", ""))
	return result
