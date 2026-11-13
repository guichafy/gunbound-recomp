extends "res://tests/support/suite.gd"
## Catches material selection, signed truncation, contact edges and lifecycle gates.
const Terrain = preload("res://scripts/terrain.gd")
var Rules

func ground(empty: bool = false):
	var terrain = Terrain.new()
	terrain.WIDTH = 160
	terrain.HEIGHT = 120
	terrain.cells.resize(160*120)
	terrain.cells.fill(0)
	terrain.native_cells.resize(320*240)
	terrain.native_cells.fill(0)
	if not empty:
		for y in range(100,240):
			for x in 320:
				terrain.native_cells[y*320+x] = 1
	return terrain

func run() -> void:
	check(ResourceLoader.exists("res://scripts/jewel_rules.gd"), "JEWEL rules module exists")
	if not ResourceLoader.exists("res://scripts/jewel_rules.gd"):
		finish("JEWEL RULES CHECKS")
		return
	Rules = load("res://scripts/jewel_rules.gd")
	var terrain = ground()
	var state: Dictionary = Rules.create(terrain,1)
	check(state.entities.is_empty() and state.scores == [0,0] and not state.finished, "creation does not insert entities or finish")
	var life: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/jewel-implementation/lifecycle/lifecycle-fixtures.json"))
	for row in life.kind_boundaries:
		var sample: Dictionary = Rules.create(terrain,1)
		check(Rules.spawn(sample,terrain,100,int(row.roll)), "spawn accepts column with native mask")
		check(int(sample.entities[0].type) == int(row.kind), "native roll boundary %d" % int(row.roll))
	for index in 8:
		check(Rules.spawn(state,terrain,100,index*10), "slot %d available" % index)
	check(not Rules.spawn(state,terrain,100,0), "ninth spawn refused")
	check(not Rules.spawn(Rules.create(terrain,1),terrain,-1,0), "invalid X refused")
	check(not Rules.spawn(Rules.create(terrain,1),ground(true),100,0), "column without solid refused")
	for row in [[89,90,false],[90,90,true],[110,90,true],[111,90,false],[100,79,false],[100,80,true],[100,100,true],[100,101,false]]:
		var sample: Dictionary = Rules.create(terrain,1)
		Rules.spawn(sample,terrain,100,0)
		sample.entities[0].pos = Vector2i(100,100)
		check((Rules.hit(sample,Vector2i(row[0],row[1]))>=0)==bool(row[2]), "inclusive contact %s" % str(row))
	var fixtures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/jewel-implementation/damage/damage-fixtures.json"))
	for row in fixtures.blast:
		var p: Dictionary = row.input
		var sample: Dictionary = Rules.create(terrain,1)
		Rules.spawn(sample,terrain,100,0)
		var jewel: Dictionary = sample.entities[0]
		jewel.pos = Vector2i(int(p.get("jx",100)),int(p.get("jy",100)))
		jewel.damage = int(p.get("old_damage",0))
		jewel.owner = int(p.get("old_owner",7))
		jewel.removed = int(p.get("removed",0)) != 0
		jewel.drop = bool(p.get("dropping",false))
		# Dispatcher excludes all removed entities; direct PE routine excludes only1.
		if int(p.get("removed",0))==2:
			continue
		sample.blocked = bool(p.get("global_blocked",false))
		var shot := {"power":[],"dimension":[],"aspect":[],"material":int(p.get("stage_coef",0)),"percent":int(p.get("percent",100)),"bonus":int(p.get("bonus",0)),"force":int(p.get("force",0)),"owner":int(p.get("owner",1)),"scale":int(p.get("scale",100))}
		for kind in 3:
			for key in ["power","dimension","aspect"]:
				shot[key].append(int(p.get(key+str(kind),p.get(key,{"power":200,"dimension":60,"aspect":100}[key]))))
		Rules.blast(sample,Vector2i(int(p.get("ix",100)),int(p.get("iy",90))),shot)
		check(jewel.damage==int(row.output.damage) and jewel.owner==int(row.output.owner), "PE blast fixture %s" % str(p))
	for kind in 4:
		var sample: Dictionary = Rules.create(terrain,1)
		Rules.spawn(sample,terrain,100,[0,15,40,80][kind])
		sample.scores=[0,20]
		sample.entities[0].owner=1
		sample.entities[0].damage=sample.entities[0].resistance
		Rules.tick(sample,terrain,0.05)
		check(sample.scores==[0,[45,30,25,15][kind]] and sample.entities[0].removed,"score kind %d" % kind)
		Rules.tick(sample,terrain,0.05)
		check(sample.scores==[0,[45,30,25,15][kind]],"removed jewel cannot score twice")
	for owner in [-1,255]:
		var sample: Dictionary=Rules.create(terrain,1)
		Rules.spawn(sample,terrain,100,0)
		sample.entities[0].owner=owner
		sample.entities[0].damage=300
		Rules.tick(sample,terrain,0.05)
		check(sample.scores==[0,0],"unknown author does not score")
	var falling: Dictionary=Rules.create(terrain,1)
	Rules.spawn(falling,terrain,100,0,true)
	falling.entities[0].owner=0
	falling.entities[0].damage=300
	Rules.tick(falling,terrain,0.05)
	check(falling.entities[0].removed and falling.scores==[0,0],"drop removal does not score")
	check(bool(falling.events[0].effect),"Native drop destruction still emits Jflame after score branch is skipped")
	var win: Dictionary=Rules.create(terrain,1)
	Rules.spawn(win,terrain,100,0)
	win.scores=[75,0]
	win.entities[0].owner=0
	win.entities[0].damage=300
	Rules.tick(win,terrain,0.05)
	check(win.finished and win.winner==0 and win.scores==[100,0],"target100 finishes once")
	var negative: Dictionary=Rules.create(terrain,1)
	Rules.spawn(negative,terrain,100,80)
	negative.scores=[4,0]
	negative.entities[0].owner=0
	negative.entities[0].damage=100
	Rules.tick(negative,terrain,0.05)
	check(negative.scores==[0,0],"negative score clamps zero")
	var initial: Dictionary=Rules.initial(terrain,1)
	check(initial.entities.size()==6,"initial emits six attempts on solid mask")
	check(initial==Rules.initial(terrain,1),"private CRT deterministic")
	Rules.next_turn(initial,terrain)
	check(initial.entities.size()==6 and initial.turn==1,"six established block replacement")
	initial.entities[0].removed=true
	Rules.next_turn(initial,terrain)
	check(initial.entities.size()==6 and initial.entities[0].drop and initial.entities[0].slot==0,"one drop reuses first free slot")
	var timing: Dictionary=Rules.create(terrain,1)
	Rules.spawn(timing,terrain,100,0,true)
	Rules.tick(timing,terrain,0.025)
	check(timing.entities[0].pos==Vector2i(100,0),"subtick does not move collision position")
	Rules.tick(timing,terrain,0.025)
	check(timing.entities[0].pos==Vector2i(100,1) and int(timing.entities[0].get("pose_tick",-1))==1,"native first fall tick and pose index")
	var partition: Dictionary=Rules.create(terrain,1)
	Rules.spawn(partition,terrain,100,0,true)
	Rules.tick(partition,terrain,0.05)
	check(partition==timing,"partitioned dt produces identical state")
	check(win.get("events",[]).size()==2,"scored removal emits score and removal events exactly once")
	var missing: Dictionary=Rules.create(terrain,1)
	Rules.spawn(missing,terrain,100,0,true)
	Rules.tick(missing,ground(true),2.0)
	check(missing.entities[0].removed and missing.scores==[0,0],"unsupported drop leaves world without scoring")
	var motion: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/jewel-implementation/damage/damage-tick-fixtures.json"))
	for scenario in motion.scenarios:
		var p: Dictionary=scenario.input
		var mask=ground(bool(p.get("void",false)))
		if not bool(p.get("void",false)):
			mask.native_cells.fill(0)
			for x in 320:
				var top := 100+int((x-100)*float(p.get("slope",0.0)))
				for y in range(maxi(0,top),240):
					mask.native_cells[y*320+x]=1
		var sample: Dictionary=Rules.create(mask,1)
		Rules.spawn(sample,mask,100,0,true)
		var entity: Dictionary=sample.entities[0]
		entity.pos=Vector2i(int(p.get("x",100)),int(p.get("y",0)))
		entity.fall=int(p.get("fall",0))
		entity.drop=bool(p.get("drop",true))
		entity.pose=["normal","drop","shock","damage","say"][int(p.get("pose",1))]
		entity.owner=int(p.get("owner",-1))
		sample.terrain_owner=3
		sample.wind=int(p.get("wind",0))
		sample.wind_angle=int(p.get("wind_angle",0))
		for index in scenario.ticks.size():
			var want: Dictionary=scenario.ticks[index]
			Rules.tick(sample,mask,0.05)
			var actual := [entity.pos.x,entity.pos.y,entity.fall,int(entity.get("drift",0)),int(entity.angle),entity.drop,entity.pose,int(entity.pose_tick)%20,entity.owner,entity.removed]
			var expected := [int(want.x),int(want.y),int(want.fall),int(want.drift),int(want.angle),bool(want.drop),["normal","drop","shock","damage","say"][int(want.pose)],int(want.frame),int(want.owner),bool(want.removed)]
			check(actual==expected,"native tick %s #%d got%s want%s" % [str(p),index,str(actual),str(expected)])
	finish("JEWEL RULES CHECKS")
