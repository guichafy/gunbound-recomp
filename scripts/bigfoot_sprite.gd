extends RefCounted
## Original frames documented in OpenBound MobileFlipbook.cs (GPL-3.0-or-later).
## Copyright (C) 2020, Carlos H.M.S. <carlos_judo@hotmail.com>
## Asset provenance and copied files: assets/openbound/ATTRIBUTION.md.

const CELL := Vector2(129, 130)
const PIVOT := Vector2(75, 88)
const COLUMNS := 20
const SEQUENCES := {
	"idle": [0, 19, 20.0, true],
	"idle_low": [45, 64, 18.0, true],
	"moving": [20, 44, 17.0, true],
	"moving_low": [65, 104, 17.0, true],
	"charging_0": [212, 233, 19.0, true],
	"charging_1": [254, 273, 19.0, true],
	"charging_2": [254, 273, 14.0, true],
	"recoil_0": [125, 146, 19.0, false],
	"recoil_1": [125, 146, 19.0, false],
	"recoil_2": [274, 293, 20.0, false],
	"hurt": [394, 418, 24.0, false],
	"destroyed": [202, 211, 19.0, false]
}
var texture: Texture2D = load("res://assets/openbound/bigfoot/CharacterSpritesheet.png")
var paint_texture: CanvasTexture
var bullets: Array[Texture2D] = []
var rider_body: CanvasTexture
var rider_head: CanvasTexture
var rider_offsets: Array = []

func _init() -> void:
	paint_texture = pixel_texture(texture)
	for number in range(1, 4):
		bullets.append(pixel_texture(load("res://assets/openbound/bigfoot/Bullet%d.png" % number)))
	rider_body = pixel_texture(load("res://assets/openbound/bigfoot/RiderBody.png"))
	rider_head = pixel_texture(load("res://assets/openbound/bigfoot/RiderHead.png"))
	# JSON.NET accepted this source file's final comma; normalize it for Godot.
	var text := FileAccess.get_file_as_string("res://assets/openbound/bigfoot/RiderPivot.json").strip_edges()
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
	var sequence: Array = SEQUENCES.get(key, SEQUENCES.idle)
	var count := int(sequence[1]) - int(sequence[0]) + 1
	var step := maxi(0, int(floor(age * float(sequence[2]) + 0.00001)))
	return int(sequence[0]) + (step % count if sequence[3] else mini(step, count - 1))

func frame_rect(index: int) -> Rect2:
	return Rect2(Vector2(index % COLUMNS, int(index / COLUMNS)) * CELL, CELL)

func draw(view: Node2D, pos: Vector2, width: float, facing: int, rotation: float, frame: int, color: Color = Color.WHITE) -> void:
	# Native artwork faces left. The first frame's alpha hull is 49 px wide,
	# with its ground contact at y=119. Scale around the original pivot.
	var amount := width / 49.0
	var ground := 24.0 if width < 150.0 else width * 0.23
	view.draw_set_transform(pos, rotation, Vector2(-facing, 1))
	var rect := Rect2(Vector2(-PIVOT.x * amount, ground - 119.0 * amount), CELL * amount)
	view.draw_texture_rect_region(paint_texture, rect, frame_rect(frame), color)
	var rider := rider_offset(frame)
	var origin := Vector2(0, ground - 31.0 * amount)
	var avatar_frame := int(view.elapsed * 10.0) % 11
	view.draw_texture_rect_region(rider_body, Rect2(origin + (rider - Vector2(22, 12)) * amount, Vector2(44, 28) * amount), Rect2(avatar_frame * 44, 0, 44, 28), color)
	view.draw_texture_rect_region(rider_head, Rect2(origin + (rider + Vector2(7, -17) - Vector2(25, 12)) * amount, Vector2(38, 24) * amount), Rect2((11 + avatar_frame) * 38, 0, 38, 24), color)
	view.draw_set_transform(Vector2.ZERO)

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int) -> void:
	var cell: Vector2 = [Vector2(63, 40), Vector2(18, 15), Vector2(69, 35)][weapon]
	var count: int = [5, 10, 5][weapon]
	var frame := int(projectile.age * 20.0) % count
	# Canonical bullet sprites also face left; align them with actual velocity.
	view.draw_set_transform(projectile.pos, Vector2(projectile.velocity).angle() + PI)
	view.draw_texture_rect_region(bullets[weapon], Rect2(-cell * 0.5, cell), Rect2(Vector2(frame * cell.x, 0), cell))
	view.draw_set_transform(Vector2.ZERO)
