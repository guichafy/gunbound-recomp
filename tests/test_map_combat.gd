extends "res://tests/support/suite.gd"
func run() -> void:
	check(preload("res://scripts/ci/map_smoke.gd").run(check)==1056,"all48weapons on22sides")
	finish("MAP COMBAT CHECKS")
