extends RefCounted
## Map catalog. Pixels come from the original client (graphics.xfs "mos"; ADR-133);
## spawns and weather preset were taken from OpenBound Map.cs/LevelScene.cs and
## remain declared adaptations. The world is the native foreground (1 world unit
## = 1 original pixel). Copyright (C) 2020, Carlos H.M.S.; reference data GPL-3.0-or-later.

const DEFAULT := "miramo_town_a"
const MAPS := {
	"miramo_town_a": {
		"name": "Miramo Town",
		"openbound_id": 20,
		"type": "A",
		# Force, Tornado, Electricity, Wind, Weakness, Protection, Ignorance, Thor, Mirror, Random.
		"weather": [2, 1, 2, 1, 0, 2, 0, 0, 0, 1],
		# Foreground pixel coordinates, as listed in Map.cs.
		"spawns": [[148, 1439], [325, 1410], [448, 1374], [596, 1392], [743, 1341], [883, 1396], [1041, 1354], [1192, 1409], [1363, 1374], [1515, 1394], [1673, 1400]],
		# Client stage "mos" (stage.dat record 1), extracted by import_xfs_map.py.
		# Collision truth and visual: mos.img frame 0, whose alpha equals mos.lnd.
		"mask": "res://assets/xfs/maps/mos/foreground.png",
		# Alpha bounding box: the only region with terrain.
		"crop": Rect2i(17, 1344, 1766, 456),
		# mos.img frame 1, 1300×1300.
		"background": "res://assets/xfs/maps/mos/background.png",
		# pmos.img: 60 frames on 48×48 cells around their pivot.
		"particle": "res://assets/xfs/maps/mos/particle.png",
		"particle_frames": 60,
		"particle_pivot": Vector2(24, 24),
		# Same pixels from the earlier import; only used when the client files are missing.
		"fallback": {
			"mask": "res://assets/openbound/maps/miramo_town/ForegroundA.png",
			"background": "res://assets/openbound/maps/miramo_town/Background.png",
			"particle": "res://assets/openbound/maps/miramo_town/Particle.png",
		},
	}
}

static func get_map(id: String) -> Dictionary:
	return MAPS.get(id, {})

## Client file for `key` ("mask", "background", "particle"), or its fallback copy.
static func path(map: Dictionary, key: String) -> String:
	var primary: String = map.get(key, "")
	if ResourceLoader.exists(primary):
		return primary
	return map.get("fallback", {}).get(key, primary)

static func foreground_rect(map: Dictionary) -> Rect2:
	return Rect2(map.crop)

static func spawn_points(map: Dictionary, left_side: bool, world_width: float) -> Array:
	# 1×1 keeps the player left and the CPU right; each picks from its half.
	var result := []
	for point in map.spawns:
		if (float(point[0]) < world_width * 0.5) == left_side:
			result.append(Vector2(point[0], point[1]))
	return result
