extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(FileAccess.file_exists("res://scripts/gold_rewards.gd"), "Gold scoring exists")
	if failures == 0:
		var G = load("res://scripts/gold_rewards.gd")
		var state := {"gold":0,"enemy_damage":0}
		var shot := {"enemy_damage":200,"ally_damage":0,"enemy_kills":0,"ally_kills":0,"angle":30.0,"travelled":1.0,"tornado":false,"mirror":false,"boomer":false,"backward":false}
		var next: Dictionary = G.apply_shot(state,shot,50)
		check(next.gold == 7 and state.gold == 0, "Popularity truncates without mutating")
		next = G.apply_shot(next,shot,50)
		check(next.gold == 18, "Source accumulative Popularity")
		check(G.result_bonus(true,false) == 4 and G.result_bonus(false,false) == 1 and G.result_bonus(false,true) == 0, "Source result4/1, draw0")
		for data in [[150,0],[151,5],[250,5],[251,10],[500,10],[501,15]]:
			shot.enemy_damage = data[0]
			check(G.apply_shot(state,shot,0).gold == data[1], "Damage tier "+str(data[0]))
		shot.enemy_damage = 200
		shot.angle = 90
		for data in [[2.5,5],[2.51,10],[4.0,10],[4.01,15]]:
			shot.travelled = data[0]
			check(G.apply_shot(state,shot,0).gold == data[1], "Flight tier "+str(data[0]))
		shot.angle = 30
		shot.travelled = 1
		shot.ally_damage = 31
		shot.enemy_kills = 1
		check(G.apply_shot(state,shot,0).gold == 25, "Enemy kill and friendly penalty")
		shot.ally_damage = 0
		shot.enemy_kills = 0
		check(G.apply_shot({"gold":0,"enemy_damage":900},shot,0).gold == 15, "1000 milestone")
		check(G.apply_shot({"gold":0,"enemy_damage":1900},shot,0).gold == 5, "Source unreachable2000")
		var m = load("res://scripts/match.gd").new()
		m.start(2,1,42,"","original",null,[[0,0,0,0,0,0,0,50]])
		m.actors[1].pos = m.muzzle(0,30)
		m.fire(30,65,0)
		m.explode(m.actors[1].pos,1,m.projectiles[0])
		check(m.shot_gold.enemy_damage == 90, "Live damage informs Gold")
		m.finish_gold_shot()
		var before: int = m.actors[0].gold_state.gold
		m.finish_gold_shot()
		check(before > 0 and m.actors[0].gold_state.gold == before, "Shot credit once")
	print("GOLD REWARDS CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
