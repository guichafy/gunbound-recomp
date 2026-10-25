extends RefCounted
## Original 20 Hz integer ballistics (ADR-084). Pure state after warmup on main.
## Native LUT bytes/VA/hashes are recorded in assets/openbound/physics/source.json.
const STEP := 0.05
const SCALE := 256
static var sine: PackedFloat32Array
static var angles: PackedByteArray
static func warmup() -> void:
	if not sine.is_empty():
		return
	var bytes := FileAccess.get_file_as_bytes("res://assets/openbound/physics/native-sine-f32.bin")
	assert(bytes.size() == 1440)
	sine = bytes.to_float32_array()
	angles = FileAccess.get_file_as_bytes("res://assets/openbound/physics/native-angle-i16.bin")
	assert(angles.size() == 131072)
static func quot(n: int, d: int) -> int:
	return int(n / d)
static func s(angle: int) -> float:
	return sine[posmod(angle, 360)]
static func native_power(percent: float, force_max: int) -> int:
	return clampi(int(clampf(percent, 0.0, 100.0) * force_max / 10.0), 1, 10 * force_max)
static func power_percent(power: int, force_max: int) -> float:
	return float(power) * 10.0 / force_max
static func launch_velocity_fp(theta: int, power: int) -> Vector2i:
	return Vector2i(quot(int(s(theta + 90) * power) << 8, 10), -quot(int(s(theta) * power) << 8, 10))
static func acceleration_fp(gravity: int, wind_force: int, wind_angle: int) -> Vector2i:
	return Vector2i(quot(int(wind_force * s(wind_angle + 90)) << 8, 100), quot((gravity - int(wind_force * s(wind_angle))) << 8, 100))
static func seed(shell: Dictionary, position_fp: Vector2i, velocity_fp: Vector2i, acceleration: Vector2i) -> void:
	shell.fp_pos = position_fp
	shell.fp_velocity = velocity_fp
	shell.fp_acceleration = acceleration
	shell.fp_ready = true
	publish_motion(shell)
static func position_fp(position: Vector2) -> Vector2i:
	return Vector2i(int(position.x * SCALE), int(position.y * SCALE))
static func velocity_fp(velocity: Vector2) -> Vector2i:
	return Vector2i(int(velocity.x * SCALE * STEP), int(velocity.y * SCALE * STEP))
static func import_external_motion(shell: Dictionary, position: Vector2, velocity: Vector2) -> void:
	# Explicit C# bridge: truncate once at the external mutation, never every tick.
	shell.fp_pos = position_fp(position)
	shell.fp_velocity = velocity_fp(velocity)
	publish_motion(shell)
static func publish_motion(shell: Dictionary) -> void:
	shell.pos = Vector2(shell.fp_pos) / SCALE
	shell.velocity = Vector2(shell.fp_velocity) / (SCALE * STEP)
static func integer_position(shell: Dictionary) -> Vector2i:
	return Vector2i(int(shell.fp_pos.x) >> 8, int(shell.fp_pos.y) >> 8)
static func move(shell: Dictionary) -> void:
	shell.fp_pos += shell.fp_velocity
	publish_motion(shell)
static func finish_tick(shell: Dictionary, accelerate: bool = true) -> void:
	if accelerate:
		shell.fp_velocity += shell.fp_acceleration
	publish_motion(shell)
static func mirror_x(shell: Dictionary) -> void:
	if bool(shell.get("fp_ready", false)):
		shell.fp_velocity.x = -int(shell.fp_velocity.x)
		publish_motion(shell)
	else:
		shell.velocity.x = -float(shell.velocity.x)
static func outside(position: Vector2i, world: Vector2i) -> bool:
	var x := position.x >> 8
	var y := position.y >> 8
	return x < 0 or x >= world.x or y < -1000 or y >= world.y
static func velocity_angle(velocity: Vector2i) -> int:
	var x := quot(velocity.x, 100)
	var y := quot(velocity.y, 100)
	while x < -127 or x > 128 or y < -127 or y > 128:
		x = quot(x, 2)
		y = quot(y, 2)
	var raw := angles.decode_s16(2 * (x + 127 + 256 * (y + 127)))
	return 3 * quot(raw + 1, 3)
