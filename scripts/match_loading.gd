extends RefCounted
const Maps = preload("res://scripts/maps.gd")
## Match-loading preview. The client places each name on load_stage with
## preview_x = spawn_x * 748 / map_width and preview_y = first solid mask
## row + 18 (VA 0x004430c0, GunBound.gme 4af6283d…). A null mask uses y = 122.
## 1×1 local holds this screen for at least HOLD seconds; multiplayer can
## replace the timer later without changing the marker contract.

const PREVIEW_W := 748
const MASK_H := 209
const LABEL_DROP := 18
const EMPTY_MASK_Y := 122
const HOLD := 5.0

static func column(spawn_x: int, world_width: int) -> int:
	var width := maxi(world_width, 1)
	var x := int(spawn_x) * PREVIEW_W / width
	return clampi(x, 0, PREVIEW_W - 1)

static func point(spawn_x: int, world_width: int, rows: PackedInt32Array) -> Vector2:
	var x := column(spawn_x, world_width)
	if rows.is_empty():
		return Vector2(x, EMPTY_MASK_Y)
	var row := MASK_H
	if x < rows.size():
		row = int(rows[x])
	return Vector2(x, row + LABEL_DROP)

## Same two draws as Match.start: player from the left half, CPU from the right.
static func roll_spawns(rng: RandomNumberGenerator, map: Dictionary, world_width: float) -> Array:
	var rolled := []
	for left_side in [true, false]:
		var options: Array = Maps.spawn_points(map, left_side, world_width)
		rolled.append(options[rng.randi_range(0, options.size() - 1)])
	return rolled

static func ground_rows() -> PackedInt32Array:
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/classic/loading/catalog.json"))
	var rows := PackedInt32Array()
	if catalog is Dictionary and catalog.get("ground_rows") is Array:
		for value in catalog.ground_rows:
			rows.append(int(value))
	return rows
