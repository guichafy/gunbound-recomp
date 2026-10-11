extends RefCounted
## Original OpenBound map data (Map.cs, LevelScene.cs) and its fixed-arena transform.
## Copyright (C) 2020, Carlos H.M.S.; reference data GPL-3.0-or-later.

const DEFAULT := "miramo_town_a"
const ARENA_WIDTH := 1280.0
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
		# Alpha bounding box in original pixels; scaled to the arena width.
		"crop": Rect2i(17, 1344, 1766, 456),
		"top": 420.0,
		# HUD starts at y670: below it is abyss, so nothing survives out of sight.
		"floor": 670.0,
		"foreground_hd": "res://assets/hd/maps/miramo_town/foreground_a.png",
		"background_hd": "res://assets/hd/maps/miramo_town/background.png",
		"background": "res://assets/openbound/maps/miramo_town/Background.png",
		# Original background pixels covered by the HD file, and the bottom-aligned
		# 1.6:1 window shown behind the arena (original camera resting on the ground).
		"background_hd_source": Rect2(0, 260, 1300, 1040),
		"background_view": Rect2(0, 487.5, 1300, 812.5),
	}
}

static func get_map(id: String) -> Dictionary:
	return MAPS.get(id, {})

static func world_scale(map: Dictionary) -> float:
	return ARENA_WIDTH / float(map.crop.size.x)

static func to_world(map: Dictionary, source: Vector2) -> Vector2:
	var crop: Rect2i = map.crop
	return Vector2((source.x - crop.position.x) * world_scale(map), float(map.top) + (source.y - crop.position.y) * world_scale(map))

static func to_source(map: Dictionary, world: Vector2) -> Vector2:
	var crop: Rect2i = map.crop
	return Vector2(crop.position.x + world.x / world_scale(map), crop.position.y + (world.y - float(map.top)) / world_scale(map))

static func foreground_rect(map: Dictionary) -> Rect2:
	return Rect2(0.0, float(map.top), ARENA_WIDTH, float(map.crop.size.y) * world_scale(map))

static func spawn_x(map: Dictionary, left_side: bool) -> Array:
	# 1×1 keeps the player left and the CPU right; each picks from its half.
	var result := []
	for point in map.spawns:
		var x: float = to_world(map, Vector2(point[0], point[1])).x
		if (x < ARENA_WIDTH * 0.5) == left_side:
			result.append(x)
	return result
