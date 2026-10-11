extends "res://scripts/mobile_sprite.gd"
## Original frames documented in OpenBound MobileFlipbook.cs (GPL-3.0-or-later).
## Copyright (C) 2020, Carlos H.M.S. <carlos_judo@hotmail.com>
## Asset provenance and copied files: assets/openbound/ATTRIBUTION.md.

const CELL := Vector2(129, 130)
const PIVOT := Vector2(75, 88)
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
var bullets: Array[Texture2D] = []
var effects: Array[Texture2D] = []
var shoot_sounds: Array[AudioStream] = []
var blast_sounds: Array[AudioStream] = []
const ProjectileArt = preload("res://scripts/projectile_art.gd")
var projectile_art
var effect_sizes: Array[Vector2] = []
var hd_shots
var hd_effects

func _init() -> void:
	configure("res://assets/openbound/bigfoot", CELL, PIVOT, SEQUENCES, 49.0, 119.0)
	projectile_art = ProjectileArt.new()
	hd_shots = projectile_art.sheet
	hd_effects = HDSheet.new("res://assets/hd/effects.png", 6, 6)
	for number in range(1, 4):
		bullets.append(pixel_texture(load("res://assets/openbound/bigfoot/Bullet%d.png" % number)))
		effects.append(pixel_texture(load("res://assets/openbound/bigfoot/Flame%d.png" % number)))
	for key in ["S1", "S2", "SS"]:
		shoot_sounds.append(load("res://assets/openbound/bigfoot/Shoot%s.mp3" % key))
		blast_sounds.append(load("res://assets/openbound/bigfoot/Blast%s.mp3" % key))

	for weapon in range(3):
		effect_sizes.append(ProjectileArt.effect_size(effects[weapon], effect_cell(weapon)))

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	if projectile_art.draw(view, "bigfoot", projectile, weapon, offset):
		return
	if not projectile.get("launched", true):
		return
	var cell: Vector2 = [Vector2(63, 40), Vector2(18, 15), Vector2(69, 35)][weapon]
	var count: int = [5, 10, 5][weapon]
	var frame := int(projectile.age * 20.0) % count
	# Original bullets point RIGHT, unlike the left-facing mobile atlas.
	view.draw_set_transform(projectile.get("hit_pos", projectile.pos) + offset, Vector2(projectile.velocity).angle())
	view.draw_texture_rect_region(bullets[weapon], Rect2(-cell * 0.5, cell), Rect2(Vector2(frame * cell.x, 0), cell))
	view.draw_set_transform(Vector2.ZERO)

func effect_cell(weapon: int) -> Vector2:
	return [Vector2(166, 158), Vector2(175, 183), Vector2(192, 192)][weapon]

func effect_capacity(weapon: int) -> int:
	var size := effect_cell(weapon)
	return int(effects[weapon].get_width() / size.x) * int(effects[weapon].get_height() / size.y)

func draw_effect(view: Node2D, effect: Dictionary, offset: Vector2 = Vector2.ZERO) -> void:
	var weapon: int = effect.weapon
	var size := effect_cell(weapon)
	var count := effect_capacity(weapon)
	if projectile_art.draw_effect(view, effect, hd_effects, weapon, effect_sizes[weapon], count / 30.0, offset):
		return
	var frame := int(float(effect.age) * 30.0)
	if frame >= count:
		return
	var columns := int(effects[weapon].get_width() / size.x)
	view.draw_set_transform(effect.pos + offset)
	var target := Rect2(-size / 2, size)
	var source := Rect2(Vector2(frame % columns, int(frame / columns)) * size, size)
	view.draw_texture_rect_region(effects[weapon], target, source)
	view.draw_set_transform(Vector2.ZERO)
