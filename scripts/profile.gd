extends RefCounted
## Local JSON profile. Tests use a separate path; the game uses user://.

const Catalog = preload("res://scripts/avatar_catalog.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
var catalog = Catalog.new()
var gold := 1000
var cash := 1000
var gender := 0
var owned: Array = []
var equipped: Dictionary = {}
var attributes: Array = [0,0,0,0,0,0,0,0]
var path: String
var nickname := "Piloto"
var xp := 0
var wins := 0
var matches := 0
var awarded: Array = []
var last_save_ok := true

func _init(save_path: String = "user://profile.json", avatar_catalog = null) -> void:
	path = save_path
	if avatar_catalog!=null:
		catalog=avatar_catalog
	for kind in [0, 1]:
		equipped[str(kind)] = catalog.defaults(kind)
		for key in equipped[str(kind)].values():
			if key not in owned:
				owned.append(key)

func load_profile() -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return
	var data: Dictionary = parser.data
	awarded.clear()
	if data.get("nickname") is String:
		nickname = clean_nickname(data.nickname)
	if data.get("xp") is float or data.get("xp") is int:
		xp = clampi(int(data.xp), 0, 1000000000)
	if data.get("matches") is float or data.get("matches") is int:
		matches = clampi(int(data.matches), 0, 1000000000)
	if data.get("wins") is float or data.get("wins") is int:
		wins = clampi(int(data.wins), 0, matches)
	if data.get("awarded") is Array:
		for item in data.awarded:
			if item is String:
				awarded.append(item)
		while awarded.size() > 64:
			awarded.pop_front()

	if data.has("shop") or data.get("version",1) != 1:
		load_shop(data.shop if data.get("shop") is Dictionary else {})

func clean_nickname(value: String) -> String:
	var result := value.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ").left(20)
	return "Piloto" if result.is_empty() else result

func level() -> int:
	return 1 + int(xp / 200.0)

func award(match_id: String, victory: bool, draw: bool = false, gold_delta: int = 0) -> int:
	if awarded.has(match_id):
		return 0
	var previous := snapshot()
	var reward := 120 if victory else (70 if draw else 45)
	xp += reward
	gold = clampi(gold + gold_delta, 0, 1000000000)
	matches += 1
	if victory:
		wins += 1
	awarded.append(match_id)
	if awarded.size() > 64:
		awarded.pop_front()
	if not save_profile():
		restore(previous)
		return 0
	return reward

func save_profile() -> bool:
	nickname = clean_nickname(nickname)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_save_ok = false
		return false
	file.store_string(JSON.stringify(snapshot(), "\t"))
	file.close()
	last_save_ok = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK
	return last_save_ok

func shop_data() -> Dictionary:
	return {"version":1,"gold":gold,"cash":cash,"gender":gender,"owned":owned.duplicate(),"equipped":equipped.duplicate(true),"attributes":attributes.duplicate()}
func snapshot() -> Dictionary:
	return {"version":3,"nickname":nickname,"xp":xp,"wins":wins,"matches":matches,"awarded":awarded.duplicate(),"shop":shop_data()}
func restore(data: Dictionary) -> void:
	nickname = data.nickname
	xp = data.xp
	wins = data.wins
	matches = data.matches
	awarded = data.awarded.duplicate()
	load_shop(data.shop)
func balance(value) -> int:
	return clampi(int(value), 0, 1000000000) if (value is int or value is float) and is_finite(float(value)) else 0
func load_shop(data: Dictionary) -> void:
	gold = balance(data.get("gold", 0))
	cash = balance(data.get("cash", 0))
	gender = 1 if data.get("gender") == 1 else 0
	owned.clear()
	for kind in [0,1]:
		equipped[str(kind)] = catalog.defaults(kind)
		for key in equipped[str(kind)].values():
			if key not in owned:
				owned.append(key)
	if data.get("owned") is Array:
		for key in data.owned:
			if key is String:
				key=catalog.canonical_key(key,gender)
			if key is String and not catalog.find(key).is_empty() and key not in owned:
				owned.append(key)
	if data.get("equipped") is Dictionary:
		for kind in [0,1]:
			var set_data = data.equipped.get(str(kind), {})
			if not set_data is Dictionary:
				continue
			for category in range(4):
				var key = catalog.canonical_key(str(set_data.get(str(category), "")),kind)
				var item: Dictionary = catalog.find(str(key))
				if key in owned and catalog.compatible(str(key), kind) and int(item.get("category", -1)) == category:
					equipped[str(kind)][str(category)] = key
	attributes = Attributes.sanitize(data.get("attributes", []) if data.get("attributes") is Array else [], level())
func owns(key: String) -> bool:
	return catalog.canonical_key(key,gender) in owned
func equipment_bonuses(equipment: Dictionary = {}) -> Array:
	return catalog.bonuses(equipped_set() if equipment.is_empty() else equipment)
func equipped_set(kind: int = -1) -> Dictionary:
	return equipped[str(gender if kind < 0 else clampi(kind,0,1))].duplicate(true)
func persist(previous: Dictionary) -> bool:
	if save_profile():
		return true
	restore(previous)
	return false
func purchase(key: String, currency: String) -> String:
	key=catalog.canonical_key(key,gender)
	var item: Dictionary = catalog.find(key)
	if not catalog.compatible(key, gender) or currency not in ["gold","cash"]:
		return "invalid"
	if owns(key):
		return "owned"
	if catalog.xfs_active and (item.get("source")!="xfs" or not item.get("buyable",false) or not item.get("art_available",false)):
		return "invalid"
	var price := int(item.get(currency + "_price", 0))
	if price <= 0:
		return "invalid"
	if (gold if currency == "gold" else cash) < price:
		return "funds"
	var previous := snapshot()
	if currency == "gold":
		gold -= price
	else:
		cash -= price
	owned.append(key)
	return "ok" if persist(previous) else "save"
func equip(key: String) -> bool:
	key=catalog.canonical_key(key,gender)
	if not owns(key) or not catalog.compatible(key, gender):
		return false
	var previous := snapshot()
	equipped[str(gender)][str(int(catalog.find(key).category))] = key
	return persist(previous)
func set_gender(value: int) -> bool:
	if value not in [0,1]:
		return false
	var previous := snapshot()
	gender = value
	return persist(previous)
func commit_attributes(values: Array) -> bool:
	if not Attributes.valid(values, level()):
		return false
	var previous := snapshot()
	attributes = values.duplicate()
	return persist(previous)
