extends RefCounted
## PopupGameOptions values that exist in this game (GameClientSettingsInformation).
## Accept saves them next to the profile; progress lives in the profile only.
## The equipped items (PopupSelectItem, REQ-36) are kept here too.

const Items = preload("res://scripts/items.gd")
const JsonStore = preload("res://scripts/json_store.gd")

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
	var data = JsonStore.read_dict(path)
	if data == null:
		return
	sfx = JsonStore.read_int(data, "sfx", 0, 100, sfx)
	bgm = JsonStore.read_int(data, "bgm", 0, 100, bgm)
	scroll = JsonStore.read_int(data, "scroll", 0, 100, scroll)
	aiming = JsonStore.read_int(data, "aiming", 0, 1, aiming)
	if data.get("background") is bool:
		background = data.background
	if data.get("items") is Array:
		items = Items.sanitize(data.items)

func save_options() -> bool:
	last_save_ok = JsonStore.write_atomic(path, {"version": 1, "sfx": sfx, "bgm": bgm, "scroll": scroll, "aiming": aiming, "background": background, "items": items})
	return last_save_ok
