extends SceneTree
## Extract/repack reference cells only; source PNGs stay untouched.
func _initialize() -> void:
	var entries := {
		"bigfoot": {"cell": Vector2i(129, 130), "frames": [[0, 6, 12, 19], [20, 28, 36, 44], [212, 219, 226, 233], [254, 260, 267, 273], [125, 132, 139, 146], [274, 280, 287, 293], [394, 402, 410, 418], [202, 205, 208, 211]]},
		"mage": {"cell": Vector2i(109, 150), "frames": [[0, 6, 12, 19], [20, 26, 33, 39], [204, 210, 216, 222], [303, 309, 315, 321], [391, 397, 403, 409], [100, 106, 113, 119], [341, 349, 357, 365], [179, 187, 195, 203]]}
	}
	for key in entries:
		var data: Dictionary = entries[key]
		var cell: Vector2i = data.cell
		var source := Image.load_from_file("res://assets/openbound/" + key + "/CharacterSpritesheet.png")
		var sheet := Image.create(cell.x * 4, cell.y * 8, false, Image.FORMAT_RGBA8)
		for row in range(8):
			for column in range(4):
				var frame: int = data.frames[row][column]
				sheet.blit_rect(source, Rect2i(Vector2i(frame % 20, int(frame / 20)) * cell, cell), Vector2i(column, row) * cell)
		sheet.save_png("res://.tools/hd-" + key + "-reference.png")
	var shot_sheet := Image.create(96 * 4, 96 * 6, false, Image.FORMAT_RGBA8)
	var effect_sheet := Image.create(384 * 6, 384 * 6, false, Image.FORMAT_RGBA8)
	var shots: Array[Vector2i] = [Vector2i(63, 40), Vector2i(18, 15), Vector2i(69, 35), Vector2i(16, 16), Vector2i(16, 16), Vector2i(54, 54)]
	var flames: Array[Vector2i] = [Vector2i(166, 158), Vector2i(175, 183), Vector2i(192, 192), Vector2i(193, 192), Vector2i(143, 142), Vector2i(385, 384)]
	for row in range(6):
		var mobile := "bigfoot" if row < 3 else "mage"
		var number := row % 3 + 1
		var file := "S%dT.png" % number if row in [3, 4] else "Bullet%d.png" % number
		var shot := Image.load_from_file("res://assets/openbound/" + mobile + "/" + file)
		var count: int = [5, 10, 5, 8, 8, 15][row]
		for column in range(4):
			var frame := roundi(column * (count - 1) / 3.0)
			var offset := Vector2i(48, 48) - shots[row] / 2
			shot_sheet.blit_rect(shot, Rect2i(Vector2i(frame * shots[row].x, 0), shots[row]), Vector2i(column, row) * 96 + offset)
		var flame := Image.load_from_file("res://assets/openbound/" + mobile + "/Flame%d.png" % number)
		var capacity := int(flame.get_width() / flames[row].x) * int(flame.get_height() / flames[row].y)
		var columns := int(flame.get_width() / flames[row].x)
		for column in range(6):
			var frame := roundi(column * (capacity - 1) / 5.0)
			var region := Rect2i(Vector2i(frame % columns, int(frame / columns)) * flames[row], flames[row])
			effect_sheet.blit_rect(flame, region, Vector2i(column, row) * 384 + (Vector2i(384, 384) - flames[row]) / 2)
	shot_sheet.save_png("res://.tools/hd-shots-reference.png")
	effect_sheet.save_png("res://.tools/hd-effects-reference.png")
	var rider_sheet := Image.create(64 * 4, 64 * 2, false, Image.FORMAT_RGBA8)
	for row in range(2):
		var size := Vector2i(44, 28) if row == 0 else Vector2i(38, 24)
		var source := Image.load_from_file("res://assets/openbound/bigfoot/Rider" + ("Body" if row == 0 else "Head") + ".png")
		for column in range(4):
			var frame := roundi(column * 10 / 3.0) + (0 if row == 0 else 11)
			rider_sheet.blit_rect(source, Rect2i(Vector2i(frame * size.x, 0), size), Vector2i(column, row) * 64 + (Vector2i(64, 64) - size) / 2)
	rider_sheet.save_png("res://.tools/hd-rider-reference.png")
	print("HD REFERENCES EXTRACTED")
	quit()
