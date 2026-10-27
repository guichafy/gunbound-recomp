extends "res://tests/support/suite.gd"
## REQ-21/22/48: Miramo Town A in native coordinates — collision and visual from the
## client "mos" files (ADR-133), spawns, craters, prediction, camera and fallback.
func run() -> void:
	var Maps = load("res://scripts/maps.gd")
	var Terrain = load("res://scripts/terrain.gd")
	var Match = load("res://scripts/match.gd")
	var map: Dictionary = Maps.get_map(Maps.DEFAULT)
	check(Maps.DEFAULT == "miramo_town_a" and not map.is_empty(), "Default arena is Miramo Town A")
	check(map.openbound_id == 20 and map.type == "A" and map.spawns.size() == 11, "Catalog mirrors Map.cs ID20 and its 11 spawn points")
	check(map.weather == [2, 1, 2, 1, 0, 2, 0, 0, 0, 1], "Weather preset is copied from Map.cs")

	# Collision truth: every cell equals the original alpha at its centre (1:1 world).
	var terrain = Terrain.new()
	check(terrain.load_map(Maps.DEFAULT), "Map loads from the original foreground")
	check(Maps.path(map, "mask") == "res://assets/xfs/maps/mos/foreground.png", "Collision reads the client foreground (mos.img frame 0)")
	var source: Image = Terrain.texture_image(Maps.path(map, "mask"))
	check(source != null and source.get_size() == Vector2i(1800, 1800), "Client foreground is available at native size")
	check(terrain.world_size() == Vector2(1800, 1800) and terrain.WIDTH == 900 and terrain.HEIGHT == 900, "World is the native 1800×1800 foreground on 2 px cells")
	var mismatched := 0
	var solid := 0
	for y in range(terrain.HEIGHT):
		for x in range(terrain.WIDTH):
			var expected: bool = source.get_pixel(x * 2 + 1, y * 2 + 1).a > 0.0
			var actual: bool = terrain.cells[y * terrain.WIDTH + x] != 0
			solid += 1 if actual else 0
			mismatched += 1 if expected != actual else 0
	check(mismatched == 0, "Collision mask equals the original alpha (%d mismatches)" % mismatched)
	check(solid > 150000, "Map provides the full snow body (%d cells)" % solid)
	check(not terrain.is_solid(Vector2(900, 1200)) and terrain.is_solid(Vector2(900, 1600)), "Sky above and snow body below the surface")
	var surface: float = terrain.surface_at(900.0)
	check(surface > 1344.0 and surface < 1450.0, "Surface matches the original foreground band (%.1f)" % surface)
	check(terrain.is_void(terrain.surface_at(5.0)) and terrain.void_y() == 1850.0, "Columns without ground report the void below the world")

	# The drawn foreground is the client raster itself, at density 1.
	check(terrain.visual != null and terrain.visual.get_size() == Vector2i(1766, 456), "Client foreground is drawn at native size (1766×456 crop)")
	check(terrain.visual_rect == Rect2(17, 1344, 1766, 456), "Drawn foreground covers the original alpha crop")
	check(terrain.visual.get_data() == source.get_region(map.crop).get_data(), "Drawn pixels are the client foreground pixels")
	var density := 1.0
	var disagree := 0
	var sampled := 0
	for y in range(672, 900, 2):
		for x in range(9, 891, 3):
			var world := Vector2(x * 2 + 1.0, y * 2 + 1.0)
			var local: Vector2 = (world - terrain.visual_rect.position) * density
			if local.x < 0.0 or local.y < 0.0 or local.x >= 1766.0 or local.y >= 456.0:
				continue
			sampled += 1
			var shown: bool = terrain.visual.get_pixel(int(local.x), int(local.y)).a > 0.5
			if shown != (terrain.cells[y * terrain.WIDTH + x] != 0):
				disagree += 1
	check(sampled > 20000 and disagree == 0, "Visual alpha equals collision (%d/%d samples differ)" % [disagree, sampled])

	# Client import record and fallback copies (identical pixels, ADR-133).
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/xfs/maps/mos/catalog.json"))
	check(catalog is Dictionary and catalog.stage.name == "MiramoTown" and catalog.stage.prefix == "mos", "stage.dat record names the mos graphics")
	var files_ok := catalog is Dictionary
	for key in ["foreground", "background", "particle"]:
		var record: Dictionary = catalog.files[key]
		files_ok = files_ok and FileAccess.get_sha256(record.file) == record.sha256 and bool(record.matches_legacy)
	check(files_ok, "Catalog hashes match the imported PNGs, all equal to the earlier copies")
	check(bool(catalog.files.foreground.alpha_equals_lnd) and catalog.entries["mos.lnd"].size == [1800.0, 1800.0], "Importer proved foreground alpha == mos.lnd")
	var legacy: Image = Terrain.texture_image(map.fallback.mask)
	check(legacy != null and legacy.get_data() == source.get_data(), "Fallback ForegroundA decodes to the same pixels")
	var missing: Dictionary = map.duplicate(true)
	for key in ["mask", "background", "particle"]:
		missing[key] = "res://assets/xfs/maps/missing/%s.png" % key
	check(Maps.path(missing, "mask") == map.fallback.mask and Maps.path(missing, "background") == map.fallback.background and Maps.path(missing, "particle") == map.fallback.particle, "Missing client files fall back to the earlier copies, never to HD")
	var fallback_mask: Dictionary = Terrain.mask_from_source(Terrain.texture_image(Maps.path(missing, "mask")), missing)
	var fallback_visual: Image = Terrain.original_visual(missing)
	check(fallback_mask.cells == terrain.cells and fallback_visual != null and fallback_visual.get_data() == terrain.visual.get_data(), "Fallback copy yields the same collision and drawing")
	check(not map.has("foreground_hd") and not map.has("background_hd"), "GPT HD layers are not referenced by the active map")
	check(FileAccess.file_exists("res://assets/hd/maps/miramo_town/foreground_a.png") and FileAccess.file_exists("res://assets/hd/maps/miramo_town/background.png"), "GPT HD layers stay preserved on disk")

	# Craters: cells and HD pixels, ring darkened like Topography.CreateErosion.
	var center := Vector2(900, terrain.surface_at(900.0) + 40.0)
	var ring_point: Vector2 = center + Vector2(26.5, 0)
	var ring_local: Vector2 = (ring_point - terrain.visual_rect.position) * density
	var before_ring: Color = terrain.visual.get_pixel(int(ring_local.x), int(ring_local.y))
	var copy = terrain.collision_copy()
	var revision: int = terrain.revision
	var removed: int = terrain.carve(center, 25.0)
	var center_local: Vector2 = (center - terrain.visual_rect.position) * density
	check(not terrain.is_solid(center) and terrain.revision == revision + 1, "Crater removes collision cells")
	check(removed > 400 and removed < 520, "Carve reports removed cells for ground particles (%d)" % removed)
	check(terrain.visual.get_pixel(int(center_local.x), int(center_local.y)).a == 0.0, "Crater erases client foreground pixels")
	var after_ring: Color = terrain.visual.get_pixel(int(ring_local.x), int(ring_local.y))
	check(before_ring.a > 0.0 and after_ring.a > 0.0 and absf(after_ring.r - before_ring.r * 0.4) < 0.01, "Blackmask ring darkens surviving pixels by 0.4")
	check(copy.is_solid(center) and copy.visual == null and copy.world_size() == terrain.world_size(), "Collision copy is independent, same size, no visual")

	# Spawns: native Map.cs points, player left, CPU right, resting on solid snow.
	var model = Match.new()
	var left: Array = Maps.spawn_points(map, true, 1800.0)
	var right: Array = Maps.spawn_points(map, false, 1800.0)
	check(left.size() == 6 and right.size() == 5, "Spawn list splits into left and right halves")
	var seen := {}
	for seed_value in range(1, 31):
		model.start(1 + seed_value % 2, 1, seed_value)
		var a: Vector2 = model.actors[0].pos
		var b: Vector2 = model.actors[1].pos
		seen[a.x] = true
		var listed_a := false
		var listed_b := false
		for point in left:
			listed_a = listed_a or (is_equal_approx(point.x, a.x) and absf(point.y - a.y) < 80.0)
		for point in right:
			listed_b = listed_b or (is_equal_approx(point.x, b.x) and absf(point.y - b.y) < 80.0)
		var ok: bool = model.map_id == Maps.DEFAULT and listed_a and listed_b
		ok = ok and model.terrain.is_solid(a + Vector2(0, model.stance_of(0) + 2.0)) and model.terrain.is_solid(b + Vector2(0, model.stance_of(1) + 2.0))
		if not ok:
			check(false, "Seed %d spawns on solid ground near its Map.cs point" % seed_value)
	check(seen.size() >= 3, "Seeded matches draw different original spawns")
	check(model.terrain.texture == null, "Map arena does not build the procedural texture")

	# Prediction and the live shell share the map mask (REQ-08).
	model.start(1, 1, 7)
	model.wind = Vector2.ZERO
	var power := 15.0
	var predicted: Dictionary = {}
	while power <= 100.0:
		predicted = model.predict_shot(0, 45.0, power, 0)
		if bool(predicted.get("hit", false)):
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
	check(bool(predicted.get("hit", false)) and Vector2(predicted.position).distance_to(impact) < 2.0, "Prediction and live shot agree on a map impact")

	# Falling below the world eliminates (REQ-05).
	model.start(1, 1, 9)
	model.wind = Vector2.ZERO
	var foot: Vector2 = model.actors[1].pos + Vector2(0, model.stance_of(1))
	for y in range(int(foot.y), 1820, 20):
		model.terrain.carve(Vector2(foot.x, y), 60.0)
	model.settle_actors()
	model.check_end()
	check(model.phase == "finished" and model.winner == 0, "Digging through the map eliminates the CPU by fall")

	# Fallback: empty or unknown map keeps the procedural arena.
	model.start(2, 1, 5, "")
	check(model.map_id == "" and model.terrain.texture != null and model.actors[0].pos.x == 235.0 and model.terrain.world_size() == Vector2(1280, 800), "Empty map keeps the procedural arena")
	model.start(2, 1, 5, "unknown")
	check(model.map_id == "" and model.terrain.texture != null, "Unknown map falls back to procedural terrain")

	# Scene: camera, parallax background and HD terrain (REQ-22).
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/map-test-profile.json")
	root.add_child(scene)
	if scene.get("sound") != null:
		scene.sound.muted = true
	scene.opening = 0
	scene.start_match()
	await process_frame
	var limits: Rect2 = scene.camera_limits()
	check(limits.position == Vector2.ZERO and limits.end.is_equal_approx(Vector2(520,1134.4)), "Camera range shows the whole 1800×1800 world above the HUD")
	var player_screen: Vector2 = Vector2(scene.model.actors[0].pos) - scene.rig.position
	check(Rect2(Vector2.ZERO, scene.VIEW_SIZE).has_point(player_screen), "Match opens with the player on screen")
	scene.update_hud()
	player_screen = Vector2(scene.model.actors[0].pos) - scene.rig.position
	check(Rect2(Vector2.ZERO, scene.VIEW_SIZE).has_point(player_screen + Vector2(0, 40)), "Life bar (actor + 40 px, drawn in world space) stays above the action bar")
	var backdrop: Dictionary = scene.map_background(scene.model.map_id)
	check(not backdrop.is_empty() and backdrop.texture.resource_path == map.background and backdrop.texture.get_size() == Vector2(1300, 1300) and backdrop.density == 1.0, "Arena draws the client background (mos.img frame 1, 1300×1300)")
	scene.rig.position = Vector2(0, 0)
	var top_region: Rect2 = scene.background_region(backdrop)
	scene.rig.position = Vector2(520,1134.4)
	var bottom_region: Rect2 = scene.background_region(backdrop)
	check(is_equal_approx(top_region.size.x / top_region.size.y, 1.6) and top_region.position.y == 0.0, "Parallax starts at the top of the client background")
	check(bottom_region.end.y <= 1300.5 and bottom_region.position.y > top_region.position.y, "Parallax slides down within the client background")
	scene.rig.manual = false
	var before: Vector2 = scene.rig.position
	scene.update_camera(1.0 / 60.0)
	check(scene.rig.position.distance_to(before) > 0.0, "Camera eases toward the active actor")
	var drag := InputEventMouseButton.new()
	drag.button_index = MOUSE_BUTTON_LEFT
	drag.pressed = true
	drag.position = Vector2(640, 300)
	scene._unhandled_input(drag)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120, 40)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	scene.rig.position = Vector2(300, 600)
	scene._unhandled_input(motion)
	check(scene.rig.position == Vector2(180, 560) and scene.rig.manual, "Dragging pans the camera and pauses tracking")
	scene.update_camera(1.0 / 60.0)
	check(scene.rig.position == Vector2(180, 560), "Manual camera holds until the next turn or shot")
	var hover := InputEventMouseMotion.new()
	hover.relative = Vector2(50, 50)
	scene._unhandled_input(hover)
	check(scene.rig.position == Vector2(180, 560) and not scene.dragging, "Motion without a pressed button never pans (release eaten by the HUD)")
	check(scene.model.terrain.visual_texture != null, "Arena draws the client foreground texture")
	check(scene.weather_art.ground != null and scene.weather_art.ground.resource_path == map.particle, "Ground particles use the client pmos frames")
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/map-test-profile.json"))
	finish("MAP CHECKS")
