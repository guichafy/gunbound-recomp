extends RefCounted
## PopupGameOptions values that exist in this game (GameClientSettingsInformation).
## Accept saves them next to the profile; progress lives in the profile only.
## The equipped items (PopupSelectItem, REQ-36) are kept here too.

const Items = preload("res://scripts/items.gd")

var path: String
var sfx := 100
var bgm := 50
var scroll := 50
# Aiming Mode radio (GameClientSettingsInformation.AimType): 0 Drag, 1 Slice (default).
var aiming := 1
var background := true
# PlayerInformation.SelectedItemTypeList: stable item ids, 6 slots at most.
var items: Array = Items.DEFAULT_LOADOUT.duplicate()
var last_save_ok := true

func _init(save_path: String = "user://profile-options.json") -> void:
	path = save_path

func drag_aiming() -> bool:
	return aiming == 0

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
	if data.get("bgm") is float or data.get("bgm") is int:
		bgm = clampi(int(data.bgm), 0, 100)
	if data.get("scroll") is float or data.get("scroll") is int:
		scroll = clampi(int(data.scroll), 0, 100)
	if data.get("aiming") is float or data.get("aiming") is int:
		aiming = clampi(int(data.aiming), 0, 1)
	if data.get("background") is bool:
		background = data.background
	if data.get("items") is Array:
		items = Items.sanitize(data.items)

func save_options() -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_save_ok = false
		return false
	file.store_string(JSON.stringify({"version": 1, "sfx": sfx, "bgm": bgm, "scroll": scroll, "aiming": aiming, "background": background, "items": items}, "\t"))
	file.close()
	last_save_ok = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK
	return last_save_ok
