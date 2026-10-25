extends SceneTree
## ADR-084 integration: natural CPU-controlled matches cover every mobile,
## including its ordinary and special emissions, on the real default map.
## No profile is opened; this suite only exercises in-memory models.

const Match = preload("res://scripts/match.gd")
const Maps = preload("res://scripts/maps.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
var failures := 0

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	for vehicle in Mobiles.PLAYABLE:
		var model = Match.new()
		var seed_value := 1700 + int(vehicle)
		model.start(int(vehicle), 2, seed_value, Maps.DEFAULT, "original", null, [], [], [], Match.RANDOM_OPENING)
		var shots := 0
		var results := 0
		for frame in range(90000):
			if model.phase == Match.PHASE_FINISHED:
				break
			if model.phase == Match.PHASE_AIM:
				var plan: Dictionary = model.choose_cpu_shot()
				if not model.fire(plan.angle, plan.power, plan.weapon):
					printerr("FAIL: rejected CPU shot for vehicle ", vehicle)
					failures += 1
					break
				shots += 1
			model.tick(1.0 / 30.0)
			for event in model.events:
				if event.type == "finished":
					results += 1
			model.events.clear()
		if model.phase != Match.PHASE_FINISHED or results != 1:
			printerr("FAIL: vehicle ", vehicle, " must finish exactly once; phase=", model.phase, " results=", results)
			failures += 1
		if model.winner not in [-1, 0, 1] or shots <= 0:
			printerr("FAIL: invalid natural match result for vehicle ", vehicle)
			failures += 1
		print("CLASSIC MATCH id=", vehicle, " seed=", seed_value, " shots=", shots, " winner=", model.winner,
			" remaining_hp=", [model.actors[0].hp, model.actors[1].hp])
	print("CLASSIC MATCHES: ", Mobiles.PLAYABLE.size(), " | FAILURES: ", failures,
		" | TIME MS: ", Time.get_ticks_msec() - started)
	quit(0 if failures == 0 else 1)
