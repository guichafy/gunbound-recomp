extends RefCounted
## Grub (type 12) T2 and SS flight: Shot2_Bullet13 / SuperShot_Bullet13 ricochet.
## Per-tick state machine of GunBound.gme 0x49fd40 (T2) and 0x486ea0 (SS) with the
## sweeps 0x49e650 / 0x4857f0 and the refinements 0x458920 / 0x458a00; ADR-142 and
## docs/sdd/GRUB_CLIENT_FIX.md hold the VA, matrix and the independent PE fixtures.
## Everything here is integer 24.8 fixed point, Y grows downward, and the state
## lives in the shell Dictionary so the CPU prediction copies it with the shell.

const Physics = preload("res://scripts/classic_ballistics.gd")
const Surface = preload("res://scripts/grub_surface.gd")

const T2 := 1
const SS := 2
## T2 forces its detonation at counter 44; the SS at 2 x cell 0xe55ab8 (20).
const LIMITS := {T2: 44, SS: 40}
## Constant speed (24.8 units per tick) after every ricochet: characterdata [69]/[82].
const SPEEDS := {T2: 1800, SS: 1600}
const SWEEP_STRIDE := 8

## Seeds the native flight on a shell whose fp_pos / fp_velocity / fp_acceleration
## were already seeded by Physics.seed.
static func begin(shell: Dictionary, kind: int) -> void:
	shell.g_kind = kind
	shell.g_ctr = -1
	shell.g_int = Vector2i(shell.fp_pos.x >> 8, shell.fp_pos.y >> 8)
	shell.g_speed = int(SPEEDS[kind])
	shell.g_limit = int(LIMITS[kind])

static func active(shell: Dictionary) -> bool:
	return shell.has("g_kind")

## Flight mode names of the catalog (classic_mobiles.gd) -> native kind.
static func kind_of(shell: Dictionary) -> int:
	return {"grub_t2": T2, "grub_ss": SS}.get(str(shell.get("flight", "")), 0)

## One native tick. `cells` is the 1 px solid mask (w x h). `hit_mobile` is called
## as hit_mobile.call(x, y) -> bool for T2 only. Returns
## {"event": "", "explode" or "oob", "position": Vector2i, "mobile": bool, "ricochet": bool}.
static func tick(shell: Dictionary, cells: PackedByteArray, w: int, h: int, hit_mobile: Callable) -> Dictionary:
	var kind := int(shell.g_kind)
	var limit := int(shell.g_limit)
	var pos: Vector2i = shell.fp_pos
	var velocity: Vector2i = shell.fp_velocity
	var inside: Vector2i = shell.g_int
	pos += velocity
	var terrain_hit := false
	var mobile_hit := false
	var contact := _sweep(cells, w, h, Vector2i((pos - velocity).x >> 8, (pos - velocity).y >> 8), Vector2i(pos.x >> 8, pos.y >> 8), hit_mobile, kind == T2)
	if not contact.is_empty():
		inside = Vector2i(contact.x, contact.y)
		pos = Vector2i(inside.x << 8, inside.y << 8)
		mobile_hit = bool(contact.mobile)
		terrain_hit = not mobile_hit
	var counter := int(shell.g_ctr)
	var ricochet := false
	if terrain_hit or mobile_hit or counter == limit:
		if counter >= limit or mobile_hit:
			shell.fp_pos = pos
			shell.g_int = inside
			return {"event": "explode", "position": inside, "mobile": mobile_hit, "ricochet": false}
		ricochet = true
		var snapped := _snap(cells, w, h, inside, pos)
		inside = snapped.inside
		pos = snapped.pos
		if counter == -1:
			counter = 0
		var surface := Surface.angle_at(cells, w, h, inside.x, inside.y)
		# 0x49fd40: 0x40a500 (a NEG) turns vx and vy around, then 0x4585e0 reads the
		# quantized heading of that reversed velocity. A found surface S adds 90 to its
		# cell and gives 2 x (S + 90) - heading; with the four scans blocked the shell
		# keeps the reversed heading, so it goes straight back.
		var heading := Physics.velocity_angle(-velocity)
		var turned := 2 * (int(surface.angle) + 90) - heading if bool(surface.ok) else heading
		var speed := int(shell.g_speed)
		velocity = Vector2i(int(Physics.s(turned + 90) * speed), int(-(Physics.s(turned) * speed)))
	inside = Vector2i(pos.x >> 8, pos.y >> 8)
	velocity += Vector2i(shell.fp_acceleration)
	shell.fp_pos = pos
	shell.fp_velocity = velocity
	shell.g_int = inside
	shell.g_ctr = counter
	var gone := inside.x < 0 or inside.x > w or inside.y > h or inside.y < -1000
	return {"event": "oob" if gone else "", "position": inside, "mobile": false, "ricochet": ricochet}

