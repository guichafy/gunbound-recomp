extends "res://tests/support/suite.gd"
## Dragon (ID 14, client type 13), ADR-154: MainAction 0x46d070 emission, the
## SS children of 0x46ca60/0x4388e0 and the 0x46fb20 spark trail. Expected
## values are written from the ASM constants, not read back from the port.
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Combat = preload("res://scripts/combat.gd")
const ClassicFlight = preload("res://scripts/classic_flight.gd")
const ClassicSprite = preload("res://scripts/classic_sprite.gd")
const Sparks = preload("res://scripts/dragon_sparks.gd")
const SparkArt = preload("res://scripts/mage_spark_art.gd")

func fresh(facing: int = 1):
	var model = Match.new()
	model.start(14, 1, 42, "", "original")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.actors[0].facing = facing
	return model

## Native theta of a launch velocity: the LUT inverse used by the client.
func native_power_of(model, percent: float) -> int:
	return Physics.native_power(percent, Mobiles.force_max(14))

func test_emission() -> void:
	for facing in [1, -1]:
		var model = fresh(facing)
		var angle := 45.0
		var power := 60.0
		var theta := int(angle if facing > 0 else 180.0 - angle)
		var base := native_power_of(model, power)
		var s1: Array = model.shot_shells(0, angle, power, 0)
		check(s1.size() == 1 and Vector2i(s1[0].launch_velocity_fp) == Physics.launch_velocity_fp(theta, base + 10), "S1 facing %d: theta, P+10 (0x46d18b, [0xe9ba40]=10)" % facing)
		var s2: Array = model.shot_shells(0, angle, power, 1)
		var expected := [[1, 10], [1, -10], [-1, 10], [-1, -10]]
		check(s2.size() == 4, "S2 facing %d: four calls of 0x42bbb0" % facing)
		for index in mini(4, s2.size()):
			var pair: Array = expected[index]
			check(Vector2i(s2[index].launch_velocity_fp) == Physics.launch_velocity_fp(theta + int(pair[0]), base + int(pair[1])), "S2 facing %d shell %d: theta%+d, P%+d" % [facing, index, pair[0], pair[1]])
		var ticks: Array = []
		for shell in s2:
			ticks.append(int(round(float(shell.spawn_at) / Combat.STEP)))
		check(ticks == [1, 6, 11, 16], "S2 frames 1/6/11/16 of fire2 (jump table 0x46ddc8)")
		var ss: Array = model.shot_shells(0, angle, power, 2)
		check(ss.size() == 1 and Vector2i(ss[0].launch_velocity_fp) == Physics.launch_velocity_fp(theta, base + 10) and str(ss[0].flight) == ClassicFlight.DRAGON_SS, "SS facing %d: theta, P+10 through 0x42de70" % facing)
	# The offsets ride on the clamped aim (cells 0x4d90/0x7864): 60 is the top of the range.
	var top = fresh(1)
	var clamped: Array = top.shot_shells(0, 80.0, 50.0, 1)
	check(Vector2i(clamped[0].launch_velocity_fp) == Physics.launch_velocity_fp(61, native_power_of(top, 50.0) + 10), "S2 theta+1 is added after the 30..60 clamp")

func test_children() -> void:
	var model = fresh()
	var rules: Dictionary = model.weapon_rules(0, 2)
	check(int(rules.dragon_step) == 30 and int(rules.dragon_radius) == 200, "type-13 extras [81]=30 and [82]=200")
	var parent := {"owner": 0, "vehicle": 14, "volley": 0, "weapon": 2, "flight": ClassicFlight.DRAGON_SS}
	var impact := Vector2i(900, 600)
	var children: Array = ClassicFlight.dragon_children(parent, impact, rules)
	check(children.size() == 5, "0x46ca60 loop i<5")
	for index in children.size():
		var theta := 30 + 30 * index
		var child: Dictionary = children[index]
		var start := impact + Vector2i(int(Physics.s(theta + 90) * 200.0), int(-(Physics.s(theta) * 200.0)))
		check(Vector2i(child.fp_pos) == start * 256, "child %d starts on the 200 px half circle at %d degrees" % [index, theta])
		var heading := theta + 180
		check(Vector2i(child.fp_velocity) == Vector2i(int(Physics.s(heading + 90) * 2560.0), int(Physics.s(heading) * -2560.0)), "child %d flies inward at 2560 (0x55808c/0x558088)" % index)
		check(Vector2i(child.fp_acceleration) == Vector2i.ZERO, "child %d: acceleration cells 0xaf4/0xd18 are 0" % index)
		check(bool(child.child) and str(child.flight) == ClassicFlight.DRAGON_CHILD and int(child.weapon) == 2 and int(child.damage) == 160, "child %d keeps the SS row (160) and its own flight" % index)
	# 90 degrees: straight above, falling at 10 px per tick onto the impact.
	var middle: Dictionary = children[2]
	check(Vector2i(middle.fp_pos) == Vector2i(900, 400) * 256 and Vector2i(middle.fp_velocity) == Vector2i(0, 2560), "middle child: 200 px above, 10 px per tick down")

func test_children_in_the_match() -> void:
	var model = fresh()
	model.projectiles.clear()
	var parent := {"owner": 0, "vehicle": 14, "volley": 0, "weapon": 2, "flight": ClassicFlight.DRAGON_SS, "damage": 160, "pos": Vector2(1000, 300), "hit_pos": Vector2(1000, 300), "velocity": Vector2(0, 100)}
	model.phase = Match.PHASE_FLIGHT
	model.shot_actor = 0
	model.shot_weapon = 2
	ClassicFlight.burst(model, parent, Vector2(1000, 300), Vector2(0, 100))
	check(model.projectiles.size() == 5, "burst of the SS appends the five children")
	var middle: Dictionary = model.projectiles[2]
	var start := Vector2(middle.pos)
	for _tick in 5:
		model.advance_projectiles(Combat.STEP)
	var moved := Vector2(model.projectiles[2].pos) - start if model.projectiles.size() > 2 else Vector2.ZERO
	check(moved.is_equal_approx(Vector2(0, 50)), "a child moves 10 px per tick in a straight line (got %s)" % moved)

