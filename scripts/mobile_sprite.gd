extends RefCounted
## Shared source-atlas renderer: animation, original rider offsets and pixel filtering.
## Reference data: OpenBound; notices in assets/openbound/ATTRIBUTION.md.

const COLUMNS := 20
var cell: Vector2
var pivot: Vector2
var hull_width: float
var contact_y: float
var sequences: Dictionary
var texture: Texture2D
var paint_texture: CanvasTexture
var rider_body: CanvasTexture
var rider_head: CanvasTexture
var rider_offsets: Array = []

func configure(folder: String, frame_size: Vector2, anchor: Vector2, animations: Dictionary, hull: float, ground_contact: float) -> void:
	cell = frame_size
	pivot = anchor
	sequences = animations
	hull_width = hull
	contact_y = ground_contact
	texture = load(folder + "/CharacterSpritesheet.png")
	paint_texture = pixel_texture(texture)
	rider_body = pixel_texture(load("res://assets/openbound/bigfoot/RiderBody.png"))
	rider_head = pixel_texture(load("res://assets/openbound/bigfoot/RiderHead.png"))
	var text := FileAccess.get_file_as_string(folder + "/RiderPivot.json").strip_edges()
	text = text.trim_suffix("]").strip_edges().trim_suffix(",") + "]"
	rider_offsets = JSON.parse_string(text)

func rider_offset(frame: int) -> Vector2:
	var point: Array = rider_offsets[clampi(frame, 0, rider_offsets.size() - 1)]
	return Vector2(point[0], point[1])

func pixel_texture(source: Texture2D) -> CanvasTexture:
	var result := CanvasTexture.new()
	result.diffuse_texture = source
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return result

func frame_index(pose: String, age: float, weapon: int, low_health: bool) -> int:
	var key := pose
	if pose in ["charging", "recoil"]:
		key += "_" + str(clampi(weapon, 0, 2))
	elif low_health and pose in ["idle", "moving"]:
		key += "_low"
	var sequence: Array = sequences.get(key, sequences.idle)
	var count := int(sequence[1]) - int(sequence[0]) + 1
	var step := maxi(0, int(floor(age * float(sequence[2]) + 0.00001)))
	return int(sequence[0]) + (step % count if sequence[3] else mini(step, count - 1))

func frame_rect(index: int) -> Rect2:
	return Rect2(Vector2(index % COLUMNS, int(index / COLUMNS)) * cell, cell)

func draw(view: Node2D, pos: Vector2, width: float, facing: int, rotation: float, frame: int, color: Color = Color.WHITE) -> void:
	# Native artwork faces left. Scale the configured alpha hull around its
	# original pivot and ground contact, without editing the source pixels.
	var amount := width / hull_width
	var ground := 24.0 if width < 150.0 else width * 0.23
	view.draw_set_transform(pos, rotation, Vector2(-facing, 1))
	var rect := Rect2(Vector2(-pivot.x * amount, ground - contact_y * amount), cell * amount)
	view.draw_texture_rect_region(paint_texture, rect, frame_rect(frame), color)
	var rider := rider_offset(frame)
	var origin := Vector2(0, ground - (contact_y - pivot.y) * amount)
	var avatar_frame := int(view.elapsed * 10.0) % 11
	view.draw_texture_rect_region(rider_body, Rect2(origin + (rider - Vector2(22, 12)) * amount, Vector2(44, 28) * amount), Rect2(avatar_frame * 44, 0, 44, 28), color)
	view.draw_texture_rect_region(rider_head, Rect2(origin + (rider + Vector2(7, -17) - Vector2(25, 12)) * amount, Vector2(38, 24) * amount), Rect2((11 + avatar_frame) * 38, 0, 38, 24), color)
	view.draw_set_transform(Vector2.ZERO)
