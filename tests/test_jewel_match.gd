extends "res://tests/support/suite.gd"
const MatchModel = preload("res://scripts/match.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Damage = preload("res://scripts/damage.gd")

func game(kind: int = 2, mode: String = "jewel"):
	var model = MatchModel.new()
	model.start(kind,1,46,"","original",null,[],[],[],0,-1,[],mode)
	return model

func run() -> void:
	var model = game()
	check(model.mode=="jewel", "Explicit JEWEL mode")
	check(not model.jewel_state.entities.is_empty(), "Initial entities")
	var original_hp: int = model.actors[0].hp
	var original_shield: int = model.actors[0].shield
	Damage.deal_damage(model.actors,model.events,0,9999)
	check(model.actors[0].hp==original_hp and model.actors[0].shield==original_shield,"JEWEL gates pilot damage")
	check(model.events.any(func(event):return event.type=="pilot_hit"),"Immunity preserves a presentation-only pilot hit")
	check(not model.events.any(func(event):return event.type in ["damage","shield_damage"]),"JEWEL hit gives no fake damage/Gold/XP")
	var art=load("res://scripts/battle_art.gd").new()
	art.reset(model.actors)
	for event in model.events:art.react(event)
	check(float(art.motion[0].hurt)>0,"Native hurt pose survives HP immunity")
	check(not model.check_end(),"Pilot HP is not JEWEL objective")
	var copy = Snapshot.capture(model)
	copy.jewel_state.scores[0]=75
	copy.jewel_state.entities[0].damage=999
	check(model.jewel_state.scores[0]==0 and model.jewel_state.entities[0].damage==0,"Snapshot deep copies objective")
	model.kill_by_fall(0)
	check(model.actors[0].jewel_waiting and model.actors[0].hp==original_hp,"Void enters waiting without SOLO death")
	check(not model.fire(45,50,0),"Waiting pilot cannot fire")
	check(model.choose_respawn(0,400),"Human chooses return X")
	var deadline: int = model.actors[0].jewel_respawn_turn
	check(deadline==model.total_turns+2,"Return two transitions after choice")
	model.total_turns=deadline-2
	model.begin_turn()
	check(model.actors[0].jewel_waiting,"Return not early")
	model.begin_turn()
	check(not model.actors[0].jewel_waiting and model.actors[0].hp==model.actors[0].max_hp,"Return at exact transition restores HP")
	model.jewel_state.scores=[100,75]
	check(model.check_end() and model.winner==0,"Target ends JEWEL")
	var ends: int = model.events.filter(func(event):return event.type=="finished").size()
	model.check_end()
	check(model.events.filter(func(event):return event.type=="finished").size()==ends,"Finish event once")
	var solo = game(2,"solo")
	Damage.deal_damage(solo.actors,solo.events,0,9999)
	check(solo.check_end() and solo.winner==1,"SOLO elimination preserved")
	finish("JEWEL MATCH CHECKS")
