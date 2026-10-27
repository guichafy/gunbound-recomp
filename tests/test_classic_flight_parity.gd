extends "res://tests/support/suite.gd"
## REQ-05/06/08/45: placed ordnance shares flight time and keeps its owner.
const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const TurnTable = preload("res://scripts/turn_table.gd")
const Shell = preload("res://scripts/shell_state.gd")
const Mobiles = preload("res://scripts/mobiles.gd")

func fresh(vehicle: int = 7):
	var model = Match.new()
	model.start(vehicle, 1, 7, "")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	return model

func mine_at(model, point: Vector2, steps: int = 1) -> Dictionary:
	return {"pos": point, "owner": 1, "radius": 21.0, "damage": 400, "weapon": 2,
		"vehicle": 7, "crystal": false, "crawl": true, "dir": 1.0, "steps": steps, "debt": 0.0}

func count_events(model, kind: String) -> int:
	var count := 0
	for event in model.events:
		if str(event.type) == kind:
			count += 1
	return count

func test_owner_and_parity(delta: float) -> void:
	var model = fresh()
	var x := float(model.actors[0].pos.x) + 1.0
	var location := Vector2(x, model.terrain.surface_at(x, 0) - 5)
	model.actors[0].shield = 30
	model.mines = [mine_at(model, location, 9)]
	model.turn_time = 25.0
	model.actors[0].turn_item = "power_up"
	check(model.fire(35, 60, 1), "Raon fires while the other actor owns a mine")
	var cost := TurnTable.shot_cost(model, 0, 1, model.shot_elapsed)
	var sim = Snapshot.capture(model)
	Snapshot.arm(sim, 0, 1, model.projectiles.duplicate(true))
	# Compare the flight event suffix, including launches, damage and explosions.
	model.events.clear()
	for frame in 24:
		sim.advance_projectiles(delta)
		if frame == 0:
			check(model.mines.size() == 1 and int(model.actors[0].shield) == 30, "Advancing prediction cannot consume a live mine or shield")
		model.tick(delta)
	check(model.shot_actor == 0 and model.shot_weapon == 1 and model.shot_elapsed == 5,
		"Mine never replaces shot ownership, weapon or spent time at delta %s" % delta)
	check(str(model.actors[0].turn_item) == "power_up", "Foreign mine preserves the current shooter's item")
	check(is_equal_approx(TurnTable.shot_cost(model, 0, model.shot_weapon, model.shot_elapsed), cost), "Mine preserves the firing actor's delay")
	check(model.mines == sim.mines and model.mines.is_empty(), "Real flight and prediction advance the same mine steps at delta %s" % delta)
	check(model.events == sim.events, "Complete flight events match prediction at delta %s" % delta)
	check(model.actors == sim.actors and model.terrain.cells == sim.terrain.cells, "Actors, shield and terrain match prediction")
	check(int(model.actors[0].hp) < 1050 and int(model.actors[0].shield) == 0, "Parity includes the mine's real shield and HP damage")
	var attributed := false
	for event in model.events:
		if str(event.type) == "explosion" and int(event.weapon) == 2:
			attributed = int(event.get("actor", -1)) == 1
	check(attributed, "Mine explosion identifies its owner 1")
	# Both directions are deep copies, including the newly consumed mine debt.
	sim.actors[0].hp = 1
	sim.mines.append(mine_at(sim, location))
	sim.terrain.cells[0] = 1
	check(model.actors[0].hp != 1 and model.mines.is_empty() and model.terrain.cells[0] == 0, "Prediction keeps live actor, mine and terrain isolated")
	# Complete the shot: the original shooter alone pays its original delay.
	for step in 5000:
		if model.phase not in [Match.PHASE_FLIGHT, Match.PHASE_SETTLE]:
			break
		model.tick(Combat.STEP)
	check(is_equal_approx(float(model.actors[0].ready), cost) and is_zero_approx(float(model.actors[1].ready)), "Mine does not transfer the shot's scheduled delay")

func test_lethal_mine(phase: String) -> void:
	var model = fresh()
	model.phase = phase
	model.resolve_wait = 0.4
	model.actors[0].hp = 1
	model.actors[0].shield = 0
	model.mines = [mine_at(model, Vector2(model.actors[0].pos))]
	model.tick(Combat.STEP)
	check(model.phase == Match.PHASE_FINISHED and model.winner == 1, "Lethal mine ends the match during %s" % phase)
	for step in 120:
		model.tick(Combat.STEP)
	check(count_events(model, "finished") == 1, "Lethal mine emits exactly one result during %s" % phase)

func test_shell_rules() -> void:
	var rules := Mobiles.weapon(8, 1)
	var first := Shell.create(Vector2.ZERO, Vector2.RIGHT, 0.0, rules, 1, 0)
	var second := Shell.create(Vector2.ZERO, Vector2.RIGHT, 0.0, rules, 1, 1)
	check(float(first.get("blast_radius", -1)) == float(rules.radius), "Factory preserves the base blast radius")
	check(float(first.get("bolt_extra", -1)) == 35.0 and float(first.get("bolt_extra_radius", -1)) == 25.0, "Factory preserves Lightning extra shock")
	check(first.get("bolt_angles", []) == rules.bolt_angles, "Factory preserves all four Lightning diagonals")
	if first.has("bolt_angles"):
		first.bolt_angles[0] = 0.0
		check(second.bolt_angles == rules.bolt_angles, "Lightning arrays are private to each shell")
	var special := Shell.create(Vector2.ZERO, Vector2.RIGHT, 0.0, Mobiles.weapon(8, 2), 2, 0)
	check(float(special.get("bolt_reach", -1)) == 100.0, "Factory preserves Lightning SS reach")

