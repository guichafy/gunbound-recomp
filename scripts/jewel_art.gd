extends RefCounted
## Thor JewelTexture publication: registered sprites clipped into a64px cell.
## 0x4784a0 caps right/bottom at63exclusive. Body and light use one EPA index;
## an absent light frame stays absent, as native resource lookup does.
const Timing = preload("res://scripts/classic_shot_timing.gd")
const Additive = preload("res://scripts/additive_sprite_art.gd")
const FOLDER := "res://assets/xfs/jewel/"
const CELL_CLIP := Rect2(-32, -48, 63, 63)
var meta: Dictionary = {}
var textures: Dictionary = {}
var glow = Additive.new()

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(FOLDER + "catalog.json"))
	if parsed is Dictionary:
		meta = parsed
	for name in meta.get("sheets", {}):
		textures[name] = load(FOLDER + str(name) + ".png")

static func kind(entity: Dictionary) -> int:
	return int(entity.get("type", entity.get("kind", 0)))

func _state(name: String, pose: String) -> Dictionary:
	for state in meta.get("sheets", {}).get(name, {}).get("epa", []):
		if str(state.name) == pose:
			return state
	return {}

func frame(entity: Dictionary) -> int:
	var name := "jewel%d" % (kind(entity) + 1)
	var pose := str(entity.get("pose", entity.get("state", "normal")))
	var state := _state(name, pose)
	if state.is_empty():
		state = _state(name, "normal")
	var tick := float(entity.get("pose_tick", entity.get("state_tick", 0)))
	return Timing.frame(state.get("frames", []), state.get("durations", []), tick * Timing.STEP, int(state.get("flag", 0)) == 1)

func _layer(name: String, index: int, transform: Transform2D, additive: bool, clipped: bool = false) -> Dictionary:
	var info: Dictionary = meta.get("sheets", {}).get(name, {})
	if info.is_empty() or index < 0 or index >= int(info.frames):
		return {}
	var size := Vector2(info.cell[0], info.cell[1])
	var source := Rect2(Vector2(index % int(meta.columns), index / int(meta.columns)) * size, size)
	var target := Rect2(-Vector2(info.origin[0], info.origin[1]), size)
	if clipped:
		var visible := target.intersection(CELL_CLIP)
		if not visible.has_area():
			return {}
		source.position += visible.position - target.position
		source.size = visible.size
		target = visible
	return {"texture": textures[name], "source": source, "target": target, "transform": transform, "additive": additive, "frame": index}

func layers(entity: Dictionary, light: bool = false, offset: Vector2 = Vector2.ZERO) -> Array:
	if bool(entity.get("removed", false)) or kind(entity) < 0 or kind(entity) > 3:
		return []
	var name := "jewel%d%s" % [kind(entity) + 1, "l" if light else ""]
	var at: Vector2 = Vector2(entity.get("pos", Vector2.ZERO)) + offset
	var transform := Transform2D(-deg_to_rad(float(entity.get("angle", 0))), at)
	var layer := _layer(name, frame(entity), transform, light, true)
	return [] if layer.is_empty() else [layer]

func _paint(canvas: Node2D, items: Array) -> void:
	for layer in items:
		if layer.additive:
			glow.draw(canvas, layer.texture, layer.target, layer.source, layer.transform)
		else:
			canvas.draw_set_transform_matrix(layer.transform)
			canvas.draw_texture_rect_region(layer.texture, layer.target, layer.source)
	canvas.draw_set_transform(Vector2.ZERO)

func draw(canvas: Node2D, entities: Array, offset: Vector2 = Vector2.ZERO) -> void:
	for entity in entities:
		_paint(canvas, layers(entity, false, offset))

func draw_lights(canvas: Node2D, entities: Array, offset: Vector2 = Vector2.ZERO) -> void:
	glow.begin(canvas)
	for entity in entities:
		_paint(canvas, layers(entity, true, offset))

func effect_frame(effect: Dictionary) -> int:
	var name := "jflame%d" % (kind(effect) + 1)
	var state := _state(name, "flame")
	var tick := float(effect.get("tick", effect.get("state_tick", float(effect.get("age", 0)) / Timing.STEP)))
	var duration := 0
	for value in state.get("durations", []):
		duration += maxi(1, int(value))
	if tick < 0 or tick >= duration:
		return -1
	return Timing.frame(state.get("frames", []), state.get("durations", []), tick * Timing.STEP, false)

func effect_layers(effect: Dictionary, offset: Vector2 = Vector2.ZERO) -> Array:
	var name := "jflame%d" % (kind(effect) + 1)
	var layer := _layer(name, effect_frame(effect), Transform2D(0, Vector2(effect.get("pos", Vector2.ZERO)) + offset), false)
	return [] if layer.is_empty() else [layer]

func draw_effects(canvas: Node2D, effects: Array, offset: Vector2 = Vector2.ZERO) -> void:
	for effect in effects:
		_paint(canvas, effect_layers(effect, offset))

## Digits189..198. Position is the first digit's
## native top-left; caller chooses right alignment by measuring this width.
func digit_layers(value: int, position: Vector2, advance: float = 18.0) -> Array:
	var result: Array = []
	var text := str(maxi(0, value))
	for i in text.length():
		var index := int(text[i])
		var layer := _layer("score_digits", index, Transform2D(0, position + Vector2(i * advance, 0)), false)
		if not layer.is_empty():
			result.append(layer)
	return result

func score_digits(canvas: Node2D, value: int, position: Vector2, advance: float = 18.0) -> void:
	_paint(canvas, digit_layers(value, position, advance))

## SOLO keeps the caller's existing plate. The JEWEL control has4nativeframes.
func room_frame(mode: String, index: int = 0) -> Texture2D:
	if mode.to_upper() != "JEWEL":
		return null
	var layer := _layer("room_jewel", clampi(index, 0, 3), Transform2D.IDENTITY, false)
	if layer.is_empty():
		return null
	var texture := AtlasTexture.new()
	texture.atlas = layer.texture
	texture.region = layer.source
	return texture
