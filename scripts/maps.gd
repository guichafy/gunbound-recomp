extends RefCounted
## Native Thor's Hammer catalog:22sides,11family worlds. The client normalizes
## geometry/music by family, while side selects stage.dat weather (ADR-MAPS-45).
## Only MiramoA retains its historical offline spawn list/fallback copies;
## new spawns use pinned jglim auxiliary ranges with an explicit1×1 policy.
## Copyright (C)2020CarlosH.M.S.; historical reference data GPL-3.0-or-later.

const DEFAULT := "miramo_town_a"
const MAPS := {
	"miramo_town_a": {
		"name": "Miramo Town",
		"openbound_id": 20,
		# stage.dat record of the client; its % 11 picks stage%d.mp3 (ADR-153).
		"client_stage": 1,
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

static var catalog: Dictionary = {}
static var valid_sizes: Dictionary = {}

static func _static_init() -> void:
	var source = JSON.parse_string(FileAccess.get_file_as_string("res://assets/xfs/maps/catalog.json"))
	if not source is Dictionary:
		return
	for value in source.get("maps", []):
		var row: Dictionary = value.duplicate(true)
		row.native_weather = row.weather.duplicate()
		var box: Array = row.crop
		row.crop = Rect2i(int(box[0]),int(box[1]),int(box[2])-int(box[0]),int(box[3])-int(box[1]))
		row.world_size = Vector2(row.world_size[0],row.world_size[1])
		row.particle_pivot = Vector2(row.particle_pivot[0],row.particle_pivot[1])
		if row.id == DEFAULT:
			row.merge(MAPS[DEFAULT],true)
		catalog[str(row.id)] = row

static func get_map(id: String) -> Dictionary:
	return catalog.get(id, MAPS.get(id, {}))

static func is_available(id: String) -> bool:
	var map := get_map(id)
	if map.is_empty():
		return false
	var side := 1200 if int(map.world_size.x)==1600 else 1300
	var expected := {"mask":Vector2(map.world_size),"background":Vector2(side,side),"preview":Vector2(748,209),
		"particle":Vector2(map.particle_pivot)*2*Vector2(20,ceili(float(map.particle_frames)/20.0))}
	for key in expected:
		var resource := path(map,key)
		if not ResourceLoader.exists(resource):return false
		var cache_key := resource+str(expected[key])
		if not valid_sizes.has(cache_key):
			var texture: Texture2D = load(resource)
			valid_sizes[cache_key] = texture!=null and texture.get_size()==Vector2(expected[key])
		if not valid_sizes[cache_key]:return false
	return true

static func available_ids() -> Array[String]:
	var result: Array[String] = []
	for id in catalog:
		if is_available(id):
			result.append(id)
	return result

static func native_weather(map: Dictionary) -> Array:
	return map.get("native_weather",[1,1,1,1,1,1,1])


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
	for point in map.get("spawns",[]):
		if (float(point[0]) < world_width * 0.5) == left_side:
			result.append(Vector2(point[0], point[1]))
	return result
