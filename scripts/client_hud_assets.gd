extends RefCounted
## Thor's Hammer header/footer and compatibility HUD atlases (REQ-27/48).
## Catalog validation is per texture; gaps/failures keep the preserved 1x art.
const CATALOG := "res://assets/xfs/hud/catalog.json"
const ROOT := "res://assets/xfs/hud/"
const ARCHIVE_SHA := "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
var files: Dictionary = {}
var _cache: Dictionary = {}

func _init(path: String = CATALOG) -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if parsed is Dictionary and parsed.get("version") == 1 and parsed.get("archive_sha256") == ARCHIVE_SHA and parsed.get("files") is Dictionary:
		files = parsed.files

func texture(name: String, fallback: Texture2D = null) -> Texture2D:
	if _cache.has(name):
		return _cache[name] if _cache[name] != null else fallback
	var info = files.get(name)
	var result: Texture2D = null
	if info is Dictionary and info.get("size") is Array and info["size"].size() == 2:
		var path := ROOT + name.get_basename() + ".png"
		if info.get("file") == path and ResourceLoader.exists(path):
			var loaded = load(path)
			if loaded is Texture2D and loaded.get_size() == Vector2(info["size"][0],info["size"][1]):
				# PNG files become .ctex/.remap in PCK exports; validate decoded
				# pixels, so the same provenance check works outside the checkout.
				var pixels: Image = loaded.get_image()
				if pixels != null:
					if pixels.is_compressed():
						pixels.decompress()
					pixels.convert(Image.FORMAT_RGBA8)
					var digest := HashingContext.new()
					digest.start(HashingContext.HASH_SHA256)
					digest.update(pixels.get_data())
					if digest.finish().hex_encode() == info.get("rgba_sha256"):
						result = loaded
	_cache[name] = result
	return result if result != null else fallback

func has(name: String) -> bool:
	return texture(name) != null
