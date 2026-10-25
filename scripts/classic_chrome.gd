extends RefCounted
## Tiras EPA do lobby/sala. Densidade4× somente nos recortes de textura;
## layout e hitboxes continuam no palco nativo800×600 com escala4/3.

const LobbyArt = preload("res://scripts/classic_lobby_art.gd")
var lobby_art = LobbyArt.new()
const RoomArt = preload("res://scripts/classic_room_art.gd")
var room_art = RoomArt.new()

const ROOT := "res://assets/classic/"
const HD_ROOT := "res://assets/hd/classic/buttons_smooth_4x/"
const HD_DENSITY := 4.0
const VIEW := Vector2(1280, 800)
const NATIVE := Vector2(800, 600)
const SCALE := 4.0 / 3.0

var manifest: Dictionary = {}
var hd_manifest: Dictionary = {}
var _sheets: Dictionary = {}

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
	manifest = parsed if parsed is Dictionary else {}
	if FileAccess.file_exists(HD_ROOT + "catalog.json"):
		var hd_parsed = JSON.parse_string(FileAccess.get_file_as_string(HD_ROOT + "catalog.json"))
		hd_manifest = hd_parsed if hd_parsed is Dictionary else {}

static func stage_origin() -> Vector2:
	return Vector2((VIEW.x - NATIVE.x * SCALE) * 0.5, 0.0)

static func to_scene(native: Vector2) -> Vector2:
	return stage_origin() + native * SCALE

static func mount(parent: Node) -> Control:
	var stage := Control.new()
	stage.name = "ClassicStage"
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.position = stage_origin()
	stage.scale = Vector2(SCALE, SCALE)
	stage.size = NATIVE
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stage)
	return stage

func image(key: String) -> Texture2D:
	if key == "room_back":
		return room_art.image(key)
	var info: Dictionary = manifest.get("images", {}).get(key, {})
	var hd: Texture2D = lobby_art.texture(key, info) if key.begins_with("lobby_") else null
	return hd if hd != null else _load_sheet(str(info.get("file", "")))

func frame_count(key: String) -> int:
	return int(manifest.get("strips", {}).get(key, {}).get("frames", 1))

func frame_size(key: String) -> Vector2:
	var size: Array = manifest.get("strips", {}).get(key, {}).get("frame_size", [1, 1])
	return Vector2(int(size[0]), int(size[1]))

func frame(key: String, index: int) -> AtlasTexture:
	var info: Dictionary = manifest.get("strips", {}).get(key, {})
	var size := frame_size(key)
	var atlas := AtlasTexture.new()
	var hd := _hd_button(key, info)
	var density := HD_DENSITY if hd != null else 1.0
	atlas.atlas = hd if hd != null else _load_sheet(str(info.get("file", "")))
	var safe := clampi(index, 0, maxi(0, int(info.get("frames", 1)) - 1))
	atlas.region = Rect2(Vector2(safe * size.x, 0) * density, size * density)
	return atlas

## O catálogo nativo decide geometria/estados; o HD só fornece mais texels.
func _hd_button(key: String, native: Dictionary) -> Texture2D:
	if hd_manifest.get("version") != 1 or hd_manifest.get("scale") != HD_DENSITY:
		return null
	var records = hd_manifest.get("buttons")
	if not records is Dictionary:
		return null
	var info = records.get(key)
	if not info is Dictionary:
		return null
	var source = info.get("source")
	if not source is Dictionary or source.get("record") != native:
		return null
	var relative := str(native.get("file", ""))
	if relative.is_empty() or info.get("file") != relative or source.get("file") != "assets/classic/" + relative:
		return null
	var size := frame_size(key) * HD_DENSITY
	var count := frame_count(key)
	if info.get("frames") != native.get("frames") or info.get("order") != native.get("order"):
		return null
	if info.get("frame_size") != [size.x, size.y] or info.get("size") != [size.x * count, size.y]:
		return null
	if not ResourceLoader.exists(HD_ROOT + relative):
		return null
	var sheet := _load_sheet(relative, HD_ROOT)
	return sheet if sheet != null and sheet.get_size() == Vector2(size.x * count, size.y) else null

func place(parent: Node, key: String, at: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.texture = image(key)
	rect.position = at
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	var native_size: Array = manifest.get("images", {}).get(key, {}).get("size", [0,0])
	rect.size = Vector2(native_size[0], native_size[1])
	parent.add_child(rect)
	rect.size = Vector2(native_size[0], native_size[1])
	return rect

## Quadro 0 normal, 1 hover, 2 push, 3 disable. `shown` troca o quadro parado
## (4 = active nos filtros e nos mobiles).
func button(parent: Node, key: String, at: Vector2, shown: int = 0) -> TextureButton:
	var node := TextureButton.new()
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.position = at
	node.ignore_texture_size = true
	node.custom_minimum_size = frame_size(key)
	node.size = frame_size(key)
	node.stretch_mode = TextureButton.STRETCH_SCALE
	paint(node, key, shown)
	parent.add_child(node)
	node.size = frame_size(key)
	return node

func paint(node: TextureButton, key: String, shown: int = 0) -> void:
	var last := frame_count(key) - 1
	node.texture_normal = frame(key, clampi(shown, 0, last))
	node.texture_hover = frame(key, 1 if shown == 0 and last >= 1 else clampi(shown, 0, last))
	node.texture_pressed = frame(key, 2 if last >= 2 else 0)
	node.texture_disabled = frame(key, 3 if last >= 3 else 0)

func _load_sheet(relative: String, directory: String = ROOT) -> Texture2D:
	if relative.is_empty():
		return null
	var path := directory + relative
	if _sheets.has(path):
		return _sheets[path]
	var loaded: Texture2D = load(path)
	_sheets[path] = loaded
	return loaded
