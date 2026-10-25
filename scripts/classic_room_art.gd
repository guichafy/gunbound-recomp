extends RefCounted
## Room-only conservative artwork. No changes to battle item presentation.
const Conservative = preload("res://scripts/classic_lobby_art.gd")
const Items = preload("res://scripts/items.gd")
const ROOT := "res://assets/hd/classic/room_smooth_4x/"
const PORTRAITS := {4:1,1:2,3:3,5:4,2:5,6:6,7:7,8:8,9:9,10:10,11:11,12:12,13:13,16:16}
var art = Conservative.new(ROOT)
var item_art = Conservative.new(ROOT,"assets/openbound/")
var records: Dictionary = {}

func _init() -> void:
	var native = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/room/details/catalog.json"))
	if native is Dictionary and native.get("assets") is Dictionary:
		records = native.assets
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/manifest.json"))
	records["room_back"] = manifest.images.room_back

func image(key: String) -> Texture2D:
	var record: Dictionary = records.get(key,{})
	if record.is_empty():
		return null
	var hd: Texture2D = art.texture(key,record)
	return hd if hd != null else load("res://assets/classic/" + str(record.file))

func frame(key: String, index: int) -> AtlasTexture:
	var record: Dictionary = records.get(key,{})
	if record.is_empty():
		return null
	var sheet := image(key)
	if sheet == null:
		return null
	var density := 4.0 if sheet.resource_path.begins_with(ROOT) else 1.0
	var cell := Vector2(record.frame_size[0],record.frame_size[1])
	var safe := clampi(index,0,int(record.frames)-1)
	var result := AtlasTexture.new()
	result.atlas = sheet
	result.region = Rect2(Vector2(safe*cell.x,0)*density,cell*density)
	return result

func item_frame(id: String, state: int) -> AtlasTexture:
	var name: String = str(Items.definition(id).file)
	var width := 73.0 if Items.slots(id)==2 else 37.0
	var record := {"file":"items/Item"+name+".png","size":[width*4,36.0],"frame_size":[width,36.0],"frames":4.0}
	var hd: Texture2D = item_art.texture("item_"+name,record)
	var density := 4.0 if hd != null else 1.0
	var result := AtlasTexture.new()
	result.atlas = hd if hd != null else load("res://assets/openbound/"+str(record.file))
	result.region = Rect2(Vector2(clampi(state,0,3)*width,0)*density,Vector2(width,36)*density)
	return result

func style_item(button: TextureButton, id: String) -> void:
	button.texture_normal = item_frame(id,0)
	button.texture_hover = item_frame(id,1)
	button.texture_pressed = item_frame(id,2)
	button.texture_disabled = item_frame(id,3)
	button.set_meta("activated",false)
