extends RefCounted
## Stable HD heads and continuous effects. Physics/trail/collider are read-only.
const Sheet = preload("res://scripts/hd_sheet.gd")
var sheet
var flames
func _init() -> void:
	sheet = Sheet.new("res://assets/hd/projectile_heads.png", 3, 2)
	flames = Sheet.new("res://assets/hd/shots.png", 4, 6)
func available(kind: String) -> bool:
	if kind not in ["bigfoot", "mage"]:
		return false
	if not sheet.available() or not sheet.catalog_valid:
		return false
	if kind == "bigfoot":
		if not flames.available() or not flames.catalog_valid:
			return false
		for key in ["t1_flame", "ss_flame"]:
			var area: Rect2 = flames.components.get(key, Rect2())
			if not area.has_area():
				return false
	var row := 0 if kind == "bigfoot" else 1
	for weapon in range(3):
		if not sheet.region(row, weapon).has_area():
			return false
	return true
static func fit_rect(size: Vector2, source: Rect2) -> Rect2:
	if not source.has_area():
		return Rect2()
	var amount := minf(size.x / source.size.x, size.y / source.size.y)
	var fitted := source.size * amount
	return Rect2(-fitted / 2.0, fitted)
func sample(kind: String, weapon: int, shot: Dictionary) -> Dictionary:
	var row := 0 if kind == "bigfoot" else 1
	var size: Vector2 = [Vector2(14, 11), Vector2(8, 6), Vector2(18, 12)][weapon] if row == 0 else [Vector2(6, 10), Vector2(6, 10), Vector2(28, 28)][weapon]
	var age: float = shot.age
	var phase: float = shot.get("phase", 0.0)
	var position: Vector2 = shot.get("hit_pos", shot.pos)
	var rotation := Vector2(shot.velocity).angle()
	var flame := 0.0
	if row == 0 and weapon != 1:
		flame = (22.0 if weapon == 0 else 27.0) + sin(age * TAU * 10.0 + phase) * 3.0
	var tint := Color("dcd2ff")
	if row == 1 and weapon == 1:
		tint = Color("d43e70") if phase < 1.0 else Color("99a5de")
	return {"position": position, "rotation": rotation, "source": Vector2i(weapon, row),
		"body_rect": fit_rect(size, sheet.region(row, weapon)), "flame_length": flame,
		"flame_tip": position + Vector2(-flame - size.x / 2.0, 0).rotated(rotation),
		"pulse": 0.75 + sin(age * TAU * 6.0 + phase) * 0.15,
		"ring_angle": age * 2.2, "tint": tint}
func draw(view: Node2D, kind: String, shot: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> bool:
	if not available(kind):
		return false
	if not shot.get("launched", true):
		return true
	var state := sample(kind, weapon, shot)
	var row: int = state.source.y
	if row == 1 and weapon < 2:
		# Continuous ribbon follows actual helix/collision samples; no head duplicates.
		var points := PackedVector2Array(shot.get("trail", []))
		view.draw_set_transform(offset)
		if points.is_empty() or not points[points.size() - 1].is_equal_approx(state.position):
			points.append(state.position)
		if points.size() >= 2:
			var outer := PackedColorArray()
			var core := PackedColorArray()
			for index in range(points.size()):
				var alpha := float(index) / (points.size() - 1.0)
				outer.append(Color(state.tint, alpha * 0.6))
				core.append(Color(1, 1, 1, alpha * 0.8))
			view.draw_polyline_colors(points, outer, 3.0, true)
			view.draw_polyline_colors(points, core, 1.0, true)
	view.draw_set_transform(state.position + offset, state.rotation)
	var rect: Rect2 = state.body_rect
	if state.flame_length > 0.0:
		var rear := rect.position.x
		var length: float = state.flame_length
		var source: Rect2 = flames.components["t1_flame" if weapon == 0 else "ss_flame"]
		var height: float = 13.0 + state.pulse * 3.0
		view.draw_texture_rect_region(flames.paint, Rect2(rear - length, -height / 2.0, length, height), source, Color(1, 1, 1, state.pulse))
	if row == 1:
		var radius := 17.0 if weapon == 2 else 6.0
		view.draw_circle(Vector2.ZERO, radius, Color(state.tint if weapon < 2 else Color("5de9ff"), state.pulse * 0.16))
		if weapon == 2:
			view.draw_arc(Vector2.ZERO, 16.5, state.ring_angle, state.ring_angle + PI * 1.5, 36, Color("ff9cf4"), 1.0, true)
	var tint: Color = state.tint if row == 1 and weapon == 1 else Color.WHITE
	view.draw_texture_rect_region(sheet.paint, rect, sheet.region(row, weapon), tint)
	view.draw_set_transform(Vector2.ZERO)
	return true
static func effect_sample(age: float, duration: float) -> Dictionary:
	var progress := clampf(age / maxf(duration, 0.0001), 0.0, 1.0)
	var phase := progress * 5.0
	var first := int(floor(phase))
	return {"first": first, "second": mini(5, first + 1), "blend": phase - first,
		"scale": 0.08 + 0.92 * sin(clampf(progress / 0.35, 0.0, 1.0) * PI / 2.0),
		"alpha": 1.0 - smoothstep(0.55, 1.0, progress)}
static func effect_size(original: Texture2D, cell: Vector2) -> Vector2:
	var image: Image = original.diffuse_texture.get_image() if original is CanvasTexture else original.get_image()
	if image.is_compressed():
		image.decompress()
	var size := Vector2.ZERO
	for row in range(int(image.get_height() / cell.y)):
		for column in range(int(image.get_width() / cell.x)):
			var bounds: Rect2i = image.get_region(Rect2i(Vector2(column, row) * cell, cell)).get_used_rect()
			size = size.max(Vector2(bounds.size))
	return size
func draw_effect(view: Node2D, effect: Dictionary, atlas, row: int, size: Vector2, duration: float, offset: Vector2 = Vector2.ZERO, emp = null) -> bool:
	if emp != null:
		if not emp.available() or not emp.catalog_valid or not emp.region(0, 0).has_area():
			return false
	else:
		if not atlas.available() or not atlas.catalog_valid:
			return false
		for column in range(6):
			if not atlas.region(row, column).has_area():
				return false
	var state := effect_sample(effect.age, duration)
	if effect.age >= duration:
		return true
	view.draw_set_transform(effect.pos + offset, float(effect.age) * PI if emp != null else 0.0)
	if emp != null:
		view.draw_texture_rect_region(emp.paint, fit_rect(size * state.scale, emp.region(0, 0)), emp.region(0, 0), Color(1, 1, 1, state.alpha))
	else:
		# Normalize only once against maximum original occupancy, keeping aspect and
		# physical impact center fixed while phases blend and the envelope expands.
		for entry in [[state.first, 1.0 - state.blend], [state.second, state.blend]]:
			if entry[1] <= 0.0:
				continue
			var source: Rect2 = atlas.region(row, entry[0])
			view.draw_texture_rect_region(atlas.paint, fit_rect(size * state.scale, source), source, Color(1, 1, 1, state.alpha * entry[1]))
	view.draw_set_transform(Vector2.ZERO)
	return true
