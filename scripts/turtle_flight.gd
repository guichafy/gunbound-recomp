extends RefCounted
## Turtle S2: Detonate0x4af7a0 + Animate0x4b1050. State uses native20Hz ticks;
## collision samples the old phase, render sections use post-acceleration V.
const Physics = preload("res://scripts/classic_ballistics.gd")
const MODE := "turtle_wave"
const AMPLITUDE_DIVISOR := 100
const HALF_WIDTH := 10

static func prepare(shell: Dictionary, phase: int) -> void:
	shell.wave_counter = 0
	shell.wave_phase = phase
	shell.wave_amplitude = 1000
	shell.wave_step = 5
	var velocity: Vector2i = shell.get("launch_velocity_fp",Physics.velocity_fp(shell.velocity))
	shell.water_sides = [section_side(velocity)]

static func offset_fp(velocity: Vector2i, phase: int, amplitude: int) -> Vector2i:
	var theta := Physics.velocity_angle(velocity)+90
	# x87 multiplies both float32 LUT entries before truncating, then shifts
	# the integer product and divides toward zero. Do not round the sine first.
	var dx := int(amplitude*Physics.s(phase)*Physics.s(theta+90))
	var dy := int(-amplitude*Physics.s(phase)*Physics.s(theta))
	return Vector2i(Physics.quot(dx << 8,AMPLITUDE_DIVISOR),Physics.quot(dy << 8,AMPLITUDE_DIVISOR))

static func hit_point(shell: Dictionary, carrier: Vector2) -> Vector2:
	return carrier+Vector2(offset_fp(shell.fp_velocity,int(shell.wave_phase),int(shell.wave_amplitude)))/Physics.SCALE

static func section_side(velocity: Vector2i) -> Vector2:
	var theta := Physics.velocity_angle(velocity)+90
	return Vector2(int(HALF_WIDTH*Physics.s(theta+90)),-int(HALF_WIDTH*Physics.s(theta)))

static func finish_tick(shell: Dictionary) -> void:
	# Called after acceleration, once the common flight loop records hit_pos.
	shell.water_sides.append(section_side(shell.fp_velocity))
	while shell.water_sides.size() > shell.trail.size():
		shell.water_sides.pop_front()
	shell.wave_phase = posmod(int(shell.wave_phase)+int(shell.wave_step),360)
	if int(shell.wave_counter) < 10:
		shell.wave_amplitude = int(shell.wave_amplitude)+200
		shell.wave_step = int(shell.wave_step)+4
	else:
		shell.wave_amplitude = maxi(0,int(shell.wave_amplitude)-20)
		shell.wave_step = maxi(0,int(shell.wave_step)-1)
	shell.wave_counter = int(shell.wave_counter)+1
