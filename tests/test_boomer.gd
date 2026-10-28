extends "res://tests/support/suite.gd"
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Shell = preload("res://scripts/shell_state.gd")
const Boomer = preload("res://scripts/boomer_flight.gd")
const NativeWeather = preload("res://scripts/aduka_weather.gd")
const ClassicSprite = preload("res://scripts/classic_sprite.gd")
const Mobiles = preload("res://scripts/mobiles.gd")

func model_with_item(item: String = ""):
	var model = Match.new()
	model.start(6,1,42,"","original",null,[] if item.is_empty() else [item])
	model.actors[0].pos = Vector2(500,100)
	model.actors[1].pos = Vector2(1100,400)
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	if not item.is_empty():
		model.use_item(0)
	return model

func launch_clock() -> void:
	var model = model_with_item()
	var shells: Array = model.shot_shells(0,45,60,1)
	check(shells.size() == 4,"S2 four shells")
	for index in 4:
		check(is_equal_approx(float(shells[index].spawn_at),[0.4,0.5,0.6,0.7][index]),"S2 native spawn tick" + str(index))
		check(shells[index].pos == shells[0].pos and shells[index].velocity == shells[0].velocity,"S2 same aim power muzzle " + str(index))
	model.fire(45,60,1)
	var launches: Array = []
	for tick in range(1,16):
		model.tick(0.05)
		for event in model.events:
			if event.type == "projectile_launch":
				launches.append(tick)
		model.events.clear()
	check(launches == [8,10,12,14],"S2 actual native ticks8/10/12/14")
	for weapon in [0,2]:
		check(is_equal_approx(float(model.shot_shells(0,45,60,weapon)[0].spawn_at),0.4),"S1/SS tick8 " + str(weapon))

func transformation() -> void:
	var model = model_with_item()
	model.fire(87,60,2)
	for _i in 8:
		model.tick(0.05)
	var shell: Dictionary = model.projectiles[0]
	check(int(shell.flight_ticks) == 0,"emission boundary before first flight tick")
	for _i in 35:
		model.tick(0.05)
	check(int(shell.flight_ticks) == 35 and shell.ss_state == "normal","SS normal through35")
	Physics.import_external_motion(shell,Vector2(shell.pos.x,300),shell.velocity)
	shell.hit_pos = shell.pos
	model.weather.add_column("mirror",shell.pos.x,1)
	var position: Vector2i = shell.fp_pos
	var velocity: Vector2i = shell.fp_velocity
	for index in 10:
		model.tick(0.05)
		check(shell.fp_pos == position and shell.fp_velocity == velocity,"SS frozen tick" + str(index+36))
		check(shell.ss_state == "change" and int(shell.ss_state_tick) == index,"SS model change tick" + str(index+36))
	model.weather.columns.clear()
	model.tick(0.05)
	check(int(shell.flight_ticks) == 46 and shell.ss_state == "cnormal","SS resumes46")
	check(shell.fp_pos != position and int(shell.damage) == 700,"SS doubles damage and moves at46")
	check(is_equal_approx(float(shell.blast_radius),27.5),"SS scales diameter46→55 before radius")
	model.tick(0.05)
	check(int(shell.damage) == 700 and is_equal_approx(float(shell.blast_radius),27.5),"SS transforms only once")
	for item in ["dual","dual_plus"]:
		var dual = model_with_item(item)
		var both: Array = dual.shot_shells(0,90,60,2)
		check(both.size() >= 2,"SS with " + item)
		dual.seed_projectile(both[0])
		dual.seed_projectile(both[-1])
		Boomer.begin_tick(both[0])
		check(int(both[0].flight_ticks) == 1 and int(both[-1].flight_ticks) == 0,"independent flight clocks " + item)

