extends RefCounted
## Slice charge and Drag aim. The scene forwards angle, power, weapon and charging.

const Match = preload("res://scripts/match.gd")

# TODO(Mouse Speed): scale DRAG_FULL_POWER by the popup's Mouse Speed slider.
const DRAG_FULL_POWER := 640.0
const DRAG_QUIVER := 2.0

var angle := 45.0
var power := 65.0
var weapon := 0
var charging := false:
	set(value):
		charging = value
		if not value:
			drag_aiming = false
var drag_aiming := false
var drag_origin_x := 0.0
var drag_advanced := false
var drag_quiver_timer := 0.0
var charge_timer := 0.0
var aim_direction := 0
var aim_elapsed := 0.0
var aim_limit := 0.15
var drag_rng := RandomNumberGenerator.new()

func begin_charge(host) -> void:
	if host.player_can_act() and not drag_aiming:
		charging = true
		power = 0.0
		charge_timer = 0.0

func release_charge(host) -> void:
	if charging and not drag_aiming:
		host.shoot()

func begin_drag(host, x: float) -> void:
	if host.player_can_act() and not charging:
		charging = true
		drag_aiming = true
		power = 0.0
		drag_origin_x = x
		drag_advanced = false
		drag_quiver_timer = 0.0

func update_drag(x: float, relative_x: float) -> void:
	power = clampf((x - drag_origin_x) / DRAG_FULL_POWER * 100.0, 0.0, 100.0)
	if relative_x > 0.0:
		drag_advanced = true

func release_drag(host) -> void:
	if not (charging and drag_aiming):
		return
	if power >= 1.0:
		host.shoot()
	charging = false

func tick(host, frame_delta: float) -> void:
	if charging and drag_aiming:
		drag_quiver_timer += frame_delta
		while drag_quiver_timer >= 0.04:
			drag_quiver_timer -= 0.04
			if not drag_advanced:
				power = clampf(power + drag_rng.randf_range(-DRAG_QUIVER, DRAG_QUIVER), 0.0, 100.0)
			drag_advanced = false
	elif charging:
		charge_timer += frame_delta
		while charge_timer > 0.04 and power < 100.0:
			charge_timer -= 0.04
			power = minf(100.0, power + 2.0)
		if power >= 100.0:
			host.shoot()

func update_keys(host, delta: float) -> void:
	var direction := 0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction = 1
	elif Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction = -1
	if direction != aim_direction:
		aim_direction = direction
		aim_elapsed = 0.0
		aim_limit = 0.15
		if direction != 0:
			step_angle(host, direction)
		return
	if direction == 0:
		return
	aim_elapsed += delta
	if aim_elapsed > aim_limit:
		aim_elapsed = 0.0
		aim_limit = maxf(aim_limit - 0.008, 0.03)
		step_angle(host, direction)

func step_angle(host, direction: int) -> void:
	var limits: Vector2 = host.model.aim_limits(Match.PLAYER, weapon)
	angle = clampf(roundf(angle) + direction, limits.x, limits.y)
