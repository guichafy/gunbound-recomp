extends RefCounted
## Non-destructive remastered keyframes, aligned to the source alpha footprint.
var texture: Texture2D
var paint: CanvasTexture
var columns: int
var rows: int
var regions: Dictionary = {}
var footprints: Dictionary = {}
var source_images: Dictionary = {}

func _init(path: String, column_count: int, row_count: int) -> void:
	columns = column_count
	rows = row_count
	if ResourceLoader.exists(path):
		texture = load(path)
		paint = CanvasTexture.new()
		paint.diffuse_texture = texture
		paint.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var catalog_path := "res://assets/hd/atlas_regions.json"
		if FileAccess.file_exists(catalog_path):
			var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
			if catalog is Dictionary:
				var data: Dictionary = catalog.get(path.get_file(), {})
				var size: Array = data.get("size", [])
				var grid: Array = data.get("grid", [])
				if size.size() == 2 and grid.size() == 2 and Vector2i(int(size[0]), int(size[1])) == Vector2i(texture.get_size()) and Vector2i(int(grid[0]), int(grid[1])) == Vector2i(columns, rows) and data.get("regions", []).size() == columns * rows:
					for row in range(rows):
						for column in range(columns):
							var rect: Array = data.regions[row * columns + column]
							regions[Vector2i(column, row)] = Rect2(rect[0], rect[1], rect[2], rect[3])
					return
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		# Generated canvas dimensions need not be divisible by the requested grid.
		# Split on integer boundaries so adjacent cells never share source pixels.
		for row in range(rows):
			for column in range(columns):
				var start := Vector2i(int(column * image.get_width() / float(columns)), int(row * image.get_height() / float(rows)))
				var finish := Vector2i(int((column + 1) * image.get_width() / float(columns)), int((row + 1) * image.get_height() / float(rows)))
				var bounds := image.get_region(Rect2i(start, finish - start)).get_used_rect()
				regions[Vector2i(column, row)] = Rect2(bounds.position + start, bounds.size)

func available() -> bool:
	return texture != null

func region(row: int, column: int) -> Rect2:
	return regions.get(Vector2i(column, row), Rect2())

func destination(source: Texture2D, source_rect: Rect2, target_rect: Rect2) -> Rect2:
	var original: Texture2D = source.diffuse_texture if source is CanvasTexture else source
	var key := str(original.get_instance_id()) + ":" + str(source_rect)
	if not footprints.has(key):
		var id := original.get_instance_id()
		if not source_images.has(id):
			var image := original.get_image()
			if image.is_compressed():
				image.decompress()
			source_images[id] = image
		var image: Image = source_images[id]
		footprints[key] = Rect2(image.get_region(Rect2i(source_rect)).get_used_rect())
	var bounds: Rect2 = footprints[key]
	var scale := target_rect.size / source_rect.size
	return Rect2(target_rect.position + bounds.position * scale, bounds.size * scale)

func draw_patch(view: Node2D, row: int, column: int, source: Texture2D, source_rect: Rect2, target_rect: Rect2, color: Color = Color.WHITE) -> bool:
	if not available():
		return false
	var area := region(row, column)
	if area.size == Vector2.ZERO:
		return false
	var target := destination(source, source_rect, target_rect)
	if target.size != Vector2.ZERO:
		view.draw_texture_rect_region(paint, target, area, color)
	return true
