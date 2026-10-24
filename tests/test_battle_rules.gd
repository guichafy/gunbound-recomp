extends "res://tests/support/suite.gd"
## Battle rules parity (REQ-44, ADR-076): original rule when reverse engineering
## proves it, OpenBound C# otherwise. Evidence in docs/sdd/BATTLE_RULES_AUDIT.md.

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Items = preload("res://scripts/items.gd")

## Ticks the live model until the shot is scheduled (or the match ends).
func resolve(model) -> void:
	for _frame in range(4000):
		if model.phase == "aim" or model.phase == "finished":
			return
		model.tick(1.0 / 60.0)

func _initialize() -> void:
	# characterdata.dat: base [28] + shot [30/31/32]; the C# Nak row is another mobile's.
	var nak_delays := [770.0, 920.0, 1320.0]
	for weapon in range(3):
		check(is_equal_approx(float(Mobiles.weapon(3, weapon).delay), nak_delays[weapon] / 7.5), "Nak shot %d uses the original delay" % weapon)
	for id in Mobiles.PLAYABLE:
		check(int(Mobiles.definition(id).time_delay) == 10, "characterdata [29]: 10 delay per second spent for mobile %d" % id)
	var mage: Dictionary = Mobiles.definition(1)
	check(int(mage.hp) == 730 and int(mage.shield) == 220 and int(mage.shield_regen) == 30, "Mage keeps the original 730 HP and 30 shield regeneration")

	# itemdata.dat delay column; Dual, Thunder, Power Up, Energy Up 1, Team Teleport and Blood already matched the C#.
	var costs := {"dual": 600, "dual_plus": 250, "thunder": 200, "energy_up_2": 300, "team_teleport": 50, "teleport": 100,
		"blood": 0, "bunge_shot": 50, "power_up": 150, "change_wind": 150, "energy_up_1": 100}
	for id in costs:
		check(int(Items.definition(id).cost) == int(costs[id]), "itemdata delay for %s" % id)

	# Opening: fixtures keep the player first; the real match draws it from the seed.
	var model = Match.new()
	model.start(2, 1, 7, "")
	check(model.active == Match.PLAYER, "Default opening stays with the player for fixtures")
	var openers := {}
	for seed_value in range(1, 41):
		model = Match.new()
		model.start(2, 1, seed_value, "", "original", null, [], [], [], -1)
		openers[model.active] = true
		var again = Match.new()
		again.start(2, 1, seed_value, "", "original", null, [], [], [], -1)
		if again.active != model.active:
			check(false, "Opening draw is deterministic per seed")
	check(openers.has(Match.PLAYER) and openers.has(Match.CPU), "Random opening gives the first turn to either side")
	model = Match.new()
	model.start(2, 1, 7, "", "original", null, [], [], [], Match.CPU)
	check(model.active == Match.CPU and int(model.actors[Match.CPU].turns) == 1, "An explicit CPU opening starts the CPU turn")

	# Pass: TurnSkipDelayCost 200, no time term.
	model = Match.new()
	model.start(2, 1, 7, "")
	model.turn_time = 5.0
	model.pass_turn()
	check(is_equal_approx(float(model.actors[Match.PLAYER].ready), 200.0 / 7.5), "Passing costs 200 regardless of the time spent")
	model = Match.new()
	model.start(2, 1, 7, "")
	model.tick(30.5)
	check(model.active == Match.CPU and is_equal_approx(float(model.actors[Match.PLAYER].ready), 200.0 / 7.5), "Timeout passes for 200")

	# Time spent: ((turn length − remaining) / 1 s) whole seconds × [29].
	model = Match.new()
	model.start(2, 1, 7, "")
	model.turn_time = Match.TURN_TIME - 12.4
	var preview: Array = model.initiative_preview(0)
	var own: Dictionary = preview[0] if int(preview[0].actor) == Match.PLAYER else preview[1]
	check(is_equal_approx(float(own.ready), (770.0 + 120.0) / 7.5), "Initiative preview charges the live time spent")
	check(model.fire(45.0, 60.0, 0), "Bigfoot S1 fires")
	check(int(model.shot_elapsed) == 12, "Fire records 12 whole seconds spent")
	model.turn_time = 1.0
	resolve(model)
	check(is_equal_approx(float(model.actors[Match.PLAYER].ready), (770.0 + 120.0) / 7.5), "Shot delay = table + 12 s × 10 (time after firing is free)")
	model = Match.new()
	model.start(2, 1, 7, "")
	model.turn_time = Match.TURN_TIME - 0.97
	model.fire(45.0, 60.0, 0)
	resolve(model)
	check(is_equal_approx(float(model.actors[Match.PLAYER].ready), 770.0 / 7.5), "A fraction of a second adds nothing")

	# Tie on initiative still goes to the other side.
	model = Match.new()
	model.start(2, 1, 7, "")
	model.actors[Match.CPU].ready = 200.0 / 7.5
	model.pass_turn()
	check(model.active == Match.CPU, "Equal initiative favours the actor that did not just play")

	# CPU think time (ADR-076): the CPU pays a fixed time, never its search wall clock.
	var TurnTable = preload("res://scripts/turn_table.gd")
	var cpu_ready := []
	for spent in [0.4, 19.5]:
		model = Match.new()
		model.start(2, 1, 7, "", "original", null, [], [], [], Match.CPU)
		model.tick(spent)
		check(model.fire(45.0, 60.0, 0), "CPU fires after %.1f s of search" % spent)
		check(int(model.shot_elapsed) == TurnTable.CPU_THINK_SECONDS, "CPU shot records the fixed think time")
		resolve(model)
		cpu_ready.append(float(model.actors[Match.CPU].ready))
	check(is_equal_approx(cpu_ready[0], cpu_ready[1]) and is_equal_approx(cpu_ready[0], (float(Mobiles.weapon(1, 0).delay) * 7.5 + 10.0 * TurnTable.CPU_THINK_SECONDS) / 7.5),
		"CPU delay = table + fixed think time, independent of the search duration")
	# Same seed => same turn order, however long each CPU search takes.
	var orders := []
	for search in [0.2, 14.0]:
		model = Match.new()
		model.start(2, 2, 11, "", "original", null, [], [], [], -1)
		var order := []
		for _turn in range(8):
			if model.phase == "finished":
				break
			order.append(model.active)
			if model.active == Match.CPU:
				var plan: Dictionary = model.choose_cpu_shot()
				model.tick(search)
				model.fire(plan.angle, plan.power, plan.weapon)
				resolve(model)
			else:
				model.pass_turn()
		orders.append(order)
	check(orders[0] == orders[1] and orders[0].has(Match.CPU), "Same seed gives the same turn order regardless of CPU search time")
	# CPU search freezes the turn clock (ADR-076): a slow search never times out.
	model = Match.new()
	model.start(2, 1, 7, "", "original", null, [], [], [], Match.CPU)
	var slow_plan: Dictionary = model.begin_cpu_plan()
	model.tick(45.0)
	check(model.phase == "aim" and model.active == Match.CPU and is_equal_approx(model.turn_time, Match.TURN_TIME), "A 45 s CPU search neither expires the turn nor spends its clock")
	Match.search_cpu_plan(slow_plan)
	model.finish_cpu_plan(slow_plan)
	model.tick(1.0)
	check(is_equal_approx(model.turn_time, Match.TURN_TIME - 1.0), "The clock runs again once the plan is chosen")
	var frozen_orders := []
	for search in [0.1, 60.0]:
		model = Match.new()
		model.start(2, 2, 11, "", "original", null, [], [], [], -1)
		var order := []
		for _turn in range(8):
			if model.phase == "finished":
				break
			order.append(model.active)
			if model.active == Match.CPU:
				var plan: Dictionary = model.begin_cpu_plan()
				model.tick(search)
				Match.search_cpu_plan(plan)
				var best: Dictionary = model.finish_cpu_plan(plan)
				model.fire(best.angle, best.power, best.weapon)
				resolve(model)
			else:
				model.pass_turn()
		frozen_orders.append(order)
	check(frozen_orders[0] == frozen_orders[1] and frozen_orders[0].has(Match.CPU), "Same seed, same turn order with a 0.1 s or 60 s CPU search")

	# HUD queue order lives in TurnTable: a tie favours the side that is not active.
	model = Match.new()
	model.start(2, 1, 7, "")
	model.actors[Match.PLAYER].ready = 40.0
	model.actors[Match.CPU].ready = 40.0
	var queue: Array = model.current_order()
	check(int(queue[0].actor) == Match.CPU and int(queue[1].actor) == Match.PLAYER, "Queue tie favours the actor that is not active")
	model.actors[Match.CPU].ready = 41.0
	check(int(model.current_order()[0].actor) == Match.PLAYER, "Queue puts the lower readiness first")

	# Ballistics from the C# (Parameter.cs): gravity 9.8 × 20, speed = force × 100 / mass 14, wind × 1.2.
	check(is_equal_approx(Combat.GRAVITY, 196.0), "Gravity 196")
	check(is_equal_approx(Combat.launch_velocity(45.0, 70.0, 1).length(), 70.0 * 100.0 / 14.0), "Launch speed = force × 100 / 14")
	check(is_equal_approx(Combat.launch_velocity(45.0, 50.0, 1, 0.0, 4.0).length(), 54.0 * 100.0 / 14.0), "Emitter force offset joins before the mass division")
	check(is_equal_approx(Combat.launch_velocity(45.0, 0.0, 1).length(), 15.0 * 100.0 / 14.0), "Power floor stays at 15")
	var step: Dictionary = Combat.advance(Vector2.ZERO, Vector2.ZERO, Vector2(10.0, 0.0), 1.0)
	check(is_equal_approx(step.velocity.x, 12.0) and is_equal_approx(step.velocity.y, 196.0), "Wind accelerates by force × 1.2")
	model = Match.new()
	model.start(2, 1, 7, "", "original", null, ["teleport"])
	check(model.use_item(0), "Teleport is used")
	var beacon: Array = model.shot_shells(Match.PLAYER, 45.0, 60.0, 0)
	check(beacon.size() == 1 and is_equal_approx(Vector2(beacon[0].velocity).length(), 60.0 * 100.0 / 10.0), "Beacon mass 10")

	finish("BATTLE RULES CHECKS")