func parity() -> void:
	for wind in [Vector2.ZERO,Vector2(26,0),Vector2(-26,0)]:
		for item in ["","dual","dual_plus"]:
			var model = model_with_item(item)
			model.wind = wind
			var weapon := 2 if item.is_empty() else 1
			model.actors[1].pos = Vector2(900,model.terrain.surface_at(900)-30)
			var predicted: Dictionary = model.predict_shot(0,45,25,weapon)
			check(model.fire(45,25,weapon),"legal Boomer shot " + item)
			var simulation = Snapshot.capture(model)
			Snapshot.arm(simulation,0,weapon,model.projectiles.duplicate(true))
			model.events.clear()
			var outcomes: Array = []
			for _i in 300:
				if model.phase != "flight":
					break
				model.tick(0.05)
				simulation.advance_projectiles(0.05)
				for event in model.events:
					if event.type in ["explosion","miss","teleport"]:
						outcomes.append(event)
				model.events.clear()
			var found := false
			for event in outcomes:
				found = found or (Vector2(event.position).distance_to(Vector2(predicted.position)) < 0.0001 and int(event.get("collided_actor",-1)) == int(predicted.actor))
			check(found,"real/predict same outcome wind" + str(wind) + " item" + item)
			var reference_outcomes: Array = []
			for event in simulation.events:
				if event.type in ["explosion","miss","teleport"]:
					reference_outcomes.append(event)
			check(outcomes == reference_outcomes,"full outcome trace parity wind" + str(wind) + " item" + item)
			check(model.terrain.cells == simulation.terrain.cells,"crater mask parity wind" + str(wind) + " item" + item)
			check(model.actors == simulation.actors,"actor damage and attribution parity wind" + str(wind) + " item" + item)

# ASM 41e4eb and 41e761: 3*Attack/count and (Dig/2)/count,
# truncating each division. Source DAT row 6: 254/48, 118/42, 350/46.
func native_damage_fields() -> void:
	var model = model_with_item()
	model.actors[0].attributes = [11,0,0,0,0,0,19,0]
	for weapon in range(3):
		var shells: Array = model.shot_shells(0,45,60,weapon)
		for shell in shells:
			check(int(shell.damage) == [287,126,383][weapon], "native power with attack " + str(weapon))
			check(int(shell.get("boomer_diameter",0)) == [57,44,55][weapon], "native dimension with dig " + str(weapon))
			check(float(shell.blast_radius) == [28.5,22.0,27.5][weapon], "native initial radius " + str(weapon))
	var ss: Dictionary = model.shot_shells(0,45,60,2)[0]
	ss.flight_ticks = 45
	Boomer.advance_state(ss)
	check(int(ss.damage) == 766 and int(ss.boomer_diameter) == 66 and float(ss.blast_radius) == 33.0, "SS scales prepared power and dimension")

func native_muzzle() -> void:
	# 43c860/4542a0; raw tank6 frame0 has hotspot −35 and opaque bottom +1.
	# At the current 24px visual support, the native origin is actor.y + 23.
	for row in [[1,0.0,Vector2(509,487)],[-1,0.0,Vector2(491,487)],
		[1,30.0,Vector2(514,493)],[-1,30.0,Vector2(497,483)],
		[1,-30.0,Vector2(502,483)],[-1,-30.0,Vector2(485,493)]]:
		check(Boomer.muzzle(Vector2(500,500),int(row[0]),deg_to_rad(float(row[1]))) == row[2],"native muzzle fixture " + str(row))
	var model = model_with_item()
	model.terrain.WIDTH = 640
	model.terrain.HEIGHT = 400
	model.terrain.cells.resize(640*400)
	model.terrain.cells.fill(0)
	for y in range(300,400):
		for x in 640:
			model.terrain.cells[y*640+x] = 1
	model.terrain.native_cells.clear()
	model.terrain.enable_native()
	model.actors[0].pos = Vector2(250,575)
	for facing in [-1,1]:
		model.actors[0].facing = facing
		for weapon in 3:
			var low: Array = model.shot_shells(0,10,60,weapon)
			var high: Array = model.shot_shells(0,90,60,weapon)
			var expected := Vector2(250+facing*9,562)
			check(low[0].pos == expected and high[0].pos == expected,"weapon %d facing %d starts at chassis muzzle independent of aim" % [weapon,facing])
			check(low[0].velocity != high[0].velocity,"aim still changes projectile velocity")
	model.actors[0].turn_item = "teleport"
	var beacon: Dictionary = model.shot_shells(0,45,60,2)[0]
	check(bool(beacon.beacon) and beacon.pos == Vector2(259,562),"Teleport beacon uses the shared chassis muzzle")

