extends RefCounted
## Pixel mask is the single source of truth for both drawing and collision.

const SCALE := 2
const WIDTH := 640
const HEIGHT := 400
var cells := PackedByteArray()
var image: Image
var texture: ImageTexture
var revision := 0

func generate() -> void:
	cells.resize(WIDTH * HEIGHT)
	cells.fill(0)
	image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(14, WIDTH - 14):
		var world_x := float(x * SCALE)
		var top := int((465.0 + sin(world_x * 0.009) * 22.0 + sin(world_x * 0.022) * 9.0 + 35.0 * exp(-pow((world_x - 640.0) / 180.0, 2))) / SCALE)
		var edge := minf(float(x - 14), float(WIDTH - 15 - x))
		var bottom := int(310.0 - maxf(0.0, 24.0 - edge) * 2.5 + sin(x * 0.026) * 7.0)
		for y in range(top, bottom):
			cells[y * WIDTH + x] = 1
			image.set_pixel(x, y, ground_color(x, y, top))
	texture = ImageTexture.create_from_image(image)
	revision += 1

func ground_color(x: int, y: int, top: int) -> Color:
	var depth := y - top
	if depth < 2:
		return Color("c7e884")
	if depth < 5:
		return Color("629b54")
	if depth < 8:
		return Color("416b4a")
	var grain := float((x * 73 + y * 29 + x * y * 3) % 19) / 19.0
	var base := Color("b18b69").lerp(Color("594e53"), clampf(float(depth) / 82.0, 0.0, 1.0))
	if (x * 7 + y * 11) % 97 < 3:
		base = base.lightened(0.16)
	return base.lightened(grain * 0.045)

func is_solid(point: Vector2) -> bool:
	var x := int(floor(point.x / SCALE))
	var y := int(floor(point.y / SCALE))
	if x < 0 or y < 0 or x >= WIDTH or y >= HEIGHT:
		return false
	return cells[y * WIDTH + x] != 0

func surface_at(world_x: float, from_y: float = 0.0) -> float:
	var x := int(floor(world_x / SCALE))
	if x < 0 or x >= WIDTH:
		return 850.0
	for y in range(maxi(0, int(from_y / SCALE)), HEIGHT):
		if cells[y * WIDTH + x] != 0:
			return float(y * SCALE)
	return 850.0

func raycast(from: Vector2, to: Vector2) -> Dictionary:
	# Traverse every crossed mask cell (DDA), including short corner intersections.
	var direction := to - from
	var x := int(floor(from.x / SCALE))
	var y := int(floor(from.y / SCALE))
	var step_x := int(signf(direction.x))
	var step_y := int(signf(direction.y))
	var stride_x := float(SCALE) / absf(direction.x) if step_x != 0 else INF
	var stride_y := float(SCALE) / absf(direction.y) if step_y != 0 else INF
	var boundary_x := float((x + (1 if step_x > 0 else 0)) * SCALE)
	var boundary_y := float((y + (1 if step_y > 0 else 0)) * SCALE)
	var next_x := (boundary_x - from.x) / direction.x if step_x != 0 else INF
	var next_y := (boundary_y - from.y) / direction.y if step_y != 0 else INF
	var fraction := 0.0
	var maximum := int(ceil(absf(direction.x) / SCALE) + ceil(absf(direction.y) / SCALE)) + 4
	for iteration in range(maximum):
		if x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT and cells[y * WIDTH + x] != 0:
			return {"position": from + direction * fraction, "fraction": fraction}
		if next_x == INF and next_y == INF:
			break
		if next_x < next_y:
			fraction = next_x
			x += step_x
			next_x += stride_x
		elif next_y < next_x:
			fraction = next_y
			y += step_y
			next_y += stride_y
		else:
			fraction = next_x
			x += step_x
			y += step_y
			next_x += stride_x
			next_y += stride_y
		if fraction > 1.0:
			break
	return {}

func collision_copy():
	# Prediction owns its mask; no image/GPU resources or live state are shared.
	var copy = get_script().new()
	copy.cells = cells.duplicate()
	copy.revision = revision
	return copy

func carve(center: Vector2, radius: float) -> void:
	var left := maxi(0, int((center.x - radius) / SCALE) - 1)
	var right := mini(WIDTH - 1, int((center.x + radius) / SCALE) + 1)
	var top := maxi(0, int((center.y - radius) / SCALE) - 1)
	var bottom := mini(HEIGHT - 1, int((center.y + radius) / SCALE) + 1)
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if Vector2(x * SCALE, y * SCALE).distance_squared_to(center) <= radius * radius:
				cells[y * WIDTH + x] = 0
				if image != null:
					image.set_pixel(x, y, Color.TRANSPARENT)
	revision += 1
	if image == null:
		return
	# Dress the new crater lip without changing the collision mask.
	for x in range(left, right + 1):
		for y in range(maxi(1, top - 3), mini(HEIGHT - 1, bottom + 4)):
			if cells[y * WIDTH + x] != 0 and cells[(y - 1) * WIDTH + x] == 0:
				image.set_pixel(x, y, Color("d8b28b"))
	texture.update(image)
