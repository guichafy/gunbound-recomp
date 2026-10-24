extends "res://tests/support/suite.gd"
## REQ-35: OpenBound items in the shared turn/flight rules (ITEMS_0_13.md).
var Match
var Items
var Damage
## Procedural arena, no wind and no weather columns; player Bigfoot (2) or Mage (1).
func fresh(vehicle: int, loadout: Array, seed_value: int = 5):
	var model = Match.new()
	model.start(vehicle, 1, seed_value, "", "original", null, loadout)
	calm(model)
	return model

func calm(model) -> void:
	model.weather.wind_force = 0
	model.weather.columns.clear()
	model.weather.queue[0].type = "wind"
	model.wind = Vector2.ZERO

func fly(model) -> void:
	for i in range(4000):
		if model.phase not in ["flight", "settle"]:
			return
		model.tick(1.0 / 120.0)

func events_of(model, type: String) -> Array:
	var result: Array = []
	for event in model.events:
		if event.type == type:
			result.append(event)
	return result

func run() -> void:
	Match = load("res://scripts/match.gd")
	Items = load("res://scripts/items.gd")
	Damage = load("res://scripts/damage.gd")

	# Catalog (Item.cs, NetworkObjectParameters.cs): order, slots and delay ÷ 7.5.
	check(Items.ORDER.size() == 11 and Items.ORDER[0] == "dual" and Items.ORDER[10] == "energy_up_1", "Eleven items in the Item.ItemPresets order")
	var two_slots := 0
	for id in Items.ORDER:
		two_slots += 1 if Items.slots(id) == 2 else 0
	check(two_slots == 6, "Six 2-slot items and five 1-slot items")
	check(is_equal_approx(Items.delay("dual"), 80.0) and is_equal_approx(Items.delay("dual_plus"), 250.0 / 7.5) and is_equal_approx(Items.delay("teleport"), 100.0 / 7.5) and is_equal_approx(Items.delay("blood"), 0.0) and is_equal_approx(Items.delay("thunder"), 200.0 / 7.5), "Delay cost is the itemdata.dat cost ÷ 7.5 (ADR-076)")
	check(Items.sanitize(["dual", "dual", "teleport", "power_up"]) == ["dual", "dual", "teleport"], "Loadout keeps at most 6 slots (later items that do not fit are skipped)")
	check(Items.sanitize(["dual", "nope", 3, "blood", "blood"]) == ["dual", "blood", "blood"], "Unknown entries are dropped")
	check(Items.used_slots(Items.DEFAULT_LOADOUT) == 6, "Default loadout fills the six slots")

	# Equipping and usage gates.
	var model = fresh(2, ["dual", "power_up", "energy_up_1", "change_wind"])
	check(model.actors[Match.PLAYER].items.size() == 4 and model.actors[Match.CPU].items.is_empty(), "Player gets the loadout; the CPU plays without items")
	check(model.can_use_item(Match.PLAYER, 0) and not model.can_use_item(Match.CPU, 0) and not model.can_use_item(Match.PLAYER, 9), "Only the active actor can use an equipped slot")
	model.weather.queue[0].type = "ignorance"
	check(model.items_locked() and not model.use_item(0), "Ignorance locks the item bar")
	calm(model)
	var ready_before := float(model.actors[Match.PLAYER].ready)
	check(model.use_item(1), "Power Up is used in the aim phase")
	check(is_equal_approx(float(model.actors[Match.PLAYER].ready) - ready_before, 20.0), "Item delay is charged at once (150 ÷ 7.5)")
	var preview: Array = model.initiative_preview(0)
	var own := {}
	for entry in preview:
		if entry.actor == Match.PLAYER:
			own = entry
	check(is_equal_approx(float(own.ready), 20.0 + 770.0 / 7.5), "Delay preview adds the item cost to the shot delay")
	check(not model.use_item(2) and not model.can_use_item(Match.PLAYER, 0), "One item per turn")
	model.actors[Match.PLAYER].turns = 3
	check(not model.can_use_special(Match.PLAYER) and not model.fire(30.0, 60.0, 2), "Using an item locks SS for the turn")
	var events_before: int = model.events.size()
	model.pass_turn()
	check(str(model.actors[Match.PLAYER].turn_item).is_empty(), "Passing the turn dismisses the item effect")
	check(model.actors[Match.PLAYER].items[1].used and not model.actors[Match.PLAYER].items[0].used, "The used item stays consumed; the others remain")
	check(events_before > 0 and model.events.back().type == "turn", "The match continues with the next turn")

	# Energy Up: percentage of the maximum, clamped, shield untouched.
	model = fresh(1, ["energy_up_1", "energy_up_2"])
	var mage: Dictionary = model.actors[Match.PLAYER]
	mage.hp = 400
	mage.shield = 50
	model.use_item(0)
	check(int(mage.hp) == 400 + int(730 * 0.12) and int(mage.shield) == 50, "Energy Up 1 heals 12% of max health, not the shield")
	model.actors[Match.PLAYER].turn_item = ""
	mage.hp = 700
	model.use_item(1)
	check(int(mage.hp) == 730, "Energy Up 2 (30%) never exceeds max health")
	check(events_of(model, "item").size() == 2 and int(events_of(model, "item")[0].amount) == 87, "Item events carry the healed amount")

	# Blood: −8% of max health (never below 1), +33 attack.
	model = fresh(2, ["blood", "blood"])
	var bigfoot: Dictionary = model.actors[Match.PLAYER]
	model.use_item(0)
	check(int(bigfoot.hp) == 1100 - 88, "Blood costs 8% of max health")
	bigfoot.turn_item = ""
	bigfoot.hp = 50
	model.use_item(1)
	check(int(bigfoot.hp) == 1, "Blood cannot bring health to 0")

	# Attack multiplier after falloff (Projectile.CalculateDamage), truncated.
	var targets := [{"hp": 5000, "pos": Vector2(100, 100), "shield": 0}]
	var plain_events: Array = []
	Damage.blast(targets, plain_events, Vector2(110, 100), 25.0, 90.0)
	var plain := int(plain_events[0].amount)
	targets = [{"hp": 5000, "pos": Vector2(100, 100), "shield": 0}]
	var boosted_events: Array = []
	Damage.blast(targets, boosted_events, Vector2(110, 100), 25.0, 90.0, 0.0, 30.0)
	check(int(boosted_events[0].amount) == int(plain * 1.3), "Power Up multiplies the final damage by 1.3")
	targets = [{"hp": 5000, "pos": Vector2(100, 100), "shield": 0}]
	boosted_events = []
	Damage.blast(targets, boosted_events, Vector2(110, 100), 25.0, 90.0, 0.0, 33.0)
	check(int(boosted_events[0].amount) == int(plain * 1.33), "Blood multiplies the final damage by 1.33")

	# Power Up through explode(): the turn item reaches the blast.
	model = fresh(2, ["power_up"])
	model.actors[Match.CPU].shield = 0
	var target: Vector2 = model.actors[Match.CPU].pos
	model.shot_actor = Match.PLAYER
	model.explode(target + Vector2(5, 0), Match.CPU, {"damage": 90, "weapon": 0})
	var base_damage := int(events_of(model, "damage")[0].amount)
	model = fresh(2, ["power_up"])
	model.actors[Match.CPU].shield = 0
	model.use_item(0)
	model.shot_actor = Match.PLAYER
	model.explode(target + Vector2(5, 0), Match.CPU, {"damage": 90, "weapon": 0})
	check(int(events_of(model, "damage")[0].amount) == int(base_damage * 1.3), "explode() applies the Power Up of the shooter")

	# Bunge Shot: only the crater grows by 25%.
	model = fresh(2, ["bunge_shot"])
	var ground := Vector2(640, model.terrain.surface_at(640) + 30.0)
	model.shot_actor = Match.PLAYER
	model.explode(ground, -1, {"damage": 90, "weapon": 0})
	var normal_removed := int(events_of(model, "explosion")[0].removed)
	model = fresh(2, ["bunge_shot"])
	model.use_item(0)
	model.shot_actor = Match.PLAYER
	model.explode(ground, -1, {"damage": 90, "weapon": 0})
	var bunge: Dictionary = events_of(model, "explosion")[0]
	check(int(bunge.removed) > normal_removed and is_equal_approx(float(bunge.radius), 25.0), "Bunge Shot carves a wider crater; the damage radius is unchanged")

	# Change Wind: opposite direction, same force.
	model = fresh(2, ["change_wind"])
	model.weather.wind_force = 20
	model.weather.wind_angle = 300
	model.wind = model.weather.wind_vector()
	var old_wind: Vector2 = model.wind
	model.use_item(0)
	check(model.weather.wind_angle == 120 and model.wind.distance_to(-old_wind) < 0.001 and model.weather.wind_force == 20, "Change Wind turns the wind 180°")

	# Dual (Mage S1): two lasers, the second 1 s after the first spawn.
	model = fresh(1, ["dual"])
	model.use_item(0)
	model.fire(40.0, 70.0, 0)
	check(model.projectiles.size() == 2 and is_equal_approx(float(model.projectiles[1].spawn_at), 1.0) and int(model.projectiles[1].weapon) == 0, "Dual fires the same shot twice, 1 s apart")
	check(not model.projectiles[1].launched, "The second shot waits for its interaction time")
	fly(model)
	check(events_of(model, "volley").size() == 1 and events_of(model, "fire").size() == 1, "The second volley emits its own shooting event")
	check(events_of(model, "explosion").size() + events_of(model, "miss").size() == 2, "Both shots resolve")
	check(is_equal_approx(float(model.actors[Match.PLAYER].ready), 80.0 + 100.0), "Dual turn costs the item plus one shot delay")
	check(str(model.actors[Match.PLAYER].turn_item).is_empty(), "Shot turn end dismisses the item")

	# Dual with a Bigfoot salvo: InteractionTime 1 + 0.6, then each SpawnTime.
	model = fresh(2, ["dual", "dual_plus"])
	model.use_item(0)
	model.fire(30.0, 60.0, 0)
	var spawns: Array = []
	for shell in model.projectiles:
		if int(shell.volley) == 1:
			spawns.append(snappedf(float(shell.spawn_at), 0.001))
	check(model.projectiles.size() == 8 and spawns == [1.6, 1.8, 2.0, 2.2], "Bigfoot T1 Dual: second salvo at 1.6/1.8/2.0/2.2 s")

	# Dual+: S1 then S2, S2 then S1, each shell with its own weapon.
	model = fresh(2, ["dual_plus", "dual_plus"])
	model.use_item(0)
	model.fire(30.0, 60.0, 0)
	var second_weapons := {}
	var second_count := 0
	for shell in model.projectiles:
		if int(shell.volley) == 1:
			second_weapons[int(shell.weapon)] = true
			second_count += 1
	check(second_count == 6 and second_weapons.keys() == [1], "Dual+ after T1 fires a T2 salvo (6 bombs)")
	fly(model)
	var weapons_seen := {}
	for event in events_of(model, "projectile_launch"):
		weapons_seen[int(event.weapon)] = true
	check(weapons_seen.has(0) and weapons_seen.has(1), "Launch events report each shell's weapon")
	model = fresh(1, ["dual_plus"])
	model.use_item(0)
	model.fire(40.0, 70.0, 1)
	check(int(model.projectiles.back().weapon) == 0 and int(model.projectiles.back().volley) == 1, "Dual+ after S2 fires S1")

	# Thunder: every shell electric once; the weather column does not stack.
	model = fresh(1, ["thunder"])
	model.use_item(0)
	model.fire(40.0, 35.0, 1)
	var all_electric := true
	for shell in model.projectiles:
		all_electric = all_electric and shell.electric and "electricity" in shell.influenced
	check(all_electric and model.projectiles.size() == 2, "Thunder makes every shell electric")
	fly(model)
	check(events_of(model, "lightning").size() == events_of(model, "explosion").size() and events_of(model, "explosion").size() > 0, "Each electric explosion raises a lightning strike")

	# Teleport: one beacon, faster, no wind, ground only, no damage or crater.
	model = fresh(2, ["teleport"])
	model.weather.wind_force = 30
	model.weather.wind_angle = 0
	model.wind = model.weather.wind_vector()
	var normal: Array = model.projectile_parameters(Match.PLAYER, 30.0, 25.0, 1)
	model.use_item(0)
	var predicted: Dictionary = model.predict_shot(Match.PLAYER, 30.0, 25.0, 1)
	var origin: Vector2 = model.actors[Match.PLAYER].pos
	var cpu_hp := int(model.actors[Match.CPU].hp)
	model.fire(30.0, 25.0, 1)
	var beacon: Dictionary = model.projectiles[0]
	check(model.projectiles.size() == 1 and beacon.beacon and is_equal_approx(float(beacon.wind_scale), 0.0), "Teleport replaces the T2 salvo with one beacon without wind")
	check(is_equal_approx(Vector2(beacon.velocity).length(), Vector2(model.shot_velocity(Match.PLAYER, 30.0, 25.0, 1)).length() * 1.4) and normal.size() == 6, "Beacon speed is ×1.4 (mass 14 → 10)")
	var cells_before: int = model.terrain.cells.count(1)
	fly(model)
	var teleports: Array = events_of(model, "teleport")
	check(teleports.size() == 1 and events_of(model, "explosion").is_empty() and int(model.actors[Match.CPU].hp) == cpu_hp, "The beacon teleports without explosion or damage")
	check(model.terrain.cells.count(1) == cells_before, "The beacon leaves no crater")
	var landed: Vector2 = model.actors[Match.PLAYER].pos
	check(landed.distance_to(origin) > 40.0 and absf(landed.x - Vector2(teleports[0].position).x) < 8.0 and is_equal_approx(landed.y, model.terrain.surface_at(landed.x, landed.y) - model.stance_of(Match.PLAYER)), "The mobile stands on the ground where the beacon landed")
	check(not predicted.is_empty() and Vector2(predicted.position).distance_to(teleports[0].position) < 0.01, "Prediction follows the beacon to the same landing point")
	check(is_equal_approx(float(model.actors[Match.PLAYER].ready), (100.0 + 920.0) / 7.5), "Teleport turn costs 100/7.5 plus the selected shot delay")

	# Prediction with Dual equals the real flight (same shells, same craters).
	model = fresh(2, ["dual"])
	model.use_item(0)
	var dual_prediction: Dictionary = model.predict_shot(Match.PLAYER, 32.0, 72.0, 0)
	model.fire(32.0, 72.0, 0)
	fly(model)
	var matched := false
	for event in events_of(model, "explosion") + events_of(model, "miss"):
		matched = matched or Vector2(event.position).distance_to(dual_prediction.position) < 0.01
	check(matched and events_of(model, "explosion").size() + events_of(model, "miss").size() == 8, "Dual prediction lands on a real impact of the eight bombs")

	# Team Teleport in 1×1: no teammate, only the effect and the delay.
	model = fresh(2, ["team_teleport"])
	var before_pos: Vector2 = model.actors[Match.PLAYER].pos
	model.use_item(0)
	check(model.actors[Match.PLAYER].pos == before_pos and is_equal_approx(float(model.actors[Match.PLAYER].ready), 50.0 / 7.5), "Team Teleport without a teammate keeps the position and costs 6.67")

	# Items do not leak into the CPU plan (no new RNG draws; CPU never uses items).
	var a = fresh(2, Items.DEFAULT_LOADOUT, 81)
	var b = fresh(2, [], 81)
	a.pass_turn()
	b.pass_turn()
	check(a.choose_cpu_shot() == b.choose_cpu_shot(), "The loadout does not change the CPU plan")

	finish("ITEMS CHECKS")
