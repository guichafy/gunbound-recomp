extends "res://tests/support/suite.gd"
## REQ-04/07/08/32/45/51: native terrain cannot depend on an incidental opponent.
const Match = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Mobiles = preload("res://scripts/mobiles.gd")

func ready_mask(model) -> bool:
	return model.terrain.native_cells.size() == model.terrain.WIDTH * model.terrain.HEIGHT * 4

func start_pair(model, left: int, right: int, map: String) -> void:
	model.start(left, 1, 42, map, "original", null, [], [], [], 0, right)

func flight_parity(vehicle: int, side: int, weapon: int, map: String) -> void:
	var model = Match.new()
	model.start(vehicle if side == 0 else 2, 1, 42, map, "original", null, [], [], [], side, 2 if side == 0 else vehicle)
	check(ready_mask(model), "native flight starts with complete mask")
	if not ready_mask(model): return
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	var before: PackedByteArray = model.terrain.native_cells.duplicate()
	var predicted: Dictionary = model.predict_shot(side, 45, 30, weapon)
	check(not predicted.is_empty(), "prediction resolves vehicle %d weapon %d side %d" % [vehicle, weapon, side])
	check(model.terrain.native_cells == before, "predict_shot preserves live native ground")
	check(model.fire(45, 30, weapon), "native shot accepted on either side")
	var sim = Snapshot.capture(model)
	Snapshot.arm(sim, side, weapon, model.projectiles.duplicate(true))
	model.events.clear()
	var same := true
	var impact := false
	for tick in 1000:
		model.advance_projectiles(0.05)
		sim.advance_projectiles(0.05)
		same = same and model.events == sim.events and model.actors == sim.actors and model.projectiles == sim.projectiles
		for event in model.events:
			if event.type == "explosion": impact = true
		model.events.clear()
		sim.events.clear()
		if model.phase != Match.PHASE_FLIGHT: break
	check(impact and model.phase == Match.PHASE_SETTLE, "native shot resolves with an impact")
	check(same and model.terrain.native_cells == sim.terrain.native_cells and model.terrain.cells == sim.terrain.cells, "real flight equals prediction snapshot including ground and actors")

func run() -> void:
	# Independent inventory of consumers: common contact + Grub ricochet.
	for native in [1, 6, 8, 13, 16]:
		for opponent in Mobiles.PLAYABLE:
			for side in 2:
				for map in ["miramo_town_a", ""]:
					var model = Match.new()
					start_pair(model, native if side == 0 else opponent, opponent if side == 0 else native, map)
					check(ready_mask(model), "native %d, opponent %d, side %d, map '%s': mask ready at start" % [native, opponent, side, map])
	var reused = Match.new()
	for pair in [[13,2], [2,2], [2,6], [2,13]]:
		start_pair(reused, pair[0], pair[1], "miramo_town_a")
		if pair == [2,2]:
			check(ready_mask(reused), "global Thor requires fresh mask even on non-native-contact restart")
		else:
			check(ready_mask(reused), "reused match prepares native mask for %s" % str(pair))
			if not ready_mask(reused): continue
			var sim = Snapshot.capture(reused)
			check(sim.terrain.native_cells == reused.terrain.native_cells, "CPU snapshot owns complete native mask")
			var index: int = reused.terrain.native_cells.find(1)
			check(index >= 0, "native map contains solid ground")
			if index >= 0:
				sim.terrain.native_cells[index] = 0
				check(reused.terrain.native_cells[index] == 1, "CPU native mask mutation leaves live terrain intact")
	for vehicle in [6, 13]:
		for side in 2:
			for weapon in 3:
				for map in ["miramo_town_a", ""]:
					flight_parity(vehicle, side, weapon, map)
	finish("NATIVE TERRAIN CHECKS")
