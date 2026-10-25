extends RefCounted
## Boomer Bullet6/SS native state. Renderer consumes ss_state, never its own age.
const Physics = preload("res://scripts/classic_ballistics.gd")
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
			shell.blast_radius = float(Physics.quot(int(shell.boomer_diameter) * 120, 100)) * 0.5
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
	if not outside_column:
		return
	if int(shell.fp_velocity.y) > 0:
		shell.boomer_direction = 0
	if bool(shell.boomer_curve):
		shell.boomer_angle = int(shell.boomer_angle) + int(shell.boomer_direction)
		if (int(shell.boomer_direction) == 1 and int(shell.boomer_angle) >= 90) or (int(shell.boomer_direction) == -1 and int(shell.boomer_angle) <= 90):
			shell.boomer_direction = 0
			shell.fp_velocity.y = 0
	Physics.publish_motion(shell)
