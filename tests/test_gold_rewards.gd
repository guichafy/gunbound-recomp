extends "res://tests/support/suite.gd"

func test_mine_credit() -> void:
	var Match = load("res://scripts/match.gd")
	var Combat = load("res://scripts/combat.gd")
	var Classic = load("res://scripts/classic_flight.gd")
	for scenario in [[0, 1], [1, 0], [1, 1]]:
		var owner: int = scenario[0]
		var target: int = scenario[1]
		var model = Match.new()
		model.start(7, 1, 7, "")
		model.weather.columns.clear()
		model.weather.thor.active = false
		model.fire(30, 40, 1)
		model.actors[target].hp = 1
		model.actors[target].shield = 0
		model.mines = [{"owner": owner, "pos": Combat.full_hit(model.actors[target], 21.0), "radius": 21.0,
			"damage": 400, "weapon": 2, "vehicle": 7}]
		Classic._detonate_mine(model, 0)
		model.finish_gold_shot()
		check(model.shot_actor == 0, "Mine Gold never replaces the firing actor")
		var expected_gold := -60 if target == owner else 40
		var enemy_damage := 0 if target == owner else 400
		check(int(model.actors[owner].gold_state.gold) == expected_gold and int(model.actors[owner].gold_state.enemy_damage) == enemy_damage,
			"Mine owner %d receives the damage and kill credit against actor %d" % [owner, target])
		check(int(model.actors[1 - owner].gold_state.gold) == 0, "A foreign mine cannot award the current shooter an unrelated suicide or kill")
		var credit: Dictionary = model.actors[owner].gold_state.duplicate(true)
		model.finish_gold_shot()
		model.check_end()
		model.tick(1.0 / 30.0)
		check(model.actors[owner].gold_state == credit, "Mine damage and kill are credited once")

func run() -> void:
	test_mine_credit()
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
		m.start(2,1,42,"","original",null,[],[[0,0,0,0,0,0,0,50]])
		m.actors[1].pos = m.muzzle(0,30)
		m.fire(30,65,0)
		var contact: Vector2 = load("res://scripts/combat.gd").full_hit(m.actors[1], 25.0)
		m.explode(contact,1,m.projectiles[0])
		check(m.shot_gold.enemy_damage == 90, "Live damage informs Gold")
		m.explode(contact,1,m.projectiles[1])
		m.finish_gold_shot()
		var before: int = m.actors[0].gold_state.gold
		m.finish_gold_shot()
		check(before > 0 and m.actors[0].gold_state.gold == before, "Shot credit once")
		for mobile in [1,2]:
			for facing in [1,-1]:
				m.start(mobile,1,42,"")
				m.terrain.cells.fill(0)
				m.actors[0].pos = Vector2(240,100)
				m.actors[0].facing = facing
				m.fire(30,65,0)
				# Native LUT/truncation at P292 (Mage) and P273 (Bigfoot),
				# rather than an exact continuous 30-degree vector.
				var native_velocity: Vector2 = Vector2(6451,-3737) if mobile == 1 else Vector2(6041,-3481)
				native_velocity.x *= facing
				var expected_angle := fposmod(rad_to_deg(native_velocity.angle()) + 180.0, 360.0)
				check(is_equal_approx(float(m.shot_gold.angle),expected_angle), "Source HUD angle uses quantized central trajectory")
				m.events = [{"type":"damage","actor":1,"amount":200}]
				m.collect_gold_damage(0,Vector2(240+100*facing,100),{"age":1,"influenced":[]})
				check(not m.shot_gold.boomer and not m.shot_gold.backward, "Normal forward shot no Boomer")
				m.events.clear()
				m.collect_gold_damage(0,Vector2(240-100*facing,100),{"age":5,"influenced":["mirror","tornado"]})
				check(m.shot_gold.travelled == 1 and not m.shot_gold.mirror and not m.shot_gold.tornado and not m.shot_gold.backward, "Zero damage pellet cannot contaminate bonuses")
	finish("GOLD REWARDS CHECKS")
