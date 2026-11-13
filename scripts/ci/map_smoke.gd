extends RefCounted
const Maps = preload("res://scripts/maps.gd")
const Match = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const MapArt = preload("res://scripts/map_art.gd")
const Combat = preload("res://scripts/combat.gd")

static func run(check: Callable, extensive: bool = true) -> int:
	var shots := 0
	check.call(Maps.available_ids().size()==22,"all22map sides packaged")
	for id in Maps.available_ids():
		var map := Maps.get_map(id)
		var art = MapArt.new()
		art.prepare(map)
		check.call(art.textures.size()==(map.scenery.size() if bool(map.get("scenery_enabled",false)) else 0),id+": scenery packaged")
		var vehicles: Array = range(1,17) if extensive else [int(map.stage_index)%16+1]
		for vehicle in vehicles:
			for weapon in 3:
				var model = Match.new()
				model.start(vehicle,1,5300+vehicle,id,"original",null,[],[],[],0,2)
				var label := "%s/%d/%d: "%[id,vehicle,weapon]
				check.call(model.map_id==id,label+"identity")
				var before: PackedByteArray = model.terrain.native_cells.duplicate()
				var target: Vector2 = model.actors[1].pos
				var prediction: Dictionary = model.predict_shot(0,45,30,weapon)
				check.call(model.terrain.native_cells==before,label+"prediction preserves live terrain")
				var simulation = Snapshot.capture(model)
				Snapshot.arm(simulation,0,weapon,model.shot_shells(0,45,30,weapon))
				check.call(model.fire(45,30,weapon),label+"shot accepted")
				var closest: Dictionary = {}
				var distance := INF
				for tick in 1100:
					model.advance_projectiles(Combat.STEP)
					simulation.advance_projectiles(Combat.STEP)
					simulation.events.clear()
					for event in model.events:
						if event.type not in ["explosion","miss","teleport","thor","mine_plant"]:continue
						var d := Vector2(event.position).distance_to(target)
						if d<distance:
							distance = d
							closest = {"position":event.position,"actor":event.get("collided_actor",-1),"hit":event.type!="miss"}
					model.events.clear()
					if model.phase!=Match.PHASE_FLIGHT:break
				check.call(model.phase!=Match.PHASE_FLIGHT,label+"flight terminates")
				check.call(prediction==closest,label+"prediction matches real endpoint")
				check.call(model.terrain.cells==simulation.terrain.cells and model.terrain.native_cells==simulation.terrain.native_cells,label+"prediction masks match")
				for index in 2:
					check.call(model.actors[index].hp==simulation.actors[index].hp and model.actors[index].pos==simulation.actors[index].pos,label+"prediction actor state matches")
				shots+=1
	return shots
