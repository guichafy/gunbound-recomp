extends SceneTree

const Match = preload("res://scripts/match.gd")
const Maps = preload("res://scripts/maps.gd")
const Partition = preload("res://tests/support/match_partition.gd")
var failures := 0

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	# Seeds 81–90 play Mage/Bigfoot, 91–93 Nak (ID 3, vs Mage). ADR-076 changed the
	# rules on purpose (C# ballistics, time-spent delay, drawn opening), so the
	# reference results in HANDOFF.md were recorded again.
	var seeds := [81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93]
	seeds = Partition.select(seeds, OS.get_cmdline_user_args())
	if seeds.is_empty():
		printerr("FAIL: invalid match partition")
		quit(1)
		return
	for seed_value in seeds:
		var model = Match.new()
		model.start(3 if seed_value > 90 else (1 if seed_value % 2 else 2), seed_value % 3, seed_value, Maps.DEFAULT, "original", null, [], [], [], Match.RANDOM_OPENING)
		var first: int = model.active
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
		print("MATCH seed=", seed_value, " opener=", first, " shots=", shots, " winner=", model.winner, " remaining_hp=", [model.actors[0].hp, model.actors[1].hp])
	print("COMPLETE MATCHES: ", seeds.size(), " | FAILURES: ", failures, " | TIME MS: ", Time.get_ticks_msec() - started)
	quit(0 if failures == 0 else 1)