func muzzle_contact_bridge() -> void:
	var model = model_with_item()
	model.terrain.WIDTH = 640
	model.terrain.HEIGHT = 400
	model.terrain.cells.resize(640*400)
	model.terrain.cells.fill(0)
	for y in range(300,400):
		for x in 640:
			model.terrain.cells[y*640+x] = 1
	model.terrain.native_cells.clear()
	model.terrain.enable_native()
	model.actors[0].pos = Vector2(250,595)
	model.actors[1].pos = Vector2(1000,595)
	check(model.fire(65,70,0),"disparo Boomer válido")
	for tick in 10:
		model.advance_projectile_tick(0.05)
	check(not model.projectiles.is_empty(),"projétil sai da caixa própria antes de ativar contato")

func native_tornado() -> void:
	var model = model_with_item()
	var shell: Dictionary = model.shot_shells(0,45,60,0)[0]
	model.seed_projectile(shell)
	check(NativeWeather.active(shell), "Boomer usa clima nativo")
	shell.boomer_curve = true
	shell.boomer_initialized = true
	shell.boomer_angle = 45
	shell.boomer_direction = 1
	shell.fp_velocity = Vector2i(100,500)
	shell.tornado = {"native":true,"column":1,"turns":0,"center":500,"half":32}
	var velocity: Vector2i = shell.fp_velocity
	Boomer.begin_tick(shell,false,false)
	check(shell.fp_velocity == velocity,"tornado suprime sustentação")
	Boomer.finish_tick(shell,false)
	check(int(shell.boomer_angle) == 46 and int(shell.boomer_direction) == 1,"curva avança sem reset descendente no tornado")
	for crossing in range(1,4):
		shell.fp_pos = Vector2i(533 * 256,0)
		var previous := int(shell.fp_velocity.x)
		check(not NativeWeather.finish(shell), "sem aceleração na saída " + str(crossing))
		if crossing < 3:
			var clamped := -200 if previous < 0 else 200
			if absi(previous) >= 200:
				clamped = previous
			check(int(shell.fp_velocity.x) == -clamped and int(shell.tornado.turns) == crossing,"inversão nativa " + str(crossing))
		else:
			check(shell.tornado.is_empty(),"terceira saída libera")
	check(bool(shell.boomer_curve),"tornado não recalcula flag de curva")

func native_weather_parity() -> void:
	for wind in [Vector2(27,0),Vector2(-27,0),Vector2(0,27),Vector2(0,-27)]:
		for facing in [-1,1]:
			var model = model_with_item()
			model.actors[0].facing = facing
			model.wind = wind
			var shells: Array = model.shot_shells(0,45,60,0)
			model.weather.add_column("tornado",float(shells[0].pos.x),1.0)
			var sim = Snapshot.capture(model)
			Snapshot.arm(sim,0,0,shells.duplicate(true))
			model.fire(45,60,0)
			model.events.clear()
			var sampled := false
			for tick in 80:
				if model.phase != Match.PHASE_FLIGHT:
					break
				model.advance_projectile_tick(0.05)
				sim.advance_projectile_tick(0.05)
				for projectile in model.projectiles:
					if not projectile.tornado.is_empty():
						sampled = true
						check(bool(projectile.tornado.get("native",false)),"Boomer usa tornado nativo")
				check(model.projectiles == sim.projectiles and model.events == sim.events, "tornado real/previsão %s lado%d tick%d" % [str(wind),facing,tick])
			check(sampled,"Boomer entrou no tornado %s lado%d" % [str(wind),facing])

