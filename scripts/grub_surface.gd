extends RefCounted
## Grub (type 12) ricochet surface angle: GunBound.gme 0x4a1740 and its four
## terrain scanners 0x4e4340/0x4e4390/0x4e43d0/0x4e4410 (docs/sdd/GRUB_CLIENT_FIX.md).
## Pure function of the 1-pixel solid mask and the contact pixel; Y grows downward.

const Physics = preload("res://scripts/classic_ballistics.gd")
const FAR := 10000

## 4e4340: first solid row at or below y0 in column x (FAR when none).
static func scan_down(cells: PackedByteArray, w: int, h: int, y0: int, x: int) -> int:
	if x < 0 or x >= w:
		return FAR
	var y := maxi(y0, 0)
	while y < h:
		if cells[y * w + x] != 0:
			return y
		y += 1
	return FAR

## 4e4390: first solid row at or above y0 in column x (-FAR when none).
static func scan_up(cells: PackedByteArray, w: int, h: int, y0: int, x: int) -> int:
	if x < 0 or x >= w:
		return -FAR
	var y := mini(y0, h - 1)
	while y >= 0:
		if cells[y * w + x] != 0:
			return y
		y -= 1
	return -FAR

## 4e43d0: first solid column at or left of x0 in row y. The client loop has no
## lower bound: it keeps walking the flat buffer into the previous row.
static func scan_left(cells: PackedByteArray, w: int, h: int, y: int, x0: int) -> int:
	if y < 0 or y >= h:
		return -FAR
	var x := mini(x0, w - 1)
	if x < 0:
		return -FAR
	var at := y * w + x
	while at >= 0:
		if cells[at] != 0:
			return x
		x -= 1
		at -= 1
	return -FAR

## 4e4410: first solid column at or right of x0 in row y; the client loop has no
## upper bound either.
static func scan_right(cells: PackedByteArray, w: int, h: int, x0: int, y: int) -> int:
	if y < 0 or y >= h:
		return FAR
	var x := maxi(x0, 0)
	if x >= w:
		return FAR
	var at := y * w + x
	while at < cells.size():
		if cells[at] != 0:
			return x
		x += 1
		at += 1
	return FAR

## Table 0x598e7e indexed [row * 256 + col], after halving both until they fit.
static func table_angle(row: int, col: int) -> int:
	while col < -127 or col > 128 or row < -127 or row > 128:
		col = int(col / 2)
		row = int(row / 2)
	return Physics.angles.decode_s16(2 * (col + 127 + 256 * (row + 127)))

## Returns {"ok": bool, "angle": int}. ok=false leaves the client cell 0x3fa4
## untouched, so "angle" is then the caller's previous value.
static func angle_at(cells: PackedByteArray, w: int, h: int, cx: int, cy: int, previous: int = 0) -> Dictionary:
	if cx == 0 or cx == w - 1:
		return {"ok": true, "angle": 90}
	if cy == -0x113:
		return {"ok": true, "angle": 180}
	if cy == h - 1:
		return {"ok": true, "angle": 0}
	# Floor: three columns scanned downward from 6 px above the contact.
	var a0 := scan_down(cells, w, h, cy - 6, cx)
	var a1 := scan_down(cells, w, h, cy - 6, cx - 4)
	var a2 := scan_down(cells, w, h, cy - 6, cx + 4)
	var blocked := a0 == cy - 6 or cy + 10 < a1 or cy + 10 < a2 or a1 == cy - 6 or a2 == cy - 6
	if not blocked:
		return {"ok": true, "angle": 0 if a1 == a2 else table_angle(a2 - a1, 8)}
	# Ceiling: three columns scanned upward from 6 px below.
	var b0 := scan_up(cells, w, h, cy + 6, cx)
	var b1 := scan_up(cells, w, h, cy + 6, cx - 4)
	var b2 := scan_up(cells, w, h, cy + 6, cx + 4)
	blocked = b0 == cy + 6 or b1 < cy - 10 or b2 < cy - 10 or b1 == cy + 6 or b2 == cy + 6
	if not blocked:
		return {"ok": true, "angle": 180 if b1 == b2 else table_angle(b2 - b1, 8)}
	# Wall on the left of the contact: rows scanned rightward from 6 px left.
	var c0 := scan_right(cells, w, h, cx - 6, cy)
	var c1 := scan_right(cells, w, h, cx - 6, cy - 4)
	var c2 := scan_right(cells, w, h, cx - 6, cy + 4)
	blocked = c0 == cx - 6 or cx + 10 < c1 or cx + 10 < c2 or c1 == cx - 6 or c2 == cx - 6
	if not blocked:
		return {"ok": true, "angle": 90 if c1 == c2 else table_angle(8, c1 - c2)}
	# Wall on the right: rows scanned leftward from 6 px right.
	var d0 := scan_left(cells, w, h, cy, cx + 6)
	var d1 := scan_left(cells, w, h, cy - 4, cx + 6)
	var d2 := scan_left(cells, w, h, cy + 4, cx + 6)
	blocked = d0 == cx + 6 or d1 < cx - 10 or d2 < cx - 10 or d1 == cx + 6 or d2 == cx + 6
	if blocked:
		return {"ok": false, "angle": previous}
	return {"ok": true, "angle": 90 if d1 == d2 else table_angle(8, d1 - d2)}
