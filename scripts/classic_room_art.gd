extends RefCounted
## Room-only conservative artwork. No changes to battle item presentation.
const Conservative = preload("res://scripts/classic_lobby_art.gd")
const Items = preload("res://scripts/items.gd")
const ROOT := "res://assets/hd/classic/room_smooth_4x/"
const REFERENCE_ROOT := "res://assets/hd/classic/room_reference_4x/"
const POLISH_ROOT := "res://assets/hd/classic/room_polish_4x/"
const STATUS_ROOT := "res://assets/hd/classic/room_status_4x/"
const SETTINGS_ROOT := "res://assets/hd/classic/room_settings_4x/"
var settings_art = Conservative.new(SETTINGS_ROOT)
var settings_keys: Array = []
var status_art = Conservative.new(STATUS_ROOT)
var status_keys: Array = []
var polish_art = Conservative.new(POLISH_ROOT)
var polish_keys: Array = []
var reference_art = Conservative.new(REFERENCE_ROOT)
var reference_keys: Array = []
const ANDROID_PREVIEWS := "res://assets/hd/classic/android_map_previews/"
var android_mode := OS.has_feature("android")
var android_previews: Dictionary = {}
var android_cache: Dictionary = {}
const PORTRAITS := {4:1,1:2,3:3,5:4,2:5,6:6,7:7,8:8,9:9,10:10,11:11,12:12,13:13,16:16}
var art = Conservative.new(ROOT)
var item_art = Conservative.new(ROOT,"assets/openbound/")
var records: Dictionary = {}

func _init() -> void:
	if FileAccess.file_exists(ANDROID_PREVIEWS+"catalog.json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(ANDROID_PREVIEWS+"catalog.json"))
		if parsed is Dictionary:android_previews=parsed
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
	var status = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/room/status/catalog.json"))
	if status is Dictionary and status.get("assets") is Dictionary:
		status_keys = status.assets.keys()
		records.merge(status.assets)
	var settings = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/room/settings/catalog.json"))
	if settings is Dictionary and settings.get("assets") is Dictionary:
		settings_keys = settings.assets.keys()
		records.merge(settings.assets)
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/manifest.json"))
	records["room_back"] = manifest.images.room_back

func image(key: String) -> Texture2D:
	# Android must never load the11968px strip, including fallback paths.
	if android_mode and key=="room_maps":return load("res://assets/classic/room/details/maps.png")
	var record: Dictionary = records.get(key,{})
	if record.is_empty():
		return null
	var provider = polish_art if key in polish_keys else (reference_art if key in reference_keys else art)
	if key in status_keys:
		provider = status_art
	if key in settings_keys:
		provider = settings_art
	var hd: Texture2D = provider.texture(key,record)
	return hd if hd != null else load("res://assets/classic/" + str(record.file))

func frame(key: String, index: int) -> AtlasTexture:
	if android_mode and key=="room_maps":
		var preview := android_map_frame(index)
		if preview!=null:return preview
	var record: Dictionary = records.get(key,{})
	if record.is_empty():
		return null
	var sheet := image(key)
	if sheet == null:
		return null
	var density := 4.0 if (sheet.resource_path.begins_with(ROOT) or sheet.resource_path.begins_with(REFERENCE_ROOT) or sheet.resource_path.begins_with(POLISH_ROOT) or sheet.resource_path.begins_with(STATUS_ROOT) or sheet.resource_path.begins_with(SETTINGS_ROOT)) else 1.0
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

## Exact crops of approved HD, partitioned for GLES maximum texture dimensions.
func android_map_frame(index: int) -> AtlasTexture:
	if android_previews.get("schema")!=1:return null
	var frame_size=android_previews.get("frame_size")
	if not frame_size is Array or frame_size.size()!=2 or frame_size[0]!=544 or frame_size[1]!=336:return null
	var source = android_previews.get("source")
	var approved: Dictionary=art.catalog.get("assets",{}).get("room_maps",{})
	if not source is Dictionary or source.get("file")!="assets/hd/classic/room_smooth_4x/room/details/maps.png" or source.get("sha256")!=approved.get("sha256"):return null
	var frames = android_previews.get("frames")
	if not frames is Array or frames.size()!=22:return null
	for i in 22:
		if not frames[i] is Dictionary or frames[i].get("index")!=i or frames[i].get("file")!="map_%02d.png"%i:return null
		if not ResourceLoader.exists(ANDROID_PREVIEWS+str(frames[i].file)):return null
	var safe := clampi(index,0,21)
	var path := ANDROID_PREVIEWS+str(frames[safe].file)
	if not android_cache.has(path):android_cache[path]=load(path)
	var texture: Texture2D=android_cache[path]
	if texture==null or texture.get_size()!=Vector2(544,336):return null
	var result := AtlasTexture.new()
	result.atlas=texture
	result.region=Rect2(0,0,544,336)
	return result
