extends SceneTree
## Native-scale GPU QA of the integrated Match and active original renderers.
## Six independent real contacts: T1/T2/SS x right/left in 200px lanes.
## No main scene instantiation, profile, account or user input.
const Match = preload("res://scripts/match.gd")
const Game = preload("res://scripts/game.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const WeatherArt = preload("res://scripts/weather_art.gd")
const Sound = preload("res://scripts/sound.gd")
const OUT := "res://docs/special-mobiles/"
const FRAMES := "res://.tools/special-mobiles-fix/gpu-frames/"
const IDS := [10,9,16,7]
const NAMES := {8:"Lightning",10:"ASate",9:"JD",16:"Aduka",7:"Raon"}
const TOTAL := 300
var sprites: Dictionary
var models: Array = []
var impacts: Array = []
var weather_art: Array = []
var records: Array = []
var panels: Array = []
var sound
var view: SubViewport
var board
var mobile := 10
var elapsed := 0.0
var capture_paused := false
var output := OUT
var frame_output := FRAMES
var weather_capture := false
var report: Dictionary = {"resolution":[1920,1080],"world_area":[1280,800],"native_scale":1,"simulation_hz":20,"presentation_hz":60,"frames_per_mobile":TOTAL,"pause_frames":[90,119],"fixtures":"six independent real short flights with controlled initial positions/velocities; common swept contact; no profile","runs":[]}

class Board extends Node2D:
	var host
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("11232e"))
		draw_string(font,Vector2(320,60),"%s | %s | Gunbound Classic"%[host.NAMES[host.mobile],"T2 · vento atual e tornado" if host.weather_capture else "T1 · T2 · SS"],HORIZONTAL_ALIGNMENT_LEFT,-1,32)
		draw_string(font,Vector2(320,100),"Sprites nativos1:1 · modelo20Hz · captura60Hz · t=%.2fs · %s"%[host.elapsed,"PAUSA" if host.capture_paused else "ANIMAÇÃO"],HORIZONTAL_ALIGNMENT_LEFT,-1,20)
		draw_string(font,Vector2(320,985),"Cada coluna: contato real em terreno simples, efeito e impacto. Sem perfil; áudio silenciado.",HORIZONTAL_ALIGNMENT_LEFT,-1,18)
		draw_string(font,Vector2(320,1022),"Fixtures do Godot integrado; não são execução do cliente original nem aceite visual.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("9cb5c4"))

class Lane extends Node2D:
	var host
	var index := 0
	var ui := {"bold":ThemeDB.fallback_font,"INK":Color.BLACK}
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		var model = host.models[index]
		var group := int(index/2)
		var weapon := 1 if host.weather_capture else group
		var facing := 1 if index%2 == 0 else -1
		var sprite = host.sprites[host.mobile]
		if sprite.has_method("begin_projectiles"):
			sprite.begin_projectiles(self)
		draw_rect(Rect2(0,0,200,800),Color("18313c") if index%2 == 0 else Color("142c38"))
		var caption: String = ["calmo","vento+27/tornado","vento−27/tornado"][group] if host.weather_capture else ["T1","T2","SS"][weapon]
		draw_string(font,Vector2(8,24),"%s · %s"%[caption,"→" if facing == 1 else "←"],HORIZONTAL_ALIGNMENT_LEFT,-1,15)
		# Flat fixture mask is the actual model's image and keeps crater changes.
		draw_texture_rect(model.terrain.texture,Rect2(0,0,200,800),false)
		host.weather_art[index].draw_columns(self,model,Vector2.ZERO)
		for satellite in model.satellites.values():
			sprite.satellite_art.draw_satellite(self,satellite,Vector2.ZERO,clampf(float(model.accumulator)/0.05,0,1))
		for actor_index in 2:
			var actor: Dictionary = model.actors[actor_index]
			var body = host.sprites[int(actor.vehicle)]
			var pose := "recoil" if actor_index == 0 and host.elapsed < body.pose_duration("recoil",weapon,false) else "idle"
			body.draw(self,host.Pose.new(actor.pos,60,int(actor.facing),{"frame":body.frame_index(pose,host.elapsed,weapon,false),"age":host.elapsed,"pose":pose,"weapon":weapon}))
		for source in model.projectiles:
			var shot: Dictionary = source.duplicate()
			var blend := clampf(float(model.accumulator)/0.05,0,1)
			shot.draw_fraction = blend
			shot.hit_pos = Vector2(shot.get("previous_hit_pos",shot.hit_pos)).lerp(shot.hit_pos,blend)
			shot.pos = Vector2(shot.get("previous_draw_pos",shot.pos)).lerp(shot.pos,blend)
			sprite.draw_projectile(self,shot,int(shot.weapon),Vector2.ZERO)
		var marks: Array = model.mines.duplicate()
		for effect in model.battle_effects:
			if str(effect.kind) == "jd_crystal":
				marks.append(effect)
		host.sprites[7].draw_placed(self,marks,model.actors,Vector2.ZERO)
		host.weather_art[index].draw_thor(self,model,Vector2.ZERO)
		host.weather_art[index].draw_beams(self,Vector2.ZERO)
		for effect in host.impacts[index]:
			sprite.draw_effect(self,effect,Vector2.ZERO)
		draw_line(Vector2(199,0),Vector2(199,800),Color("45606d"),1)
		var stats: Dictionary = host.records[index]
		draw_string(font,Vector2(8,755),"filhos%d · Thor%d"%[stats.children,stats.thor],HORIZONTAL_ALIGNMENT_LEFT,-1,16)
		draw_string(font,Vector2(8,779),"impactos%d · minas%d"%[stats.explosions,model.mines.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,16)

func _initialize() -> void:
	call_deferred("run")

func reset_models() -> void:
	models.clear(); impacts.clear(); weather_art.clear(); records.clear()
	for group in 3:
		var weapon := 1 if weather_capture else group
		for facing in [1,-1]:
			var model = Match.new()
			model.start(mobile,1,42,"","original")
			model.wind = Vector2.ZERO
			model.weather.columns.clear()
			model.weather.thor.active = false
			if weather_capture:
				model.wind = Vector2([0,27,-27][group],0)
				if group>0:
					model.weather.add_column("tornado",100,1.0)
			var terrain = model.terrain
			terrain.WIDTH = 100; terrain.HEIGHT = 400
			terrain.cells.resize(40000); terrain.cells.fill(0)
			terrain.image = Image.create(100,400,false,Image.FORMAT_RGBA8)
			terrain.image.fill(Color.TRANSPARENT)
			for y in range(350,400):
				for x in 100:
					terrain.cells[y*100+x] = 1
					terrain.image.set_pixel(x,y,Color("685741") if y > 350 else Color("cdbd88"))
			terrain.texture = ImageTexture.create_from_image(terrain.image)
			terrain.visual = null
			if mobile in [8,16]:
				terrain.native_cells.clear()
				terrain.enable_native()
			if mobile==16:
				# Native Thor stays inside this narrow controlled contact lane.
				model.weather.thor.pos = Vector2(100,350)
				model.weather.thor.display_pos = model.weather.thor.pos
				model.weather.thor.previous_display_pos = model.weather.thor.pos
			model.actors[0].pos = Vector2(45 if facing > 0 else 155,675)
			model.actors[0].facing = facing
			model.actors[1].pos = Vector2(155 if facing > 0 else 45,675)
			model.actors[1].facing = -facing
			model.actors[1].hp = 10000; model.actors[1].max_hp = 10000; model.actors[1].shield = 500
			model.fire(40,50,weapon)
			# Keep the real EPA launch schedule and child composition. Shorten
			# only the test trajectory so all four reported effects get a contact.
			for shell in model.projectiles:
				var target_x: float = float(model.actors[1].pos.x)-facing*20
				shell.pos = Vector2(target_x,610)
				shell.hit_pos = shell.pos
				shell.previous_draw_pos = shell.pos
				shell.previous_hit_pos = shell.pos
				shell.velocity = Vector2(facing*8,180)
				if weather_capture:
					shell.pos = Vector2(50 if facing>0 else 150,550)
					shell.hit_pos = shell.pos
					shell.previous_draw_pos = shell.pos
					shell.previous_hit_pos = shell.pos
					shell.velocity = Vector2(facing*180,-25)
				shell.trail = [shell.pos]
				shell.age = 0.0; shell.fp_ready = false
				shell.erase("launch_velocity_fp")
			model.events.clear()
			models.append(model); impacts.append([]); weather_art.append(WeatherArt.new())
			records.append({"weapon":weapon,"facing":facing,"children":0,"thor":0,"explosions":0,"effect_ticks":0,"maximum_mines":0,"event_types":{}})

func advance() -> void:
	elapsed += 1.0/60
	for index in models.size():
		var model = models[index]
		if model.phase == Match.PHASE_FLIGHT:
			model.advance_projectiles(1.0/60)
		elif mobile==16:
			model.tick(1.0/60)
		weather_art[index].tick(1.0/60,model)
		for effect in impacts[index]:
			effect.age += 1.0/60
		for event in model.events:
			var type := str(event.type)
			var stats: Dictionary = records[index]
			stats.event_types[type] = int(stats.event_types.get(type,0))+1
			if type == "explosion":
				stats.explosions += 1
				impacts[index].append({"pos":event.position,"weapon":event.weapon,"child":event.get("child",false),"ss_state":event.get("ss_state","normal"),"age":0.0,"angle":event.angle})
			if type == "projectile_launch" and bool(event.get("child",false)):
				stats.children += 1
			if type == "thor":
				stats.thor += 1
			weather_art[index].react(event,model,sound)
		model.events.clear()
		records[index].maximum_mines = maxi(int(records[index].maximum_mines),model.mines.size())
		if not model.battle_effects.is_empty():
			records[index].effect_ticks += 1

func run() -> void:
	var targets: Array = IDS
	if "--aduka" in OS.get_cmdline_user_args():
		targets = [16]
		output = "res://docs/aduka-audit/"
		frame_output = "res://.tools/aduka-audit/gpu-frames/"
	if "--aduka-combat" in OS.get_cmdline_user_args():
		targets = [16]
		output = "res://docs/aduka-combat/"
		frame_output = "res://.tools/aduka-combat/gpu-frames/"
	if "--aduka-weather" in OS.get_cmdline_user_args():
		targets = [16]
		weather_capture = true
		output = "res://docs/aduka-combat/weather/"
		frame_output = "res://.tools/aduka-combat/weather-frames/"
	if "--lightning" in OS.get_cmdline_user_args() or "--lightning-weather" in OS.get_cmdline_user_args():
		report.pause_frames=[30,59]
		report.fixtures="six controlled Lightning launches; native contact/terrain/beam/shock; no profile"
		targets=[8]
		weather_capture="--lightning-weather" in OS.get_cmdline_user_args()
		output="res://docs/lightning-review/weather/" if weather_capture else "res://docs/lightning-review/"
		frame_output="res://.tools/lightning-review/weather-frames/" if weather_capture else "res://.tools/lightning-review/gpu-frames/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frame_output))
	sprites = Game.build_sprites()
	sound = Sound.new(); sound.muted = true; root.add_child(sound)
	view = SubViewport.new(); view.size = Vector2i(1920,1080)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	board = Board.new(); board.host = self; view.add_child(board)
	for index in 6:
		var lane_view := SubViewport.new(); lane_view.size = Vector2i(200,800)
		lane_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		view.add_child(lane_view)
		var panel := Lane.new(); panel.host = self; panel.index = index; lane_view.add_child(panel); panels.append(panel)
		var display := TextureRect.new(); display.texture = lane_view.get_texture()
		display.position = Vector2(320+index*200,140); display.size = Vector2(200,800)
		view.add_child(display)
	for id in targets:
		mobile = id; elapsed = 0; reset_models()
		var folder := frame_output+str(id)+"/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
		var hashes: Array = []
		var begin_time := Time.get_ticks_usec()
		for frame in TOTAL:
			capture_paused = frame >= (30 if mobile==8 else 90) and frame < (60 if mobile==8 else 120)
			if not capture_paused:
				advance()
			board.queue_redraw()
			for panel in panels:
				panel.queue_redraw()
			await process_frame
			# Explicit offscreen draw also works when macOS occludes the empty
			# parent window; waiting for its automatic frame can stop indefinitely.
			RenderingServer.force_draw()
			var picture := view.get_texture().get_image()
			var path := folder+"%03d.png"%frame
			picture.save_png(path)
			hashes.append(FileAccess.get_sha256(path))
			if frame in [18,30,59,60,90,119,150,210,299]:
				picture.save_png(output+"%s-%03d.png"%[str(NAMES[id]).to_lower(),frame])
		var identical := true
		var pause_start:=30 if mobile==8 else 90
		for frame in range(pause_start+1,pause_start+30):
			identical = identical and hashes[frame] == hashes[pause_start]
		report.runs.append({"id":id,"mobile":NAMES[id],"frames":TOTAL,"elapsed_wall_seconds":float(Time.get_ticks_usec()-begin_time)/1000000,"pause30_identical":identical,"resume_changes_pixels":hashes[pause_start+30] != hashes[pause_start+29],"frame_sha256":hashes,"events":records.duplicate(true)})
		print("SPECIAL GPU ",NAMES[id],":300frames1920x1080, pause30=",identical,", resume=",hashes[pause_start+30] != hashes[pause_start+29])
	var manifest := FileAccess.open(output+"manifest.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify(report,"\t")+"\n")
	sound.queue_free()
	quit()
