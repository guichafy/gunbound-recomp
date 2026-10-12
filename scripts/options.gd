extends RefCounted
## PopupGameOptions values that exist in this game (GameClientSettingsInformation).
## Accept saves them next to the profile; progress lives in the profile only.

var path: String
var sfx := 100
var scroll := 50
var background := true
var last_save_ok := true

func _init(save_path: String = "user://profile-options.json") -> void:
	path = save_path

## Camera drag multiplier: 0 → 0.5×, 50 → 1× (current behaviour), 100 → 2×.
func scroll_factor() -> float:
	return pow(2.0, (scroll - 50) / 50.0)

func load_options() -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return
	var data: Dictionary = parser.data
	if data.get("sfx") is float or data.get("sfx") is int:
		sfx = clampi(int(data.sfx), 0, 100)
	if data.get("scroll") is float or data.get("scroll") is int:
		scroll = clampi(int(data.scroll), 0, 100)
	if data.get("background") is bool:
		background = data.background

func save_options() -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_save_ok = false
		return false
	file.store_string(JSON.stringify({"version": 1, "sfx": sfx, "scroll": scroll, "background": background}, "\t"))
	file.close()
	last_save_ok = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK
	return last_save_ok
