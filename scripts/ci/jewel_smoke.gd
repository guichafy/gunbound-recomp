extends RefCounted
## Runs inside release templates: no docs/test fixture or profile dependency.
const Match = preload("res://scripts/match.gd")
const Maps = preload("res://scripts/maps.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Art = preload("res://scripts/jewel_art.gd")

static func run(check: Callable) -> int:
	var count := 0
	var art := Art.new()
	check.call(art.textures.size()==14,"JEWEL body/light/flame/control/glyph resources packaged")
	check.call(art.room_frame("jewel")!=null,"JEWEL room control packaged")
	check.call(Maps.available_ids().size()==22,"JEWEL package has all22map sides")
	for id in Maps.available_ids():
		var model = Match.new()
		model.start(2,1,46,id,"original",null,[],[],[],0,1,[],"jewel")
		var label := id+": JEWEL "
		check.call(model.mode=="jewel" and model.map_id==id,label+"mode and map identity")
		var hp: int=model.actors[0].hp
		var shield: int=model.actors[0].shield
		check.call(model.deal_damage(0,99999)==0 and model.actors[0].hp==hp and model.actors[0].shield==shield,label+"pilot immunity")
		check.call(not model.events.any(func(event):return event.type in ["damage","shield_damage"]),label+"no fake damage credit")
		# One controlled source column; no repair/replacement of the package mask.
		model.jewel_state.entities.clear()
		var spawned: bool=model.JewelRules.spawn(model.jewel_state,model.terrain,int(model.actors[0].pos.x),40)
		check.call(spawned,label+"native jewel supported on real map")
		if not spawned:continue
		check.call(art.layers(model.jewel_state.entities[0]).size()==1,label+"native registered artwork available")
		var snapshot = Snapshot.capture(model)
		snapshot.jewel_state.entities[0].damage=1
		check.call(model.jewel_state.entities[0].damage==0 and snapshot.mode==model.mode and snapshot.map_id==id,label+"private objective snapshot")
		var point := Vector2(model.jewel_state.entities[0].pos)-Vector2(0,10)
		var shell: Dictionary=model.projectile_parameters(0,30,50,0)[0]
		model.explode(point,-1,shell)
		model.explode(point,-1,shell)
		model.step_jewels(0.05)
		check.call(model.jewel_state.scores==[5,0],label+"native blast and blue jewel credit")
		model.jewel_state.scores=[100,0]
		check.call(model.check_end() and model.winner==0,label+"objective result")
		var events: int=model.events.filter(func(event):return event.type=="finished").size()
		model.check_end()
		check.call(events==1 and model.events.filter(func(event):return event.type=="finished").size()==events,label+"idempotent result latch")
		count+=1
	art.glow.clear()
	return count