func native_draw_angle() -> void:
	# Raster 4ebdd0: (−48,−32) → (−32,+48) at90°.
	var shell := {"boomer":true,"boomer_angle":90,"velocity":Vector2(100,100)}
	var sprite = ClassicSprite.new()
	if not sprite.has_method("projectile_angle"):
		check(false,"renderer expõe ângulo nativo")
		return
	check(is_equal_approx(sprite.projectile_angle(shell),-PI/2),"ângulo publicado gira anti-horário no canvas")
	shell.boomer_angle = 0
	check(is_zero_approx(sprite.projectile_angle(shell)),"sem curva usa zero mesmo com velocidade inclinada")
	shell.boomer = false
	check(is_equal_approx(sprite.projectile_angle(shell),PI/4),"outros projéteis conservam heading")

func attached_weather() -> void:
	for weapon in range(3):
		var model = model_with_item()
		model.weather.queue = [{"type":"thor"}]
		model.terrain.native_cells.fill(0)
		var width := int(model.terrain.world_size().x)
		model.terrain.native_cells[250*width+200] = 1
		var shell: Dictionary = model.shot_shells(0,45,60,weapon)[0]
		shell.electric = true
		var sim = Snapshot.capture(model)
		model.events.clear()
		sim.events.clear()
		model.explode(Vector2(200,300),-1,shell)
		sim.explode(Vector2(200,300),-1,shell.duplicate(true))
		var ray := -1
		var thor := -1
		var own := -1
		for i in model.events.size():
			var event: Dictionary = model.events[i]
			if event.type == "mobile_lightning": ray = i
			if event.type == "thor" and bool(event.get("native",false)):
				thor = i
				check(int(event.power) == [100,25,100][weapon] and int(event.period) == [1000,4000,1000][weapon],"Thor divide por emissão arma%d" % weapon)
			if event.type == "explosion" and int(event.get("vehicle",0)) == 6: own = i
		check(ray >= 0 and thor > ray and own > thor,"eletricidade e Thor precedem impacto arma%d" % weapon)
		check(model.events.filter(func(e): return e.type == "thor").size() == 1,"Thor não é duplicado arma%d" % weapon)
		check(model.events == sim.events and model.actors == sim.actors and model.terrain.native_cells == sim.terrain.native_cells,"efeitos e cratera iguais à previsão arma%d" % weapon)

func native_item_bridges() -> void:
	var thunder = model_with_item("thunder")
	var shots: Array = thunder.shot_shells(0,45,60,1)
	check(shots.size() == 4 and shots.all(func(s): return bool(s.electric)),"Thunder marca as quatro emissões")
	var beacon_model = model_with_item("teleport")
	var beacons: Array = beacon_model.shot_shells(0,45,60,2)
	check(beacons.size() == 1 and bool(beacons[0].beacon),"Teleport substitui o tiro por sinalizador")
	check(not bool(beacons[0].boomer) and not NativeWeather.active(beacons[0]),"sinalizador não herda curva nem clima de projétil Boomer")
	var model = model_with_item()
	model.wind = Vector2(27,0)
	var shell: Dictionary = model.shot_shells(0,45,60,0)[0]
	model.seed_projectile(shell)
	var acceleration: Vector2i = shell.fp_acceleration
	var curve: bool = shell.boomer_curve
	model.wind = Vector2(-27,0)
	model.seed_projectile(shell)
	check(shell.fp_acceleration == acceleration and bool(shell.boomer_curve) == curve,"mudança posterior de vento preserva semente")

func mine_blast_boundary() -> void:
	# 499650: q(dx*100,aspect)^2+dy^2 < (q(dimension,2)+10)^2.
	# Native DAT and SS IDIV give these adjacent inside/outside samples.
	for row in [[0,false,42,43],[1,false,35,36],[2,false,39,40],[2,true,44,45]]:
		for sign_value in [-1,1]:
			var model = model_with_item()
			var hit := Vector2(600,250)
			for distance in [row[2],row[3]]:
				model.mines.append({"pos":hit+Vector2(sign_value*distance,0),"owner":1,"vehicle":7,"weapon":1,
					"radius":21.0,"damage":118,"raon_mine":true})
			var shell: Dictionary = model.shot_shells(0,45,60,int(row[0]))[0]
			if bool(row[1]):
				shell.flight_ticks = 45
				Boomer.advance_state(shell)
			var sim = Snapshot.capture(model)
			model.events.clear()
			sim.events.clear()
			model.explode(hit,-1,shell)
			sim.explode(hit,-1,shell.duplicate(true))
			check(model.mines.size()==1 and model.mines[0].pos==hit+Vector2(sign_value*int(row[3]),0),"elipse exclui borda %s lado%d" % [str(row),sign_value])
			var blasts: Array = model.events.filter(func(e): return e.type=="explosion" and bool(e.get("raon_mine",false)))
			check(blasts.size()==1 and int(blasts[0].actor)==0,"mina transfere autoria %s lado%d" % [str(row),sign_value])
			check(model.mines==sim.mines and model.events==sim.events and model.actors==sim.actors and model.terrain.cells==sim.terrain.cells,"mina e dano iguais na previsão %s lado%d" % [str(row),sign_value])

