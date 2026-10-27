extends "res://tests/support/suite.gd"
## Expected timelines, layer roles and Thor clocks transcribed from PE/EPA.
const Game = preload("res://scripts/game.gd")
const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Aduka = preload("res://scripts/aduka_effect.gd")
const WeatherArt = preload("res://scripts/weather_art.gd")

class SoundProbe extends RefCounted:
	var played: Array = []
	func play(_kind: String, stream = null) -> void:
		played.append(stream)

func run() -> void:
	var sprite = Game.build_sprites()[16]
	check(sprite.get_script().resource_path == "res://scripts/aduka_sprite.gd", "Active Aduka has its family renderer")
	check(sprite.rider_offset(0) == Vector2(0,-23) and sprite.rear, "Approved centered rider and rear firing survive the audit")
	check(sprite.frame_index("recoil",0.1,1,false) == 267, "T2 first emission uses the third EPA fire2 frame")
	check(sprite.frame_index("recoil",0.3,1,false) == 267, "T2 second emission repeats the EPA recoil")
	for weapon in 3:
		var emission: Array = Mobiles.emission(16,weapon)
		var ticks: Array = []
		for entry in emission:
			ticks.append(roundi(float(entry.spawn)*20))
		check(ticks == [[1],[2,6,10],[2,6,10]][weapon], "Native timeline plus requested three-creature T2 weapon%d"%weapon)
		check(not sprite.has_trail("aduka",weapon), "Aduka keeps the user's no-trail decision weapon%d"%weapon)
	check(sprite.has_method("projectile_layers"), "Aduka exposes the actual native layer composition")
	if sprite.has_method("projectile_layers"):
		var shot := {"launched":true,"pos":Vector2(200,100),"hit_pos":Vector2(200,100),"velocity":Vector2(200,0),"age":0.0}
		for weapon in 3:
			var layers: Array = sprite.projectile_layers(shot,weapon,Vector2.ZERO)
			check(layers.size() == [2,1,2][weapon], "Native body/light count weapon%d"%weapon)
			check(layers[-1].additive == (weapon!=1), "T2 colored fallback stays visible with alpha; actual glow remains additive weapon%d"%weapon)
			if weapon != 1:
				check(not layers[0].additive, "Physical body keeps alpha blend weapon%d"%weapon)
		var second: Array = sprite.projectile_layers(shot,1,Vector2.ZERO)
		check(second[0].sheet == "Bullet2.png" and second[0].target == Rect2(-17,-16,34,27), "T2 uses bullet16sl once at the native hotspot")
		shot.velocity = Vector2(-200,0)
		check(sprite.projectile_layers(shot,1,Vector2.ZERO)[0].flip_y, "T2 flips vertical UV on the left half of flight")
		check(not sprite.projectile_layers(shot,0,Vector2.ZERO)[0].flip_y, "T1 keeps the shared non-Facing draw")
	var aduka = Aduka.new()
	var model = Match.new()
	model.start(16,1,42,"")
	check(bool(model.weather.thor.get("present",false)), "Thor exists before the first Aduka guide impacts")
	check(bool(model.weather.thor.get("native",false)), "Aduka opts into the native Thor presentation/state")
	check(aduka.has_method("step_thor"), "Thor owns a shared model tick")
	if aduka.has_method("step_thor"):
		var thor: Dictionary = model.weather.thor
		thor.pos = Vector2(400,80)
		thor.display_pos = Vector2(400,100)
		thor.previous_display_pos = thor.display_pos
		aduka.call("step_thor",model)
		check(thor.display_pos == Vector2(400,99), "Native Y ease truncates (-20+7)/8 toward zero")
		check(thor.previous_display_pos == Vector2(400,100), "Render interpolation has the previous native position")
		var copied = model.weather.copy()
		aduka.call("step_thor",{"weather":copied})
		check(copied.thor.display_pos != thor.display_pos, "Snapshot Thor motion is isolated from the live model")
		thor.state = "fire"
		thor.state_tick = 0
		thor.active = false
		for tick in 15:
			aduka.call("step_thor",model)
		check(thor.state == "fire" and thor.state_tick == 15, "Thor retains fire through EPA tick15")
		aduka.call("step_thor",model)
		check(thor.state == "normal" and thor.state_tick == 0, "Thor returns to normal at EPA tick16")
	var art = WeatherArt.new()
	var sound = SoundProbe.new()
	var event := {"type":"thor","native":true,"source":"aduka","weapon":1,"from":Vector2(500,100),"position":Vector2(600,400),"level":1,"removed":0}
	art.react(event,model,sound)
	check(sound.played[-1] is AudioStreamWAV and sound.played[-1].resource_path.ends_with("22blast.wav"), "T2 plays original22blast PCM, not OpenBound's substitute MP3")
	event.weapon = 2
	art.react(event,model,sound)
	check(sound.played[-1] is AudioStreamWAV and sound.played[-1].resource_path.ends_with("22blast.wav"), "SS Thor effect uses the same432320 Mage T2 sound slot")
	var played_count: int = sound.played.size()
	event.contact = false
	art.react(event,model,sound)
	check(sound.played.size()==played_count,"Missing native contact record cannot play an impact sound")
	var guide_sound = load("res://scripts/classic_shot_timing.gd").stream(16,2,"blast")
	check(guide_sound is AudioStreamWAV and guide_sound.data.is_empty(), "Missing guide23blast does not invent a second sound")
	check(FileAccess.file_exists("res://assets/openbound/aduka/thor_native.json"), "Thor original body/light/EPA catalog ships")
	if FileAccess.file_exists("res://assets/openbound/aduka/thor_native.json"):
		var thor_art = load("res://scripts/thor_native_art.gd").new()
		var state := {"pos":Vector2(400,100),"display_pos":Vector2(400,100),"previous_display_pos":Vector2(400,100),"state":"normal","state_tick":0,"idle_tick":0,"native_angle":0}
		var sample: Dictionary = thor_art.sample(state)
		check(sample.position == Vector2(400,99) and sample.rotation == 0.0, "Native right heading has no PI correction; idle bob is minus1")
		state.state = "fire"
		state.state_tick = 3
		sample = thor_art.sample(state)
		check(sample.frame == 43 and sample.position == Vector2(400,100), "Fire EPA advances at20Hz and suppresses idle bob")
		state.native_angle = 270
		check(Vector2.RIGHT.rotated(float(thor_art.sample(state).rotation)).is_equal_approx(Vector2.DOWN), "Native default270 points down rather than up")
		check(thor_art.meta.sheets["ThorBody.png"].frames == 56 and thor_art.meta.sheets["ThorLight.png"].frames == 56, "Both native Thor layers retain56frames")
	var first = Match.new()
	var second_model = Match.new()
	first.start(16,1,77,"")
	second_model.start(16,1,77,"")
	for tick in 60:
		first.tick(1.0/30.0)
	for tick in 120:
		second_model.tick(1.0/60.0)
	check(first.weather.thor == second_model.weather.thor, "Thor model/EPA state agrees at30 and60FPS")
	finish("ADUKA NATIVE CHECKS")
