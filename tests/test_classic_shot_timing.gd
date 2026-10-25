extends "res://tests/support/suite.gd"
const Mobiles = preload("res://scripts/mobiles.gd")
const Match = preload("res://scripts/match.gd")
const Art = preload("res://scripts/battle_art.gd")

func run() -> void:
	for pair in [[4,1,14], [4,2,14], [11,0,13], [7,0,11]]:
		var shells: Array = Mobiles.emission(pair[0],pair[1])
		check(is_equal_approx(float(shells[0].spawn), pair[2] * 0.05), "MainAction tick %s" % str(pair))
	for id in range(1,17):
		for weapon in 3:
			var source: Dictionary = Mobiles.ShotTiming.shot(id,weapon)
			var emitted: Array = Mobiles.emission(id,weapon)
			var cursor := 0
			for group in source.spawn_ticks.size():
				for component in int(source.components_per_spawn[group]):
					check(is_equal_approx(float(emitted[cursor].spawn),int(source.spawn_ticks[group])*0.05) and bool(emitted[cursor].sound) == (component == 0),"48 source contracts: ID%d weapon%d group%d component%d" % [id,weapon,group,component])
					cursor += 1
			check(cursor == emitted.size(),"Source total component count ID%d weapon%d" % [id,weapon])
	var boomer := Mobiles.emission(6,1)
	for i in 4:
		check(is_equal_approx(float(boomer[i].spawn),(8+i*2)*0.05),"Boomer four source spawns without double delay")
	var model = Match.new()
	model.start(4,1,42,"", "original", null, ["dual"])
	model.actors[0].ss_lock = 0
	model.use_item(0)
	var dual: Array = model.shot_shells(0,40,60,1)
	var poses: Array = Match.second_volley(dual)
	check(not poses.is_empty() and float(poses[0].time) < float(dual[-1].spawn_at),"Dual starts second pose before source spawn")
	for fps in [30,60,120]:
		for pair in [[1,1,1], [2,1,2], [5,1,1], [6,1,4], [7,1,1], [16,2,3]]:
			model = Match.new()
			model.start(pair[0],1,42,"","original")
			model.actors[0].ss_lock = 0
			model.fire(40,60,pair[1])
			var sounds := 0
			var launches := 0
			for _frame in range(fps*2):
				for event in model.events:
					if event.type == "projectile_launch":
						launches += 1
						if bool(event.get("sound",true)): sounds += 1
				model.events.clear()
				model.tick(1.0/fps)
			check(sounds == pair[2],"%dFPS one audio event per spawn group %s (%d/%d launches)" % [fps,str(pair),sounds,launches])
	model = Match.new()
	model.start(4,1,42,"","original")
	var art = Art.new()
	art.reset(model.actors)
	art.react({"type":"fire","actor":0,"vehicle":4,"weapon":1})
	check(is_equal_approx(float(art.motion[0].recoil), 1.25),"Armor recoil duration follows fire2 EPA")
	finish("CLASSIC SHOT TIMING CHECKS")
