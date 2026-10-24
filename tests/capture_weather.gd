extends SceneTree
## REQ-24/25/26 GPU captures at 1920×1080: weather columns, forecast, Thor,
## lightning and ground particles on Miramo Town with the original sprites.
var view
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/weather/" + name + ".png")
func advance(seconds: float) -> void:
	for frame in range(int(seconds / 0.05)):
		view._process(0.05)
func run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/weather"))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new("res://.tools/weather-capture-profile.json")
	root.add_child(view)
	view.scale = Vector2(1.35, 1.35)
	view.position = Vector2(96, 0)
	view.set_process(false)
	view.sound.muted = true
	var bars := CanvasLayer.new()
	bars.layer = 10
	root.add_child(bars)
	for rect in [Rect2(0, 0, 96, 1080), Rect2(1824, 0, 96, 1080)]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = rect.position
		bar.size = rect.size
		bars.add_child(bar)
	view.profile.nickname = "Piloto"
	view.show_menu()
	view.select_vehicle(2)
	view.opening = 0
	view.start_match()
	view.model.start(2, 1, 4)
	view.art.reset(view.model.actors)
	view.weather_art.reset(view.Maps.get_map(view.model.map_id))
	view.consume_events()
	var player: Vector2 = view.model.actors[0].pos
	var cpu: Vector2 = view.model.actors[1].pos
	var weather = view.model.weather
	weather.columns.clear()
	weather.add_column("force", player.x + 230.0, 1.0)
	weather.add_column("tornado", player.x + 420.0, 1.0)
	weather.add_column("electricity", cpu.x - 120.0, 1.0)
	weather.add_column("random", player.x - 160.0, 1.0, "mirror")
	weather.thor.active = true
	weather.thor.pos = Vector2((player.x + cpu.x) * 0.5, 1050.0)
	weather.thor.level = 2
	weather.thor.xp = 950
	view.model.wind = Vector2.ZERO
	weather.wind_force = 12
	weather.wind_angle = 200
	view.model.wind = weather.wind_vector()
	view.aim.angle = 40
	# Pick the power whose shared-physics prediction lands near the CPU.
	view.aim.power = 60.0
	var best := INF
	for power in range(30, 100, 2):
		var landing: Dictionary = view.model.predict_shot(0, 40.0, float(power), 0)
		if landing.is_empty():
			continue
		var distance: float = Vector2(landing.position).distance_to(cpu)
		if distance < best:
			best = distance
			view.aim.power = float(power)
	view.update_hud()
	advance(1.5)
	await snap("weather-columns")
	view.shoot()
	view.consume_events()
	var saw_thor := false
	for frame in range(240):
		view._process(0.05)
		if not view.weather_art.beams.is_empty() and not saw_thor:
			saw_thor = true
			await snap("weather-thor-lightning")
		if view.model.phase != "flight" and saw_thor:
			break
	advance(0.25)
	await snap("weather-particles")
	view.paused = true
	var before: Array = view.weather_art.particles.duplicate(true)
	advance(0.5)
	print("PAUSE FREEZES PARTICLES: ", view.weather_art.particles == before, " | THOR XP ", weather.thor.xp, " | PARTICLES ", before.size())
	view.paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/weather-capture-profile.json"))
	quit()
