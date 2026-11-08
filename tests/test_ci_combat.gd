extends "res://tests/support/suite.gd"
const CombatSmoke = preload("res://scripts/ci/combat_smoke.gd")

func run() -> void:
	check(CombatSmoke.run(check) == 48, "packaged smoke executes all 48 weapon cases")
	finish("CI COMBAT CHECKS")
