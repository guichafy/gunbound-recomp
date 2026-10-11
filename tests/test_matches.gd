extends SceneTree

const Match = preload("res://scripts/match.gd")
var failures := 0

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	for seed_value in [81, 82, 83, 84, 85, 86, 87, 88, 89, 90]:
		var model = Match.new()
		model.start(1 if seed_value >= 89 else (2 if seed_value >= 87 else seed_value % 2), seed_value % 3, seed_value)
		if seed_value >= 89:
			# Exercise Bigfoot as CPU opponent of Mage, including delayed salvos.
			model.actors[1].vehicle = 2
			model.actors[1].hp = 1100
			model.actors[1].max_hp = 1100
			model.actors[1].shield = 0
			model.actors[1].max_shield = 0
		var shots := 0
		for frame in range(50000):
			if model.phase == "finished":
				break
			if model.phase == "aim":
				var shot: Dictionary = model.choose_cpu_shot()
				if not model.fire(shot.angle, shot.power, shot.weapon):
					printerr("FAIL: legal simulated shot rejected")
					failures += 1
					break
				shots += 1
			model.tick(1.0 / 30.0)
			model.events.clear()
		if model.phase != "finished":
			printerr("FAIL: Match did not reach result for seed ", seed_value)
			failures += 1
		print("MATCH seed=", seed_value, " shots=", shots, " winner=", model.winner, " remaining_hp=", [model.actors[0].hp, model.actors[1].hp])
	print("COMPLETE MATCHES: 10 | FAILURES: ", failures, " | TIME MS: ", Time.get_ticks_msec() - started)
	quit(0 if failures == 0 else 1)
