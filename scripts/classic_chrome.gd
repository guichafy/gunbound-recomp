extends RefCounted
## Tiras EPA do lobby e da sala (ADR-096). Cada botão é um PNG horizontal;
## o quadro N vira um AtlasTexture. O palco nativo é 800×600 com escala 4/3.

const ROOT := "res://assets/classic/"
const VIEW := Vector2(1280, 800)
const NATIVE := Vector2(800, 600)
const SCALE := 4.0 / 3.0

var manifest: Dictionary = {}
var _sheets: Dictionary = {}

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
	manifest = parsed if parsed is Dictionary else {}

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
	var info: Dictionary = manifest.get("images", {}).get(key, {})
	return _load_sheet(str(info.get("file", "")))

func frame_count(key: String) -> int:
	return int(manifest.get("strips", {}).get(key, {}).get("frames", 1))

func frame_size(key: String) -> Vector2:
	var size: Array = manifest.get("strips", {}).get(key, {}).get("frame_size", [1, 1])
	return Vector2(int(size[0]), int(size[1]))

func frame(key: String, index: int) -> AtlasTexture:
	var info: Dictionary = manifest.get("strips", {}).get(key, {})
	var size := frame_size(key)
	var atlas := AtlasTexture.new()
	atlas.atlas = _load_sheet(str(info.get("file", "")))
	var safe := clampi(index, 0, maxi(0, int(info.get("frames", 1)) - 1))
	atlas.region = Rect2(safe * size.x, 0, size.x, size.y)
	return atlas

func place(parent: Node, key: String, at: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = image(key)
	rect.position = at
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = rect.texture.get_size() if rect.texture != null else Vector2.ZERO
	parent.add_child(rect)
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

func _load_sheet(relative: String) -> Texture2D:
	if relative.is_empty():
		return null
	if _sheets.has(relative):
		return _sheets[relative]
	var loaded: Texture2D = load(ROOT + relative)
	_sheets[relative] = loaded
	return loaded
