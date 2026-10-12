extends RefCounted
## Turn order for the two training slots. The match keeps phase, actors and events.

const Mobiles = preload("res://scripts/mobiles.gd")
const PLAYER := 0
const CPU := 1

static func other(index: int) -> int:
	return 1 - index

static func schedule(model, index: int, delay: float) -> void:
	model.actors[index].ready = maxf(float(model.actors[index].ready), model.clock) + delay
	var difference := float(model.actors[PLAYER].ready) - float(model.actors[CPU].ready)
	model.active = other(index) if is_zero_approx(difference) else (PLAYER if difference < 0.0 else CPU)
	model.clock = float(model.actors[model.active].ready)
	model.begin_turn()

static func pass_turn(model) -> void:
	if model.phase != "aim":
		return
	model.events.append({"type": "pass", "actor": model.active})
	var delay := 80.0 + float(model.VEHICLES[model.actors[model.active].vehicle].delay)
	schedule(model, model.active, delay)

static func initiative_preview(model, weapon: int) -> Array:
	var ready := [float(model.actors[PLAYER].ready), float(model.actors[CPU].ready)]
	if model.phase in ["aim", "flight", "settle"]:
		var count := Mobiles.weapon_count(model.actors[model.active].vehicle)
		var selected: int = clampi(weapon, 0, count - 1) if model.phase == "aim" else int(model.shot_weapon)
		ready[model.active] = maxf(ready[model.active], model.clock) + float(model.weapon_rules(model.active, selected).delay) + float(model.VEHICLES[model.actors[model.active].vehicle].delay)
	var first := other(model.active) if is_zero_approx(ready[PLAYER] - ready[CPU]) else (PLAYER if ready[PLAYER] < ready[CPU] else CPU)
	return [
		{"actor": first, "ready": ready[first], "delay": maxf(0.0, ready[first] - model.clock)},
		{"actor": other(first), "ready": ready[other(first)], "delay": maxf(0.0, ready[other(first)] - model.clock)}
	]

static func check_end(model) -> bool:
	if int(model.actors[PLAYER].hp) > 0 and int(model.actors[CPU].hp) > 0:
		return false
	var player_alive := int(model.actors[PLAYER].hp) > 0
	var cpu_alive := int(model.actors[CPU].hp) > 0
	model.winner = -1 if not player_alive and not cpu_alive else (PLAYER if player_alive else CPU)
	model.phase = "finished"
	model.projectiles.clear()
	model.events.append({"type": "finished", "winner": model.winner})
	return true
