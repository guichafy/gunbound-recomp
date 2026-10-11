extends RefCounted
## Same integrator and swept collision are used by live shots and CPU aiming.

const GRAVITY := 260.0
const STEP := 1.0 / 120.0
const WEAPONS := [
	{"name": "Pulso", "damage": 145.0, "radius": 46.0, "delay": 100.0, "speed": 1.0, "count": 1, "color": Color("a2edf0")},
	{"name": "Impacto", "damage": 210.0, "radius": 62.0, "delay": 155.0, "speed": 0.93, "count": 1, "color": Color("ffc080")},
	{"name": "Tempestade", "damage": 105.0, "radius": 43.0, "delay": 210.0, "speed": 1.04, "count": 3, "color": Color("f2a8dd")}
]

static func advance(position: Vector2, velocity: Vector2, wind: float, delta: float) -> Dictionary:
	var acceleration := Vector2(wind * 1.5, GRAVITY)
	return {"position": position + velocity * delta + acceleration * delta * delta * 0.5, "velocity": velocity + acceleration * delta}

static func launch_velocity(angle: float, power: float, facing: int, weapon: int) -> Vector2:
	var speed := lerpf(180.0, 660.0, clampf(power, 15.0, 100.0) / 100.0) * float(WEAPONS[weapon].speed)
	var radians := deg_to_rad(clampf(angle, 10.0, 85.0))
	return Vector2(cos(radians) * facing, -sin(radians)) * speed

static func trace_segment(from: Vector2, to: Vector2, terrain, actors: Array, ignored: int) -> Dictionary:
	var terrain_hit: Dictionary = terrain.raycast(from, to)
	var closest := float(terrain_hit.fraction) if not terrain_hit.is_empty() else INF
	var hit: Dictionary = {"position": terrain_hit.position, "actor": -1} if not terrain_hit.is_empty() else {}
	var direction := to - from
	var length_squared := direction.length_squared()
	for index in range(actors.size()):
		if index == ignored or int(actors[index].hp) <= 0:
			continue
		var offset: Vector2 = from - Vector2(actors[index].pos)
		var c := offset.length_squared() - 24.0 * 24.0
		var fraction := INF
		if c <= 0.0:
			fraction = 0.0
		elif length_squared > 0.0:
			var b := 2.0 * offset.dot(direction)
			var discriminant := b * b - 4.0 * length_squared * c
			if discriminant >= 0.0:
				fraction = (-b - sqrt(discriminant)) / (2.0 * length_squared)
		if fraction >= 0.0 and fraction <= 1.0 and fraction < closest:
			closest = fraction
			hit = {"position": from + direction * fraction, "actor": index}
	return hit

static func ignored_shooter(age: float, shooter: int) -> int:
	return shooter if age < 0.15 else -1

static func damage_at(distance: float, damage: float, radius: float) -> int:
	if distance > radius + 22.0:
		return 0
	var effective := maxf(0.0, distance - 22.0)
	return maxi(0, int(round(damage * (1.0 - effective / radius))))

static func predict(origin: Vector2, velocity: Vector2, wind: float, terrain, actors: Array, ignored: int) -> Dictionary:
	var position := origin
	var speed := velocity
	var age := 0.0
	for i in range(1440):
		var next := advance(position, speed, wind, STEP)
		var hit := trace_segment(position, next.position, terrain, actors, ignored_shooter(age, ignored))
		if not hit.is_empty():
			return hit
		position = next.position
		speed = next.velocity
		age += STEP
		if position.x < -150.0 or position.x > 1430.0 or position.y > 820.0:
			return {"position": position, "actor": -1}
	return {"position": position, "actor": -1}
