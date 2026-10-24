extends RefCounted
## Parameter object of MobileSprite.draw and MobileRig.draw (ADR-081): where and
## how one mobile is drawn. Presentation only; built per draw call.
##
##     sprite.draw(view, SpritePose.new(pos, 60.0, facing, {"pose": "idle", "age": t}))

var pos := Vector2.ZERO
var width := 60.0
var facing := 1
var rotation := 0.0
var frame := 0
var color := Color.WHITE
var pose := "idle"
var age := 0.0
var weapon := 0
var low_health := false
var wheel_phase := 0.0
# Equipment, avatar clock and the blended rig state (BattleArt.presentation).
var avatar_context: Dictionary = {}

const OPTIONAL := ["rotation", "frame", "color", "pose", "age", "weapon", "low_health", "wheel_phase", "avatar_context"]

## Named optional fields keep call sites readable; an unknown name is an error.
func _init(at: Vector2 = Vector2.ZERO, size: float = 60.0, side: int = 1, options: Dictionary = {}) -> void:
	pos = at
	width = size
	facing = side
	for key in options:
		if key in OPTIONAL:
			set(key, options[key])
		else:
			push_error("SpritePose has no field " + str(key))

## Same pose seen from the other side (the Nak art faces against its aim).
func mirrored():
	var copy = get_script().new(pos, width, -facing)
	for key in OPTIONAL:
		copy.set(key, get(key))
	return copy
