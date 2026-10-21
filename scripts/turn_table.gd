extends RefCounted
## Turn order for the two training slots. The match keeps phase, actors and events.

const Mobiles = preload("res://scripts/mobiles.gd")
const PLAYER := 0
const CPU := 1
# Delay units are the original ones ÷ 7.5 (MAGE_0_4.md).
const DELAY_SCALE := 7.5
# NetworkObjectParameters.TurnSkipDelayCost (ADR-076): passing pays no time term.
const PASS_COST := 200.0 / DELAY_SCALE

static func other(index: int) -> int:
	return 1 - index

static func schedule(model, index: int, delay: float) -> void:
	# The turn is over: item effects are dismissed (also after a pass, ADR-058).
	model.actors[index].turn_item = ""
	model.actors[index].ready = maxf(float(model.actors[index].ready), model.clock) + delay
	var difference := float(model.actors[PLAYER].ready) - float(model.actors[CPU].ready)
	model.active = other(index) if is_zero_approx(difference) else (PLAYER if difference < 0.0 else CPU)
	model.clock = float(model.actors[model.active].ready)
	model.begin_turn()

static func pass_turn(model) -> void:
	if model.phase != "aim":
		return
	model.events.append({"type": "pass", "actor": model.active})
	var delay := PASS_COST + float(model.VEHICLES[model.actors[model.active].vehicle].delay)
	schedule(model, model.active, delay)

## Whole seconds of the turn spent so far (ComputeTurnDelay: (400 − clock) / 20 ticks).
static func elapsed_seconds(model) -> int:
	return maxi(0, floori(float(model.TURN_TIME) - float(model.turn_time) + 0.000001))

## Original delay of a shot (ADR-076): table cost (base + shot, C# attribute
## discount) + seconds spent before firing × characterdata [29]. Both the
## scheduler and the initiative preview read this, so they cannot disagree.
static func shot_cost(model, index: int, weapon: int, elapsed: int) -> float:
	var vehicle: Dictionary = model.VEHICLES[model.actors[index].vehicle]
	var time_term := float(elapsed * int(vehicle.get("time_delay", 0))) / DELAY_SCALE
	return float(model.weapon_rules(index, weapon).delay) + float(vehicle.delay) + time_term

static func initiative_preview(model, weapon: int) -> Array:
	var ready := [float(model.actors[PLAYER].ready), float(model.actors[CPU].ready)]
	if model.phase in ["aim", "flight", "settle"]:
		var count := Mobiles.weapon_count(model.actors[model.active].vehicle)
		var selected: int = clampi(weapon, 0, count - 1) if model.phase == "aim" else int(model.shot_weapon)
		# SortTurnOrderByDelay previews with the live clock; after firing the spent time is fixed.
		var elapsed: int = elapsed_seconds(model) if model.phase == "aim" else int(model.shot_elapsed)
		ready[model.active] = maxf(ready[model.active], model.clock) + shot_cost(model, model.active, selected, elapsed)
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
