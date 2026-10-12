extends RefCounted
## Generated fixed pieces, registered in original pixels. Missing data returns fallback.
var pieces: Dictionary = {}
var sheets: Dictionary = {}
var textures: Dictionary = {}
var paints: Dictionary = {}
func _init(path: String = "res://assets/hd/avatars/catalog.json") -> void:
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version")!=1 or not data.get("pieces") is Dictionary or not data.get("sheets") is Dictionary:
		return
	pieces = data.pieces
	sheets = data.sheets
func rectangle(value) -> Rect2:
	if not value is Array or value.size()!=4:
		return Rect2()
	for number in value:
		if not (number is int or number is float) or not is_finite(float(number)):
			return Rect2()
	return Rect2(float(value[0]),float(value[1]),float(value[2]),float(value[3]))
func piece(key: String, frame: int) -> Dictionary:
	var entry = pieces.get(key)
	if not entry is Dictionary:
		return {}
	var sheet = sheets.get(entry.get("sheet",""))
	if not sheet is Dictionary or not sheet.get("size") is Array or sheet.size.size()!=2:
		return {}
	var path := str(sheet.get("file",""))
	if not textures.has(path):
		if not ResourceLoader.exists(path):
			return {}
		var loaded = load(path)
		if not loaded is Texture2D:
			return {}
		textures[path] = loaded
		var paint := CanvasTexture.new()
		paint.diffuse_texture = textures[path]
		paint.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		paints[path] = paint
	var texture = textures[path]
	if texture.get_width()!=int(sheet.size[0]) or texture.get_height()!=int(sheet.size[1]):
		return {}
	var source := rectangle(entry.get("region"))
	var native := rectangle(entry.get("native_rect"))
	if not source.has_area() or not native.has_area() or not Rect2(Vector2.ZERO,texture.get_size()).encloses(source):
		return {}
	var raw_pivot = entry.get("native_pivot")
	if not raw_pivot is Array or raw_pivot.size()!=2:
		return {}
	for number in raw_pivot:
		if not (number is int or number is float) or not is_finite(float(number)):
			return {}
	var pivot := Vector2(float(raw_pivot[0]),float(raw_pivot[1]))
	var registration := (pivot-native.position)/native.size
	var fitted := source.size*minf(native.size.x/source.size.x,native.size.y/source.size.y)
	# Preserve both intrinsic aspect and the original pivot's normalized location.
	native = Rect2(pivot-fitted*registration,fitted)
	var offsets = entry.get("offsets")
	if not offsets is Array or offsets.size()!=22:
		return {}
	var offset = offsets[clampi(frame,0,21)]
	if not offset is Array or offset.size()!=2:
		return {}
	for number in offset:
		if not (number is int or number is float) or not is_finite(float(number)):
			return {}
	# Silhouette centers vary with eyes, hair and cloth; they are not joints.
	# The fixed HD image keeps its reference registration through all frames.
	return {"texture":texture,"paint":paints[path],"source":source,"native":native}
func portrait(key: String):
	var data := piece(key,11 if int(key.get_slice(":",1))!=1 else 0)
	if data.is_empty():
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = data.texture
	atlas.region = data.source
	return atlas
