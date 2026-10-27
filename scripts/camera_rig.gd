extends RefCounted
## Follows the active mobile, the shell, then the impact. The scene owns panning.

const Layout = preload("res://scripts/battle_hud_layout.gd")
const VIEW_SIZE := Layout.WORLD.size
const DAMPENING := 25.0

var position := Vector2.ZERO
var manual := false
var last_impact := Vector2.INF

func limits(terrain) -> Rect2:
	if terrain == null:
		return Rect2()
	var world: Vector2 = terrain.world_size()
	if world.x <= 1280.0 and world.y <= 800.0:
		return Rect2()
	var low := Vector2(minf(0.0, (world.x - VIEW_SIZE.x) * 0.5), 0.0)
	var high := Vector2(maxf(0.0, world.x - VIEW_SIZE.x), maxf(0.0, world.y - VIEW_SIZE.y))
	if world.x < VIEW_SIZE.x:
		high.x = low.x
	return Rect2(low, high - low)

func fit(terrain, value: Vector2) -> Vector2:
	var box := limits(terrain)
	return Vector2(clampf(value.x, box.position.x, box.end.x), clampf(value.y, box.position.y, box.end.y))

func goal(model) -> Vector2:
	var focus: Vector2 = model.actors[model.active].pos + Vector2(0, -60) if not model.actors.is_empty() else Vector2.ZERO
	if model.phase == model.PHASE_FLIGHT:
		for projectile in model.projectiles:
			if bool(projectile.launched):
				focus = projectile.pos
				break
	elif model.phase in [model.PHASE_SETTLE, model.PHASE_FINISHED] and last_impact != Vector2.INF:
		focus = last_impact
	return focus - VIEW_SIZE * 0.5

func update(delta: float, model) -> void:
	var terrain = model.terrain if model != null else null
	if not manual:
		var follow := 1.0 - pow(1.0 - 1.0 / DAMPENING, delta * 60.0)
		position = position.lerp(fit(terrain, goal(model)), follow)
	position = fit(terrain, position)
