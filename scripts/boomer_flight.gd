extends RefCounted
## Boomer Bullet6/SS native state. Renderer consumes ss_state, never its own age.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Items = preload("res://scripts/items.gd")

## 43c860/4542a0: fixed DAT angle75/length38, independent of aim. The
## 23px anchor converts the current Boomer visual support to tank6 hotspot;
## support-angle filtering remains the offline model's declared bridge.
static func muzzle(position: Vector2, facing: int, rotation: float) -> Vector2:
	var anchor := Vector2i(position + Vector2(0,23).rotated(rotation))
	var theta := (75 if facing > 0 else 105) - roundi(rad_to_deg(rotation))
	return Vector2(anchor + Vector2i(int(38.0 * Physics.s(theta + 90)), -int(38.0 * Physics.s(theta))))

## 45cf14: integer quotient and signed remainder, reset at the start of a fall.
static func fall_wind_step(remainder: int, force: int, angle: int) -> Vector2i:
	var horizontal := int(float(force) * Physics.s(angle + 90))
	var accumulated := remainder + 3 * horizontal
	var pixels := Physics.quot(accumulated, 100)
	return Vector2i(pixels, accumulated - pixels * 100)

static func active(shell: Dictionary) -> bool:
	return int(shell.get("vehicle", 0)) == 6 and not bool(shell.get("beacon", false))

# 41da80: Attack/Dig additions are divided by the emission count.
static func prepare(shell: Dictionary, actor: Dictionary) -> void:
	if not active(shell):
		return
	var weapon := int(shell.weapon)
	var count := 4 if weapon == 1 else 1
	var power: int = [254, 118, 350][weapon]
	var dimension: int = [48, 42, 46][weapon]
	shell.damage = power + Physics.quot(3 * Attributes.points(actor, Attributes.ATTACK), count)
	shell.boomer_diameter = dimension + Physics.quot(Physics.quot(Attributes.points(actor, Attributes.DIG), 2), count)
	shell.blast_radius = float(shell.boomer_diameter) * 0.5
	shell.boomer_crater_percent = 100 + int(Items.dig(str(actor.get("turn_item", ""))))

static func parameters(shell: Dictionary, actor: Dictionary) -> Dictionary:
	var weapon := int(shell.weapon)
	return {"power": int(shell.damage), "dimension": int(shell.boomer_diameter),
		"aspect": [124, 114, 120][weapon], "flags": 2,
		"weather_bonus": int(shell.get("native_force", 0)),
		"percent": 100 + int(Items.attack(str(actor.get("turn_item", ""))))}

static func seed(shell: Dictionary) -> void:
	var vx := int(shell.fp_velocity.x)
	var ax := int(shell.fp_acceleration.x)
	shell.boomer_curve = vx != 0 and not ((ax <= 0 and vx < 0) or (ax >= 0 and vx > 0))
	shell.boomer_initialized = false
	shell.boomer_angle = 0
	shell.boomer_direction = 0
	shell.ss_state = "normal"
	shell.ss_state_tick = 0
static func advance_state(shell: Dictionary) -> bool:
	shell.flight_ticks = int(shell.flight_ticks) + 1
	if bool(shell.get("boomer_ss", false)):
		var tick := int(shell.flight_ticks)
		if tick >= 36 and tick <= 45:
			shell.ss_state = "change"
			shell.ss_state_tick = tick - 36
			return false
		if tick == 46:
			shell.ss_state = "cnormal"
			shell.ss_state_tick = 0
			shell.damage = Physics.quot(int(shell.damage) * 200, 100)
			shell.boomer_diameter = Physics.quot(int(shell.boomer_diameter) * 120, 100)
			shell.blast_radius = float(shell.boomer_diameter) * 0.5
		else:
			shell.ss_state_tick = int(shell.ss_state_tick) + 1
	return true

static func begin_tick(shell: Dictionary, outside_column: bool = true, advance_clock: bool = true) -> bool:
	if advance_clock and not advance_state(shell):
		return false
	if not outside_column:
		return true
	if bool(shell.boomer_curve):
		if not bool(shell.boomer_initialized):
			shell.boomer_angle = Physics.velocity_angle(shell.fp_velocity)
			shell.boomer_direction = 1 if int(shell.boomer_angle) < 90 else -1
			shell.boomer_initialized = true
		if int(shell.boomer_direction) == 0:
			shell.boomer_angle = Physics.velocity_angle(shell.fp_velocity)
	else:
		shell.boomer_angle = 0
	var angle := int(shell.boomer_angle)
	var dx := Physics.quot(int(256 * 50 * Physics.s(angle + 180)), 100)
	var dy := -Physics.quot(int(256 * 50 * Physics.s(angle + 90)), 100)
	if dy > 0:
		dx = -dx
		dy = -dy
	shell.fp_velocity += Vector2i(dx, dy)
	Physics.publish_motion(shell)
	return true
static func finish_tick(shell: Dictionary, outside_column: bool = true) -> void:
	if outside_column and int(shell.fp_velocity.y) > 0:
		shell.boomer_direction = 0
	if bool(shell.boomer_curve):
		shell.boomer_angle = int(shell.boomer_angle) + int(shell.boomer_direction)
		if (int(shell.boomer_direction) == 1 and int(shell.boomer_angle) >= 90) or (int(shell.boomer_direction) == -1 and int(shell.boomer_angle) <= 90):
			shell.boomer_direction = 0
			shell.fp_velocity.y = 0
	Physics.publish_motion(shell)
