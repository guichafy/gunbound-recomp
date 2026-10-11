extends RefCounted
## Original OpenBound map data (Map.cs, LevelScene.cs). The world is the native
## foreground (1 world unit = 1 original pixel), so Map.cs coordinates apply as-is.
## Copyright (C) 2020, Carlos H.M.S.; reference data GPL-3.0-or-later.

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
		# Collision truth: alpha > 0 of the original foreground, as Topography.cs.
		"mask": "res://assets/openbound/maps/miramo_town/ForegroundA.png",
		# Alpha bounding box: the only region with terrain; the HD file covers it.
		"crop": Rect2i(17, 1344, 1766, 456),
		"foreground_hd": "res://assets/hd/maps/miramo_town/foreground_a.png",
		"background_hd": "res://assets/hd/maps/miramo_town/background.png",
		"background": "res://assets/openbound/maps/miramo_town/Background.png",
		# Original background pixels covered by the stitched HD file.
		"background_hd_source": Rect2(0, 260, 1300, 1040),
		# Map.cs: GroundParticleNumberOfFrames / GroundParticlePivot.
		"particle": "res://assets/openbound/maps/miramo_town/Particle.png",
		"particle_frames": 60,
		"particle_pivot": Vector2(24, 24),
	}
}

static func get_map(id: String) -> Dictionary:
	return MAPS.get(id, {})

static func foreground_rect(map: Dictionary) -> Rect2:
	return Rect2(map.crop)

static func spawn_points(map: Dictionary, left_side: bool, world_width: float) -> Array:
	# 1×1 keeps the player left and the CPU right; each picks from its half.
	var result := []
	for point in map.spawns:
		if (float(point[0]) < world_width * 0.5) == left_side:
			result.append(Vector2(point[0], point[1]))
	return result