func test_planted_radius(weapon: int) -> void:
	var model = fresh()
	check(model.fire(30, 40, weapon), "Raon shot %d fires before planting" % weapon)
	for step in 2500:
		if not model.mines.is_empty() or model.phase != Match.PHASE_FLIGHT:
			break
		model.advance_projectiles(Combat.STEP)
	check(not model.mines.is_empty(), "Raon shot %d plants a mine through actual flight" % weapon)
	if model.mines.is_empty():
		return
	var mine: Dictionary = model.mines[0].duplicate(true)
	check(float(mine.radius) == 21.0, "Raon shot %d plants its rule radius 21" % weapon)
	model.actors[0].pos = Vector2(100, 100)
	model.actors[1].pos = Vector2(mine.pos) - Vector2(Mobiles.body(model.actors[1]).offset)
	model.actors[1].shield = 30
	var hp := int(model.actors[1].hp)
	model.mines = [mine.duplicate(true)]
	load("res://scripts/classic_flight.gd")._detonate_mine(model, 0)
	check(int(model.actors[1].hp) < hp and int(model.actors[1].shield) == 0, "Planted Raon mine damages HP through shield inside its box")
	model.actors[1].hp = hp
	model.actors[1].shield = 30
	model.actors[1].pos += Vector2(100, 0)
	model.mines = [mine.duplicate(true)]
	load("res://scripts/classic_flight.gd")._detonate_mine(model, 0)
	check(int(model.actors[1].hp) == hp and int(model.actors[1].shield) == 30, "Planted Raon mine cannot hurt outside radius")

func test_lightning_diagonals() -> void:
	# Lightning native review supersedes the old four C# arms/35 shock.
	var model=fresh(8)
	model.terrain.cells.fill(0)
	model.terrain.native_cells.fill(0)
	var width:=int(model.terrain.world_size().x)
	for x in width:
		model.terrain.native_cells[400*width+x]=1
	model.actors[0].pos=Vector2(100,50)
	model.actors[1].pos=Vector2(900,50)
	model.shot_actor=0
	model.shot_weapon=1
	var shell: Dictionary=model.shot_shells(0,30,40,1)[0]
	model.explode(Vector2(640,400),-1,shell)
	var rays: Array=model.events.filter(func(event):return event.type=="mobile_lightning")
	check(rays.size()==2,"Native T2 creates two sky diagonals")
	check(rays[0].direction==1 and rays[1].direction==-1,"Native T2 preserves ordered opposing diagonals")
	check(bool(shell.skip_actors),"Native T2 never collides with mobiles during flight")

func test_children(vehicle: int, count: int) -> void:
	var model = fresh(vehicle)
	if vehicle == 12:
		# A clear, long flight exercises division rather than an early impact
		# or the random procedural spawn leaving the arena before tick44.
		model.terrain.cells.fill(0)
		model.actors[0].pos = Vector2(100,650)
		model.actors[1].pos = Vector2(1200,700)
	# Turtle needs enough flight time to finish44+10 native ticks before impact.
	check(model.fire(80 if vehicle == 12 else 35, 80 if vehicle == 12 else 25, 2), "Mobile %d fires SS through the common factory" % vehicle)
	var saw_children := false
	var complete_children := false
	for step in 6000:
		if model.phase != Match.PHASE_FLIGHT:
			break
		model.advance_projectiles(Combat.STEP)
		if not saw_children and model.projectiles.size() == count:
			saw_children = true
			complete_children = true
			for child in model.projectiles:
				complete_children = complete_children and child.has("skip_actors") and child.has("blast_radius") and child.has("bolt_angles")
				check(str(child.flight).is_empty() and int(child.weapon) == 2 and float(child.blast_radius) == (23.0 if vehicle == 12 else 27.0), "SS child preserves its weapon and explicit radius without recursively splitting")
	check(saw_children and complete_children, "Mobile %d emits %d complete factory children" % [vehicle, count])
	check(model.projectiles.is_empty() and model.phase == Match.PHASE_SETTLE, "Mobile %d children all finish normally" % vehicle)

func test_begin_turn_mine() -> void:
	var model = fresh()
	model.actors[0].hp = 1
	var mine := mine_at(model, Combat.box_center(model.actors[0]))
	mine.crawl = false
	model.mines = [mine]
	model.begin_turn()
	check(model.phase == Match.PHASE_FINISHED and count_events(model, "finished") == 1, "A dormant lethal mine at turn start ends the match once")

func test_beacon_crosses_mobile() -> void:
	var model = fresh()
	model.actors[0].turn_item = "teleport"
	check(model.fire(30, 40, 1), "Teleport fires instead of Raon's mine salvo")
	var shell: Dictionary = model.projectiles[0]
	shell.pos = Vector2(600, 200)
	shell.hit_pos = shell.pos
	shell.velocity = Vector2(240, 0)
	shell.age = 1.0
	shell.launched = true
	model.actors[1].pos = Vector2(620, 200) - Vector2(Mobiles.body(model.actors[1]).offset)
	var hp: int = model.actors[1].hp
	model.advance_projectiles(0.16)
	check(model.projectiles.size() == 1 and model.actors[1].hp == hp and count_events(model, "teleport") == 0,
		"Teleport beacon crosses the mobile box and keeps flying")

func run() -> void:
	for delta in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]:
		test_owner_and_parity(delta)
	test_lethal_mine(Match.PHASE_AIM)
	test_lethal_mine(Match.PHASE_SETTLE)
	test_shell_rules()
	test_planted_radius(1)
	test_planted_radius(2)
	test_lightning_diagonals()
	test_children(12, 6)
	test_children(14, 5)
	test_begin_turn_mine()
	test_beacon_crosses_mobile()
	finish("CLASSIC FLIGHT PARITY CHECKS")
