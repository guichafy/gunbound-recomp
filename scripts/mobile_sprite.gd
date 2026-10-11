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
const HDSheet = preload("res://scripts/hd_sheet.gd")
var hd_sheet
var hd_rider
var hd_heroes
var hd_hero_column := 0
var hd_rows: Array[String] = []

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
	hd_sheet = HDSheet.new("res://assets/hd/" + folder.get_file() + ".png", 4, 8)
	hd_rider = HDSheet.new("res://assets/hd/rider.png", 4, 2)
	hd_heroes = HDSheet.new("res://assets/hd/heroes.png", 2, 1)
	hd_hero_column = 1 if folder.get_file() == "mage" else 0

func hd_frame(frame: int) -> Vector2i:
	for key in sequences:
		var sequence: Array = sequences[key]
		if frame < int(sequence[0]) or frame > int(sequence[1]):
			continue
		var canonical: String = key.trim_suffix("_low")
		if not hd_rows.has(canonical):
			canonical = "charging_1" if canonical == "charging_2" else "recoil_0"
		var row := hd_rows.find(canonical)
		if row < 0:
			return Vector2i(-1, -1)
		var progress := float(frame - int(sequence[0])) / maxi(1, int(sequence[1]) - int(sequence[0]))
		return Vector2i(roundi(progress * 3), row)
	return Vector2i(-1, -1)

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
	var key := hd_frame(frame)
	var body_color := color
	if frame in range(int(sequences.idle_low[0]), int(sequences.idle_low[1]) + 1) or frame in range(int(sequences.moving_low[0]), int(sequences.moving_low[1]) + 1):
		body_color *= Color(0.7, 0.7, 0.7) if hd_sheet.available() else Color.WHITE
	var menu_drawn: bool = width >= 150.0 and hd_heroes.draw_patch(view, 0, hd_hero_column, texture, frame_rect(frame), rect, body_color)
	if not menu_drawn and not hd_sheet.draw_patch(view, key.y, key.x, texture, frame_rect(frame), rect, body_color):
		view.draw_texture_rect_region(paint_texture, rect, frame_rect(frame), color)
	var rider := rider_offset(frame)
	var origin := Vector2(0, ground - (contact_y - pivot.y) * amount)
	var avatar_frame := int(view.elapsed * 10.0) % 11
	var body_rect := Rect2(origin + (rider - Vector2(22, 12)) * amount, Vector2(44, 28) * amount)
	var head_rect := Rect2(origin + (rider + Vector2(7, -17) - Vector2(25, 12)) * amount, Vector2(38, 24) * amount)
	var body_source := Rect2(avatar_frame * 44, 0, 44, 28)
	var head_source := Rect2((11 + avatar_frame) * 38, 0, 38, 24)
	var avatar_column := roundi(avatar_frame * 3.0 / 10)
	if not hd_rider.draw_patch(view, 0, avatar_column, rider_body, body_source, body_rect, color):
		view.draw_texture_rect_region(rider_body, body_rect, body_source, color)
	if not hd_rider.draw_patch(view, 1, avatar_column, rider_head, head_source, head_rect, color):
		view.draw_texture_rect_region(rider_head, head_rect, head_source, color)
	view.draw_set_transform(Vector2.ZERO)
