extends RefCounted
## Offline1×1 spawn policy; native family resources and auxiliary jglim ranges.
const Maps = preload("res://scripts/maps.gd")
const Terrain = preload("res://scripts/terrain.gd")
static var candidates: Dictionary = {}

static func resolve(id: String, rng: RandomNumberGenerator) -> Dictionary:
	if id=="random":
		var ids := Maps.available_ids()
		if ids.is_empty():return {}
		id = ids[rng.randi_range(0,ids.size()-1)]
	if not Maps.is_available(id):return {}
	var terrain = Terrain.new()
	if not terrain.load_map(id,false):return {}
	var map := Maps.get_map(id)
	var points: Array = []
	if id==Maps.DEFAULT:
		# Preserve two draws and every legacy spawn, including its source Y.
		for left in [true,false]:
			var options := Maps.spawn_points(map,left,terrain.world_size().x)
			if options.is_empty():return {}
			points.append(options[rng.randi_range(0,options.size()-1)])
	else:
		if not candidates.has(id):
			var sides := [[],[]]
			for slot in map.spawn_ranges:
				var groups := [[],[]]
				for x in range(maxi(0,int(slot.x_min)),mini(int(terrain.world_size().x)-1,int(slot.x_max))+1):
					var from_y := 0.0 if slot.y==null else float(slot.y)
					var ground: float = terrain.surface_at(float(x),from_y)
					# A range Y may lie inside land. Rise only within this solid run;
					# crossing air would select a different (upper) platform.
					while ground>=Terrain.SCALE and terrain.is_solid(Vector2(x,ground-Terrain.SCALE)):
						ground-=Terrain.SCALE
					if not terrain.is_void(ground):
						groups[0 if x<terrain.world_size().x/2 else 1].append(Vector2(x,ground))
				for side in 2:
					if not groups[side].is_empty():sides[side].append(groups[side])
			candidates[id] = sides
		for groups in candidates[id]:
			if groups.is_empty():return {}
			var group: Array = groups[rng.randi_range(0,groups.size()-1)]
			points.append(group[rng.randi_range(0,group.size()-1)])
	return {"map_id":id,"world_width":int(terrain.world_size().x),"spawns":points}
