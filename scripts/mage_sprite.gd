extends "res://scripts/mobile_sprite.gd"
## Original Mage data from OpenBound (GPL-3.0-or-later).
## Copyright (C) 2020, Carlos H.M.S. <carlos_judo@hotmail.com>

const SEQUENCES := {
	"idle": [0, 19, 20.0, true], "idle_low": [40, 59, 18.0, true],
	"moving": [20, 39, 17.0, true], "moving_low": [60, 79, 17.0, true],
	"charging_0": [204, 222, 19.0, true], "charging_1": [303, 321, 19.0, true],
	"charging_2": [391, 409, 14.0, true],
	"recoil_0": [100, 119, 19.0, false], "recoil_1": [100, 119, 21.0, false],
	"recoil_2": [100, 119, 20.0, false],
	"hurt": [341, 365, 24.0, false], "destroyed": [179, 203, 19.0, false]
}
var laser_textures: Array[Texture2D] = []
var orb: Texture2D
var effects: Array[Texture2D] = []
var shoot_sounds: Array[AudioStream] = []
var blast_sounds: Array[AudioStream] = []
const ProjectileArt = preload("res://scripts/projectile_art.gd")
var projectile_art
var effect_sizes: Array[Vector2] = []
var hd_shots
var hd_effects
var hd_emp

func _init() -> void:
	configure("res://assets/openbound/mage", Vector2(109, 150), Vector2(52, 85), SEQUENCES, 46.0, 117.0)
	projectile_art = ProjectileArt.new()
	hd_shots = projectile_art.sheet
	hd_effects = HDSheet.new("res://assets/hd/effects.png", 6, 6)
	hd_emp = HDSheet.new("res://assets/hd/emp.png", 1, 1)
	for number in [1, 2]:
		laser_textures.append(pixel_texture(load("res://assets/openbound/mage/S%dT.png" % number)))
	orb = pixel_texture(load("res://assets/openbound/mage/Bullet3.png"))
	for number in [1, 2, 3]:
		effects.append(pixel_texture(load("res://assets/openbound/mage/Flame%d.png" % number)))
	for key in ["S1", "S2", "SS"]:
		shoot_sounds.append(load("res://assets/openbound/mage/Shoot%s.mp3" % key))
		blast_sounds.append(load("res://assets/openbound/mage/Blast%s.mp3" % key))

	for weapon in range(3):
		effect_sizes.append(ProjectileArt.effect_size(effects[weapon], effect_cell(weapon)))

func effect_cell(weapon: int) -> Vector2:
	return [Vector2(193, 192), Vector2(143, 142), Vector2(385, 384)][weapon]

func effect_capacity(weapon: int) -> int:
	var size := effect_cell(weapon)
	return int(effects[weapon].get_width() / size.x) * int(effects[weapon].get_height() / size.y)

func effect_frame(weapon: int, age: float) -> int:
	return clampi(int(age * 30.0), 0, effect_capacity(weapon) - 1)

func draw_effect(view: Node2D, effect: Dictionary, offset: Vector2 = Vector2.ZERO) -> void:
	var weapon: int = effect.weapon
	var size := effect_cell(weapon)
	var columns := int(effects[weapon].get_width() / size.x)
	var frame := effect_frame(weapon, effect.age)
	var duration := float(effect_capacity(weapon)) / 30.0
	if effect.age >= duration:
		return
	if projectile_art.draw_effect(view, effect, hd_effects, weapon + 3, effect_sizes[weapon], duration, offset, hd_emp if weapon == 2 else null):
		return
	var alpha := 1.0 - float(effect.age) / duration
	view.draw_set_transform(effect.pos + offset, float(effect.age) * PI if weapon == 2 else 0.0)
	var target := Rect2(-size / 2, size)
	var source := Rect2(Vector2(frame % columns, int(frame / columns)) * size, size)
	view.draw_texture_rect_region(effects[weapon], target, source, Color(1, 1, 1, alpha))
	view.draw_set_transform(Vector2.ZERO)

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	if projectile_art.draw(view, "mage", projectile, weapon, offset):
		return
	if not projectile.get("launched", true):
		return
	var position: Vector2 = projectile.get("hit_pos", projectile.pos)
	var rotation := Vector2(projectile.velocity).angle()
	if weapon == 2:
		var frame := int(projectile.age * 20.0) % 15
		view.draw_set_transform(position + offset, rotation + PI)
		view.draw_texture_rect_region(orb, Rect2(-27, -27, 54, 54), Rect2(frame * 54, 0, 54, 54))
	else:
		var tint := Color.WHITE
		if weapon == 1:
			tint = Color("d43e70") if float(projectile.get("phase", 0)) < 1.0 else Color("99a5de")
		var trail: Array = projectile.trail
		for index in range(trail.size()):
			var age := float(trail.size() - index) / 30.0
			var frame := clampi(int(age * 72.0), 0, 72)
			view.draw_set_transform(trail[index] + offset, rotation)
			var fade := Color(tint, float(index + 1) / trail.size() * 0.8)
			var source := Rect2((frame % 8) * 16, int(frame / 8) * 16, 16, 16)
			view.draw_texture_rect_region(laser_textures[weapon], Rect2(-8, -8, 16, 16), source, fade)
		var frame := int(projectile.age * 30.0) % 8
		view.draw_set_transform(position + offset, rotation)
		view.draw_texture_rect_region(laser_textures[weapon], Rect2(-8, -8, 16, 16), Rect2(frame * 16, 0, 16, 16), tint)
	view.draw_set_transform(Vector2.ZERO)
