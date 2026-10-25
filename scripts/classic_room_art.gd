extends RefCounted
## Room-only conservative artwork. No changes to battle item presentation.
const Conservative = preload("res://scripts/classic_lobby_art.gd")
const Items = preload("res://scripts/items.gd")
const ROOT := "res://assets/hd/classic/room_smooth_4x/"
const REFERENCE_ROOT := "res://assets/hd/classic/room_reference_4x/"
const POLISH_ROOT := "res://assets/hd/classic/room_polish_4x/"
var polish_art = Conservative.new(POLISH_ROOT)
var polish_keys: Array = []
var reference_art = Conservative.new(REFERENCE_ROOT)
var reference_keys: Array = []
const PORTRAITS := {4:1,1:2,3:3,5:4,2:5,6:6,7:7,8:8,9:9,10:10,11:11,12:12,13:13,16:16}
var art = Conservative.new(ROOT)
var item_art = Conservative.new(ROOT,"assets/openbound/")
var records: Dictionary = {}

func _init() -> void:
	var native = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/room/details/catalog.json"))
	if native is Dictionary and native.get("assets") is Dictionary:
		records = native.assets
	var reference = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/room/reference/catalog.json"))
	if reference is Dictionary and reference.get("assets") is Dictionary:
		reference_keys = reference.assets.keys()
		records.merge(reference.assets)
	var polish = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/room/polish/catalog.json"))
	if polish is Dictionary and polish.get("assets") is Dictionary:
		polish_keys = polish.assets.keys()
		records.merge(polish.assets)
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/manifest.json"))
	records["room_back"] = manifest.images.room_back

func image(key: String) -> Texture2D:
	var record: Dictionary = records.get(key,{})
	if record.is_empty():
		return null
	var provider = polish_art if key in polish_keys else (reference_art if key in reference_keys else art)
	var hd: Texture2D = provider.texture(key,record)
	return hd if hd != null else load("res://assets/classic/" + str(record.file))

func frame(key: String, index: int) -> AtlasTexture:
	var record: Dictionary = records.get(key,{})
	if record.is_empty():
		return null
	var sheet := image(key)
	if sheet == null:
		return null
	var density := 4.0 if (sheet.resource_path.begins_with(ROOT) or sheet.resource_path.begins_with(REFERENCE_ROOT) or sheet.resource_path.begins_with(POLISH_ROOT)) else 1.0
	var cell := Vector2(record.frame_size[0],record.frame_size[1])
	var safe := clampi(index,0,int(record.frames)-1)
	var result := AtlasTexture.new()
	result.atlas = sheet
	result.region = Rect2(Vector2(safe*cell.x,0)*density,cell*density)
	return result

func item_frame(id: String, state: int, catalog: bool = false) -> AtlasTexture:
	return frame(("catalog_" if catalog else "equipped_")+id,1 if state==3 else 0)

func style_item(button: TextureButton, id: String, catalog: bool = false) -> void:
	# Native catalog has normal/disabled only. Pointer and press retain native art.
	button.texture_normal = item_frame(id,0,catalog)
	button.texture_hover = item_frame(id,0,catalog)
	button.texture_pressed = item_frame(id,0,catalog)
	button.texture_disabled = item_frame(id,3,catalog)
	button.set_meta("activated",false)


func style_reference(button: TextureButton, key: String, shown: int = 0) -> void:
	var atlas := key == "room_random"
	button.texture_normal = frame(key,shown) if atlas else image(key+"_0")
	button.texture_hover = frame(key,1 if shown==0 else shown) if atlas else image(key+"_1")
	button.texture_pressed = frame(key,2) if atlas else image(key+"_2")
	button.texture_disabled = frame(key,3) if atlas else image(key+"_3")
