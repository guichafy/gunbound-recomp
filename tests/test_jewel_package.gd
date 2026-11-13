extends "res://tests/support/suite.gd"
func run() -> void:
	check(ResourceLoader.exists("res://scripts/ci/jewel_smoke.gd"),"Exported template has a JEWEL smoke")
	if ResourceLoader.exists("res://scripts/ci/jewel_smoke.gd"):
		check(load("res://scripts/ci/jewel_smoke.gd").run(check)==22,"JEWEL smoke covers all22sides")
	finish("JEWEL PACKAGE CHECKS")
