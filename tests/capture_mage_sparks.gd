extends SceneTree
## Real Match flight + native Mage/LaserEffect and additive decorative FX.
const Match = preload("res://scripts/match.gd")
const Game = preload("res://scripts/game.gd")
const WeatherArt = preload("res://scripts/weather_art.gd")
const OUT := "res://docs/mage-sparks/"
const FRAMES := "res://.tools/mage-sparks/frames/"
var models: Array=[]
var visuals: Array=[]
var centers: Array=[]
var seen: Array=[]
var peak: Array=[]
var panes: Array=[]
var sprites: Dictionary
var target: SubViewport
var elapsed:=0.0
var facing:=1
var is_paused:=false
var sound

class SparkPanel extends Node2D:
	var host
	var index: int
	func _draw() -> void:
		var model=host.models[index]
		draw_rect(Rect2(0,0,960,340),Color("182a3c") if index%2==0 else Color("8197ae"))
		for shell in model.projectiles:
			if bool(shell.launched):
				host.centers[index]=Vector2(shell.previous_hit_pos).lerp(shell.hit_pos,clampf(model.accumulator/0.05,0,1))
				break
		var offset: Vector2=Vector2(580 if host.facing==1 else 380,165)-host.centers[index]
		for x in range(0,2000,100):
			draw_line(Vector2(x+offset.x,0),Vector2(x+offset.x,340),Color(0.5,0.7,0.8,0.14))
		for shell in model.projectiles:
			var shown: Dictionary=shell.duplicate(true)
			shown.draw_fraction=clampf(model.accumulator/0.05,0,1)
			shown.hit_pos=Vector2(shell.previous_hit_pos).lerp(shell.hit_pos,shown.draw_fraction)
			shown.pos=Vector2(shell.previous_draw_pos).lerp(shell.pos,shown.draw_fraction)
			host.sprites[1].draw_projectile(self,shown,index/2,offset)
		host.visuals[index].draw_shell_marks(self,model,offset)
		draw_string(ThemeDB.fallback_font,Vector2(18,30),["T1","T2","SS"][index/2]+(" | Force" if index%2==0 else " | Electric")+" | %d partículas"%host.visuals[index].mage_sparks.particles.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)

class Board extends Node2D:
	var host
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("101c28"))
		draw_string(ThemeDB.fallback_font,Vector2(22,38),"Mage · partículas originais · "+("direita" if host.facing==1 else "esquerda")+" · t=%.2f · "%host.elapsed+("PAUSA" if host.is_paused else "20Hz / apresentação60Hz"),HORIZONTAL_ALIGNMENT_LEFT,-1,24)

func _initialize() -> void:call_deferred("run")

func reset_models() -> void:
	models.clear();visuals.clear();centers.clear();seen.clear();peak.clear()
	for weapon in 3:
		for climate in ["force","electricity"]:
			var model=Match.new()
			model.start(1,1,42,"")
			model.weather.columns.clear()
			model.weather.queue[0].type="wind"
			model.weather.thor.active=false
			model.wind=Vector2.ZERO
			model.terrain.cells.fill(0)
			for y in range(300,400):
				for x in 640:model.terrain.cells[y*640+x]=1
			model.terrain.native_cells=PackedByteArray()
			model.terrain.enable_native()
			model.actors[0].pos=Vector2(650,350)
			model.actors[0].facing=facing
			model.actors[1].pos=Vector2(100,750)
			var shells: Array=model.shot_shells(0,35,30,weapon)
			model.weather.add_column(climate,shells[0].pos.x,4.0)
			var visual=WeatherArt.new()
			visual.mage_sparks.reset(4242)
			assert(model.fire(35,30,weapon))
			models.append(model);visuals.append(visual);centers.append(shells[0].hit_pos);seen.append({});peak.append(0)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	root.size=Vector2i(1920,1080)
	sprites=Game.build_sprites()
	sound=load("res://scripts/sound.gd").new();sound.muted=true
	target=SubViewport.new();target.size=Vector2i(1920,1080);target.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(target)
	var board=Board.new();board.host=self;target.add_child(board)
	for index in 6:
		var sub=SubViewport.new();sub.size=Vector2i(960,340);sub.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		target.add_child(sub)
		var pane=SparkPanel.new();pane.host=self;pane.index=index;sub.add_child(pane);panes.append(pane)
		var display=TextureRect.new();display.texture=sub.get_texture();display.position=Vector2(index%2*960,60+(index/2)*340)
		target.add_child(display)
	var report: Array=[]
	var pause_hash:=""
	var began:=Time.get_ticks_msec()
	for frame in 360:
		var local:=frame%180
		if local==0:
			facing=1 if frame==0 else -1
			elapsed=0;reset_models()
		is_paused=local>=60 and local<90
		if not is_paused:
			elapsed+=1.0/60
			for index in 6:
				models[index].tick(1.0/60)
				visuals[index].tick(1.0/60,models[index])
				for event in models[index].events:visuals[index].react(event,models[index],sound)
				models[index].events.clear()
				for effect in visuals[index].mage_sparks.particles:
					seen[index][str([effect.kind,effect.position,effect.birth,effect.initial_angle])]=true
				peak[index]=maxi(peak[index],visuals[index].mage_sparks.particles.size())
		board.queue_redraw()
		for pane in panes:pane.queue_redraw()
		await process_frame
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var image:=target.get_texture().get_image()
		image.save_png(FRAMES+"frame%04d.png"%frame)
		if local in [30,59,60,89,120]:image.save_png(OUT+"frame%03d.png"%frame)
		var digest:=image.get_data().hex_encode().sha256_text()
		if local==60:pause_hash=digest
		if is_paused:assert(digest==pause_hash,"Native decorative FX freeze exactly during pause")
		if local==179:
			for index in 6:assert(not seen[index].is_empty(),"All real Mage weapons must create native particles")
			report.append({"facing":facing,"unique_particles":seen.map(func(values):return values.size()),"peak_alive":peak.duplicate(),"pause_30_identical":true})
	for visual in visuals:
		visual.clear_beams()
		assert(visual.mage_sparks.particles.is_empty())
		visual.mage_sparks.draw(panes[0],Vector2.ZERO)
		for canvas in visual.mage_sparks.canvases.values():RenderingServer.canvas_item_clear(canvas)
	var output=FileAccess.open(OUT+"gpu-validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"size":[1920,1080],"frames":360,"clock_hz":60,"directions":report,"clear_verified":true,"capture_write_seconds":(Time.get_ticks_msec()-began)/1000.0},"\t"));output.close()
	print("MAGE SPARKS GPU:360frames,12real-flight cases,2directions,30frame pauses identical,reset cleared")
	models.clear();visuals.clear();sprites.clear();sound.free();target.free()
	quit()
