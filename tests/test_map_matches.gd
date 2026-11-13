extends SceneTree
const Match = preload("res://scripts/match.gd")
const Maps = preload("res://scripts/maps.gd")
const Partition = preload("res://tests/support/match_partition.gd")
func _initialize() -> void:
	var failures := 0
	var cases := Partition.select(range(44),OS.get_cmdline_user_args())
	var ids := Maps.available_ids()
	if ids.size()!=22 or cases.is_empty():
		printerr("FAIL: expected22map sides and valid partition")
		quit(1)
		return
	for index in cases:
		var id: String = ids[int(index)/2]
		var model = Match.new()
		model.start(2 if index%2==0 else 3,2,4500+index,id,"original",null,[],[],[],index%2)
		var shots := 0
		var results := 0
		for frame in 90000:
			if model.phase==Match.PHASE_FINISHED:break
			if model.phase==Match.PHASE_AIM:
				var shot: Dictionary = model.choose_cpu_shot()
				if not model.fire(shot.angle,shot.power,shot.weapon):
					failures += 1
					break
				shots += 1
			model.tick(1.0/30.0)
			for event in model.events:
				if event.type=="finished":results+=1
			model.events.clear()
		if model.phase!=Match.PHASE_FINISHED or results!=1 or shots==0:
			printerr("FAIL: map match case ",index," ",id," phase ",model.phase)
			failures+=1
		print("MAP MATCH id=",index," map=",id," seed=",4500+index," shots=",shots," winner=",model.winner)
	print("COMPLETE MATCHES: ",cases.size()," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
