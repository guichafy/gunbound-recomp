extends RefCounted
## Stable HD pieces. Continuous presentation transforms; never changes combat.
const AvatarArt = preload("res://scripts/avatar_art.gd")
var avatars = AvatarArt.new()
const Sheet = preload("res://scripts/hd_sheet.gd")
const MobileLooks = preload("res://scripts/mobile_looks.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
# Geometry for a mobile without approved HD parts: sample() still feeds the
# pose blend, but draw() falls back to the original atlas.
const NO_LAYOUT := {"row": -1, "parts": 0, "hull": 60.0, "seat": Vector2.ZERO, "body_size": Vector2.ZERO,
	"body_top": 0.0, "gun_pivot": Vector2.ZERO, "gun_rect": Rect2(), "tip": Vector2.ZERO, "wheels": false}
var kind: String
var sheet
var pilot
var avatar_mount := Transform2D.IDENTITY
var avatar_registered := false
func _init(mobile_kind: String) -> void:
	kind = mobile_kind
	sheet = Sheet.new("res://assets/hd/mobile_parts.png", 3, 2)
	pilot = Sheet.new("res://assets/hd/pilot_side.png", 1, 1)
func register_avatar(native_origin: Vector2, contact_offset: float, native_hull: float) -> void:
	# RiderPivot is the body sprite origin, distinct from the HD master's hip.
	var native_scale := 60.0 / native_hull
	avatar_mount = Transform2D(0,Vector2.ONE*native_scale,0,(native_origin-Vector2(0,contact_offset))*native_scale)
	avatar_registered = true
func avatar_transform(state: Dictionary) -> Transform2D:
	return Transform2D(state.body_angle,state.body_offset) * avatar_mount * Transform2D(state.pilot_angle,Vector2.ZERO)
## HD layout of this mobile (MobileLooks); empty when it has no approved HD parts.
func layout() -> Dictionary:
	return MobileLooks.rig_layout(kind)
func available() -> bool:
	var parts := layout()
	if parts.is_empty():
		return false
	if not sheet.available() or not sheet.catalog_valid or not pilot.available() or not pilot.catalog_valid:
		return false
	for column in range(int(parts.parts)):
		if not sheet.region(int(parts.row), column).has_area():
			return false
	return pilot.region(0, 0).has_area()
func sample(pose: String, age: float, weapon: int, idle_age: float = -1.0) -> Dictionary:
	age = maxf(0.0, age)
	var parts := layout()
	if parts.is_empty():
		parts = NO_LAYOUT
	if pose == "using_item":
		pose = "using"
	elif pose.begins_with("charging") or pose.begins_with("recoil"):
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
		var progress := clampf(age / MobileLooks.RECOIL_TIME, 0.0, 1.0)
		var kick := sin(progress * PI) * exp(-progress * 3.0)
		offset.x = kick * (9.0 if weapon == 2 else 6.0)
		barrel = -kick * (0.65 if weapon == 2 else 0.45)
		flash = sin(clampf(age / 0.16, 0.0, 1.0) * PI)
	elif pose == "using":
		# UsingItem lasts 20 frames at 19 fps. The green aura is a separate
		# overlay; the body only lifts, it does not grow a charge glow.
		var lift := sin(clampf(age / MobileLooks.USING_ITEM_TIME, 0.0, 1.0) * PI)
		offset.y = -lift * 3.0
	elif pose == "hurt" or pose == "hurt_2":
		var envelope := sin(clampf(age / float(Mobiles.definition(MobileLooks.id_of(kind)).hurt), 0.0, 1.0) * PI)
		offset.x = sin(age * 40.0) * envelope * (2.2 if pose == "hurt_2" else 1.7)
		angle = sin(age * 20.0) * envelope * (0.07 if pose == "hurt_2" else 0.04)
	elif pose == "shock":
		offset.x = sin(age * 60.0) * 1.4
		angle = sin(age * 48.0) * 0.05
	elif pose == "falling":
		offset.y = clampf(age, 0.0, 1.0) * 6.0
		angle = clampf(age, 0.0, 1.0) * 0.2
	elif pose == "unable":
		offset.x = sin(age * TAU * 6.0) * 0.8
	elif pose == "destroyed":
		var duration := float(Mobiles.definition(MobileLooks.id_of(kind)).death)
		var progress := clampf(age / duration, 0.0, 1.0)
		offset.y = progress * progress * 14.0
		angle = progress * 0.65
		alpha = 1.0 - smoothstep(0.15, 1.0, progress)
	var region: Rect2 = pilot.region(0, 0)
	# Native idle body+head union: 44px tall against the 49/46px hulls.
	# One shared composition scale, rather than unrelated pilot/vehicle boxes.
	var pilot_height := 44.0 * 60.0 / float(parts.hull)
	var pilot_size := Vector2(pilot_height * region.size.x / maxf(region.size.y, 1.0), pilot_height)
	var pilot_rect := Rect2(-pilot_size * Vector2(0.78, 0.88), pilot_size)
	var pilot_sway := Vector2.ZERO
	# Breathing follows an uninterrupted clock, independent of pose restarts.
	var pilot_angle := sin((age if idle_age < 0.0 else idle_age) * TAU * 1.5) * 0.014
	var seat: Vector2 = parts.seat
	var body_size: Vector2 = parts.body_size
	return {"body_size": body_size,
		"body_rect": Rect2(Vector2(-30, float(parts.body_top)), body_size),
		"gun_pivot": parts.gun_pivot,
		"gun_rect": parts.gun_rect,
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
## `request` is a SpritePose; false when this mobile has no HD parts.
func draw(view: Node2D, request) -> bool:
	if not available():
		return false
	var pos: Vector2 = request.pos
	var width: float = request.width
	var facing: int = request.facing
	var rotation: float = request.rotation
	var pose: String = request.pose
	var age: float = request.age
	var weapon: int = request.weapon
	var color: Color = request.color
	var wheel_phase: float = request.wheel_phase
	var avatar_context: Dictionary = request.avatar_context
	var state: Dictionary = avatar_context.get("rig_state",{})
	if state.is_empty():
		state = sample(pose,age,weapon,float(avatar_context.get("age",age)))
	var scale := width / 60.0
	var ground := 24.0 if width < 150.0 else width * 0.23
	var basis := Transform2D(Vector2(-facing * scale, 0), Vector2(0, scale), Vector2.ZERO)
	var world := Transform2D(rotation, pos) * basis
	var support := world * Transform2D(0, Vector2(0, ground / scale))
	var body := support * Transform2D(state.body_angle, state.body_offset)
	var tint := Color(color, color.a * state.alpha)
	if request.low_health:
		tint *= Color(0.7, 0.7, 0.7)
	var parts := layout()
	var row := int(parts.row)
	var gun_pivot: Vector2 = state.gun_pivot
	var gun := body * Transform2D(state.barrel_angle, gun_pivot)
	# Entire seated anatomy rotates as one figure around the hips, no seam/stretch.
	var seat: Vector2 = state.pilot_anchor - state.body_offset + state.pilot_sway
	var avatar_drawn := false
	if avatar_registered and not avatar_context.is_empty():
		avatar_drawn = avatars.draw(view,avatar_context.get("equipment",{}),support*avatar_transform(state),float(avatar_context.get("age",age)),tint)
	# C# depth puts the mobile in front of equipped avatars, covering the legs.
	piece(view, sheet, row, 0, body, state.body_rect, tint)
	if not avatar_drawn:
		piece(view, pilot, 0, 0, body * Transform2D(state.pilot_angle, seat), state.pilot_rect, tint)
	# Mounted weapon and near tires occlude the seated lower body naturally.
	piece(view, sheet, row, 1, gun, state.gun_rect, tint)
	if bool(parts.wheels):
		var radius: float = state.wheel_radius
		for x in [-18.0, 18.0]:
			piece(view, sheet, row, 2, support * Transform2D(-facing * wheel_phase, Vector2(x, -radius)), Rect2(-radius, -radius, radius * 2, radius * 2), tint)
	view.draw_set_transform_matrix(gun)
	var tip: Vector2 = parts.tip
	if state.glow > 0.001:
		var aura := Color("66cfff") if weapon == 2 else Color("ffbd51")
		view.draw_arc(tip, 7 + state.glow * 3, age * 3, age * 3 + TAU * 0.8, 24, Color(aura, tint.a * state.glow * 0.65), 1.2, true)
	if state.flash > 0.001:
		view.draw_circle(tip, 7 * state.flash, Color(1, 0.86, 0.45, tint.a * state.flash))
	view.draw_set_transform(Vector2.ZERO)
	return true
