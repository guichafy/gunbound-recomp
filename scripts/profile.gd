extends RefCounted
## Local JSON profile. Tests use a separate path; the game uses user://.

var path: String
var nickname := "Piloto"
var xp := 0
var wins := 0
var matches := 0
var awarded: Array = []
var last_save_ok := true

func _init(save_path: String = "user://profile.json") -> void:
	path = save_path

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

func clean_nickname(value: String) -> String:
	var result := value.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ").left(20)
	return "Piloto" if result.is_empty() else result

func level() -> int:
	return 1 + int(xp / 200.0)

func award(match_id: String, victory: bool, draw: bool = false) -> int:
	if awarded.has(match_id):
		return 0
	var reward := 120 if victory else (70 if draw else 45)
	xp += reward
	matches += 1
	if victory:
		wins += 1
	awarded.append(match_id)
	if awarded.size() > 64:
		awarded.pop_front()
	save_profile()
	return reward

func save_profile() -> bool:
	nickname = clean_nickname(nickname)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_save_ok = false
		return false
	file.store_string(JSON.stringify({"version": 1, "nickname": nickname, "xp": xp, "wins": wins, "matches": matches, "awarded": awarded}, "\t"))
	file.close()
	last_save_ok = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK
	return last_save_ok
