extends SceneTree
## REQ-21: Miramo Town A from OpenBound — collision from the original alpha,
## HD visual in agreement, spawns, craters, prediction and fallback.
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
	var Maps = load("res://scripts/maps.gd")
	var Terrain = load("res://scripts/terrain.gd")
	var Match = load("res://scripts/match.gd")
	var Combat = load("res://scripts/combat.gd")
	var map: Dictionary = Maps.get_map(Maps.DEFAULT)
	check(Maps.DEFAULT == "miramo_town_a" and not map.is_empty(), "Default arena is Miramo Town A")
	check(map.openbound_id == 20 and map.type == "A" and map.spawns.size() == 11, "Catalog mirrors Map.cs ID20 and its 11 spawn points")
	check(map.weather == [2, 1, 2, 1, 0, 2, 0, 0, 0, 1], "Weather preset is copied from Map.cs")

	# Collision truth: every cell equals the original alpha at its transformed centre.
	var terrain = Terrain.new()
	check(terrain.load_map(Maps.DEFAULT), "Map loads from the original foreground")
	var source: Image = Terrain.texture_image(map.mask)
	check(source != null and source.get_size() == Vector2i(1800, 1800), "Original ForegroundA is available at native size")
	var mismatched := 0
	var solid := 0
	for y in range(terrain.HEIGHT):
		for x in range(terrain.WIDTH):
			var world := Vector2(x * terrain.SCALE + 1.0, y * terrain.SCALE + 1.0)
			var p: Vector2 = Maps.to_source(map, world)
			var expected := false
			if world.y < float(map.floor) and Rect2(map.crop).has_point(p):
				expected = source.get_pixel(int(p.x), int(p.y)).a > 0.0
			var actual: bool = terrain.cells[y * terrain.WIDTH + x] != 0
			solid += 1 if actual else 0
			mismatched += 1 if expected != actual else 0
	check(mismatched == 0, "Collision mask equals the original alpha (%d mismatches)" % mismatched)
	var hidden := 0
	for index in range(int(map.floor / 2.0) * terrain.WIDTH, terrain.cells.size()):
		hidden += terrain.cells[index]
	check(hidden == 0, "No solid cell hides behind the HUD (y >= 670)")
	check(solid > 60000, "Map provides a substantial solid area (%d cells)" % solid)
	check(not terrain.is_solid(Vector2(640, 400)) and terrain.is_solid(Vector2(640, 600)), "Sky above and snow body below the surface")
	var surface: float = terrain.surface_at(640.0)
	check(surface > 420.0 and surface < 500.0, "Surface sits in the arena play band (%.1f)" % surface)

	# HD visual agrees with collision and keeps the documented geometry.
	check(terrain.visual != null and terrain.visual.get_size() == Vector2i(2560, 661), "HD foreground is 2560×661 (2× arena)")
	check(terrain.visual_rect.position == Vector2(0, 420) and is_equal_approx(terrain.visual_rect.size.x, 1280.0), "HD foreground spans the arena width from y420")
	var disagree := 0
	var sampled := 0
	for y in range(200, int(map.floor / 2.0), 2):
		for x in range(0, terrain.WIDTH, 3):
			var world := Vector2(x * terrain.SCALE + 1.0, y * terrain.SCALE + 1.0)
			var local: Vector2 = (world - terrain.visual_rect.position) * 2.0
			if local.y < 0.0 or local.y >= 661.0:
				continue
			sampled += 1
			var shown: bool = terrain.visual.get_pixel(int(local.x), int(local.y)).a > 0.5
			if shown != (terrain.cells[y * terrain.WIDTH + x] != 0):
				disagree += 1
	check(sampled > 10000 and float(disagree) / sampled < 0.01, "Visual alpha agrees with collision (%d/%d edge samples differ)" % [disagree, sampled])
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hd/maps/miramo_town/manifest.json"))
	check(manifest is Dictionary and manifest.foreground.sha256 == FileAccess.get_sha256(map.foreground_hd), "Manifest records the stitched HD foreground hash")
	check(manifest.foreground.original["ForegroundA.png"] == FileAccess.get_sha256(map.mask), "Original foreground is preserved byte for byte")

	var fallback: Image = Terrain.original_visual(map)
	check(fallback != null and fallback.get_size() == terrain.visual.get_size(), "Original foreground is a same-geometry fallback visual")
	if fallback != null:
		var fallback_disagree := 0
		for x in range(0, 2560, 37):
			var y := int((terrain.surface_at(x / 2.0) - 420.0) * 2.0) + 6
			if fallback.get_pixel(x, clampi(y, 0, 660)).a < 0.5:
				fallback_disagree += 1
		check(fallback_disagree <= 2, "Fallback visual is solid just below the collision surface")

	# Craters: cells and HD pixels, ring darkened like Topography.CreateErosion.
	var center := Vector2(640, terrain.surface_at(640.0) + 30.0)
	var ring_point: Vector2 = center + Vector2(26.5, 0)
	var ring_local: Vector2 = (ring_point - terrain.visual_rect.position) * 2.0
	var before_ring: Color = terrain.visual.get_pixel(int(ring_local.x), int(ring_local.y))
	var copy = terrain.collision_copy()
	var revision: int = terrain.revision
	terrain.carve(center, 25.0)
	var center_local: Vector2 = (center - terrain.visual_rect.position) * 2.0
	check(not terrain.is_solid(center) and terrain.revision == revision + 1, "Crater removes collision cells")
	check(terrain.visual.get_pixel(int(center_local.x), int(center_local.y)).a == 0.0, "Crater erases HD pixels")
	var after_ring: Color = terrain.visual.get_pixel(int(ring_local.x), int(ring_local.y))
	check(before_ring.a > 0.0 and after_ring.a > 0.0 and absf(after_ring.r - before_ring.r * 0.4) < 0.01, "Blackmask ring darkens surviving pixels by 0.4")
	check(copy.is_solid(center) and copy.visual == null and copy.map_id == Maps.DEFAULT, "Collision copy is independent and owns no visual")

	# Spawns: player left, CPU right, both resting on solid snow; seeds vary.
	var model = Match.new()
	var left: Array = Maps.spawn_x(map, true)
	var right: Array = Maps.spawn_x(map, false)
	check(left.size() == 6 and right.size() == 5, "Spawn list splits into left and right halves")
	var seen := {}
	for seed_value in range(1, 31):
		model.start(1 + seed_value % 2, 1, seed_value)
		var a: Vector2 = model.actors[0].pos
		var b: Vector2 = model.actors[1].pos
		seen[a.x] = true
		var ok: bool = model.map_id == Maps.DEFAULT and left.has(a.x) and right.has(b.x)
		ok = ok and model.terrain.is_solid(a + Vector2(0, 26)) and model.terrain.is_solid(b + Vector2(0, 26))
		ok = ok and is_equal_approx(a.y, model.terrain.surface_at(a.x) - 24.0) and is_equal_approx(b.y, model.terrain.surface_at(b.x) - 24.0)
		if not ok:
			check(false, "Seed %d spawns on solid ground at its side" % seed_value)
	check(seen.size() >= 3, "Seeded matches draw different original spawns")
	check(model.map_id == Maps.DEFAULT and model.terrain.texture == null, "Map arena does not build the procedural texture")

	# Prediction and the live shell share the map mask (REQ-08).
	model.start(1, 1, 7)
	model.wind = 0.0
	var power := 15.0
	var predicted: Dictionary = {}
	while power <= 100.0:
		predicted = Combat.predict(model.muzzle(0, 45.0), model.shot_velocity(0, 45.0, power, 0), 0.0, model.terrain, model.actors, 0)
		if bool(predicted.get("hit", false)) or int(predicted.get("actor", -1)) >= 0:
			break
		power += 5.0
	model.fire(45.0, power, 0)
	for i in range(2400):
		model.tick(1.0 / 120.0)
		if model.phase != "flight":
			break
	var impact := Vector2.INF
	for event in model.events:
		if event.type == "explosion":
			impact = event.position
	check((bool(predicted.get("hit", false)) or int(predicted.get("actor", -1)) >= 0) and Vector2(predicted.position).distance_to(impact) < 2.0, "Prediction and live shot agree on a map impact")

	# Falling through the map still eliminates (REQ-05).
	model.start(1, 1, 9)
	var foot: Vector2 = model.actors[1].pos + Vector2(0, 24)
	for y in range(int(foot.y), 670, 20):
		model.terrain.carve(Vector2(foot.x, y), 60.0)
	model.settle_actors()
	model.check_end()
	check(model.phase == "finished" and model.winner == 0, "Digging down to the HUD line eliminates the CPU by fall")

	# Fallback: empty or unknown map keeps the procedural arena.
	model.start(2, 1, 5, "")
	check(model.map_id == "" and model.terrain.texture != null and model.actors[0].pos.x == 235.0, "Empty map keeps the procedural arena")
	model.start(2, 1, 5, "unknown")
	check(model.map_id == "" and model.terrain.texture != null, "Unknown map falls back to procedural terrain")

	# Scene: arena draws the map background and HD terrain.
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/map-test-profile.json")
	root.add_child(scene)
	if scene.get("sound") != null:
		scene.sound.muted = true
	scene.start_match()
	await process_frame
	var backdrop: Array = scene.map_background(scene.model.map_id)
	check(scene.model.map_id == Maps.DEFAULT and backdrop.size() == 2 and backdrop[0] is Texture2D, "Arena uses the Miramo Town background")
	var region: Rect2 = backdrop[1] if backdrop.size() == 2 else Rect2()
	check(region.size.x > 0.0 and is_equal_approx(region.size.x / region.size.y, 1.6), "Background window keeps the 1280×800 aspect")
	check(scene.model.terrain.visual_texture != null, "Arena draws the HD foreground texture")
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/map-test-profile.json"))
	print("MAP CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
