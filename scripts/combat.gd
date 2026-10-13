extends RefCounted
## Same integrator and swept collision are used by live shots and CPU aiming.

const Mobiles = preload("res://scripts/mobiles.gd")
const GRAVITY := 260.0
const STEP := 1.0 / 120.0

# Wind is the OpenBound vector (force units, screen angle); 35 ≈ 45 px/s².
const WIND_ACCELERATION := 1.3

static func advance(position: Vector2, velocity: Vector2, wind: Vector2, delta: float) -> Dictionary:
	var acceleration := Vector2(0.0, GRAVITY) + wind * WIND_ACCELERATION
	return {"position": position + velocity * delta + acceleration * delta * delta * 0.5, "velocity": velocity + acceleration * delta}

static func launch_velocity(angle: float, power: float, facing: int, rotation: float = 0.0, power_offset: float = 0.0) -> Vector2:
	var speed := lerpf(180.0, 660.0, (clampf(power, 15.0, 100.0) + power_offset) / 100.0)
	var radians := deg_to_rad(clampf(angle, 10.0, 85.0))
	return Vector2(cos(radians) * facing, -sin(radians)).rotated(rotation) * speed

static func trace_segment(from: Vector2, to: Vector2, terrain, actors: Array, ignored: int) -> Dictionary:
	var terrain_hit: Dictionary = terrain.raycast(from, to)
	var closest := float(terrain_hit.fraction) if not terrain_hit.is_empty() else INF
	var hit: Dictionary = {"position": terrain_hit.position, "actor": -1} if not terrain_hit.is_empty() else {}
	var direction := to - from
	for index in range(actors.size()):
		if index == ignored or int(actors[index].hp) <= 0:
			continue
		var fraction := segment_box(from, to, actors[index])
		if fraction < closest:
			closest = fraction
			hit = {"position": from + direction * fraction, "actor": index}
	return hit

static func box_center(actor: Dictionary) -> Vector2:
	var spec: Dictionary = Mobiles.body(actor)
	return Vector2(actor.pos) + Vector2(spec.offset).rotated(float(actor.get("tilt", 0.0)))

## Distance from a point to the oriented rectangle. Zero means the point is inside.
static func box_gap(point: Vector2, actor: Dictionary) -> float:
	var spec: Dictionary = Mobiles.body(actor)
	var local: Vector2 = (point - box_center(actor)).rotated(-float(actor.get("tilt", 0.0)))
	var half: Vector2 = Vector2(spec.box) * 0.5
	return Vector2(maxf(absf(local.x) - half.x, 0.0), maxf(absf(local.y) - half.y, 0.0)).length()

## A point whose center distance equals the radius, so the inverse law returns the base damage.
static func full_hit(actor: Dictionary, radius: float) -> Vector2:
	return box_center(actor) + Vector2(radius, 0.0)

## Projectile.CalculateDamage: base * radius / center distance, floored at 1 px.
static func blast_damage(center_distance: float, base_damage: float, radius: float) -> int:
	return int(base_damage * radius / maxf(center_distance, 1.0))

static func damage_at(distance: float, damage: float, radius: float) -> int:
	return blast_damage(distance, damage, radius)

static func segment_box(from: Vector2, to: Vector2, actor: Dictionary) -> float:
	var spec: Dictionary = Mobiles.body(actor)
	var half: Vector2 = Vector2(spec.box) * 0.5
	var tilt := float(actor.get("tilt", 0.0))
	var center := box_center(actor)
	var start: Vector2 = (from - center).rotated(-tilt)
	var finish: Vector2 = (to - center).rotated(-tilt)
	var delta := finish - start
	var tmin := 0.0
	var tmax := 1.0
	for axis in 2:
		var origin := start.x if axis == 0 else start.y
		var step := delta.x if axis == 0 else delta.y
		var extent := half.x if axis == 0 else half.y
		if absf(step) <= 0.0000001:
			if origin < -extent or origin > extent:
				return INF
			continue
		var inverse := 1.0 / step
		var near := (-extent - origin) * inverse
		var far := (extent - origin) * inverse
		if near > far:
			var swap := near
			near = far
			far = swap
		tmin = maxf(tmin, near)
		tmax = minf(tmax, far)
		if tmin > tmax:
			return INF
	if tmax < 0.0 or tmin > 1.0:
		return INF
	return clampf(tmin, 0.0, 1.0)

static func out_of_bounds(position: Vector2, terrain) -> bool:
	# Shells may fly above the world; they leave by the sides or below it.
	var size: Vector2 = terrain.world_size()
	return position.x < -150.0 or position.x > size.x + 150.0 or position.y > size.y + 20.0

static func ignored_shooter(age: float, shooter: int) -> int:
	return shooter if age < 0.15 else -1

static func sample_position(position: Vector2, velocity: Vector2, age: float, amplitude: float = 0.0, phase: float = 0.0) -> Vector2:
	return position + Vector2(-velocity.y, velocity.x).normalized() * amplitude * sin(age * TAU + phase)

static func predict(origin: Vector2, velocity: Vector2, wind: Vector2, terrain, actors: Array, ignored: int, amplitude: float = 0.0, phase: float = 0.0) -> Dictionary:
	var position := origin
	var speed := velocity
	var age := 0.0
	var actual := origin
	for i in range(1440):
		var next := advance(position, speed, wind, STEP)
		var next_actual := sample_position(next.position, next.velocity, age + STEP, amplitude, phase)
		var hit := trace_segment(actual, next_actual, terrain, actors, ignored_shooter(age, ignored))
		if not hit.is_empty():
			hit["hit"] = true
			return hit
		actual = next_actual
		position = next.position
		speed = next.velocity
		age += STEP
		if out_of_bounds(position, terrain):
			return {"position": position, "actor": -1, "hit": false}
	return {"position": position, "actor": -1, "hit": false}
