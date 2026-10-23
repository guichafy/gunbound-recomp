extends RefCounted
## The one place that builds a combat actor (ADR-081). Actors stay Dictionaries:
## FlightSnapshot deep-copies them for the CPU thread with duplicate(true), which
## would share typed Objects with the live match.

## `items` are equipped item ids; `attributes` the sanitized eight points.
static func create(vehicle: int, position: Vector2, facing: int, max_health: int, shield: int, items: Array, attributes: Array) -> Dictionary:
	var bar: Array = []
	for id in items:
		bar.append({"id": id, "used": false})
	return {
		"vehicle": vehicle, "pos": position, "facing": facing,
		"hp": max_health, "max_hp": max_health, "shield": shield, "max_shield": shield,
		# Turn bookkeeping: readiness clock, own turns, SS lock and support tilt.
		"ready": 0.0, "turns": 0, "ss_lock": 0, "tilt": 0.0,
		# Item bar (EquippedButtonBar) and the item acting this turn.
		"items": bar, "turn_item": "",
		"attributes": attributes, "gold_state": {"gold": 0, "enemy_damage": 0},
	}
