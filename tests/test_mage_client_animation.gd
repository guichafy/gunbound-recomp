extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")

func run() -> void:
	Physics.warmup()
	var mage = load("res://scripts/game.gd").build_sprites()[1]
	check(mage.has_method("pose_duration"), "Native pose exposes EPA duration to events")
	if mage.has_method("pose_duration"):
		check(is_equal_approx(mage.pose_duration("hurt",0,false),1.25), "Mage hurt plays all25 EPA ticks")
		check(is_equal_approx(mage.pose_duration("destroyed",0,false),1.25), "Mage death uses25 native ticks")
		var bigfoot = load("res://scripts/game.gd").build_sprites()[2]
		check(is_equal_approx(bigfoot.pose_duration("destroyed",0,false),0.5), "Bigfoot death uses10 native ticks")
		check(is_equal_approx(bigfoot.pose_duration("hurt_2",0,false),1.15), "Bigfoot reverse damage uses23 native ticks")
	check(ResourceLoader.exists("res://scripts/mage_flight.gd"), "Mage original state exists")
	if ResourceLoader.exists("res://scripts/mage_flight.gd"):
		var Flight = load("res://scripts/mage_flight.gd")
		# Independent integer fixtures derived from PE sine/13px and phase40.
		for e in [[Vector2i(25600,0),0,Vector2.ZERO],[Vector2i(25600,0),40,Vector2(0,-8)],[Vector2i(25600,0),80,Vector2(0,-12)],[Vector2i(25600,0),180,Vector2.ZERO],[Vector2i(25600,0),220,Vector2(0,8)],[Vector2i(-25600,0),40,Vector2(0,8)]]:
			check(Flight.wave_offset(e[0],e[1]) == e[2], "Native13px wave fixture phase%d" % e[1])
		var shell := {"velocity":Vector2(200,0),"launch_velocity_fp":Vector2i(2560,0),"trail":[Vector2.ZERO],"fp_velocity":Vector2i(2560,0),"flight":"mage_wave"}
		Flight.prepare(shell,180)
		check(shell.mage_phase == 180 and shell.laser_sides.size() == 1,"Private phase and history initialized")
		Flight.finish_tick(shell)
		check(shell.mage_phase == 220,"Phase advances40 per20Hz tick")
	check(ResourceLoader.exists("res://scripts/mage_projectile_art.gd"), "Mage native ribbon raster exists")
	if ResourceLoader.exists("res://scripts/mage_projectile_art.gd"):
		var art = load("res://scripts/mage_projectile_art.gd").new()
		for weapon in [0,1]:
			var trail: Array = []
			var sides: Array = []
			for i in 20:
				trail.append(Vector2(i*10,0)); sides.append(Vector2(0,-8))
			var shot := {"trail":trail,"laser_sides":sides,"pos":trail[-1],"hit_pos":trail[-1],"flight_ticks":9,"phase":0.0}
			var before := shot.duplicate(true)
			var parts: Array = art.segments(shot,weapon)
			check(parts.size() == 15,"Native laser caps15 segments")
			check(parts[0].uv[0].is_equal_approx(Vector2((1.0+weapon*8)/16.0,0)),"16-column UV and T2 bank8")
			check(is_equal_approx(parts[0].uv[1].x-parts[0].uv[0].x,1.0/16),"One full native column")
			check(parts[0].points[0] == Vector2(190,8),"Native8px cross section")
			check(parts[0].color == Color8(128,255,255,255),"Native cyan first component")
			check(parts[14].color.a == Color8(128,255,255,31).a,"Byte alpha preserves low nibbleF")
			check(parts[0].points[2] == parts[1].points[1],"Neighbour quads share a section")
			shot.phase = PI
			if weapon == 1:
				check(art.segments(shot,weapon)[0].color == Color8(255,128,255,255),"Native pink second component")
			shot.phase = 0.0
			check(shot == before,"Raster never mutates simulation")
		# Real minimum-power geometry can rotate a section without moving its centre.
		var stationary := {"trail":[Vector2(636,126),Vector2(636,126)],"laser_sides":[Vector2(8,0),Vector2(0,-8)],"flight_ticks":1}
		var diamond: Dictionary = art.triangle_data(stationary,0)
		check(diamond.indices.size() == 6 and diamond.points.size() == 4,"Coincident centres preserve two nondegenerate native triangles")
	var model = Match.new()
	model.start(1,1,42,"","original")
	model.weather.columns.clear(); model.weather.thor.active = false
	model.terrain.cells.fill(0); model.wind = Vector2.ZERO
	model.actors[0].pos = Vector2(150,350); model.actors[1].pos = Vector2(1100,700)
	var shells: Array = model.shot_shells(0,40,60,1)
	check(shells.size() == 2 and shells[0].flight == "mage_wave" and shells[0].helix == 0.0,"Mage uses native wave instead of C# continuous helix")
	var poses = load("res://scripts/battle_art.gd").new()
	check(poses.has_method("bind_sprites"),"Battle presentation accepts active source poses")
	if poses.has_method("bind_sprites"):
		poses.bind_sprites(load("res://scripts/game.gd").build_sprites())
		poses.reset(model.actors)
		poses.react({"type":"damage","actor":0})
		check(is_equal_approx(poses.motion[0].hurt,1.25),"Real event plays full native hurt pose")
		check(poses.has_method("visual_style"),"One presentation style feeds the real draw")
		if poses.has_method("visual_style"):
			model.actors[0].hp = 0
			poses.motion[0].dead = 1.20
			poses.motion[0].rotation = 0.25
			var style: Dictionary = poses.visual_style(0,model.actors[0],0.0)
			check(style.rotation == 0.25 and style.color == Color.WHITE and style.visible,"Native death holds support angle and full opacity until final EPA tick")
			poses.motion[0].dead = 1.25
			check(not poses.visual_style(0,model.actors[0],0.0).visible,"Native death ends exactly with its EPA")
	# Live trajectories share wave/sections with prediction snapshots, including items.
	for item in ["", "dual", "dual_plus", "teleport"]:
		model.start(1,1,42,"","original",null,[item] if not item.is_empty() else [])
		model.weather.columns.clear(); model.weather.thor.active = false
		model.terrain.cells.fill(0); model.wind = Vector2.ZERO
		model.actors[0].pos = Vector2(150,350); model.actors[1].pos = Vector2(1100,700)
		if not item.is_empty():
			check(model.use_item(0),"Fixture uses "+item)
		var actual: Array = model.shot_shells(0,40,60,1)
		var snapshot = preload("res://scripts/flight_snapshot.gd").capture(model)
		preload("res://scripts/flight_snapshot.gd").arm(snapshot,0,1,actual.duplicate(true))
		model.fire(40,60,1)
		for tick in 18:
			model.advance_projectiles(0.05); snapshot.advance_projectiles(0.05)
			check(model.projectiles == snapshot.projectiles,"Identical native flight snapshot tick%d item%s" % [tick,item])
		if item == "teleport":
			check(actual[0].flight == "" and actual[0].beacon,"Teleport never inherits Mage wave")
	finish("MAGE CLIENT ANIMATION CHECKS")
