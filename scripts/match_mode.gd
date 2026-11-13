extends RefCounted
## Objective policy. SOLO remains the default; JEWEL never substitutes team
## alternation for initiative. Native contracts: JEWEL_IMPLEMENTATION.md.
const SOLO := "solo"
const JEWEL := "jewel"

static func normalize(value: String) -> String:
	return JEWEL if value==JEWEL else SOLO

static func setup(model, value: String) -> void:
	model.mode=normalize(value)
	for actor in model.actors:
		actor.jewel_mode=model.mode==JEWEL
		actor.jewel_waiting=false
		actor.jewel_respawn_turn=-1
		actor.jewel_respawn_x=0.0
	model.jewel_state=model.JewelRules.initial(model.terrain,int(model.rng.seed)) if model.mode==JEWEL else {}

static func fall(model, index: int) -> bool:
	if model.mode!=JEWEL:return false
	var actor: Dictionary=model.actors[index]
	if bool(actor.jewel_waiting):return true
	actor.jewel_waiting=true
	actor.invulnerable=true
	actor.jewel_respawn_turn=-1
	model.events.append({"type":"jewel_waiting","actor":index,"position":actor.pos})
	# Offline CPU chooses its previous X immediately. Human choice stays a
	# map click. The client supplies no offline AI policy for that choice.
	if index==model.CPU:choose_respawn(model,index,float(actor.pos.x))
	return true

static func choose_respawn(model, index: int, x: float) -> bool:
	if model.mode!=JEWEL or index<0 or index>=model.actors.size() or model.phase==model.PHASE_FINISHED:return false
	var actor: Dictionary=model.actors[index]
	if not bool(actor.jewel_waiting) or int(actor.jewel_respawn_turn)>=0:return false
	actor.jewel_respawn_x=clampf(floorf(x),model.WORLD_MARGIN,model.terrain.world_size().x-model.WORLD_MARGIN)
	actor.jewel_respawn_turn=model.total_turns+2
	model.events.append({"type":"jewel_return_selected","actor":index,"position":Vector2(actor.jewel_respawn_x,0)})
	return true

static func begin_turn(model) -> void:
	if model.mode!=JEWEL:return
	if model.total_turns>1:model.JewelRules.next_turn(model.jewel_state,model.terrain)
	for index in model.actors.size():
		var actor: Dictionary=model.actors[index]
		if not bool(actor.jewel_waiting) or int(actor.jewel_respawn_turn)<0 or model.total_turns<int(actor.jewel_respawn_turn):continue
		actor.jewel_waiting=false
		actor.invulnerable=false
		actor.jewel_respawn_turn=-1
		actor.hp=actor.max_hp
		actor.shield=actor.max_shield
		# Existing offline support resolver is the declared return/drop bridge.
		actor.pos=Vector2(actor.jewel_respawn_x,0)
		model.events.append({"type":"jewel_return","actor":index,"position":actor.pos})

static func check_end(model) -> bool:
	if model.mode!=JEWEL:return false
	if model.phase==model.PHASE_FINISHED:return true
	var score: Array=model.jewel_state.scores
	if maxi(int(score[0]),int(score[1]))<100:return false
	model.winner=1 if int(score[1])>int(score[0]) else 0
	model.jewel_state.finished=true
	model.phase=model.PHASE_FINISHED
	model.projectiles.clear()
	model.battle_effects.clear()
	model.events.append({"type":"finished","winner":model.winner})
	return true
