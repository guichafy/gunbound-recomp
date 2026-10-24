extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
func launches(model) -> Array:
	var result: Array = []
	for event in model.events:
		if event.type == "projectile_launch":
			result.append(float(event.time))
	model.events.clear()
	return result
func fixture():
	var model = Match.new()
	model.start(2, 2, 51, "")
	model.terrain.cells.fill(0)
	model.actors[0].pos = Vector2(200, 350)
	model.actors[1].pos = Vector2(1100, 700)
	model.actors[0].turns = 3
	model.wind = Vector2.ZERO
	model.events.clear()
	return model
func _initialize() -> void:
	var model = fixture()
	for weapon in [0, 1, 2]:
		model = fixture()
		check(model.fire(30, 70, weapon), "Bigfoot accepts legal weapon " + str(weapon))
		check(model.projectiles.size() == [4, 6, 8][weapon], "Real shot builds original number of bombs " + str(weapon))
	if model.projectiles.is_empty() or not model.projectiles[0].has("spawn_at"):
		check(false, "Bomb schedule is available to the live flight")
		finish("BIGFOOT ATTACK CHECKS")
		return
	var times := [[0.0, 0.2, 0.4, 0.6], [0.2, 0.2, 0.2, 0.4, 0.4, 0.4], [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875]]
	for weapon in [0, 1, 2]:
		model = fixture()
		model.fire(30, 70, weapon)
		var actual: Array = launches(model)
		for frame in range(120):
			model.advance_projectiles(Combat.STEP)
			actual.append_array(launches(model))
		actual.sort()
		check(actual.size() == times[weapon].size(), "Every bomb launches once " + str(weapon))
		for index in range(mini(actual.size(), times[weapon].size())):
			check(absf(actual[index] - times[weapon][index]) < 0.0001, "Correct launch time for weapon/bomb " + str(weapon) + "/" + str(index))
		model = fixture()
		model.fire(30, 70, weapon)
		var origin: Vector2 = model.projectiles[0].pos
		var same := true
		for projectile in model.projectiles:
			same = same and Vector2(projectile.pos).is_equal_approx(origin)
		check(same, "All bombs use the same original muzzle " + str(weapon))
	# T1 angular pattern mirrors; T2 changes speed, never aim.
	for facing in [1, -1]:
		model = fixture()
		model.actors[0].facing = facing
		model.fire(40, 70, 0)
		for index in range(4):
			var speed: Vector2 = model.projectiles[index].velocity
			var degrees := rad_to_deg(atan2(-speed.y, speed.x * facing))
			check(absf(degrees - [43.0, 37.0, 40.0, 40.0][index]) < 0.01, "T1 spread is preserved at upper aim bound and facing " + str(facing))
	model = fixture()
	model.fire(30, 100, 1)
	check(model.projectiles[0].velocity.length() < model.projectiles[1].velocity.length() and model.projectiles[2].velocity.length() > model.projectiles[1].velocity.length(), "T2 force variants remain distinct at full power")
	check(Vector2(model.projectiles[0].velocity).normalized().is_equal_approx(Vector2(model.projectiles[2].velocity).normalized()), "T2 force variants share aim direction")
	model.advance_projectiles(0.1)
	var pending: Dictionary = model.projectiles[0]
	check(pending.age == 0 and pending.pos == pending.hit_pos and not pending.launched, "Pending T2 bombs cannot age, move or collide")
	model = fixture()
	model.fire(30, 70, 0)
	model.projectiles.remove_at(0)
	model.advance_projectiles(Combat.STEP)
	check(model.phase == "flight", "Removing first bomb cannot end a salvo with pending bombs")
	for weapon in [0, 1, 2]:
		model = fixture()
		model.shot_weapon = weapon
		model.shot_actor = 0
		model.explode(Combat.full_hit(model.actors[1], 25.0))
		check(model.actors[1].shield == [130, 150, 130][weapon] and model.actors[1].hp == 730, "Original per-bomb damage consumes Mage shield " + str(weapon))
	model = fixture()
	model.fire(85, 70, 0)
	check(model.last_shots[0].angle == 40, "Bigfoot T1 uses original max aim")
	model = fixture()
	model.fire(10, 70, 2)
	check(model.last_shots[0].angle == 23, "Bigfoot SS uses its original min aim")
	# Predict all pending launches, terrain changes and actor health on isolated copies.
	for weapon in [0, 1, 2]:
		model = fixture()
		model.actors[1].pos = Vector2(480, 170)
		for row in range(400):
			model.terrain.cells[row * 640 + 190] = 1
		var before: PackedByteArray = model.terrain.cells.duplicate()
		var state: Array = model.actors.duplicate(true)
		var rng_state: int = model.rng.state
		var predicted: Dictionary = model.predict_shot(0, 30, 70, weapon)
		check(before == model.terrain.cells and state == model.actors and model.rng.state == rng_state, "Prediction leaves live state untouched " + str(weapon))
		model.fire(30, 70, weapon)
		model.events.clear()
		var positions: Array[Vector2] = []
		var launched := 0
		for frame in range(1800):
			model.advance_projectiles(Combat.STEP)
			for event in model.events:
				if event.type in ["explosion", "miss"]:
					positions.append(event.position)
				elif event.type == "projectile_launch":
					launched += 1
			model.events.clear()
			if model.phase != "flight":
				break
		var closest := INF
		for position in positions:
			closest = minf(closest, position.distance_to(predicted.position))
		check(closest < 0.1 and positions.size() == [4, 6, 8][weapon], "Prediction matches live salvo through wall " + str(weapon))
		check(model.phase == "settle", "Entire salvo terminates flight " + str(weapon))
	finish("BIGFOOT ATTACK CHECKS")
