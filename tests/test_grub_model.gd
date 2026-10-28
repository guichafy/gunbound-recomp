extends "res://tests/support/suite.gd"
## Grub (ID 13, client type 12): emission, catalog row, native flight in the match.
const Match = preload("res://scripts/match.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Flight = preload("res://scripts/grub_flight.gd")
const Combat = preload("res://scripts/combat.gd")
const ClassicSprite = preload("res://scripts/classic_sprite.gd")
const GrubSprite = preload("res://scripts/grub_sprite.gd")

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
	check(int(grub.hp_regen) == 0 and int(grub.protection) == 35 and not bool(grub.bionic), "Grub has no bionic regen/protection (type-12 row holds none)")
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
	check(not sprite.hull_active, "hull glow stays off outside the battle pass")
	var view := Node2D.new()
	sprite.begin_hull_glow(view)
	check(sprite.hull_active, "begin_hull_glow arms the hull pass")
	sprite.clear_hull_glow()
	sprite.hull_glow = null
	view.free()
	check(not sprite.hull_active, "clear_hull_glow disarms it")

func run() -> void:
	Physics.warmup()
	test_row()
	test_emission()
	test_flight_modes()
	test_presentation_rules()
	test_light_layers()
	test_live_flight()
	test_teleport_beacon_is_not_a_ricochet()
	test_prediction_matches_real()
	test_ss_passes_through_and_repeats()
	finish("GRUB MODEL CHECKS")