func native_fall_wind() -> void:
	# 45cf14: add 3*trunc(force*cos(angle)), IDIV 100, retain signed remainder.
	for row in [[10,0,0,30,1,20],[10,180,0,-30,-1,-20],
		[10,90,0,0,0,0],[10,270,0,0,0,0],[1,45,0,0,0,0],
		[10,45,0,21,0,84],[10,135,0,-21,0,-84],
		[10,225,0,-21,0,-84],[10,315,0,21,0,84],[34,0,1,2,4,8]]:
		var residue := 0
		var delta := 0
		for step in 4:
			var result: Vector2i = Boomer.fall_wind_step(residue,int(row[0]),int(row[1]))
			delta += result.x
			residue = result.y
			if step == 0:
				check(result.x == int(row[2]) and residue == int(row[3]),"fall wind initial result " + str(row))
		check(delta == int(row[4]),"fall wind signed displacement " + str(row))
		check(residue == int(row[5]),"fall wind signed remainder " + str(row))
	for row in [[Vector2(10,0),1],[Vector2(-10,0),-1],[Vector2(0,10),0],[Vector2.ZERO,0]]:
		var model = model_with_item()
		model.wind = row[0]
		var actor := {"vehicle":6,"pos":Vector2(500,4)}
		model.drift_fall(actor,12.0)
		check(actor.pos.x == 500.0 + float(row[1]),"boomer fall consumes native wind steps " + str(row))
		var sim = Snapshot.capture(model)
		var sim_actor := {"vehicle":6,"pos":Vector2(500,4)}
		sim.drift_fall(sim_actor,12.0)
		check(sim_actor.pos == actor.pos,"fall wind snapshot parity " + str(row))
	var changed = Match.new()
	changed.start(6,1,42,"","original",null,["change_wind"],[],[],0,1)
	changed.weather.wind_force = 10
	changed.weather.wind_angle = 0
	changed.wind = changed.weather.wind_vector()
	var shell: Dictionary = changed.shot_shells(0,45,60,0)[0]
	changed.seed_projectile(shell)
	var acceleration: Vector2i = shell.fp_acceleration
	check(changed.use_item(0),"Boomer can use Change Wind")
	var actor := {"vehicle":6,"pos":Vector2(500,4)}
	changed.drift_fall(actor,12.0)
	check(changed.weather.wind_angle == 180 and actor.pos.x == 499.0,"Change Wind reverses later fall")
	changed.seed_projectile(shell)
	check(shell.fp_acceleration == acceleration,"Change Wind preserves already seeded shot")

func boomer_moon_eclipse() -> void:
	var model = model_with_item("dual")
	model.weather.calendar.fill(5)
	model.actors[0].hp = 500
	model.active = 0
	model.begin_turn()
	check(model.actors[0].hp == 590,"Moon heals 80 HP after Boomer's 10 HP regeneration")
	model.weather.calendar.fill(6)
	model.actors[0].turn_item = "dual"
	model.actors[1].turn_item = "dual_plus"
	model.begin_turn()
	check(model.items_locked() and model.actors.all(func(a): return str(a.turn_item).is_empty()),"Eclipse locks items and clears both dual modes for Boomer")
	check(model.can_use_special(0),"Eclipse adds no SS lock")

