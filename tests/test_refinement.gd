extends SceneTree
## Requirements 14/15: launch geometry and initiative preview remain model-owned.

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	var model = Match.new()
	model.start(1, 1, 42)
	model.move_actor(-1.0, 0.1)
	check(model.actors[0].facing == -1, "Moving left turns the vehicle left")
	model.move_actor(1.0, 0.1)
	check(model.actors[0].facing == 1, "Moving right turns the vehicle right")
	check(model.has_method("body_rotation"), "Model exposes support rotation")
	check(model.has_method("shot_velocity"), "CPU and live shots share support-aware velocity")
	check(model.has_method("initiative_preview"), "Model owns initiative preview")
	if not model.has_method("body_rotation") or not model.has_method("shot_velocity") or not model.has_method("initiative_preview"):
		finish()
		return
	# A real custom mask with a known slope, not a mocked collision/rotation function.
	for slope in [-0.4, 0.4]:
		for y in range(model.terrain.HEIGHT):
			for x in range(model.terrain.WIDTH):
				model.terrain.cells[y * model.terrain.WIDTH + x] = 1 if y * 2 >= 420.0 + (x * 2 - 640.0) * slope else 0
		model.actors[0].pos = Vector2(640, model.terrain.surface_at(640) - model.stance_of(0))
		model.stamp_tilt()
		var rotation: float = model.body_rotation(0)
		check(absf(rotation - atan(slope)) < 0.06, "Support rotation follows measured slope " + str(slope))
		for facing in [-1, 1]:
			model.actors[0].facing = facing
			var velocity: Vector2 = model.shot_velocity(0, 45, 25, 0)
			var expected := Vector2(facing, -1).normalized().rotated(rotation)
			check(velocity.normalized().distance_to(expected) < 0.01, "World launch direction matches slope and facing")
			var pivot: Vector2 = model.actors[0].pos + Vector2(0, -14).rotated(rotation)
			check((model.muzzle(0, 45) - pivot).normalized().distance_to(expected) < 0.01, "Muzzle matches launch direction")
			var predicted: Dictionary = model.predict_shot(0, 45, 25, 0)
			model.phase = "aim"
			model.events.clear()
			model.fire(45, 25, 0)
			check(Vector2(model.projectiles[0].velocity).distance_to(velocity) < 0.001, "Live shell uses shared launch velocity")
			var observed := Vector2(INF, INF)
			for frame in range(1600):
				model.advance_projectiles(Combat.STEP)
				for event in model.events:
					if event.type == "explosion":
						observed = event.position
				if model.phase != "flight":
					break
			check(observed.distance_to(predicted.position) < 0.1, "Prediction equals live impact on slope")
	model.start(1, 1, 42)
	model.terrain.cells.fill(0)
	check(is_zero_approx(model.body_rotation(0)), "Missing support yields stable zero rotation")
	model.start(1, 1, 42)
	model.actors[0].ready = 100.0
	model.actors[1].ready = 215.0
	model.clock = 100.0
	var turns: int = model.total_turns
	var light: Array = model.initiative_preview(0)
	var heavy: Array = model.initiative_preview(1)
	check(light[0].actor == 0 and heavy[0].actor == 1, "Selected weapon changes predicted next actor")
	check(model.actors[0].ready == 100.0 and model.total_turns == turns, "Preview does not mutate initiative")
	var expected_actor: int = heavy[0].actor
	model.schedule(0, 120.0)
	check(model.active == expected_actor, "Preview agrees with actual scheduler")
	model.start(1, 1, 42)
	model.actors[1].ready = 100.0
	check(model.initiative_preview(0)[0].actor == 1, "Initiative ties favor the other actor")
	finish()

func finish() -> void:
	print("REFINEMENT MODEL CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
