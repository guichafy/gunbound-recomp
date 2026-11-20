extends "res://tests/support/suite.gd"

const Probe = preload("res://tests/tools/shot_damage_audit/probe.gd")
const Match = preload("res://scripts/match.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Lightning = preload("res://scripts/lightning_combat.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const FIXTURE = "res://tests/fixtures/shot_damage_native.json"

func run() -> void:
	var model = Probe.fixture(4, 2, 22)
	check_shells(model)
	var real := Probe.flight(model, 10.0, 25.0, 0, 50)
	var prediction := Probe.flight(model, 10.0, 25.0, 0, 50, true)
	check(real == prediction, "The Armor T1 replay has identical flight and damage in the prediction snapshot")
	check(real.done and real.launches == 1 and real.ticks == 3, "One Armor T1 closes its flight on tick 3")
	check(real.trace.size() == 2, "The baseline has one impact and one damage event")
	if real.trace.size() == 2:
		var impact: Array = real.trace[0]
		check(impact[0] == "explosion" and impact[3] == 1, "The projectile contacts Bigfoot")
		check(Vector2(impact[2][0], impact[2][1]).is_equal_approx(Vector2(237, 452)),
			"The sweep resolves the same integer contact as the pinned PE")
		check(real.trace[1][0] == "damage" and real.trace[1][2] == real.hp_lost and real.shield_lost == 0,
			"Reported damage matches HP lost without shield or overkill")
	check(real.hp_lost == 149, "The resolved contact applies 149 HP, as in the pinned PE")
	model.actors[1].pos.x = 250
	var actors: Array = model.actors.duplicate(true)
	var terrain: PackedByteArray = model.terrain.native_cells.duplicate()
	var probe: Dictionary = model.predict_shot(0, 10.0, 25.0, 0)
	check(probe.hit and int(probe.actor) == 1 and Vector2(probe.position).is_equal_approx(Vector2(237, 452)),
		"The public prediction returns the same Armor T1 contact")
	check(model.actors == actors and model.terrain.native_cells == terrain and model.events.is_empty(),
		"Public prediction leaves source actors, terrain and events intact")
	var fixture = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	check(fixture is Dictionary and fixture.get("schema") == 1, "PE fixture exists and has the expected schema")
	if fixture is Dictionary:
		check_fixture(model.actors[1], fixture)
	check_native_map()
	check_signed_damage()
	check_knight_contact()
	check_knight_weather()
	finish("SHOT DAMAGE REPLAY CHECKS")

func check_shells(model) -> void:
	for entry in [[-50, 60, 43], [0, 210, 68], [50, 360, 93]]:
		model.actors[0].attributes[Attributes.ATTACK] = entry[0]
		model.actors[0].attributes[Attributes.DIG] = entry[0]
		var shell: Dictionary = model.shot_shells(0, 10.0, 25.0, 0)[0]
		check(int(shell.damage) == entry[1], "Armor T1 initializes power with signed Attack %d" % entry[0])
		check(int(shell.blast_radius) == int(float(entry[2]) / 2.0),
			"Armor T1 initializes the integer radius with signed Dig %d" % entry[0])
	model.actors[0].attributes[Attributes.ATTACK] = 0
	model.actors[0].attributes[Attributes.DIG] = 0

func check_native_map() -> void:
	var model = Match.new()
	model.start(4, 1, 42, "miramo_town_a", "original", null, [], [], [], 0, 2)
	check(model.map_id == "miramo_town_a", "Miramo A native mask loads")
	var shooter_floor: float = model.terrain.surface_at(340, 0)
	var target_floor: float = model.terrain.surface_at(388, 0)
	check(shooter_floor == 1414.0 and target_floor == 1398.0, "Replay bodies are supported on the native map")
	model.actors[0].pos = Vector2(340, shooter_floor - model.stance_of(0))
	model.actors[1].pos = Vector2(388, target_floor - model.stance_of(1))
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.weather.queue = [{"type": "wind"}]
	var real := Probe.flight(model, 10.0, 25.0, 0, 188)
	var prediction := Probe.flight(model, 10.0, 25.0, 0, 188, true)
	check(real == prediction, "Miramo A actual and predicted hits agree")
	check(real.done and real.launches == 1 and real.hp_lost == 158 and real.shield_lost == 0,
		"Miramo A neutral impact delivers the pinned 158 HP")
	check(not real.trace.is_empty() and Vector2(real.trace[0][2][0], real.trace[0][2][1]) == Vector2(390, 1375),
		"Miramo A matches the controlled native contact point")

func check_signed_damage() -> void:
	var model = Probe.fixture(4, 2, 22)
	model.actors[0].attributes[Attributes.ATTACK] = 50
	model.actors[1].attributes[Attributes.DEFENSE] = -50
	model.weather.add_column("force", 240, 1.0)
	var boosted := Probe.flight(model, 10.0, 25.0, 0, 50)
	check(boosted.hp_lost == 392 and boosted == Probe.flight(model, 10.0, 25.0, 0, 50, true),
		"Attack +50, Defense -50 and the initial Force sample match the x86 result")
	model.actors[0].attributes[Attributes.ATTACK] = -50
	model.actors[1].attributes[Attributes.DEFENSE] = 50
	model.weather.columns.clear()
	var reduced := Probe.flight(model, 10.0, 25.0, 0, 50)
	check(reduced.hp_lost == 25 and reduced == Probe.flight(model, 10.0, 25.0, 0, 50, true),
		"Attack -50 and Defense +50 match the x86 result")

func check_knight_contact() -> void:
	var model = Probe.fixture(4, 15, 22)
	var real := Probe.flight(model, 10.0, 25.0, 0, 50)
	check(real == Probe.flight(model, 10.0, 25.0, 0, 50, true),
		"Knight contact and damage agree in fire and snapshot")
	check(real.trace.any(func(event): return event[0] == "explosion" and event[3] == 1),
		"Knight still registers as the physically contacted actor")
	check(real.hp_lost == 121 and real.shield_lost == 0,
		"Knight normal contact matches the x86 amount at the replay's body center")

func check_knight_weather() -> void:
	var model = Probe.fixture(4, 15, 22)
	model.actors[1].pos.x = 250
	model.actors[1].shield = 30
	model.actors[0].invulnerable = true
	model.weather.queue = [{"type": "thor"}]
	model.weather.thor.pos = Vector2(250, 100)
	model.fire(10.0, 25.0, 0)
	var shell: Dictionary = model.projectiles[0]
	shell.electric = true
	var hp := int(model.actors[1].hp)
	model.events.clear()
	model.explode(Vector2(Shared.center(model.actors[1])), 1, shell)
	Lightning.resolve(model)
	var phases: Array = []
	for event in model.events:
		if (event.type == "mobile_lightning" or event.type == "thor"
				or (event.type == "explosion" and int(event.vehicle) == 4)):
			phases.append(event.type)
	check(phases == ["mobile_lightning", "thor", "explosion"],
		"Electricity and Thor still trigger once before the Armor blast")
	check(int(model.actors[1].hp) < hp and int(model.actors[1].shield) == 0
		and int(model.weather.thor.xp) > 0 and int(model.shot_gold.enemy_damage) > 0,
		"A Knight with shield in normal combat can take weather and blast damage")

func check_fixture(body: Dictionary, fixture: Dictionary) -> void:
	var source: Dictionary = fixture.common_inputs
	var affected: Array = fixture.common_cases.duplicate()
	affected.append(fixture.contact.native_consumer)
	check(int(fixture.contact.native_consumer.amount) == 149, "Controlled PE contact and damage are pinned")
	check(int(fixture.armor_replay.amount) == 155, "PE damage at the truncated legacy point is pinned")
	for c in affected:
		var target := body.duplicate(true)
		target.hp = int(c.hp)
		target.shield = int(c.shield)
		var point := Shared.center(target) - Vector2i(int(c.dx), int(c.dy))
		var damage := {"power": int(source.power[0]), "dimension": int(source.dimension[0]),
			"aspect": int(source.aspect[0]), "flags": int(source.flags), "weather_bonus": int(c.force)}
		var total := Shared.apply([target], [], point, damage)
		check(total == int(c.amount) and int(target.hp) == int(c.hp_after)
			and int(target.shield) == int(c.shield_after), "PE isolated amount and application at %s/%s" % [c.dx, c.dy])
