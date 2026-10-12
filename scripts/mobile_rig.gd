extends RefCounted
## Stable HD pieces. Continuous presentation transforms; never changes combat.
const AvatarArt = preload("res://scripts/avatar_art.gd")
var avatars = AvatarArt.new()
const Sheet = preload("res://scripts/hd_sheet.gd")
var kind: String
var sheet
var pilot
func _init(mobile_kind: String) -> void:
	kind = mobile_kind
	sheet = Sheet.new("res://assets/hd/mobile_parts.png", 3, 2)
	pilot = Sheet.new("res://assets/hd/pilot_side.png", 1, 1)
func available() -> bool:
	if not sheet.available() or not sheet.catalog_valid or not pilot.available() or not pilot.catalog_valid:
		return false
	var row := 0 if kind == "bigfoot" else 1
	for column in range(3 if kind == "bigfoot" else 2):
		if not sheet.region(row, column).has_area():
			return false
	return pilot.region(0, 0).has_area()
func sample(pose: String, age: float, weapon: int) -> Dictionary:
	age = maxf(0.0, age)
	pose = pose.get_slice("_", 0)
	var offset := Vector2.ZERO
	var angle := 0.0
	var barrel := 0.0
	var wheels := 0.0
	var flash := 0.0
	var glow := 0.0
	var alpha := 1.0
	if pose == "moving":
		offset.y = sin(age * TAU * 4.0) * 0.65
		wheels = age * 9.0
	elif pose == "charging":
		barrel = sin(age * TAU * 2.0) * 0.025
		glow = (1.0 - exp(-age * 8.0)) * (0.65 + sin(age * TAU * 2.0) * 0.15)
	elif pose == "recoil":
		var progress := clampf(age / 1.16, 0.0, 1.0)
		var kick := sin(progress * PI) * exp(-progress * 3.0)
		offset.x = kick * (9.0 if weapon == 2 else 6.0)
		barrel = -kick * (0.65 if weapon == 2 else 0.45)
		flash = sin(clampf(age / 0.16, 0.0, 1.0) * PI)
	elif pose == "hurt":
		var envelope := sin(clampf(age / 1.05, 0.0, 1.0) * PI)
		offset.x = sin(age * 40.0) * envelope * 1.7
		angle = sin(age * 20.0) * envelope * 0.04
	elif pose == "destroyed":
		var duration := 1.6 if kind == "mage" else 1.15
		var progress := clampf(age / duration, 0.0, 1.0)
		offset.y = progress * progress * 14.0
		angle = progress * 0.65
		alpha = 1.0 - smoothstep(0.15, 1.0, progress)
	var region: Rect2 = pilot.region(0, 0)
	# Native idle body+head union: 44px tall against the 49/46px hulls.
	# One shared composition scale, rather than unrelated pilot/vehicle boxes.
	var pilot_height := 44.0 * 60.0 / (49.0 if kind == "bigfoot" else 46.0)
	var pilot_size := Vector2(pilot_height * region.size.x / maxf(region.size.y, 1.0), pilot_height)
	var pilot_rect := Rect2(-pilot_size * Vector2(0.78, 0.88), pilot_size)
	var pilot_sway := Vector2.ZERO
	var pilot_angle := sin(age * TAU * 1.5) * 0.014
	var seat := Vector2(17, -20) if kind == "bigfoot" else Vector2(18, -28)
	var body_size := Vector2(60, 24) if kind == "bigfoot" else Vector2(60, 36)
	return {"body_size": body_size,
		"body_rect": Rect2(Vector2(-30, -31 if kind == "bigfoot" else -36), body_size),
		"gun_pivot": Vector2(-17, -37) if kind == "bigfoot" else Vector2(-19, -34),
		"gun_rect": Rect2(-13, -18, 25, 21) if kind == "bigfoot" else Rect2(-17, -23, 29, 23),
		"wheel_radius": 12.0,
		"pilot_size": pilot_size, "pilot_rect": pilot_rect, "pilot_sway": pilot_sway, "pilot_angle": pilot_angle,
		"body_offset": offset, "body_angle": angle, "barrel_angle": barrel,
		"wheel_angle": wheels, "flash": flash, "glow": glow, "alpha": alpha,
		"pilot_anchor": seat + offset}
func piece(view: Node2D, atlas, row: int, column: int, transform: Transform2D, target: Rect2, color: Color) -> void:
	view.draw_set_transform_matrix(transform)
	var source: Rect2 = atlas.region(row, column)
	var fitted := source.size * minf(target.size.x / source.size.x, target.size.y / source.size.y)
	view.draw_texture_rect_region(atlas.paint, Rect2(target.get_center() - fitted * 0.5, fitted), source, color)
func draw(view: Node2D, pos: Vector2, width: float, facing: int, rotation: float, pose: String, age: float, weapon: int, low_health: bool, color: Color, wheel_phase: float = 0.0, avatar_context: Dictionary = {}) -> bool:
	if not available():
		return false
	var state := sample(pose, age, weapon)
	var scale := width / 60.0
	var ground := 24.0 if width < 150.0 else width * 0.23
	var basis := Transform2D(Vector2(-facing * scale, 0), Vector2(0, scale), Vector2.ZERO)
	var world := Transform2D(rotation, pos) * basis
	var support := world * Transform2D(0, Vector2(0, ground / scale))
	var body := support * Transform2D(state.body_angle, state.body_offset)
	var tint := Color(color, color.a * state.alpha)
	if low_health:
		tint *= Color(0.7, 0.7, 0.7)
	var row := 0 if kind == "bigfoot" else 1
	piece(view, sheet, row, 0, body, state.body_rect, tint)
	var gun_pivot: Vector2 = state.gun_pivot
	var gun := body * Transform2D(state.barrel_angle, gun_pivot)
	# Entire seated anatomy rotates as one figure around the hips, no seam/stretch.
	var seat: Vector2 = state.pilot_anchor - state.body_offset + state.pilot_sway
	var avatar_drawn := false
	if not avatar_context.is_empty():
		var avatar_scale: float = float(state.pilot_size.y)/44.0
		var rider_transform := body * Transform2D(state.pilot_angle,seat) * Transform2D(0,Vector2.ONE*avatar_scale,0,Vector2(0,-8))
		avatar_drawn = avatars.draw(view,avatar_context.get("equipment",{}),rider_transform,float(avatar_context.get("age",age)),tint)
	if not avatar_drawn:
		piece(view, pilot, 0, 0, body * Transform2D(state.pilot_angle, seat), state.pilot_rect, tint)
	# Mounted weapon and near tires occlude the seated lower body naturally.
	piece(view, sheet, row, 1, gun, state.gun_rect, tint)
	if kind == "bigfoot":
		var radius: float = state.wheel_radius
		for x in [-18.0, 18.0]:
			piece(view, sheet, 0, 2, support * Transform2D(-facing * wheel_phase, Vector2(x, -radius)), Rect2(-radius, -radius, radius * 2, radius * 2), tint)
	view.draw_set_transform_matrix(gun)
	var tip := Vector2(-12, -13) if kind == "bigfoot" else Vector2(-13, -15)
	if state.glow > 0.001:
		var aura := Color("66cfff") if weapon == 2 else Color("ffbd51")
		view.draw_arc(tip, 7 + state.glow * 3, age * 3, age * 3 + TAU * 0.8, 24, Color(aura, tint.a * state.glow * 0.65), 1.2, true)
	if state.flash > 0.001:
		view.draw_circle(tip, 7 * state.flash, Color(1, 0.86, 0.45, tint.a * state.flash))
	view.draw_set_transform(Vector2.ZERO)
	return true
