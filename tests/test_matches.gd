extends SceneTree

const Match = preload("res://scripts/match.gd")
var failures := 0

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	for seed_value in [81, 82, 83, 84, 85, 86, 87, 88, 89, 90]:
		var model = Match.new()
		model.start(1 if seed_value % 2 else 2, seed_value % 3, seed_value)
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
