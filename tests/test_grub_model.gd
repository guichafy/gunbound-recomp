extends "res://tests/support/suite.gd"
## Grub (ID 13, client type 12): emission, catalog row, native flight in the match.
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Flight = preload("res://scripts/grub_flight.gd")
const Combat = preload("res://scripts/combat.gd")
const ClassicSprite = preload("res://scripts/classic_sprite.gd")
const GrubSprite = preload("res://scripts/grub_sprite.gd")
const SpritePose = preload("res://scripts/sprite_pose.gd")
const GrubCombat = preload("res://scripts/grub_combat.gd")

func fresh(facing: int = 1, item: String = ""):
	var model = Match.new()
	model.start(13, 1, 42, "", "original", null, [] if item.is_empty() else [item])
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.WIDTH = 2000
	model.terrain.cells.resize(model.terrain.WIDTH * model.terrain.HEIGHT)
	model.terrain.cells.fill(0)
	model.terrain.native_cells = PackedByteArray()
	model.terrain.enable_native()
	model.actors[0].pos = Vector2(400 if facing == 1 else 1500, 650)
	model.actors[0].facing = facing
	model.actors[1].pos = Vector2(3000, 750)
	return model

func test_row() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/grub/combat_native.json"))
	var row: Array = catalog.row
	check(row.size() == 83 and int(row[22]) == 1000 and int(row[23]) == 0 and int(row[24]) == 0, "type 12 row: life 1000, shield 0, shield regen 0")
	check(Mobiles.force_max(13) == int(row[25]) and Mobiles.gravity_native(13) == int(row[40]), "force [25] and gravity [40] feed the Godot tables")
	for weapon in 3:
		var rules: Dictionary = Mobiles.weapon(13, weapon, 0)
		var base: int = [44, 57, 70][weapon]
		check(int(rules.cost) == int(row[28]) + int(row[30 + weapon]), "delay [28]+[%d] of weapon %d" % [30 + weapon, weapon])
		check(int(catalog.weapons[weapon].power) == int(row[base]) and int(catalog.weapons[weapon].dimension) == int(row[base + 3]) and int(catalog.weapons[weapon].aspect) == int(row[base + 6]), "weapon %d power/dimension/aspect = [%d]/[%d]/[%d]" % [weapon, base, base + 3, base + 6])
		var limits := Mobiles.aim_limits(13, weapon)
		check(limits == Vector2(float(row[[4, 10, 16][weapon]]), float(row[[3, 9, 15][weapon]])), "aim limits of weapon %d come from [4]/[3] style pairs" % weapon)
	check(int(Mobiles.definition(13).time_delay) == int(row[29]), "time factor [29]")
	# No 10 / 70 in the row or in CreateMobile: the bionic pair is gone for the Grub only.
	var grub: Dictionary = Mobiles.definition(13)
	check(int(grub.hp_regen) == 0 and int(grub.protection) == 0 and not bool(grub.bionic), "Grub has no per-turn heal and no flat protection number")
	check(grub.box == Vector2(28, 24), "movement box is the PE body 28x24")
	for other in [5, 6, 11, 12]:
		var spec: Dictionary = Mobiles.definition(other)
		check(bool(spec.bionic) and int(spec.hp_regen) == 10 and int(spec.protection) == 70, "mobile %d keeps the shared bionic adaptation (out of scope)" % other)

func test_emission() -> void:
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/grub_emission_native.json"))
	var weapons := {"t1": 0, "t2": 1, "ss": 2}
	for row in rows:
		var theta := int(row.theta)
		if theta == 90 or theta == 91:
			continue
		var facing := 1 if theta < 90 else -1
		var model = fresh(facing)
		var hud := float(theta) if facing == 1 else float(180 - theta)
		var weapon: int = weapons[row.weapon]
		var percent := Physics.power_percent(int(row.power), Mobiles.force_max(13))
		var shells: Array = model.projectile_parameters(0, hud, percent, weapon)
		check(shells.size() == row.shells.size(), "%s theta %d emits %d shells" % [row.weapon, theta, row.shells.size()])
		if shells.size() != row.shells.size():
			continue
		for index in shells.size():
			var want: Vector2i = Physics.launch_velocity_fp(int(row.shells[index][0]), int(row.shells[index][1]))
			check(Vector2i(shells[index].launch_velocity_fp) == want, "%s theta %d P %d shell %d: velocity %s, PE (angle %d, power %d) -> %s" % [row.weapon, theta, int(row.power), index, str(shells[index].launch_velocity_fp), int(row.shells[index][0]), int(row.shells[index][1]), str(want)])

