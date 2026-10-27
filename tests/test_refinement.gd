extends "res://tests/support/suite.gd"
## Requirements 14/15: launch geometry and initiative preview remain model-owned.

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")

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
		finish("REFINEMENT MODEL CHECKS")
		return
	# Literal FP vectors from the independent PE sine fixture: the mask below
	# measures support ±atan(14/36), yielding theta66/156 or23/113. Mage25%
	# quantizes P112; muzzle uses P450, whose truncated direction differs slightly.
	var reference := {
		-1: {-1:[Vector2i(-2611,-1152),Vector2i(-10521,-4684)],1:[Vector2i(1152,-2611),Vector2i(4684,-10521)]},
		1: {-1:[Vector2i(-1100,-2636),Vector2i(-4480,-10598)],1:[Vector2i(2636,-1100),Vector2i(10598,-4480)]},
	}
	# A real custom mask with a known slope, not a mocked collision/rotation function.
	for slope in [-0.4, 0.4]:
		for y in range(model.terrain.HEIGHT):
			for x in range(model.terrain.WIDTH):
				model.terrain.cells[y * model.terrain.WIDTH + x] = 1 if y * 2 >= 420.0 + (x * 2 - 640.0) * slope else 0
		model.terrain.map_id = ""
		model.terrain.native_cells = PackedByteArray()
		model.terrain.enable_native()
		model.actors[0].pos = Vector2(640, model.terrain.surface_at(640) - model.stance_of(0))
		model.stamp_tilt()
		var rotation: float = model.body_rotation(0)
		check(absf(rotation - atan(slope)) < 0.06, "Support rotation follows measured slope " + str(slope))
		for facing in [-1, 1]:
			model.actors[0].facing = facing
			var velocity: Vector2 = model.shot_velocity(0, 45, 25, 0)
			var row: Array = reference[int(signf(slope))][facing]
			var expected_velocity := Vector2(row[0]) / (256.0 * 0.05)
			var expected_muzzle := Vector2(row[1]).normalized()
			check(velocity.distance_to(expected_velocity) < 0.001, "Native FP launch matches literal slope/facing reference")
			var pivot: Vector2 = model.actors[0].pos + Vector2(0, -14).rotated(rotation)
			check((model.muzzle(0, 45) - pivot).distance_to(expected_muzzle * 38.0) < 0.001, "Muzzle matches launch direction")
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
	finish("REFINEMENT MODEL CHECKS")