func native_mobile_poses() -> void:
	# tank6.epa: fdamage/bdamage25, item23, drop20, dead10 ticks at20Hz.
	var model = model_with_item()
	var art = preload("res://scripts/battle_art.gd").new()
	var sprites: Dictionary = preload("res://scripts/game.gd").build_sprites()
	art.bind_sprites(sprites)
	art.reset(model.actors)
	check(bool(art.motion[0].native_animation),"Boomer selects native EPA presentation")
	for row in [["hurt",1.25],["hurt_2",1.25],["using_item",1.15],["falling",1.0],["destroyed",0.5]]:
		check(is_equal_approx(sprites[6].pose_duration(row[0],0,false),row[1]),"Boomer native pose duration " + row[0])
	art.react({"type":"damage","actor":0})
	check(is_equal_approx(float(art.motion[0].hurt),1.25),"damage event uses full 25-tick EPA")
	art.react({"type":"item","actor":0})
	check(is_equal_approx(float(art.motion[0].using),1.15),"item event uses full 23-tick EPA")
	model.actors[0].hp = 0
	art.motion[0].rotation = 0.25
	art.motion[0].dead = 0.49
	var style: Dictionary = art.visual_style(0,model.actors[0],0.0)
	check(style.visible and style.rotation == 0.25 and style.color == Color.WHITE,"native death preserves support rotation and opacity")
	art.motion[0].dead = 0.5
	check(not art.visual_style(0,model.actors[0],0.0).visible,"native death ends at tick10")

func impact_stages() -> void:
	var sprite = ClassicSprite.new()
	sprite.setup("boomer")
	check(sprite.effect_sheets({"weapon":2,"ss_state":"normal"}) == ["Flame3.png"],"SS normal só chama primária")
	check(sprite.effect_sheets({"weapon":2,"ss_state":"change"}) == ["Flame3.png"],"change não adiciona secundária")
	check(sprite.effect_sheets({"weapon":2,"ss_state":"cnormal"}) == ["Flame3.png","SSFlame.png"],"SS transformado chama duas camadas")
	check(sprite.has_method("effect_rotation"),"rotação visual do impacto disponível")
	if sprite.has_method("effect_rotation"):
		check(is_equal_approx(sprite.effect_rotation({"age":0.10,"primary_angle":30,"secondary_angle":200},"SSFlame.png"),-deg_to_rad(204)),"rotação da camada secundária avança dois graus por tick")

func native_blast() -> void:
	var model = model_with_item()
	model.actors[0].pos = Vector2(200,100)
	model.actors[1].pos = Vector2(900,300)
	var shell: Dictionary = model.shot_shells(0,45,60,0)[0]
	var center: Vector2i = preload("res://scripts/aduka_combat.gd").center(model.actors[1])
	model.events.clear()
	model.explode(Vector2(center),1,shell)
	var dealt := 0
	for event in model.events:
		if event.type in ["damage", "shield_damage"] and int(event.actor) == 1:
			dealt += int(event.amount)
	# DAT Mage vulnerability 92, flag4 vs Boomer attack flag2 adds4.
	# Center falloff=1000, then 254*96/100 truncates to 243.
	check(dealt == 243,"native blast at Mage center with elemental defense")

func frame_rates() -> void:
	var states: Array = []
	for fps in [30,60,120]:
		var model = model_with_item()
		model.fire(90,60,2)
		for _i in fps*3:
			model.tick(1.0/fps)
		var shell: Dictionary = model.projectiles[0]
		states.append([model.flight_elapsed,shell.fp_pos,shell.fp_velocity,shell.flight_ticks,shell.ss_state])
	check(states[0] == states[1] and states[1] == states[2],"exact FP state3s at30/60/120Hz")

func run() -> void:
	launch_clock()
	transformation()
	parity()
	native_damage_fields()
	native_blast()
	attached_weather()
	native_item_bridges()
	mine_blast_boundary()
	native_fall_wind()
	boomer_moon_eclipse()
	native_mobile_poses()
	impact_stages()
	native_muzzle()
	muzzle_contact_bridge()
	native_tornado()
	native_weather_parity()
	native_draw_angle()
	frame_rates()
	finish("BOOMER CHECKS")
