extends RefCounted
## Trico-specific 20Hz state; PE evidence/bridges: TRICO_SPECIALS_ISSUE_30.md.
const Physics = preload("res://scripts/classic_ballistics.gd")
const T2 := "trico_t2"
const SS := "trico_ss"

static func active(shell: Dictionary) -> bool:
	return str(shell.get("flight","")) in [T2,SS] and not bool(shell.get("beacon",false))

static func prepare(shell: Dictionary, entry: Dictionary, theta: int) -> void:
	if not active(shell):
		return
	shell.trico_component = int(entry.get("trico_component",0))
	shell.trico_phase = theta + int(shell.trico_component)*180
	shell.trico_step = -8 if theta<91 else 8
	shell.trico_radius = 2
	shell.trico_heading = theta

## 4a2ce0 uses the float32 LUT in x87, then truncates the sum/product to
## fixed-point. The offset never enters the central ballistic accumulator.
static func hit_point(shell: Dictionary, carrier: Vector2) -> Vector2:
	if not active(shell) or str(shell.flight)!=T2 or int(shell.trico_component)==2:
		return carrier
	var phase := int(shell.trico_phase)
	var radius := int(shell.trico_radius)*256
	var a := Physics.s(phase)
	var b := Physics.s(phase+90)
	var offset := Vector2i(int((a+b)*radius),int((b-a)*radius))
	shell.trico_heading = (phase+90)%360
	return carrier+Vector2(offset)/256.0

static func finish_tick(shell: Dictionary) -> void:
	if not active(shell) or str(shell.flight)!=T2 or int(shell.trico_component)==2:
		return
	shell.trico_radius = mini(int(shell.trico_radius)+2,30)
	shell.trico_phase = (int(shell.trico_phase)+int(shell.trico_step))%360

static func begin_ss(shell: Dictionary, point: Vector2) -> void:
	var origin := Vector2i(point)
	shell.trico_ss_tick = 0
	shell.trico_seed = (origin.x+origin.y)&0xffffffff
	shell.trico_ss_origin = origin
	shell.hit_pos = Vector2(origin)
	shell.pos = shell.hit_pos
	shell.previous_hit_pos = shell.hit_pos
	shell.previous_draw_pos = shell.pos
	shell.ss_state = "trico_start"

## 4acd10: uint32 IMUL/ADD and unsigned DIV. This generator is private to the
## impact; it consumes neither gameplay RNG nor presentation RNG.
static func _roll(seed: int) -> Array:
	var q := (seed*214013+92312341)&0xffffffff
	var next := (seed+(((q+1)*97)&0xffffffff)%1000001)&0xffffffff
	return [q,next]

static func tick_ss(shell: Dictionary) -> Dictionary:
	shell.trico_ss_tick = int(shell.trico_ss_tick)+1
	var tick := int(shell.trico_ss_tick)
	if tick>=21:
		return {"finished":true}
	if tick<2 or tick>16 or tick%2!=0:
		return {"finished":false}
	var width := int(shell.get("trico_width",50))
	var x := _roll(int(shell.trico_seed))
	var y := _roll(int(x[1]))
	shell.trico_seed = int(y[1])
	var offset := Vector2i(int(x[0])%width-Physics.quot(width,2),int(y[0])%width-Physics.quot(width,2))
	return {"finished":false,"position":Vector2(Vector2i(shell.trico_ss_origin)+offset)}
