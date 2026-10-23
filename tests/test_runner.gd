extends "res://tests/support/suite.gd"

func _initialize() -> void:
	var paths := ["res://scripts/terrain.gd", "res://scripts/combat.gd", "res://scripts/match.gd"]
	for path in paths:
		check(ResourceLoader.exists(path), "Required gameplay model exists: " + path)
	if failures > 0:
		finish("CHECKS")
		return
	var terrain_script = load(paths[0])
	var combat = load(paths[1])
	var match_script = load(paths[2])
	var terrain = terrain_script.new()
	terrain.generate()
	check(terrain.is_solid(Vector2(640, 580)), "Terrain has solid ground below its surface")
	check(not terrain.is_solid(Vector2(640, 100)), "Sky is empty")
	terrain.carve(Vector2(640, 580), 32.0)
	check(not terrain.is_solid(Vector2(640, 580)), "Explosion removes crater center")
	check(terrain.is_solid(Vector2(680, 580)), "Explosion preserves ground beyond its radius")
	var step: Dictionary = combat.advance(Vector2.ZERO, Vector2(100, -100), Vector2.ZERO, 0.1)
	check(is_equal_approx(step.velocity.x, 100.0), "No wind preserves horizontal velocity")
	check(step.velocity.y > -100.0, "Gravity accelerates projectile downward")
	var windy: Dictionary = combat.advance(Vector2.ZERO, Vector2(100, -100), Vector2(20, 0), 0.1)
	check(windy.velocity.x > step.velocity.x, "Positive wind accelerates rightwards")
	var hit: Dictionary = combat.trace_segment(Vector2(640, 100), Vector2(640, 650), terrain, [], -1)
	check(not hit.is_empty(), "Swept collision catches ground across a long segment")
	check(hit.position.y < 580.0, "Swept collision stops at first surface")
	var thin_terrain = terrain_script.new()
	thin_terrain.generate()
	thin_terrain.cells.fill(0)
	thin_terrain.cells[100 * 640 + 100] = 1
	var corner: Dictionary = combat.trace_segment(Vector2(198.9, 201.3), Vector2(201.3, 198.9), thin_terrain, [], -1)
	check(not corner.is_empty(), "Collision catches a short intersection at a pixel corner")
	check(combat.damage_at(60.0, 160.0, 60.0) == 160, "Damage at the explosion radius equals the base")
	check(combat.damage_at(30.0, 160.0, 60.0) == 320, "Closer than the radius exceeds the base")
	var match_model = match_script.new()
	match_model.start(1, 1, 42)
	check(match_model.active == 0, "Player starts the match")
	check(match_model.phase == "aim", "Match starts in aiming phase")
	check(match_model.can_use_special(0), "SS is available on the first own turn")
	match_model.actors[0].ss_lock = 4
	check(not match_model.can_use_special(0), "SS stays locked after it is fired")
	match_model.actors[0].ready = 0.0
	match_model.actors[1].ready = 40.0
	match_model.schedule(0, 30.0)
	check(match_model.active == 0, "Fast shot can retain initiative when opponent delay is larger")
	match_model.schedule(0, 60.0)
	check(match_model.active == 1, "Heavier delay gives opponent the next turn")
	match_model.start(1, 1, 43)
	match_model.tick(31.0)
	check(match_model.active == 1, "Expired turn passes control to CPU")
	match_model.start(1, 1, 44)
	var previous_x: float = match_model.actors[0].pos.x
	match_model.move_actor(1.0, 0.2)
	check(match_model.actors[0].pos.x > previous_x, "Player movement changes position")
	check(match_model.movement_left < match_model.movement_budget(), "Movement spends the turn budget")
	match_model.start(1, 1, 45)
	match_model.fire(45.0, 65.0, 0)
	check(match_model.phase == "flight", "Fire enters projectile flight phase")
	var projectiles_before: int = match_model.projectiles.size()
	match_model.fire(45.0, 65.0, 0)
	check(match_model.projectiles.size() == projectiles_before, "Cannot fire again while a shot resolves")
	for i in range(1200):
		match_model.tick(1.0 / 60.0)
		if match_model.phase != "flight":
			break
	check(match_model.phase != "flight", "Projectile always resolves or exits bounds")
	match_model.start(1, 1, 46)
	var cpu_shot: Dictionary = match_model.choose_cpu_shot()
	check(cpu_shot.angle >= 10.0 and cpu_shot.angle <= 85.0, "CPU returns a legal angle")
	check(cpu_shot.power >= 15.0 and cpu_shot.power <= 100.0, "CPU returns legal power")
	match_model.start(1, 2, 123, "")
	# A real -30-degree support makes Mage's legal 50-degree aim steep enough
	# for wind to return the laser to its shooter after muzzle clearance.
	for y in range(400):
		for x in range(640):
			match_model.terrain.cells[y * 640 + x] = 1 if y * 2 >= 480.0 - (x * 2 - 235.0) * tan(PI / 6.0) else 0
	match_model.actors[0].pos.y = match_model.terrain.surface_at(235) - match_model.stance_of(0)
	match_model.actors[1].pos.y = match_model.terrain.surface_at(1045) - match_model.stance_of(1)
	match_model.stamp_tilt()
	match_model.wind = Vector2(-35, 0)
	var returning: Dictionary = match_model.predict_shot(0, 50.0, 15.0, 0)
	check(int(returning.actor) == 0, "Prediction includes firing actor after muzzle clearance")
	match_model.fire(50.0, 15.0, 0)
	for i in range(1600):
		match_model.tick(1.0 / 120.0)
		if match_model.phase != "flight":
			break
	var live_impact := Vector2.INF
	for event in match_model.events:
		if event.type == "explosion":
			live_impact = event.position
	check(Vector2(returning.position).distance_to(live_impact) < 2.0, "Prediction and live shot agree on returning-shell impact")
	match_model.start(1, 1, 47, "")
	var foot: Vector2 = match_model.actors[1].pos + Vector2(0, 24)
	match_model.terrain.carve(foot, 200.0)
	match_model.settle_actors()
	match_model.check_end()
	check(match_model.phase == "finished" and match_model.winner == 0, "Removing all support eliminates CPU by fall")
	match_model.start(1, 1, 48)
	match_model.actors[0].hp = 0
	match_model.actors[1].hp = 0
	match_model.check_end()
	check(match_model.winner == -1, "Simultaneous elimination produces a draw")
	check(ResourceLoader.exists("res://scripts/profile.gd"), "Profile persists player progress")
	if ResourceLoader.exists("res://scripts/profile.gd"):
		var profile_script = load("res://scripts/profile.gd")
		var profile_path := "res://.tools/test-profile.json"
		var file := FileAccess.open(profile_path, FileAccess.WRITE)
		file.store_string("broken json")
		file.close()
		var profile = profile_script.new(profile_path)
		profile.load_profile()
		check(profile.xp == 0, "Corrupt profile recovers with zero XP")
		profile.nickname = "Piloto Teste"
		profile.award("unique-match", true)
		var rewarded_xp: int = profile.xp
		profile.award("unique-match", true)
		check(profile.xp == rewarded_xp, "Repeating result cannot duplicate XP")
		check(profile.wins == 1, "A victory increments wins once")
		var loaded = profile_script.new(profile_path)
		loaded.load_profile()
		check(loaded.nickname == "Piloto Teste" and loaded.xp == rewarded_xp, "Saved nickname and XP survive reload")
		loaded.xp = 450
		check(loaded.level() == 3, "Level derives from accumulated XP")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(profile_path))
	finish("CHECKS")