func test_flight_modes() -> void:
	var model = fresh()
	check(model.projectile_parameters(0, 45.0, 60.0, 1).size() == 4, "S2 launches four bodies")
	check(str(model.projectile_parameters(0, 45.0, 60.0, 1)[0].flight) == "grub_t2" and str(model.projectile_parameters(0, 45.0, 60.0, 2)[0].flight) == "grub_ss", "S2/SS use the native ricochet flights")

func floor_model(facing: int = 1, item: String = ""):
	var model = fresh(facing, item)
	for y in range(700, model.terrain.HEIGHT * model.terrain.SCALE):
		for x in model.terrain.WIDTH * model.terrain.SCALE:
			model.terrain.native_cells[y * model.terrain.WIDTH * model.terrain.SCALE + x] = 1
	for y in range(350, model.terrain.HEIGHT):
		for x in model.terrain.WIDTH:
			model.terrain.cells[y * model.terrain.WIDTH + x] = 1
	model.actors[0].pos = Vector2(400 if facing == 1 else 1500, 690)
	model.actors[1].pos = Vector2(3000, 690)
	if not item.is_empty():
		model.use_item(0)
	return model

func fly(model, weapon: int, angle: float, power: float) -> Dictionary:
	check(model.fire(angle, power, weapon), "fire weapon %d" % weapon)
	var kinds := {}
	var explosions: Array = []
	var damages := 0
	for tick in 4000:
		model.advance_projectiles(Combat.STEP)
		for event in model.events:
			kinds[event.type] = int(kinds.get(event.type, 0)) + 1
			if event.type == "explosion":
				explosions.append(Vector2(event.position))
			if event.type == "damage" or event.type == "shield_damage":
				damages += 1
		model.events.clear()
		if model.phase != Match.PHASE_FLIGHT:
			break
	return {"kinds": kinds, "explosions": explosions, "damages": damages}

func test_live_flight() -> void:
	var model = floor_model()
	var result := fly(model, 1, 45.0, 35.0)
	check(int(result.kinds.get("ricochet", 0)) >= 4, "S2 bodies ricochet on the floor before detonating (%d)" % int(result.kinds.get("ricochet", 0)))
	check(result.explosions.size() == 4, "each of the four S2 bodies detonates once (%d)" % result.explosions.size())
	var model_ss = floor_model()
	var ss := fly(model_ss, 2, 45.0, 35.0)
	check(int(ss.kinds.get("ricochet", 0)) >= 1 and ss.explosions.size() == 1, "SS ricochets and detonates once")

func test_teleport_beacon_is_not_a_ricochet() -> void:
	# Teleport replaces the shot by a beacon (flight ""): it must reach land_beacon,
	# not the Grub ricochet. The SS is locked for the turn after using an item.
	var model = floor_model(1, "teleport")
	var origin := Vector2(model.actors[0].pos)
	var result := fly(model, 1, 45.0, 35.0)
	check(int(result.kinds.get("ricochet", 0)) == 0 and int(result.kinds.get("teleport", 0)) == 1, "Teleport + Grub S2 lands the beacon (%s)" % str(result.kinds))
	check(Vector2(model.actors[0].pos) != origin, "the owner moved to the beacon")
	var locked = floor_model(1, "teleport")
	check(not locked.fire(45.0, 35.0, 2), "the SS stays locked after using Teleport (HUD.DisableSS)")

