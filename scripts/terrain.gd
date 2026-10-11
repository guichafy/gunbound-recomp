extends RefCounted
## Pixel mask is the single source of truth for both drawing and collision.

const Maps = preload("res://scripts/maps.gd")
const SCALE := 2
# Grid size in cells: procedural arena 640×400; a map uses its native foreground size.
var WIDTH := 640
var HEIGHT := 400
# Topography.cs: ring beyond the crater darkened by BlastBlackmaskExplosionRadiusColorFactor.
const BLACKMASK_RADIUS := 3.0
const BLACKMASK_FACTOR := 0.4
var cells := PackedByteArray()
var image: Image
var texture: ImageTexture
var revision := 0
# Empty map_id means the procedural fallback terrain.
var map_id := ""
var visual: Image
var visual_texture: ImageTexture
var visual_rect := Rect2()
# Topography.FirstCollidableBlockY: computed once per map, like the original.
var first_solid_y := 0.0
static var mask_cache := {}

func load_map(id: String, with_visual: bool = true) -> bool:
	var map: Dictionary = Maps.get_map(id)
	if map.is_empty():
		return false
	if not mask_cache.has(id):
		var source := texture_image(map.mask)
		if source == null:
			return false
		mask_cache[id] = mask_from_source(source, map)
	var cached: Dictionary = mask_cache[id]
	WIDTH = int(cached.width)
	HEIGHT = int(cached.height)
	cells = PackedByteArray(cached.cells).duplicate()
	first_solid_y = find_first_solid_y()
	map_id = id
	image = null
	texture = null
	visual = null
	visual_texture = null
	visual_rect = Maps.foreground_rect(map)
	if with_visual:
		visual = texture_image(map.foreground_hd)
		if visual == null:
			visual = original_visual(map)
		if visual != null:
			visual_texture = ImageTexture.create_from_image(visual)
	revision += 1
	return true

static func texture_image(path: String) -> Image:
	if not ResourceLoader.exists(path):
		push_warning("Map resource missing: " + path)
		return null
	var resource: Texture2D = load(path)
	if resource == null:
		return null
	var result: Image = resource.get_image()
	if result == null:
		return null
	if result.is_compressed():
		result.decompress()
	result.convert(Image.FORMAT_RGBA8)
	return result

static func original_visual(map: Dictionary) -> Image:
	# Fallback when the HD file is missing: never leave collision without a drawing.
	var source := texture_image(map.mask)
	if source == null:
		return null
	return source.get_region(map.crop)

static func mask_from_source(source: Image, map: Dictionary) -> Dictionary:
	# World is the native foreground; each cell samples its centre: alpha > 0 is solid.
	var width := source.get_width() / SCALE
	var height := source.get_height() / SCALE
	var mask := PackedByteArray()
	mask.resize(width * height)
	mask.fill(0)
	var crop: Rect2i = map.crop
	for y in range(crop.position.y / SCALE, mini(height, (crop.end.y + SCALE - 1) / SCALE)):
		for x in range(crop.position.x / SCALE, mini(width, (crop.end.x + SCALE - 1) / SCALE)):
			if source.get_pixel(x * SCALE + 1, y * SCALE + 1).a > 0.0:
				mask[y * width + x] = 1
	return {"cells": mask, "width": width, "height": height}

func generate() -> void:
	WIDTH = 640
	HEIGHT = 400
	map_id = ""
	visual = null
	visual_texture = null
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
	first_solid_y = find_first_solid_y()
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

func find_first_solid_y() -> float:
	for y in range(HEIGHT):
		if cells.slice(y * WIDTH, (y + 1) * WIDTH).has(1):
			return float(y * SCALE)
	return float(HEIGHT * SCALE)

func world_size() -> Vector2:
	return Vector2(WIDTH * SCALE, HEIGHT * SCALE)

func void_y() -> float:
	# surface_at sentinel: no support below this column.
	return float(HEIGHT * SCALE) + 50.0

func is_void(floor_y: float) -> bool:
	return floor_y >= float(HEIGHT * SCALE)

func is_solid(point: Vector2) -> bool:
	var x := int(floor(point.x / SCALE))
	var y := int(floor(point.y / SCALE))
	if x < 0 or y < 0 or x >= WIDTH or y >= HEIGHT:
		return false
	return cells[y * WIDTH + x] != 0

func surface_at(world_x: float, from_y: float = 0.0) -> float:
	var x := int(floor(world_x / SCALE))
	if x < 0 or x >= WIDTH:
		return void_y()
	for y in range(maxi(0, int(from_y / SCALE)), HEIGHT):
		if cells[y * WIDTH + x] != 0:
			return float(y * SCALE)
	return void_y()

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
	copy.WIDTH = WIDTH
	copy.HEIGHT = HEIGHT
	copy.cells = cells.duplicate()
	copy.first_solid_y = first_solid_y
	copy.revision = revision
	copy.map_id = map_id
	return copy

func carve(center: Vector2, radius: float) -> int:
	var left := maxi(0, int((center.x - radius) / SCALE) - 1)
	var right := mini(WIDTH - 1, int((center.x + radius) / SCALE) + 1)
	var top := maxi(0, int((center.y - radius) / SCALE) - 1)
	var bottom := mini(HEIGHT - 1, int((center.y + radius) / SCALE) + 1)
	# Removed cells feed the ground particles (Projectile.cs: removed pixels / 32).
	var removed := 0
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if Vector2(x * SCALE, y * SCALE).distance_squared_to(center) <= radius * radius:
				removed += cells[y * WIDTH + x]
				cells[y * WIDTH + x] = 0
				if image != null:
					image.set_pixel(x, y, Color.TRANSPARENT)
	revision += 1
	if visual != null:
		carve_visual(center, radius)
	if image == null:
		return removed
	# Dress the new crater lip without changing the collision mask.
	for x in range(left, right + 1):
		for y in range(maxi(1, top - 3), mini(HEIGHT - 1, bottom + 4)):
			if cells[y * WIDTH + x] != 0 and cells[(y - 1) * WIDTH + x] == 0:
				image.set_pixel(x, y, Color("d8b28b"))
	texture.update(image)
	return removed

func carve_visual(center: Vector2, radius: float) -> void:
	# Same erosion in HD pixels: open the crater, darken the surrounding ring.
	var density := float(visual.get_width()) / visual_rect.size.x
	var local := (center - visual_rect.position) * density
	var hole := radius * density
	var ring := (radius + BLACKMASK_RADIUS) * density
	var left := maxi(0, int(local.x - ring))
	var right := mini(visual.get_width() - 1, int(local.x + ring) + 1)
	var top := maxi(0, int(local.y - ring))
	var bottom := mini(visual.get_height() - 1, int(local.y + ring) + 1)
	if left > right or top > bottom:
		return
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var distance := Vector2(x + 0.5, y + 0.5).distance_squared_to(local)
			if distance > ring * ring:
				continue
			var color := visual.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			if distance <= hole * hole:
				visual.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				visual.set_pixel(x, y, Color(color.r * BLACKMASK_FACTOR, color.g * BLACKMASK_FACTOR, color.b * BLACKMASK_FACTOR, color.a))
	visual_texture.update(visual)
