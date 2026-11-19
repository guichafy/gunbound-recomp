extends "res://tests/support/suite.gd"
## Exercise the game's adapter at every native force cell boundary using the pinned sine table.

const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Aim = preload("res://scripts/aim_control.gd")
# characterdata.dat column 25, reordered by stable project ID.
const FORCE_MAX = [45, 42, 41, 46, 43, 35, 44, 47, 50, 45, 50, 46, 50, 50, 48, 48]

class SlopeMatch extends "res://scripts/match.gd":
	var support_degrees := 0.0

	func body_rotation(_index: int) -> float:
		return deg_to_rad(support_degrees)

class Host:
	var model: Match
	var aim := Aim.new()
	var result := 0.0

	func player_can_act() -> bool:
		return true

	func shoot() -> void:
		result = aim.power
		aim.charging = false

func expected_velocity(sine: PackedFloat32Array, theta: int, power: int) -> Vector2i:
	var integers := Vector2i(int(sine[posmod(theta + 90, 360)] * power), int(sine[posmod(theta, 360)] * power))
	return Vector2i(int(float(integers.x) * 25.6), -int(float(integers.y) * 25.6))

func run() -> void:
	var sine := FileAccess.get_file_as_bytes("res://assets/openbound/physics/native-sine-f32.bin").to_float32_array()
	check(sine.size() == 360, "PE sine table contains one degree cycle")
	var boundary_checks := 0
	var velocity_checks := 0
	var ui_checks := 0
	for mobile in Mobiles.PLAYABLE:
		var model := SlopeMatch.new()
		model.start(mobile, 1, 42, "", "original")
		var limit := int(FORCE_MAX[mobile - 1])
		check(Mobiles.force_max(mobile) == limit, "DAT force limit for mobile %d" % mobile)
		var host := Host.new()
		host.model = model
		for cell in range(1, limit * 10 + 1):
			var middle := minf(100.0, (float(cell) + 0.25) * 10.0 / limit)
			var near_below := (float(cell) - 0.0001) * 10.0 / limit
			var near_above := (float(cell) + 0.0001) * 10.0 / limit
			check(Physics.native_power(near_below, limit) == maxi(1, cell - 1)
				and Physics.native_power(near_above, limit) == cell, "Native integer boundaries for mobile %d cell %d" % [mobile, cell])
			boundary_checks += 1
			host.aim.begin_charge(host)
			host.aim.tick(host, middle * 0.03)
			host.aim.release_charge(host)
			var slice := host.result
			host.aim.begin_drag(host, 0.0)
			host.aim.update_drag(middle * Aim.DRAG_FULL_POWER / 100.0, 1.0)
			host.aim.release_drag(host)
			var drag := host.result
			for weapon in 3:
				var limits := model.aim_limits(0, weapon)
				check(Physics.native_power(slice, limit) == cell and Physics.native_power(drag, limit) == cell, "Slice and Drag enter the same native cell")
				ui_checks += 1
				for support in [-20.25, 0.0, 20.25]:
					model.support_degrees = support
					for facing in [-1, 1]:
						model.actors[0].facing = facing
						for angle in [limits.x, (limits.x + limits.y) * 0.5, limits.y]:
							var axis := float(angle) if facing == 1 else 180.0 - float(angle)
							var theta := int(axis - support)
							var expected := expected_velocity(sine, theta, cell)
							var from_slice := model.shot_velocity_fp(0, angle, slice, weapon)
							var from_drag := model.shot_velocity_fp(0, angle, drag, weapon)
							check(from_slice == expected and from_drag == expected,
								"Base launch vector mobile %d weapon %d cell %d" % [mobile, weapon, cell])
							velocity_checks += 1
	print("LAUNCH GRID ", JSON.stringify({"boundaries": boundary_checks, "ui_cells": ui_checks,
		"velocity_pairs": velocity_checks}))
	finish("LAUNCH GRID CHECKS")
