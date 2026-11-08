extends RefCounted
## Shell × weather columns (Weather.CheckProjectileInteraction),
## moved out of Match (ADR-081). Match keeps the facade and the event queue;
## runs on the CPU snapshot as well, so it reads only the given model.

const Physics = preload("res://scripts/classic_ballistics.gd")
const NativeWeather = preload("res://scripts/aduka_weather.gd")

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
	# These three hazards belong to a later C# ruleset, absent from this PE.
	if int(projectile.get("vehicle",0))==1 and type in ["weakness","mirror","random"]:
		return
	# Mage/Aduka sample these at native physical contact points.
	if NativeWeather.active(projectile) and type in ["force","tornado","electricity"]:
		return
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
			Physics.mirror_x(projectile)
		"electricity":
			if first:
				projectile.electric = true
		"tornado":
			# ADR-156: every shell takes the client's tornado branch (451030 in the
			# sweep, then AdukaWeather.finish): velocity kept, |vx| >= 200, X turned on
			# each border crossing up to three, no gravity or wind while inside. The
			# C# relaunch at the launch speed (tornado_step) is no longer used.
			if projectile.tornado.is_empty():
				var span := NativeWeather.geometry(column)
				projectile.tornado = {"native": true, "column": int(column.id), "turns": 0, "center": span.x, "half": span.y}
		"random":
			if not bool(column.used):
				column.used = true
				var spawned: Dictionary = model.weather.add_column(column.extra, float(column.x), 1.0)
				projectile.inside.erase(int(spawned.id))
	model.events.append({"type": "weather_hit", "weather": type, "position": projectile.pos, "extra": column.get("extra", "")})
