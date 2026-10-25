extends RefCounted
## Mage native 20Hz section/history and S2 wave. PE47ebc0/4a4950/4a6200.
## Only the carrier advances ballistically; the wave never accumulates in it.
const Physics = preload("res://scripts/classic_ballistics.gd")
const LASER := "mage_laser"
const WAVE := "mage_wave"
const HALF_WIDTH := 8

static func active(shell: Dictionary) -> bool:
	return str(shell.get("flight","")) in [LASER,WAVE]

static func prepare(shell: Dictionary, phase: int) -> void:
	shell.mage_phase = posmod(phase,360)
	shell.mage_component = 1 if shell.mage_phase == 180 else 0
	var velocity: Vector2i = shell.get("launch_velocity_fp",Physics.velocity_fp(shell.velocity))
	shell.laser_sides = [section_side(velocity)]

static func wave_offset(velocity: Vector2i, phase: int) -> Vector2:
	var theta := Physics.velocity_angle(velocity)+90
	# Native x87 truncates each complete 13*sin(phase)*LUT product to pixels,
	# then shifts by8. Preserve pixel truncation, including negative values.
	return Vector2(int(13.0*Physics.s(phase)*Physics.s(theta+90)),int(-13.0*Physics.s(phase)*Physics.s(theta)))

static func hit_point(shell: Dictionary, carrier: Vector2) -> Vector2:
	if str(shell.flight) == WAVE:
		return carrier+wave_offset(shell.fp_velocity,int(shell.mage_phase))
	return carrier

static func section_side(velocity: Vector2i) -> Vector2:
	var theta := Physics.velocity_angle(velocity)+90
	return Vector2(int(HALF_WIDTH*Physics.s(theta+90)),-int(HALF_WIDTH*Physics.s(theta)))

static func finish_tick(shell: Dictionary) -> void:
	shell.laser_sides.append(section_side(shell.fp_velocity))
	while shell.laser_sides.size() > mini(16,shell.trail.size()):
		shell.laser_sides.pop_front()
	if str(shell.flight) == WAVE:
		shell.mage_phase = posmod(int(shell.mage_phase)+40,360)