func test_prediction_matches_real() -> void:
	for weapon in [1, 2]:
		var model = floor_model()
		model.actors[1].pos = Vector2(1300, 690)
		var predicted: Dictionary = model.predict_shot(0, 45.0, 35.0, weapon)
		var result := fly(model, weapon, 45.0, 35.0)
		var best := Vector2.ZERO
		var distance := INF
		for position in result.explosions:
			if position.distance_to(model.actors[1].pos) < distance:
				distance = position.distance_to(model.actors[1].pos)
				best = position
		check(not predicted.is_empty() and Vector2(predicted.position) == best, "weapon %d: prediction %s = executed %s" % [weapon, str(predicted.get("position")), str(best)])

## 0x49e650 / 0x4857f0 call the native weather samplers on every coarse sample and
## 0x49fd40 / 0x486ea0 swap v += a for the tornado branch (ADR-150 amendment).
func column_x(weapon: int) -> int:
	var probe = floor_model()
	probe.fire(45.0, 35.0, weapon)
	var path: Array = []
	for tick in 12:
		probe.advance_projectiles(Combat.STEP)
		if not probe.projectiles.is_empty() and probe.projectiles[0].has("g_int"):
			path.append(Vector2i(probe.projectiles[0].g_int))
	return path[6].x

func test_weather_columns() -> void:
	# T1 is Projectile::Simulate 0x455cc0: the shared native sampler, not the C# trace.
	var probe = floor_model()
	probe.fire(45.0, 35.0, 0)
	for tick in 6:
		probe.advance_projectiles(Combat.STEP)
	var t1 = floor_model()
	t1.weather.add_column("electricity", probe.projectiles[0].hit_pos.x, 1.0)
	var t1_result := fly(t1, 0, 45.0, 35.0)
	check(int(t1_result.kinds.get("weather_hit", 0)) >= 1 and int(t1_result.kinds.get("lightning", 0)) >= 1, "T1 crosses electricity on the common path (%s)" % str(t1_result.kinds))
	for weapon in [1, 2]:
		var x := column_x(weapon)
		for type in ["electricity", "tornado", "force"]:
			var model = floor_model()
			model.weather.add_column(type, float(x), 1.0)
			model.actors[1].pos = Vector2(1300, 690)
			var predicted: Dictionary = model.predict_shot(0, 45.0, 35.0, weapon)
			check(model.fire(45.0, 35.0, weapon), "fire weapon %d through %s" % [weapon, type])
			var kinds := {}
			var explosions: Array = []
			var tornado_ticks := 0
			var tornado_ok := true
			var force := 0
			for tick in 4000:
				var before: Array = []
				for shell in model.projectiles:
					if shell.has("g_kind") and not shell.tornado.is_empty():
						before.append([shell, Vector2i(shell.fp_velocity)])
				model.advance_projectiles(Combat.STEP)
				var bounced: bool = model.events.any(func(event): return event.type == "ricochet")
				for shell in model.projectiles:
					force = maxi(force, int(shell.get("native_force", 0)))
				for pair in before:
					if not bounced and model.projectiles.any(func(live): return is_same(live, pair[0])):
						tornado_ticks += 1
						var then: Vector2i = pair[1]
						var now: Vector2i = pair[0].fp_velocity
						# No gravity inside the column, |vx| >= 200 and a pure horizontal flip.
						tornado_ok = tornado_ok and now.y == then.y and absi(now.x) >= 200 and (absi(now.x) == maxi(absi(then.x), 200))
				for event in model.events:
					kinds[event.type] = int(kinds.get(event.type, 0)) + 1
					if event.type == "explosion":
						explosions.append(Vector2(event.position))
				model.events.clear()
				if model.phase != Match.PHASE_FLIGHT:
					break
			var label := "weapon %d %s" % [weapon, type]
			check(int(kinds.get("weather_hit", 0)) >= 1, "%s: the shell samples the column (%s)" % [label, str(kinds)])
			match type:
				"electricity":
					check(int(kinds.get("lightning", 0)) >= 1, "%s: the impact adds the electric strike" % label)
				"tornado":
					check(tornado_ticks > 0 and tornado_ok, "%s: tornado clamps |vx| to 200, skips gravity and flips at the border (%d ticks)" % [label, tornado_ticks])
				"force":
					check(force >= 20 and force <= 100, "%s: force accumulates within 20..100 (%d)" % [label, force])
			var best := Vector2.ZERO
			var distance := INF
			for position in explosions:
				if position.distance_to(model.actors[1].pos) < distance:
					distance = position.distance_to(model.actors[1].pos)
					best = position
			check(not predicted.is_empty() and Vector2(predicted.position) == best, "%s: prediction %s = executed %s" % [label, str(predicted.get("position")), str(best)])

