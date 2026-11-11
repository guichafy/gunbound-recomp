extends RefCounted
## Thor's Hammer489580 geometry; EPA catalog remains the owner of timing.
## Contracts and independent PE oracle: docs/sdd/BIGFOOT_COMBAT_ISSUE_28.md.

const WEAPONS := [
	{"name": "T1 · Bombas", "damage": 86.0, "radius": 26.0, "cost": 770, "count": 4, "color": Color("ffd18a")},
	{"name": "T2 · Rajadas", "damage": 70.0, "radius": 20.0, "cost": 920, "count": 6, "color": Color("ffa15a")},
	{"name": "SS · Bombardeio", "damage": 92.0, "radius": 24.0, "cost": 1320, "count": 8, "color": Color("f5bd68")}
]
const AIM_LIMITS := [Vector2(18, 40), Vector2(18, 40), Vector2(23, 35)]

static func salvo(weapon: int) -> Array:
	var result: Array = []
	var offsets: Array = [Vector2i(0,15),Vector2i(4,10),Vector2i(-4,10),Vector2i(0,0),Vector2i(2,5),Vector2i(-2,5)] if weapon == 1 else [Vector2i(0,10),Vector2i(0,-10),Vector2i(1,0),Vector2i(-1,0)]
	for bomb in range([4,6,8][weapon]):
		var offset: Vector2i = offsets[bomb % offsets.size()]
		result.append({"spawn":0.0,"angle":0.0,"power":0.0,"native_angle":offset.x,"native_power":offset.y})
	return result
