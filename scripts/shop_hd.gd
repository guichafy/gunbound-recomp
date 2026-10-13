extends RefCounted
## Registered UI derivatives. Invalid or absent metadata requests native fallback.
var sprites: Dictionary = {}
var textures: Dictionary = {}
func _init(path: String = "res://assets/hd/shop/catalog.json") -> void:
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary and data.get("version")==1 and data.get("scale")==4 and data.get("sprites") is Dictionary:
		sprites = data.sprites
func dimensions(value) -> Vector2:
	if not value is Array or value.size()!=2:
		return Vector2.ZERO
	for number in value:
		if not (number is float or number is int) or not is_finite(float(number)) or float(number)!=int(number) or int(number)<=0:
			return Vector2.ZERO
	return Vector2(value[0],value[1])
func texture(key: String):
	var entry = sprites.get(key)
	if not entry is Dictionary:
		return null
	var native := dimensions(entry.get("native_size"))
	var size := dimensions(entry.get("size"))
	if native == Vector2.ZERO or size != native*4:
		return null
	var path := str(entry.get("file",""))
	if not textures.has(path):
		if not ResourceLoader.exists(path):
			return null
		var resource = load(path)
		if not resource is Texture2D:
			return null
		textures[path] = resource
	return textures[path] if textures[path].get_size()==size else null