func test_ss_passes_through_and_repeats() -> void:
	var probe = floor_model()
	probe.fire(45.0, 35.0, 2)
	var path: Array = []
	for tick in 4000:
		probe.advance_projectiles(Combat.STEP)
		if not probe.projectiles.is_empty() and probe.projectiles[0].has("g_int"):
			path.append(Vector2(probe.projectiles[0].g_int))
		if probe.phase != Match.PHASE_FLIGHT:
			break
	check(path.size() > 20, "the SS flies for several frames before detonating (%d)" % path.size())
	var model = floor_model()
	model.actors[1].pos = path[path.size() / 2]
	var before := int(model.actors[1].hp) + int(model.actors[1].shield)
	var result := fly(model, 2, 45.0, 35.0)
	check(int(model.actors[1].hp) + int(model.actors[1].shield) < before and int(result.damages) >= 2, "SS damages a mobile on several frames while crossing it (%d events)" % int(result.damages))
	check(int(result.kinds.get("explosion", 0)) == 1, "crossing a mobile does not detonate the SS (%d explosions)" % int(result.kinds.get("explosion", 0)))

func test_owner_attributes() -> void:
	GrubCombat.warmup()
	var model = fresh()
	model.actors[0].attributes = [10, 0, 0, 0, 0, 0, 10, 0]
	var shells: Array = model.projectile_parameters(0, 45.0, 50.0, 0)
	check(shells.size() == 1, "T1 is still one shell when the owner has attributes")
	check(int(shells[0].damage) == 190 + 30, "41da80 divisor 1 adds 3 x Attack 10 to power 190 (%d)" % int(shells[0].damage))
	check(int(shells[0].grub_dimension) == 50 + 5, "41da80 divisor 1 adds Dig 10 / 2 to dimension 50 (%d)" % int(shells[0].grub_dimension))
	var four: Array = model.projectile_parameters(0, 45.0, 50.0, 1)
	check(four.size() == 4 and int(four[0].damage) == 94 + 30 and int(four[3].damage) == 94 + 30, "each S2 spawn keeps the full attribute addition")

func test_moon_and_no_turn_heal() -> void:
	var model = fresh()
	model.actors[0].hp = 500
	model.actors[0].max_hp = 1000
	Mobiles.regenerate(model.actors[0])
	check(int(model.actors[0].hp) == 500, "a turn does not heal the Grub (hp_regen 0)")
	model.weather.queue = [{"type": "protection"}]
	var gained := int(model.weather.moon_heal(model.actors[0]))
	check(gained == 80 and int(model.actors[0].hp) == 580, "Moon heals 8 percent because defense flags bit 2 is set (%d)" % gained)

