extends RefCounted
## Knight Ion and children (ADR-154): knightion/knightbullet bodies in the alpha
## pass and their "l" sheets added on top, like every published bullet (0x4c3020).
## The Ion turns to its aim angle and bobs while idle (0x47dc00, same 22-step
## table as ASate); a child turns to its heading. Read-only on snapshot state.
const Timing = preload("res://scripts/classic_shot_timing.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const AsateArt = preload("res://scripts/asate_art.gd")
const FOLDER := "res://assets/openbound/knight/"
var meta: Dictionary = {}
var textures: Dictionary = {}

func _init() -> void:
	meta = JSON.parse_string(FileAccess.get_file_as_string(FOLDER + "knight_ion.json"))
	for name in meta.sheets:
		textures[name] = load(FOLDER + name)

func sheet(name: String) -> Dictionary:
	return meta.sheets.get(name, {})

## Source and target rectangles of frame `index`, or empty past the sheet.
func cell(name: String, index: int) -> Array:
	var info := sheet(name)
	if info.is_empty() or index < 0 or index >= int(info.frames):
		return []
	var size := Vector2(info.cell[0], info.cell[1])
	var columns := int(meta.columns)
	return [Rect2(Vector2(index % columns, index / columns) * size, size), Rect2(-Vector2(info.origin[0], info.origin[1]), size)]

static func ion_frame(info: Dictionary, ion: Dictionary) -> int:
	var state := str(ion.get("state", "normal"))
	var frames: Array = info.states.get(state, info.states.normal)
	var durations: Array = info.durations.get(state, [])
	return Timing.frame(frames, durations, float(ion.get("state_tick", 0)) * Timing.STEP, state in ["normal", "move"])

func layers(body: String, index: int, transform: Transform2D) -> Array:
	var result: Array = []
	for name in [body, body.replace(".png", "Light.png")]:
		var parts := cell(name, index)
		if not parts.is_empty():
			result.append({"texture": textures[name], "source": parts[0], "target": parts[1], "additive": name.ends_with("Light.png"), "transform": transform})
	return result

func ion_layers(ion: Dictionary, offset: Vector2, fraction: float = 1.0) -> Array:
	var position := Vector2(ion.get("previous_pos", ion.pos)).lerp(Vector2(ion.pos), clampf(fraction, 0, 1))
	if str(ion.get("state", "normal")) == "normal":
		position.y += AsateArt.BOB[posmod(int(ion.get("idle_tick", 0)), 22)]
	var transform := Transform2D(-deg_to_rad(float(ion.get("angle", 270))), position + offset)
	return layers("Ion.png", ion_frame(sheet("Ion.png"), ion), transform)

func child_layers(shell: Dictionary, offset: Vector2) -> Array:
	var heading := Physics.velocity_angle(shell.fp_velocity) if shell.has("fp_velocity") else int(shell.get("knight_angle", 270))
	var at: Vector2 = shell.get("hit_pos", shell.pos)
	var info := sheet("Child.png")
	var index := Timing.frame(info.states.normal, info.durations.normal, float(shell.get("age", 0.0)), true)
	return layers("Child.png", index, Transform2D(-deg_to_rad(float(heading)), at + offset))

func draw(view: Node2D, items: Array, glow) -> void:
	for layer in items:
		if layer.additive:
			glow.draw(view, layer.texture, layer.target, layer.source, layer.transform)
		else:
			view.draw_set_transform_matrix(layer.transform)
			view.draw_texture_rect_region(layer.texture, layer.target, layer.source)
	view.draw_set_transform(Vector2.ZERO)
