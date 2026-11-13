extends "res://tests/support/suite.gd"
## Natural offline CPU matches: objective score only, no forced victory.
const Model = preload("res://scripts/match.gd")
const Partition = preload("res://tests/support/match_partition.gd")

func run() -> void:
	var cases := Partition.select(range(1,31),OS.get_cmdline_user_args())
	check(not cases.is_empty(),"Valid JEWEL partition")
	var map_ids: Array=Model.Maps.available_ids()
	check(map_ids.size()==22,"JEWEL natural inventory covers all22map sides")
	for case_id in cases:
		var vehicle:int=case_id if case_id<=8 else 2
		var opponent:int=vehicle+8 if case_id<=8 else 1
		var map_id:String=Model.Maps.DEFAULT if case_id<=8 else str(map_ids[case_id-9])
		var model = Model.new()
		model.start(vehicle,2,4600+case_id,map_id,"original",null,[],[],[],0 if case_id<=8 else case_id%2,opponent,[],"jewel")
		var shots := 0
		var finishes := 0
		for frame in 90000:
			if model.phase==Model.PHASE_FINISHED:break
			if model.phase==Model.PHASE_AIM and not bool(model.actors[model.active].jewel_waiting):
				var plan: Dictionary=model.choose_cpu_shot()
				check(model.fire(plan.angle,plan.power,plan.weapon),"JEWEL CPU shot accepted")
				shots+=1
			elif model.phase==Model.PHASE_AIM and model.actors[model.active].jewel_respawn_turn<0:
				# A test bot replaces the human's map click, not a runtime rule.
				model.choose_respawn(model.active,float(model.actors[model.active].pos.x))
			model.tick(1.0/20.0)
			for event in model.events:
				if event.type=="finished":finishes+=1
			model.events.clear()
		check(model.phase==Model.PHASE_FINISHED and finishes==1,"JEWEL natural match finishes exactly once")
		check(model.winner in [0,1] and model.jewel_state.scores[model.winner]>=100,"JEWEL wins by target score")
		check(shots>0,"JEWEL match fired shots")
		print("JEWEL MATCH id=",case_id," map=",map_id," seed=",4600+case_id," shots=",shots," scores=",model.jewel_state.scores," winner=",model.winner)
	print("JEWEL MATCHES: ",cases.size()," | FAILURES: ",failures)
	finish("JEWEL MATCHES CHECKS")