func test_t1_uses_native_contact() -> void:
	var probe = floor_model()
	probe.fire(45.0, 35.0, 0)
	for tick in 8:
		probe.advance_projectiles(Combat.STEP)
	check(not probe.projectiles.is_empty(), "T1 is still in flight after 8 ticks")
	var x := float(probe.projectiles[0].hit_pos.x)
	var model = floor_model()
	model.weather.add_column("tornado", x, 1.0)
	model.fire(45.0, 35.0, 0)
	var native := false
	var samples := 0
	for tick in 80:
		var before: Array = []
		for shell in model.projectiles:
			if shell.tornado.is_empty():
				continue
			before.append([shell, Vector2i(shell.fp_velocity)])
		model.advance_projectiles(Combat.STEP)
		for pair in before:
			if not model.projectiles.any(func(live): return is_same(live, pair[0])):
				continue
			samples += 1
			var now: Vector2i = pair[0].fp_velocity
			native = native or (now.y == pair[1].y and absi(now.x) >= 200)
		if model.phase != Match.PHASE_FLIGHT:
			break
	check(samples > 0 and native, "T1 tornado follows 0x455cc0 (|vx| >= 200, no gravity) for %d ticks" % samples)
	var predicted: Dictionary = floor_model().predict_shot(0, 45.0, 35.0, 0)
	var played = floor_model()
	var result := fly(played, 0, 45.0, 35.0)
	var best := Vector2.ZERO
	var distance := INF
	for position in result.explosions:
		if position.distance_to(played.actors[1].pos) < distance:
			distance = position.distance_to(played.actors[1].pos)
			best = position
	check(not predicted.is_empty() and Vector2(predicted.position) == best, "T1 prediction %s = executed %s" % [str(predicted.get("position")), str(best)])

func test_presentation_rules() -> void:
	for weapon in 3:
		check(not ClassicSprite.has_trail("grub", weapon), "Grub weapon %d keeps the single sprite (ADR-120, no afterimage blur)" % weapon)
	check(ClassicSprite.has_trail("raon", 0) and not ClassicSprite.has_trail("raon", 1) and not ClassicSprite.has_trail("nak", 1), "ADR-120: other mobiles keep the single sprite")
	for heading in [0, 45, 90, 270, 315]:
		check(not ClassicSprite.ss_mirrored(heading), "SS heading %d is not mirrored" % heading)
	for heading in [91, 180, 269]:
		check(ClassicSprite.ss_mirrored(heading), "SS heading %d is mirrored (0x488880: >90 and <270)" % heading)

func test_light_layers() -> void:
	var sprite = GrubSprite.new()
	sprite.setup("grub")
	check(sprite is GrubSprite and sprite.hull_light != null, "Grub sprite loads tank13l as the hull light sheet")
	check(int(sprite.hull_info.frames) == int(362) and str(sprite.hull_info.entry) == "tank13l.img", "hull light covers the 362 tank13 frames")
	for light in ["Bullet1Light.png", "Bullet2Light.png"]:
		check(not sprite.sheet(light).is_empty(), "%s is available for the additive pass" % light)
	check(sprite.sheet("Bullet3Light.png").is_empty(), "the SS has no light entry in the client (bullet13p only)")
	check(sprite.hull_view == 0, "hull glow stays off until a view opens it")
	var view := Node2D.new()
	var other := Node2D.new()
	sprite.begin_hull_glow(view)
	check(sprite.hull_view == view.get_instance_id(), "begin_hull_glow arms the hull pass for that view")
	# A view that never opened the pass draws the plain body: no private additive
	# canvas that nobody clears (the room glow piled up after a match).
	sprite.draw_hull_glow(other, SpritePose.new(Vector2(100, 100), 70.0, 1, {"frame": 0}))
	check(not sprite.hull_glow.canvases.has(other.get_instance_id()), "another view does not get a hull glow canvas")
	sprite.draw_hull_glow(view, SpritePose.new(Vector2(100, 100), 70.0, 1, {"frame": 0}))
	check(sprite.hull_glow.canvases.has(view.get_instance_id()), "the opened view draws the hull glow")
	sprite.clear_hull_glow()
	check(sprite.hull_view == 0, "clear_hull_glow disarms it")
	sprite.hull_glow = null
	view.free()
	other.free()

func run() -> void:
	Physics.warmup()
	test_row()
	test_emission()
	test_flight_modes()
	test_owner_attributes()
	test_moon_and_no_turn_heal()
	test_t1_uses_native_contact()
	test_presentation_rules()
	test_light_layers()
	test_live_flight()
	test_teleport_beacon_is_not_a_ricochet()
	test_prediction_matches_real()
	test_ss_passes_through_and_repeats()
	test_weather_columns()
	finish("GRUB MODEL CHECKS")
