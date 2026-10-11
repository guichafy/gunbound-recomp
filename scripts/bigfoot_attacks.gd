extends RefCounted
## Bigfoot attack metadata/emitter adapted from OpenBound (GPL-3.0-or-later).
## Copyright (C) 2020, Carlos H.M.S. <carlos_judo@hotmail.com>
## Exact reference and adaptations: docs/sdd/BIGFOOT_ATTACKS_0_5.md.

const WEAPONS := [
	{"name": "T1 · Bombas", "damage": 90.0, "radius": 25.0, "delay": 770.0 / 7.5, "count": 4, "color": Color("ffd18a")},
	{"name": "T2 · Rajadas", "damage": 70.0, "radius": 25.0, "delay": 920.0 / 7.5, "count": 6, "color": Color("ffa15a")},
	{"name": "SS · Bombardeio", "damage": 90.0, "radius": 25.0, "delay": 1320.0 / 7.5, "count": 8, "color": Color("f5bd68")}
]
const AIM_LIMITS := [Vector2(18, 40), Vector2(18, 40), Vector2(23, 35)]

static func salvo(weapon: int) -> Array:
	var result: Array = []
	if weapon == 1:
		for burst in range(2):
			for offset in [-4.0, 0.0, 4.0]:
				result.append({"spawn": 0.2 * (burst + 1), "angle": 0.0, "power": offset})
	else:
		for bomb in range(4 if weapon == 0 else 8):
			result.append({"spawn": (0.2 if weapon == 0 else 0.125) * bomb, "angle": [3.0, -3.0, 0.0, 0.0][bomb % 4], "power": 0.0})
	return result
