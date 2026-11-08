extends "res://tests/support/suite.gd"
## Knight (ID 15, client type 14), ADR-152: guide -> Ion -> children. Expected
## values come from the ASM constants of 0x47ca40 / 0x47c3f0 / 0x4305c0 / 0x47ab00.
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Combat = preload("res://scripts/combat.gd")
const Knight = preload("res://scripts/knight_effect.gd")
const Asate = preload("res://scripts/asate_effect.gd")

func fresh():
	var model = Match.new()
	model.start(15, 1, 42, "", "original")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	return model

## Runs the guide's impact at `target` and the Ion ticks until it emitted.
func children_of(model, weapon: int, target: Vector2) -> Array:
	model.projectiles.clear()
	model.battle_effects.clear()
	model.phase = Match.PHASE_FLIGHT
	model.shot_actor = 0
	model.shot_weapon = weapon
	var guide := {"flight": Knight.MODE, "weapon": weapon, "owner": 0, "volley": 0, "pos": target, "hit_pos": target, "velocity": Vector2(0, 50), "damage": 0}
	model.explode(target, -1, guide)
	for _tick in 40:
		model.advance_battle_effects()
		if not model.projectiles.is_empty():
			break
	return model.projectiles.duplicate()

func expected_child(angle: int, start: Vector2i, delay: int, child: Dictionary, label: String) -> void:
	check(Vector2i(child.fp_pos) == start * 256, "%s starts at %s (got %s)" % [label, start, Vector2i(child.fp_pos) / 256])
	check(Vector2i(child.fp_velocity) == Vector2i(int(Physics.s(angle + 90) * 6144.0), int(Physics.s(angle) * -6144.0)), "%s velocity (cos,-sin)*6144 (0x55809c/0x558098)" % label)
	check(Vector2i(child.fp_acceleration) == Vector2i(int(Physics.s(angle + 90) * 768.0), int(Physics.s(angle) * -768.0)), "%s acceleration (cos,-sin)*768, no gravity/wind" % label)
	check(int(child.knight_delay) == delay, "%s waits %d ticks (0x47ab00 [0x3f9c])" % [label, delay])

func test_guide_and_ion() -> void:
	var model = fresh()
	check(model.satellites.has(0) and str(model.satellites[0].kind) == "knight", "the Knight owns an Ion from the start (SpawnKnightIon 0x438100)")
	var owner: Vector2i = Vector2i(Vector2(model.actors[0].pos).floor())
	check(Vector2i(model.satellites[0].pos) == owner + Vector2i(0, -200), "Ion hovers 200 px over its owner")
	for weapon in 3:
		var shells: Array = model.shot_shells(0, 45, 60, weapon)
		check(shells.size() == 1 and str(shells[0].flight) == Knight.MODE, "weapon %d fires one guide (MainAction 0x47ab90)" % weapon)
	check(int(round(float(model.shot_shells(0, 45, 60, 1)[0].spawn_at) / Combat.STEP)) == 7, "S2 guide leaves on frame 7")

func test_fans() -> void:
	for weapon in [0, 1]:
		var model = fresh()
		var target := Vector2(900, 700)
		var ion: Vector2i = model.satellites[0].pos
		var children := children_of(model, weapon, target)
		var offsets: Array = [[0, 3], [4, 7], [-4, 7]] if weapon == 0 else [[0, 3], [2, 7], [-2, 7], [4, 11], [-4, 11]]
		check(children.size() == offsets.size(), "S%d: the Ion emits %d children" % [weapon + 1, offsets.size()])
		var delta := Vector2i(900, 700) - ion
		var radius := int(sqrt(float(delta.x * delta.x + delta.y * delta.y)))
		var theta := Asate.aim_angle(delta)
		for index in mini(children.size(), offsets.size()):
			var angle: int = theta + int(offsets[index][0])
			var start := Vector2i(900 + int(float(radius) * Physics.s(angle + 270)), 700 - int(float(radius) * Physics.s(angle + 180)))
			expected_child(angle, start, int(offsets[index][1]), children[index], "S%d child %d" % [weapon + 1, index])
			check(int(children[index].damage) == [136, 128][weapon], "S%d child carries the row power" % [weapon + 1])
		# The central child starts on the Ion itself: R back from the target along theta.
		# The central child starts by the Ion: R back from the target along theta,
		# whose 0x47bfd0 LUT reading carries about a degree of quantization.
		check(Vector2(Vector2i(children[0].fp_pos) / 256).distance_to(Vector2(ion)) <= 0.03 * radius, "S%d central child leaves from the Ion" % [weapon + 1])

func test_rain() -> void:
	var model = fresh()
	var target := Vector2(1000, 700)
	var owner: Vector2i = Vector2i(Vector2(model.actors[0].pos).floor())
	var children := children_of(model, 2, target)
	check(children.size() == 8, "SS: eight children in one frame (loop i<8)")
	var step := int(tan(0.06977777928113937) * 400.0)
	check(step == 27, "sweep step tan(0x558070) * 400 = 27")
	var x0 := 1000 - step / 2 - step
	var xs := [x0, x0 + step, x0 + 2 * step, x0 + 3 * step, x0 + 3 * step, x0 + 2 * step, x0 + step, x0]
	var angles := [276, 272, 268, 264, 264, 268, 272, 276]
	for index in mini(8, children.size()):
		expected_child(angles[index], Vector2i(xs[index], owner.y - 400), index * 2, children[index], "SS child %d" % index)

func test_children_wait_then_fly() -> void:
	var model = fresh()
	var children := children_of(model, 0, Vector2(900, 700))
	var first: Dictionary = model.projectiles[0]
	var start := Vector2(first.pos)
	model.advance_projectiles(Combat.STEP)
	model.advance_projectiles(Combat.STEP)
	check(Vector2(first.pos) == start, "a child holds still during its delay")
	model.advance_projectiles(Combat.STEP)
	check(Vector2(first.pos) != start, "and flies from tick %d on" % int(first.knight_delay))
	check(children.size() == 3, "fixture fired the S1 fan")

func test_live_and_prediction() -> void:
	var model = fresh()
	model.phase = Match.PHASE_AIM
	model.active = 0
	model.actors[0].ss_lock = 0
	var predicted: Dictionary = model.predict_shot(0, 60, 40, 0)
	check(model.fire(60, 40, 0), "S1 fires")
	var saw_children := 0
	for _step in 600:
		model.advance_projectiles(Combat.STEP)
		for shell in model.projectiles:
			if bool(shell.get("child", false)):
				saw_children = maxi(saw_children, model.projectiles.size())
		if model.phase != Match.PHASE_FLIGHT:
			break
	check(saw_children >= 3, "the live match carries the guide into three children")
	check(model.phase != Match.PHASE_FLIGHT, "the shot ends once the children and the Ion are done")
	check(not predicted.is_empty(), "prediction runs the guide and the Ion on its copy")
	check(not model.satellites.is_empty() and not bool(model.satellites[0].busy), "the Ion is back home and free")

func run() -> void:
	Physics.warmup()
	test_guide_and_ion()
	test_fans()
	test_rain()
	test_children_wait_then_fly()
	test_live_and_prediction()
	finish("KNIGHT SHOT CHECKS")
