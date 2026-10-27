extends RefCounted
## CrashTexture sparks: Force48dd80/Electric481ef0, quad4ec840.
## Caller warms ClassicBallistics on the main thread and owns the 20Hz clock.
## angle is the current angle, already advanced by Animate (+1/+6); no IO here.
const Physics = preload("res://scripts/classic_ballistics.gd")
const TEXTURE := "res://assets/xfs/weather/CrashTexture.png"

static func quad(effect: Dictionary) -> Dictionary:
	var kind := str(effect.get("kind",""))
	var tick := int(effect.get("tick",-1))
	if kind not in ["force","electricity"] or tick<0 or tick>15:
		return {}
	var position: Vector2i = Vector2i(effect.get("position",Vector2i.ZERO))
	var angle := int(effect.get("angle",0))
	var s := Physics.s(angle)
	var c := Physics.s(angle+90)
	var lo := float(tick-16)
	var hi := float(15-tick)
	var x := _f32(float(position.x))
	var y := _f32(float(position.y))
	# x87 stores at4ec8d0/e2/ee/900 and4ec958 round these intermediates.
	# Other products/sums remain extended until each vertex's float32 store.
	var minus_s_lo := _f32(-s*lo)
	var c_hi := _f32(c*hi)
	var s_hi := _f32(s*hi)
	var points := PackedVector2Array([
		Vector2(_f32(x+s*lo+c*lo),_f32(y+minus_s_lo+c*lo)),
		Vector2(_f32(x+c_hi+s*lo),_f32(y-s*hi+c*lo)),
		Vector2(_f32(x+s_hi+c_hi),_f32(y-s*hi+c_hi)),
		Vector2(_f32(_f32(x+s_hi)+c*lo),_f32(y+c_hi+minus_s_lo))])
	var u := float(tick/2)*0.125
	var v := 0.25 if kind=="force" else 0.375
	return {"points":points,
		"uv":PackedVector2Array([Vector2(u,v),Vector2(u+0.125,v),Vector2(u+0.125,v+0.125),Vector2(u,v+0.125)]),
		"color":Color(1,1,1,float(255-16*tick)/255.0),"blend":"add","texture":TEXTURE}

static func _f32(value: float) -> float:
	return PackedFloat32Array([value])[0]
