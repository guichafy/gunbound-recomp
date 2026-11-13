extends "res://tests/support/suite.gd"
## Integration regressions over every packaged classic side. These checks prove
## execution/prediction agreement of the current ports and declared bridges;
## they do not turn adapted producers/items/weather into native parity claims.
const Model = preload("res://scripts/match.gd")
const Maps = preload("res://scripts/maps.gd")
const Choice = preload("res://scripts/map_choice.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Rules = preload("res://scripts/jewel_rules.gd")
const Objective = preload("res://scripts/jewel_combat.gd")
const Damage = preload("res://scripts/damage.gd")
const Combat = preload("res://scripts/combat.gd")
const REPRESENTATIVES := [1,2,3,6,12,13,15,16]
var shots := 0
var worker_cases := 0

func start_game(id: String, vehicle: int, seed_value: int, spawns: Array, mode: String = "jewel", loadout: Array = []):
	var model = Model.new()
	model.start(vehicle,1,seed_value,id,"original",null,loadout,[],[],0,2,spawns,mode)
	return model

func key_state(model) -> Dictionary:
	return {"jewels":model.jewel_state.duplicate(true),"cells":model.terrain.cells.duplicate(),
		"native":model.terrain.native_cells.duplicate(),"revision":model.terrain.revision,
		"actors":model.actors.duplicate(true),"weather_queue":model.weather.queue.duplicate(true),
		"weather_columns":model.weather.columns.duplicate(true),"rng":model.rng.state,"winner":model.winner}

func assert_live(model, before: Dictionary, label: String) -> void:
	check(model.jewel_state==before.jewels,label+": objective untouched")
	check(model.terrain.cells==before.cells and model.terrain.native_cells==before.native and model.terrain.revision==before.revision,label+": live masks untouched")
	check(model.actors==before.actors,label+": live actors untouched")
	check(model.weather.queue==before.weather_queue and model.weather.columns==before.weather_columns,label+": live weather untouched")
	check(model.rng.state==before.rng and model.winner==before.winner,label+": live RNG/result untouched")

func objective_on_map(model, label: String) -> void:
	check(not model.jewel_state.entities.is_empty() and model.jewel_state.entities.size()<=6,label+": six initial attempts create native entities")
	var seen := {}
	for entity in model.jewel_state.entities:
		var point := Vector2i(entity.pos)
		var floor_y: int=model.terrain.native_surface_at(point.x,0)
		check(point.x>=0 and point.x<int(model.terrain.world_size().x) and point.y==floor_y+1,label+": jewel begins at first native solid+1")
		check(model.terrain.native_solid(Vector2i(point.x,point.y-1)),label+": original alpha supports jewel")
		check(int(entity.type) in [0,1,2,3] and not seen.has(int(entity.slot)),label+": valid type and unique physical slot")
		seen[int(entity.slot)]=true
	var copy = Snapshot.capture(model)
	var before := key_state(model)
	copy.jewel_state.scores[0]=99
	copy.jewel_state.rng=123
	copy.jewel_state.entities[0].damage=299
	copy.jewel_state.entities[0].owner=1
	copy.jewel_state.entities[0].pos+=Vector2i(7,-7)
	copy.jewel_state.events.append({"type":"private"})
	var first := Vector2i(model.jewel_state.entities[0].pos)
	copy.terrain.carve(Vector2(first),18)
	check(copy.terrain.revision!=model.terrain.revision,label+": copied terrain crater is private")
	assert_live(model,before,label+" deep snapshot")
	# Exercise each native type with a real map mask, direct objective blast,
	# tick removal, last-author attribution, negative floor and result latch.
	var x := first.x
	for kind in 4:
		copy=Snapshot.capture(model)
		copy.jewel_state=Rules.create(copy.terrain,4400+kind)
		check(Rules.spawn(copy.jewel_state,copy.terrain,x,[0,15,40,80][kind]),label+": forced type has real support")
		copy.step_jewels(Combat.STEP)
		var entity: Dictionary=copy.jewel_state.entities[0]
		var point := Vector2i(entity.pos)-Vector2i(0,10)
		copy.jewel_state.scores=[0,4]
		Objective.native_blast(copy,point,{"power":int(entity.resistance)-1,"dimension":60,"aspect":100},0)
		check(entity.owner==0 and entity.damage==int(entity.resistance)-1,label+": first author and resistance−1")
		copy.step_jewels(Combat.STEP)
		check(not entity.removed and copy.jewel_state.scores==[0,4],label+": no early points")
		Objective.native_blast(copy,point,{"power":1,"dimension":60,"aspect":100},1)
		copy.step_jewels(Combat.STEP)
		check(entity.removed and entity.owner==1,label+": final author wins exact resistance")
		check(copy.jewel_state.scores==[0,[29,14,9,0][kind]],label+": native type score and zero floor")
		var score_before: Array=copy.jewel_state.scores.duplicate()
		copy.step_jewels(Combat.STEP)
		check(copy.jewel_state.scores==score_before,label+": removal cannot credit twice")
	assert_live(model,before,label+" copied type matrix")
	copy=Snapshot.capture(model)
	copy.jewel_state.scores=[100,0]
	check(copy.check_end() and copy.winner==0 and model.winner==-1,label+": copied JEWEL result cannot finish live match")
	check(not model.check_end(),label+": initial JEWEL cannot end from pilot HP")

func shot_case(model, angle: float, power: float, weapon: int, label: String) -> void:
	var actor_index: int=model.active
	var baseline := key_state(model)
	var prediction: Dictionary=model.predict_shot(actor_index,angle,power,weapon)
	check(prediction.has("jewel_scores") and prediction.has("jewel_damage") and prediction.has("jewel_winner"),label+": full objective result published")
	check(prediction.jewel_scores.size()==2 and typeof(prediction.jewel_scores[0])==TYPE_INT and typeof(prediction.jewel_scores[1])==TYPE_INT,label+": complete integer team scores")
	assert_live(model,baseline,label+" prediction")
	var simulation=Snapshot.capture(model)
	Snapshot.arm(simulation,actor_index,weapon,model.shot_shells(actor_index,angle,power,weapon))
	check(model.fire(angle,power,weapon),label+": legal shot accepted")
	var closest: Dictionary={}
	var distance := INF
	var target: Vector2=baseline.actors[1-actor_index].pos
	for frame in 1300:
		model.advance_projectiles(Combat.STEP)
		simulation.advance_projectiles(Combat.STEP)
		for event in model.events:
			if event.type not in ["explosion","miss","teleport","thor","mine_plant"]:continue
			var next_distance := Vector2(event.position).distance_to(target)
			if next_distance<distance:
				distance=next_distance
				closest={"position":event.position,"actor":event.get("collided_actor",-1),"hit":event.type!="miss"}
		model.events.clear()
		simulation.events.clear()
		if model.phase!=Model.PHASE_FLIGHT and simulation.phase!=Model.PHASE_FLIGHT:break
	check(model.phase!=Model.PHASE_FLIGHT and simulation.phase!=Model.PHASE_FLIGHT,label+": complete volley/children terminate with original guards")
	for settle in 360:
		if model.phase==Model.PHASE_FINISHED or not Objective.pending(model):break
		model.advance_idle_tick(Combat.STEP)
		simulation.advance_idle_tick(Combat.STEP)
		model.events.clear()
		simulation.events.clear()
	if closest.is_empty():closest={"position":model.muzzle(actor_index,angle,weapon),"actor":-1,"hit":false}
	closest.jewel_scores=model.jewel_state.scores.duplicate()
	closest.jewel_damage=Objective.progress(model.jewel_state,actor_index)
	closest.jewel_winner=model.winner
	check(prediction==closest,label+": entire predicted volley outcome equals real flight and delayed bunge")
	check(model.jewel_state==simulation.jewel_state,label+": every objective field agrees with snapshot execution")
	check(model.terrain.cells==simulation.terrain.cells and model.terrain.native_cells==simulation.terrain.native_cells,label+": both collision masks agree")
	for actor in 2:
		check(model.actors[actor].hp==simulation.actors[actor].hp and model.actors[actor].shield==simulation.actors[actor].shield and model.actors[actor].pos==simulation.actors[actor].pos,label+": pilot state agrees")
	shots+=1

static func worker_candidate(plan: Dictionary) -> void:
	# This worker receives only the plan's closed snapshot and value fields.
	plan.outcome=plan.snapshot.predict_shot(plan.actor,45,40,plan.weapon)
	Model.score_cpu_shot(plan,45,40)

func cpu_case(model, label: String) -> void:
	model.active=1
	var plan: Dictionary=model.begin_cpu_plan()
	var saved_jewels: Dictionary=model.jewel_state.duplicate(true)
	var saved_terrain=model.terrain.collision_copy()
	var saved_weather=model.weather.copy()
	var saved_wind: Vector2=model.wind
	var expected: Dictionary=plan.snapshot.predict_shot(plan.actor,45,40,plan.weapon)
	# Change only the live source after capture. A worker consulting live masks,
	# objective totals or weather will now disagree with the captured outcome.
	model.jewel_state.scores[0]=75
	var at := Vector2(model.jewel_state.entities[0].pos)
	model.jewel_state.entities[0].pos=Vector2i(-500,-500)
	model.terrain.carve(at,30)
	model.weather.columns.clear()
	model.wind=Vector2(100,-50)
	var baseline := key_state(model)
	check(plan.snapshot.terrain!=model.terrain and plan.snapshot.mode=="jewel",label+": CPU owns JEWEL collision snapshot")
	plan.best_score=INF
	var thread := Thread.new()
	var error := thread.start(worker_candidate.bind(plan))
	check(error==OK,label+": isolated CPU candidate starts on worker")
	if error==OK:thread.wait_to_finish()
	check(plan.has("outcome") and plan.outcome.has("jewel_scores") and plan.outcome.has("jewel_damage") and plan.outcome.has("jewel_winner"),label+": worker evaluates entire objective result")
	check(plan.get("outcome",{})==expected,label+": live edits cannot change captured worker outcome")
	check(is_finite(float(plan.best_score)),label+": CPU candidate objective has finite score")
	assert_live(model,baseline,label+" CPU worker")
	var selected: Dictionary=model.finish_cpu_plan(plan)
	check(plan.snapshot==null and not model.cpu_thinking and selected.has("angle") and selected.has("power"),label+": worker plan releases private snapshot")
	model.jewel_state=saved_jewels
	model.terrain=saved_terrain
	model.weather=saved_weather
	model.wind=saved_wind
	shot_case(model,45,40,int(plan.weapon),label+" CPU role full volley")
	worker_cases+=1

func run() -> void:
	var ids := Maps.available_ids()
	check(ids.size()==22,"JEWEL matrix requires every one of22 classic sides")
	var worlds := {}
	var widths := {}
	for map_index in ids.size():
		var id: String=ids[map_index]
		var map := Maps.get_map(id)
		worlds[int(map.family)]=true
		widths[int(map.world_size.x)]=true
		var rng := RandomNumberGenerator.new()
		rng.seed=7000+map_index
		var context: Dictionary=Choice.resolve(id,rng)
		check(context.get("map_id","")==id and context.get("spawns",[]).size()==2,id+": room/loading spawn policy resolves")
		if context.is_empty():continue
		var model=start_game(id,2,7400+map_index,context.spawns)
		check(model.map_id==id and model.mode=="jewel" and model.terrain.world_size()==map.world_size,id+": selected mode and world geometry preserved")
		objective_on_map(model,id)
		cpu_case(model,id)
		for representative in REPRESENTATIVES.size():
			var vehicle: int=REPRESENTATIVES[representative]
			var weapon := (map_index+representative)%3
			model=start_game(id,vehicle,7800+map_index,context.spawns)
			shot_case(model,45,35,weapon,"%s mobile%d T%d" % [id,vehicle,weapon])
		# SOLO stays the default separate objective on every side.
		var solo=Model.new()
		solo.start(2,1,8200+map_index,id,"original",null,[],[],[],0,1,context.spawns)
		check(solo.mode=="solo" and solo.jewel_state.is_empty(),id+": omitted mode remains SOLO without jewels")
		var shield_before: int=solo.actors[1].shield
		var hp_before: int=solo.actors[1].hp
		Damage.deal_damage(solo.actors,solo.events,1,99999)
		check(solo.actors[1].hp<hp_before or solo.actors[1].shield<shield_before,id+": SOLO pilot damage still applies")
		check(solo.check_end() and solo.winner==0,id+": SOLO still ends by elimination")
		# Distinct item bridges and native weather remain sampled across all
		# worlds, with full real/prediction equality rather than numeric parity.
		if map_index%2==0:
			var item: String=["dual","dual_plus","thunder","teleport"][int(map_index/2)%4]
			model=start_game(id,1,8600+map_index,context.spawns,"jewel",[item])
			if model.items_locked():model.weather.queue[0].type="wind"
			check(model.use_item(0),id+": representative item accepted "+item)
			shot_case(model,40,35,0,id+" item "+item)
		print("JEWEL MAP id=",id," shots=",shots," workers=",worker_cases)
	check(worlds.size()==11,"JEWEL integration spans all11 native worlds")
	check(widths.has(1600) and widths.has(1800) and widths.has(2000),"JEWEL covers1600/1800/2000 native world widths")
	check(shots==209 and worker_cases==22,"176 representative shots+11item volleys+22CPU role volleys and22worker candidates")
	finish("JEWEL MAPS CHECKS")