func test_sparks() -> void:
	# Sweep samples: x major, 8 px steps, as in 0x46fb20.
	var points: Array = Sparks.samples(Vector2i(100, 100), Vector2i(120, 104))
	check(points.size() == 3 and points[0] == Vector2i(100, 101) and points[1] == Vector2i(108, 103) and points[2] == Vector2i(116, 104), "x-major sweep samples every 8 px, y by slope (4<<16)/21 (got %s)" % [points])
	var vertical: Array = Sparks.samples(Vector2i(50, 50), Vector2i(50, 30))
	check(vertical.size() == 3 and vertical[0].y == 50 and vertical[1].y == 42 and vertical[2].y == 34, "y-major sweep walks up 8 px at a time")
	var sparks = Sparks.new()
	sparks.reset(7)
	sparks.accept({"type": "dragon_spark_sweep", "tick": 3, "key": "0:0", "from": Vector2i(0, 0), "to": Vector2i(40, 0)})
	check(not sparks.particles.is_empty(), "a sweep leaves sparks")
	var inside := true
	for spark in sparks.particles:
		var at: Vector2i = spark.position
		inside = inside and at.x >= -4 and at.x <= 40 and absi(at.y) <= 4
	check(inside, "sparks sit between the previous position and the samples, within ±4 px")
	check(Sparks.samples(Vector2i(0, 0), Vector2i(40, 0)).size() == 6 and int(sparks.counters["0:0"]) == 0, "the per-shell counter advances once per sample, mod 6 (six samples wrap to 0)")
	sparks.counters["0:0"] = 5
	sparks.accept({"type": "dragon_spark_sweep", "tick": 3, "key": "0:0", "first": true, "from": Vector2i(0, 0), "to": Vector2i(0, 0)})
	check(int(sparks.counters["0:0"]) == 1, "a new shell restarts its counter at 0 (one sample later: 1)")
	var count: int = sparks.particles.size()
	sparks.sync(3 + 15)
	check(sparks.particles.is_empty() and count > 0, "a spark lives 16 ticks (0x4711f0)")
	var quad: Dictionary = Sparks.quad({"position": Vector2i(10, 10), "angle": 0, "age": 6})
	var size := ((16 - 6) * 16) / 10
	var expected: Dictionary = SparkArt.native_quad(Vector2i(10, 10), 0, size, 3 * 0.125, Sparks.ROW, 255 - 96)
	check(quad.points == expected.points and quad.uv == expected.uv, "0x471240: size (16-age)*16/10, u (age/2)/8, row 0.615")
	check(is_equal_approx(float(quad.color.a), 159.0 / 255.0) and quad.blend == "add", "alpha 255-16*age, SRCALPHA/ONE")
	# Mage keeps its own quad after the shared helper.
	var mage: Dictionary = SparkArt.quad({"kind": "force", "tick": 4, "position": Vector2i(5, 5), "angle": 30})
	check(mage.points == SparkArt.native_quad(Vector2i(5, 5), 30, 24, 0.25, 0.25, 191).points, "Mage force quad unchanged: size 32-2*tick")

func test_model_publishes_sweeps() -> void:
	var model = fresh()
	model.phase = Match.PHASE_AIM
	model.active = 0
	model.actors[0].ss_lock = 0
	check(model.fire(45, 60, 0), "S1 fires")
	var sweeps := 0
	for _step in 120:
		model.advance_projectiles(Combat.STEP)
		for event in model.events:
			if event.type == "dragon_spark_sweep":
				sweeps += 1
		model.events.clear()
		if model.phase != Match.PHASE_FLIGHT:
			break
	check(sweeps > 3, "every S1 tick publishes its sweep (%d)" % sweeps)

func test_presentation() -> void:
	var sprite = ClassicSprite.new()
	sprite.setup("dragon")
	var info: Dictionary = sprite.sheet("SSChild.png")
	check(ClassicSprite.dragon_child_frame(info, 0.0) == 0 and ClassicSprite.dragon_child_frame(info, 17 * 0.05) == 17, "child plays bullet14c normal 0..17 once")
	check(ClassicSprite.dragon_child_frame(info, 18 * 0.05) == 18 and ClassicSprite.dragon_child_frame(info, (18 + 23) * 0.05) == 18, "then loops fly 18..40 (0x46c990 SetState fly)")
	check("dragon" in ClassicSprite.ADDITIVE_LIGHT_KINDS and "knight" in ClassicSprite.ADDITIVE_LIGHT_KINDS, "Dragon and Knight draw their light layers additively")
	check(not sprite.light_only("SSChild.png") and sprite.sheet("SSChildLight.png").entry == "bullet14cl.img", "child body bullet14c with light bullet14cl")
	var knight = ClassicSprite.new()
	knight.setup("knight")
	check(knight.light_only("Bullet1.png") and knight.light_only("Bullet2.png") and not knight.light_only("Bullet3.png"), "Knight guides are light only (bullet15nl/sl); SS has body bullet15p")

func run() -> void:
	Physics.warmup()
	test_emission()
	test_children()
	test_children_in_the_match()
	test_sparks()
	test_model_publishes_sweeps()
	test_presentation()
	finish("DRAGON SHOT CHECKS")