## Animate: the counter only runs once the first ricochet started it.
static func finish_frame(shell: Dictionary) -> void:
	if int(shell.g_ctr) != -1:
		shell.g_ctr = int(shell.g_ctr) + 1

## 0x49e650 / 0x4857f0: sample every 8 px along the dominant axis, refine the last
## 8 px one pixel at a time (0x458920 / 0x458a00) and clamp leaving the map to a
## contact on the map edge.
static func _sweep(cells: PackedByteArray, w: int, h: int, previous: Vector2i, current: Vector2i, hit_mobile: Callable, mobiles: bool) -> Dictionary:
	var dx := absi(previous.x - current.x)
	var dy := absi(previous.y - current.y)
	var horizontal := dy + 1 < dx + 1
	var slope: int
	var acc: int
	var step: int
	var major: int
	var length: int
	if horizontal:
		slope = Physics.quot((current.y - previous.y) << 16, dx + 1)
		acc = previous.y << 16
		step = -1 if current.x < previous.x else 1
		major = previous.x + step
		length = dx
	else:
		slope = Physics.quot((current.x - previous.x) << 16, dy + 1)
		acc = previous.x << 16
		step = -1 if current.y < previous.y else 1
		major = previous.y + step
		length = dy
	var start := major
	var count := length + SWEEP_STRIDE
	var distance := 0
	while distance < count:
		acc += slope * SWEEP_STRIDE
		var minor := acc >> 16
		var x := major if horizontal else minor
		var y := minor if horizontal else major
		if _solid(cells, w, h, x, y):
			var fine := _refine(cells, w, h, start, distance, step, slope, acc, horizontal, true, hit_mobile, mobiles)
			return {"x": fine.x if fine.found else x, "y": fine.y if fine.found else y, "mobile": false}
		if mobiles and hit_mobile.call(x, y):
			var fine_body := _refine(cells, w, h, start, distance, step, slope, acc, horizontal, false, hit_mobile, mobiles)
			return {"x": fine_body.x if fine_body.found else x, "y": fine_body.y if fine_body.found else y, "mobile": true}
		if x < 0 or x > w - 1 or y < -0x113 or y > h - 1:
			return {"x": clampi(x, 0, w - 1), "y": clampi(y, -0x113, h - 1), "mobile": false}
		distance += SWEEP_STRIDE
		major += step * SWEEP_STRIDE
	return {}

static func _solid(cells: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	return x >= 0 and x < w and y >= 0 and y < h and cells[y * w + x] != 0

## 0x458920 (x major) / 0x458a00 (y major): walk the 8 px before the coarse sample.
static func _refine(cells: PackedByteArray, w: int, h: int, start: int, distance: int, step: int, slope: int, acc: int, horizontal: bool, terrain: bool, hit_mobile: Callable, mobiles: bool) -> Dictionary:
	if distance == 0:
		return {"found": false}
	var fine_acc := acc - slope * SWEEP_STRIDE
	var index := distance - SWEEP_STRIDE
	var major := index * step + start
	while index < distance:
		fine_acc += slope
		var minor := fine_acc >> 16
		var x := major if horizontal else minor
		var y := minor if horizontal else major
		if terrain and _solid(cells, w, h, x, y):
			return {"found": true, "x": x, "y": y}
		if not terrain and mobiles and hit_mobile.call(x, y):
			return {"found": true, "x": x, "y": y}
		index += 1
		major += step
	return {"found": false}

## 0x49fd40 ricochet: pull the contact pixel to the free side of the surface
## (scanners at +/-8 px) and republish the 24.8 position from it.
static func _snap(cells: PackedByteArray, w: int, h: int, contact: Vector2i, fixed: Vector2i) -> Dictionary:
	var x := contact.x
	var y := contact.y
	var pos := fixed
	if x == 0 or x == w - 1 or y == -0x113 or y == h - 1:
		return {"inside": contact, "pos": pos}
	var left := Surface.scan_left(cells, w, h, y, x + 8)
	if left != x + 8 and left != -Surface.FAR:
		x = left + 1
	var right := Surface.scan_right(cells, w, h, x - 8, y)
	if right != x - 8 and right != Surface.FAR:
		x = right - 1
	pos.x = x << 8
	var below := Surface.scan_down(cells, w, h, y, x)
	if below == Surface.FAR:
		return {"inside": Vector2i(x, y), "pos": pos}
	var upper := Surface.scan_down(cells, w, h, y - 8, x)
	if upper != y - 8 and upper != Surface.FAR:
		y = upper - 1
	var lower := Surface.scan_up(cells, w, h, y + 8, x)
	if lower != y + 8 and lower != -Surface.FAR:
		y = lower + 1
	pos.y = y << 8
	return {"inside": Vector2i(x, y), "pos": pos}
