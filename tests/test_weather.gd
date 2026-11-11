extends "res://tests/support/suite.gd"
## Active global weather; preserved adapter is tested in test_weather_legacy.
const Match = preload("res://scripts/match.gd")
func run() -> void:
	var model=Match.new()
	model.start(2,1,41,"miramo_town_a","all",null,[],[],[],0,4)
	check(model.weather.weights==[1,1,1,1,1,1,1],"All training preset enables exactly seven native categories")
	var seen: Dictionary={}
	for turn in 18:
		seen[model.weather.queue[0].type]=true
		model.begin_turn()
	check(seen.size()==7 and not seen.has("weakness") and not seen.has("mirror") and not seen.has("random"),"All mode traverses seven categories across calendar wrap")
	model.start(2,1,41,"miramo_town_a","original",null,[],[],[],0,4)
	check(model.weather.weights==[2,1,2,1,2,0,0],"Miramo native stage preset applies without Mage")
	var initial: Array=model.weather.queue.map(func(entry):return entry.type)
	model.schedule(0,50)
	check(model.weather.queue.map(func(entry):return entry.type)==initial,"Second actor turn holds the same calendar slot")
	model.schedule(model.active,50)
	check(model.weather.queue[0].type==initial[1],"Third actor turn enters next calendar slot")
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/issue26-weather-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.opening=0
	scene.show_menu()
	for mode in ["original","all"]:
		for random_slot in [false,true]:
			scene.menu.player_vehicle_id=2
			scene.menu.cpu_vehicle_id=4
			scene.menu.player_random=random_slot
			scene.menu.cpu_random=random_slot
			scene.menu.saved_weather=mode
			scene.menu.refresh_climate()
			var weights: Array=[]
			for counter in scene.menu.climate_weights:weights.append(int(counter.text))
			check(weights==([2,1,2,1,0,0,0,2] if mode=="original" else [1,1,1,1,0,1,1,1]),"Room weights reflect native calendar without Mage, including Random slots")
			check("Eclipse" in scene.menu.climate_weights[6].tooltip_text and preload("res://scripts/i18n.gd").text("Lua") in scene.menu.climate_weights[5].tooltip_text,"Room tooltips identify native Moon/Eclipse")
	scene.start_match()
	scene.model.start(2,1,41,"miramo_town_a","all",null,[],[],[],0,4)
	scene.model.weather.add_column("electricity",900,1)
	scene.consume_events()
	scene.weather_art.emit_ground(Vector2(900,1400),480,PI*0.5,scene.model)
	scene.show_pause()
	var particles: Array=scene.weather_art.particles.duplicate(true)
	var thor: Dictionary=scene.model.weather.thor.duplicate(true)
	var cursor: int=scene.model.weather.random_cursor
	var age: Dictionary=scene.weather_art.column_age.duplicate(true)
	for frame in 30:scene._process(1.0/60)
	check(scene.weather_art.particles==particles and scene.model.weather.thor==thor and scene.model.weather.random_cursor==cursor and scene.weather_art.column_age==age,"Pause freezes global Thor/calendar and weather presentation30frames")
	scene.close_overlay()
	scene._process(0.2)
	check(scene.weather_art.particles!=particles and scene.weather_art.column_age!=age,"Weather presentation resumes without Mage")
	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/issue26-weather-profile.json"))
	finish("WEATHER CHECKS")
