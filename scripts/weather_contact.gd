extends RefCounted
## Shell × weather columns (Weather.CheckProjectileInteraction, Tornado.cs),
## moved out of Match (ADR-081). Match keeps the facade and the event queue;
## runs on the CPU snapshot as well, so it reads only the given model.

const Weather = preload("res://scripts/weather.gd")

## Entering a column's inner rectangle interacts once; leaving through the
## outer margin re-arms it.
static func apply(model, projectile: Dictionary) -> void:
	var point: Vector2 = projectile.pos
	for column in model.weather.columns.duplicate():
		var id := int(column.id)
		var inner: bool = model.weather.inside_inner(column, point)
		var inside: bool = projectile.inside.has(id)
		if inner and not inside:
			projectile.inside[id] = true
			interact(model, projectile, column)
		elif inside and not inner and column.type not in ["random", "tornado"] and model.weather.inside_outer(column, point):
			projectile.inside.erase(id)

static func interact(model, projectile: Dictionary, column: Dictionary) -> void:
	var type: String = column.type
	var first: bool = type not in projectile.influenced
	if first and type != "tornado" and type != "random":
		projectile.influenced.append(type)
	var damage := int(projectile.damage)
	match type:
		"force":
			if first and damage != 0:
				projectile.damage = int(damage * 1.2 + 10.0)
		"weakness":
			# Weakness.cs divides by the Force factors, not its own constants.
			if first and damage != 0:
				projectile.damage = int(damage / 1.2 - 10.0)
		"mirror":
			if first and damage != 0:
				projectile.damage = int(damage * 1.1 + 5.0)
			projectile.velocity = Vector2(-projectile.velocity.x, projectile.velocity.y)
		"electricity":
			if first:
				projectile.electric = true
		"tornado":
			if projectile.tornado.is_empty():
				var velocity: Vector2 = projectile.velocity
				projectile.tornado = {"column": int(column.id), "step": 1, "direction": velocity.normalized() if velocity != Vector2.ZERO else Vector2.DOWN, "speed": maxf(velocity.length(), Weather.TORNADO_MIN_SPEED)}
		"random":
			if not bool(column.used):
				column.used = true
				var spawned: Dictionary = model.weather.add_column(column.extra, float(column.x), 1.0)
				projectile.inside.erase(int(spawned.id))
	model.events.append({"type": "weather_hit", "weather": type, "position": projectile.pos, "extra": column.get("extra", "")})

## Tornado.cs: cross the column along the entry heading, back across mirrored,
## then out along the heading; afterwards relaunch at the initial speed.
static func tornado_step(model, projectile: Dictionary, delta: float) -> Dictionary:
	var state: Dictionary = projectile.tornado
	var column: Dictionary = model.weather.find_column(int(state.column))
	var direction: Vector2 = state.direction
	var travel: float = float(state.speed) * delta
	var position: Vector2 = projectile.pos
	var heading := direction
	if column.is_empty():
		state.step = 3
	match int(state.step):
		1:
			var next := position + direction * travel
			if model.weather.inside_inner(column, next):
				position = next
			else:
				state.step = 2
		2:
			heading = Vector2(-direction.x, direction.y)
			var next := position + heading * travel
			if model.weather.inside_inner(column, next):
				position = next
			else:
				state.step = 3
		_:
			position += direction * travel
			if column.is_empty() or not model.weather.inside_outer(column, position):
				projectile.tornado = {}
				projectile.inside.erase(int(state.column))
				return {"position": position, "velocity": direction * float(projectile.launch_speed)}
	return {"position": position, "velocity": heading * float(state.speed)}
