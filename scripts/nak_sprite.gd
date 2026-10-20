extends "res://scripts/mobile_sprite.gd"
## Original Nak frames from the Thor's Hammer client (tank3.img/tank3.epa),
## extracted by scripts/import_nak_assets.py; see docs/sdd/NAK_0_15.md.
## OpenBound has no Nak class, so the state names map like its MobileFlipbook
## does for Bigfoot/Mage: normal, move, bfire*, fire*, fdamage/bdamage, drop...

const CELL := Vector2(74, 57)
# Hotspot origin of every frame; RiderPivot.json is measured from this point.
const PIVOT := Vector2(37, 50)
const SEQUENCES := {
	"idle": [0, 19, 20.0, true],
	"idle_low": [38, 57, 18.0, true],
	"moving": [20, 37, 17.0, true],
	"moving_low": [58, 79, 17.0, true],
	"charging_0": [193, 202, 19.0, true],
	"charging_1": [243, 250, 19.0, true],
	"charging_2": [374, 381, 14.0, true],
	"recoil_0": [98, 112, 19.0, false],
	"recoil_1": [291, 300, 19.0, false],
	"recoil_2": [382, 391, 20.0, false],
	"hurt": [324, 348, 24.0, false], "hurt_2": [349, 373, 24.0, false],
	"shock": [113, 132, 19.0, false], "falling": [153, 172, 18.0, false],
	"unable": [80, 97, 19.0, true],
	"using_item": [203, 222, 19.0, false],
	"destroyed": [173, 192, 19.0, false]
}
# emotion1: the bubble-gum bubble of the idle Nak, every BUBBLE_PERIOD seconds.
const BUBBLE := [301, 320, 20.0]
const BUBBLE_PERIOD := 6.0
# The fork's Nak RiderPivot.json is the raw client rider point (hotspot + frame
# fields). For Bigfoot and Mage the fork's values sit (+7, +5) and (+2, +4) px
# from that raw point to fit its avatar registration; Nak takes the mean.
const RIDER_ADJUST := Vector2(5, 4)
const EFFECT_FPS := 30.0
const SHOT_FPS := 20.0

var meta: Dictionary = {}
var bullets: Array = []
var lights: Array = []
var effects: Array = []
var shoot_sounds: Array[AudioStream] = []
var blast_sounds: Array[AudioStream] = []

func _init() -> void:
	configure("res://assets/openbound/nak", CELL, PIVOT, SEQUENCES, 51.0, 53.0)
	meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/nak/frames.json"))
	for name in ["Bullet1", "Bullet2", "Bullet3"]:
		bullets.append(pixel_texture(load("res://assets/openbound/nak/%s.png" % name)))
	for name in ["Bullet1Light", "Bullet2Light"]:
		lights.append(pixel_texture(load("res://assets/openbound/nak/%s.png" % name)))
	for number in range(1, 4):
		effects.append(pixel_texture(load("res://assets/openbound/nak/Flame%d.png" % number)))
	for key in ["S1", "S2", "SS"]:
		shoot_sounds.append(load("res://assets/openbound/nak/Shoot%s.mp3" % key))
		blast_sounds.append(load("res://assets/openbound/nak/Blast%s.mp3" % key))

func rider_offset(frame: int) -> Vector2:
	return super.rider_offset(frame) + RIDER_ADJUST

func frame_index(pose: String, age: float, weapon: int, low_health: bool) -> int:
	if pose == "idle" and not low_health:
		var cycle := fmod(maxf(age, 0.0), BUBBLE_PERIOD)
		var start := BUBBLE_PERIOD - float(BUBBLE[1] - BUBBLE[0] + 1) / float(BUBBLE[2])
		if cycle >= start:
			return mini(int(BUBBLE[0]) + int(floor((cycle - start) * float(BUBBLE[2]))), int(BUBBLE[1]))
	return super.frame_index(pose, age, weapon, low_health)

## The Nak fires from its tail: the original aims 130–170° from the way the
## head looks, so the art is mirrored against the aiming side.
func draw(view: Node2D, pos: Vector2, width: float, facing: int, rotation: float, frame: int, color: Color = Color.WHITE, pose: String = "idle", age: float = 0.0, weapon: int = 0, low_health: bool = false, wheel_phase: float = 0.0, avatar_context: Dictionary = {}) -> void:
	super.draw(view, pos, width, -facing, rotation, frame, color, pose, age, weapon, low_health, wheel_phase, avatar_context)

func sheet(name: String) -> Dictionary:
	return meta.sheets[name]

## Region of frame `index` and its hotspot-relative rectangle.
func cell_frame(name: String, index: int) -> Array:
	var info := sheet(name)
	var cell := Vector2(info.cell[0], info.cell[1])
	var columns := int(info.columns)
	var source := Rect2(Vector2(index % columns, int(index / columns)) * cell, cell)
	return [source, Rect2(-Vector2(info.origin[0], info.origin[1]), cell)]

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	if not projectile.get("launched", true):
		return
	var position: Vector2 = projectile.get("hit_pos", projectile.pos) + offset
	var step := int(float(projectile.age) * SHOT_FPS)
	if weapon == 2:
		# Mini Nak faces right in bullet3pl; mirror it toward the flight.
		var parts := cell_frame("Bullet3.png", step % int(sheet("Bullet3.png").frames))
		var flip := -1.0 if Vector2(projectile.velocity).x < 0.0 else 1.0
		view.draw_set_transform(position, 0.0, Vector2(flip, 1))
		view.draw_texture_rect_region(bullets[2], parts[1], parts[0])
	else:
		var name := "Bullet%d" % (weapon + 1)
		# bullet3s: "normal" in the air, "special" once buried (SimulateShot2_Bullet3).
		var state := "special" if bool(projectile.get("underground", false)) else "normal"
		var frames: Array = sheet(name + ".png").states.get(state, [0])
		var index := int(frames[step % frames.size()])
		view.draw_set_transform(position)
		var light := cell_frame(name + "Light.png", index)
		view.draw_texture_rect_region(lights[weapon], light[1], light[0], Color(1, 1, 1, 0.75))
		var body := cell_frame(name + ".png", index)
		view.draw_texture_rect_region(bullets[weapon], body[1], body[0])
	view.draw_set_transform(Vector2.ZERO)

func effect_capacity(weapon: int) -> int:
	return int(sheet("Flame%d.png" % (weapon + 1)).frames)

func draw_effect(view: Node2D, effect: Dictionary, offset: Vector2 = Vector2.ZERO) -> void:
	var weapon: int = effect.weapon
	var frame := int(float(effect.age) * EFFECT_FPS)
	if frame >= effect_capacity(weapon):
		return
	var parts := cell_frame("Flame%d.png" % (weapon + 1), frame)
	view.draw_set_transform(Vector2(effect.pos) + offset)
	view.draw_texture_rect_region(effects[weapon], parts[1], parts[0])
	view.draw_set_transform(Vector2.ZERO)
