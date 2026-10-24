extends RefCounted
## CPU aim in three steps (REQ-32/ADR-053), moved out of Match (ADR-081):
## begin draws the weapon and snapshots mask, actors, wind and weather; search
## scores the grid only on that snapshot (no RNG, no live state, so it may run
## on a worker thread); finish draws the aim errors. Same RNG order as before.
## While the search runs the match freezes the CPU turn clock (ADR-076).

const FlightSnapshot = preload("res://scripts/flight_snapshot.gd")
const Combat = preload("res://scripts/combat.gd")
const TurnTable = preload("res://scripts/turn_table.gd")
# Aim error by difficulty (Leve, Normal, Precisa): degrees and power points.
const ANGLE_ERROR := [5.0, 2.5, 0.7]
const POWER_ERROR := [10.0, 4.0, 1.0]
# Chances of picking S2, then the SS when it is available.
const S2_CHANCE := 0.35
const SS_CHANCE := 0.45

static func begin(model) -> Dictionary:
	var index: int = model.active
	var actor: Dictionary = model.actors[index]
	var target: Dictionary = model.actors[TurnTable.other(index)]
	actor.facing = 1 if target.pos.x > actor.pos.x else -1
	var weapon := 1 if model.rng.randf() < S2_CHANCE else 0
	if model.can_use_special(index) and model.rng.randf() < SS_CHANCE:
		weapon = 2
	var snapshot = FlightSnapshot.capture(model)
	snapshot.active = index
	model.cpu_thinking = true
	return {"actor": index, "weapon": weapon, "limits": model.aim_limits(index, weapon), "snapshot": snapshot,
		"target": target.pos, "best": {"angle": 45.0, "power": 65.0, "weapon": weapon}}

static func search(plan: Dictionary) -> void:
	var limits: Vector2 = plan.limits
	plan.best_score = INF
	for angle in range(int(maxf(15, limits.x)), int(minf(80, limits.y)) + 1, 5):
		for power in range(20, 101, 4):
			score(plan, angle, power)
	# Refine around the best cell: range grows with force² under the C# ballistics
	# (ADR-076), so a 4-point power step alone lands about 100 px apart.
	var coarse: Dictionary = plan.best
	for angle in range(int(coarse.angle) - 4, int(coarse.angle) + 5, 2):
		for power in range(int(coarse.power) - 3, int(coarse.power) + 4):
			if angle >= limits.x and angle <= limits.y and power >= Combat.MIN_POWER and power <= Combat.MAX_POWER:
				score(plan, angle, power)

## Predicts one grid cell on the plan snapshot and keeps it if it lands closer.
static func score(plan: Dictionary, angle: int, power: int) -> void:
	var index: int = plan.actor
	var impact: Dictionary = plan.snapshot.predict_shot(index, angle, power, plan.weapon)
	var distance := Vector2(impact.position).distance_to(plan.target)
	if int(impact.actor) == TurnTable.other(index):
		distance -= 20.0
	elif int(impact.actor) == index:
		distance += 500.0
	if distance < float(plan.best_score):
		plan.best_score = distance
		plan.best = {"angle": float(angle), "power": float(power), "weapon": plan.weapon}

static func finish(model, plan: Dictionary) -> Dictionary:
	var best: Dictionary = plan.best
	var limits: Vector2 = plan.limits
	var angle_error: float = ANGLE_ERROR[model.difficulty]
	var power_error: float = POWER_ERROR[model.difficulty]
	best.angle = clampf(float(best.angle) + model.rng.randf_range(-angle_error, angle_error), limits.x, limits.y)
	best.power = clampf(float(best.power) + model.rng.randf_range(-power_error, power_error), Combat.MIN_POWER, Combat.MAX_POWER)
	plan.snapshot = null
	model.cpu_thinking = false
	return best
