extends SceneTree

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	var model = Match.new()
	model.start(2, 1, 42)
	check(model.VEHICLES[model.actors[1].vehicle].name == "Mage", "Bigfoot faces original Mage")
	check(model.has_method("weapon_rules"), "Actor-owned weapon rules replace generic enemy attacks")
	check(model.has_method("predict_shot"), "CPU predicts actual per-mobile shots")
	check(ResourceLoader.exists("res://scripts/mage_sprite.gd"), "Mage sprite renderer exists")
	if not model.has_method("weapon_rules") or not model.has_method("predict_shot"):
		finish()
		return
	check(model.actors[1].hp == 730 and model.actors[1].shield == 220, "Mage starts with characterdata life and shield (ADR-075)")
	# Bigfoot's actual 90-damage bomb exercises Mage shield absorption.
	model.start(2, 1, 42)
	# Real explosions exercise shield absorption, not a mocked damage handler.
	model.shot_actor = 0
	model.shot_weapon = 0
	var target: Vector2 = Combat.full_hit(model.actors[1], 25.0)
	model.explode(target)
	check(model.actors[1].hp == 730 and model.actors[1].shield == 130, "Shield absorbs an entire direct pulse")
	model.explode(target)
	model.explode(target)
	check(model.actors[1].shield == 0 and model.actors[1].hp == 680, "Damage overflow reaches health")
	model.active = 1
	model.begin_turn()
	check(model.actors[1].shield == 30, "Mage regenerates 30 shield on its own turn")
	model.actors[1].shield = 260
	model.begin_turn()
	check(model.actors[1].shield == 270, "Shield cap compensates missing health as in the fork")
	model.start(1, 1, 43)
	model.fire(80, 65, 1)
	check(model.last_shots[0].angle == 50.0, "Mage clamps aim to original 50 degree maximum")
	check(model.projectiles.size() == 2, "Second shot creates two helix components")
	model.advance_projectiles(0.05)
	check(Vector2(model.projectiles[0].hit_pos).distance_to(model.projectiles[1].hit_pos) > 1.0, "Opposite phases produce separate colliders")
	model.start(1, 1, 44)
	check(is_equal_approx(model.weapon_rules(0, 1).delay, 120.0), "Mage delay preserves normalized original ratio")
	model.actors[0].ready = 100
	model.actors[1].ready = 215
	model.clock = 100
	check(model.initiative_preview(0)[0].actor == 0 and model.initiative_preview(1)[0].actor == 1, "Preview uses selected Mage delay")
	model.start(1, 2, 45, "")
	model.terrain.cells.fill(0)
	model.actors[0].pos = Vector2(640, 300)
	model.actors[1].pos = Vector2(900, 126)
	model.wind = Vector2.ZERO
	for weapon in [0, 1, 2]:
		model.actors[0].turns = 3
		model.actors[0].special_used = false
		model.phase = "aim"
		var shield: int = model.actors[0].shield
		var revision: int = model.terrain.revision
		var predicted: Dictionary = model.predict_shot(0, 40, 55, weapon)
		check(predicted.get("hit", false), "Fixture exercises a real impact for weapon " + str(weapon))
		check(model.actors[0].shield == shield and model.terrain.revision == revision, "Prediction has no combat side effects")
		model.events.clear()
		model.fire(40, 55, weapon)
		var hits: Array[Vector2] = []
		for frame in range(1600):
			model.advance_projectiles(Combat.STEP)
			for event in model.events:
				if event.type == "explosion":
					hits.append(event.position)
			model.events.clear()
			if model.phase != "flight":
				break
		if predicted.get("hit", false):
			var closest := INF
			for point in hits:
				closest = minf(closest, point.distance_to(predicted.position))
			check(closest < 0.1, "Prediction matches live impact for Mage weapon " + str(weapon))
		else:
			check(model.phase == "settle", "Mage miss resolves and cannot hang flight")
	# A first crater must change the second laser's collision, exactly as in flight.
	model.start(1, 1, 49, "")
	model.terrain.cells.fill(0)
	model.actors[0].pos = Vector2(200, 350)
	model.actors[1].pos = Vector2(480, 153.4247)
	model.wind = Vector2.ZERO
	for row in range(400):
		model.terrain.cells[row * 640 + 190] = 1
	var before: PackedByteArray = model.terrain.cells.duplicate()
	var state: Array = model.actors.duplicate(true)
	var predicted_wall: Dictionary = model.predict_shot(0, 40, 70, 1)
	check(predicted_wall.actor == 1, "Second laser prediction passes through first crater and hits target")
	check(model.terrain.cells == before and model.actors == state, "Salvo prediction cannot change real mask, health or shield")
	model.fire(40, 70, 1)
	var wall_hits: Array[Vector2] = []
	for frame in range(1440):
		model.advance_projectiles(Combat.STEP)
		for event in model.events:
			if event.type == "explosion":
				wall_hits.append(event.position)
		model.events.clear()
		if model.phase != "flight":
			break
	check(wall_hits.size() == 2 and model.actors[1].hp < 1100, "Both components resolve, with second damaging target behind wall")
	var minimum := INF
	for point in wall_hits:
		minimum = minf(minimum, point.distance_to(predicted_wall.position))
	check(minimum < 0.1, "Predicted wall interaction matches live impact")
	model.start(1, 1, 46)
	model.actors[1].shield = 100
	model.actors[1].max_shield = 100
	model.shot_actor = 0
	model.shot_weapon = 2
	model.explode(model.actors[1].pos + Vector2(80, 0))
	check(model.actors[1].shield == 0 and model.actors[1].hp == 1100, "EMP drains nearby shield without inventing distant health damage")
	model.start(1, 2, 47)
	var shot: Dictionary = model.choose_cpu_shot()
	check(shot.angle >= 15.0 and shot.angle <= 50.0, "CPU respects Mage aim limits")
	if ResourceLoader.exists("res://scripts/mage_sprite.gd"):
		var atlas = load("res://scripts/mage_sprite.gd").new()
		check(atlas.texture.get_size() == Vector2(2180, 3150), "Original Mage atlas dimensions preserved")
		check(atlas.frame_index("moving", 0, 0, false) == 20, "Original Mage movement frames")
		check(atlas.frame_index("charging", 0, 2, false) == 391, "Original Mage special charge frames")
		check(atlas.frame_index("destroyed", 10, 0, false) == 203, "Mage death holds its last frame")
		for weapon in [0, 1, 2]:
			check(atlas.effect_frame(weapon, 100) < atlas.effect_capacity(weapon), "Effect indices stay inside actual texture")
	finish()

func finish() -> void:
	print("MAGE CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
