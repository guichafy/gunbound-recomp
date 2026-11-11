extends SceneTree
## Six real model panels, native/smooth art untouched. Manually stepped60Hz;
## this is GPU presentation QA, not an original-client or FPS benchmark.
const Match = preload("res://scripts/match.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const FRAMES := 301
const PAUSE_FROM := 45
const PAUSE_TO := 75
var mode := "normal"
var models: Array = []
var panels: Array = []
var effects: Array = []
var arts: Array = []
var counts: Array = []
var sprite
var sound
var viewport: SubViewport
var frame := 0
var elapsed := 0.0
var pause_state: Array = []
var pause_hash := ""
var journal: Array = []

class BigfootPanel extends Node2D:
	var host
	var index: int
	func _draw() -> void:
		var m = host.models[index]
		var facing: int = m.actors[0].facing
		var offset := Vector2(-120 if facing>0 else -520,100)
		draw_rect(Rect2(0,0,640,540),Color("719ab8"))
		host.arts[index].draw_columns(self,m,offset)
		draw_texture_rect(m.terrain.texture,Rect2(offset,Vector2(1280,800)),false)
		host.sprite.draw(self,Pose.new(m.actors[0].pos+offset,60,facing,{"pose":"recoil","age":host.elapsed,"weapon":index%3}))
		var fraction := clampf(float(m.projectile_accumulator)/0.05,0.0,1.0)
		host.sprite.begin_projectiles(self)
		for source in m.projectiles:
			if not source.launched:continue
			var shell: Dictionary=source.duplicate(true)
			shell.draw_fraction=fraction
			shell.pos=Vector2(shell.previous_draw_pos).lerp(shell.pos,fraction)
			shell.hit_pos=Vector2(shell.previous_hit_pos).lerp(shell.hit_pos,fraction)
			host.sprite.draw_projectile(self,shell,int(shell.weapon),offset)
		for effect in host.effects[index]:host.sprite.draw_effect(self,effect,offset)
		host.arts[index].draw_beams(self,offset)
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(0,0,640,70),Color("10212b"))
		draw_string(ThemeDB.fallback_font,Vector2(18,30),"Bigfoot %s · %s · %s"%[["T1","T2","SS"][index%3],"→" if facing>0 else "←",host.mode],HORIZONTAL_ALIGNMENT_LEFT,-1,22)
		draw_string(ThemeDB.fallback_font,Vector2(18,57),"%d impactos · %d ativos · tick%d"%[host.counts[index],m.projectiles.size(),m.spark_tick],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
		draw_line(Vector2(0,539),Vector2(640,539),Color.WHITE,2)

func _initialize() -> void:
	call_deferred("run")

func state() -> Array:
	return models.map(func(m):return [m.projectiles.duplicate(true),m.actors.duplicate(true),m.terrain.native_cells.duplicate(),m.weather.thor.duplicate(true),m.spark_tick,m.projectile_accumulator])

func make_model(weapon: int, facing: int):
	var m = Match.new()
	m.start(2,1,42,"","original",null,[],[],[],0,4)
	m.weather.columns.clear()
	m.weather.queue[0].type="wind"
	m.wind=Vector2(8,-3) if mode=="normal" else Vector2(-8,3)
	m.terrain.cells.fill(0)
	for y in range(150,400):
		for x in 640:m.terrain.cells[y*640+x]=1
	m.terrain.image=Image.create(640,400,false,Image.FORMAT_RGBA8)
	m.terrain.image.fill(Color.TRANSPARENT)
	m.terrain.image.fill_rect(Rect2i(0,150,640,250),Color("675b37"))
	m.terrain.texture=ImageTexture.create_from_image(m.terrain.image)
	m.terrain.native_cells=PackedByteArray()
	m.terrain.enable_native()
	m.actors[0].pos=Vector2(200 if facing>0 else 1080,300-m.stance_of(0))
	m.actors[0].facing=facing
	m.actors[1].pos=Vector2(1100 if facing>0 else 180,300-m.stance_of(1))
	m.actors[0].invulnerable=true
	m.actors[1].invulnerable=true
	if mode=="tornado":m.weather.add_column("tornado",350 if facing>0 else 930,0.5)
	if mode=="attachments":
		m.weather.add_column("force",300 if facing>0 else 980,1)
		m.weather.add_column("electricity",350 if facing>0 else 930,1)
		m.weather.queue[0].type="thor"
	m.fire(30,35,weapon)
	m.events.clear()
	return m

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():mode=args[0]
	var output := "res://.tools/bigfoot-native/frames-"+mode
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/bigfoot-native"))
	sprite=load("res://scripts/classic_sprite.gd").new()
	sprite.setup("bigfoot")
	sound=load("res://scripts/sound.gd").new()
	sound.muted=true
	root.add_child(sound)
	viewport=SubViewport.new()
	viewport.size=Vector2i(1920,1080)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for index in 6:
		models.append(make_model(index%3,1 if index<3 else -1))
		effects.append([])
		counts.append(0)
		arts.append(load("res://scripts/weather_art.gd").new())
		var panel_view := SubViewport.new()
		panel_view.size=Vector2i(640,540)
		panel_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		viewport.add_child(panel_view)
		var pane := BigfootPanel.new()
		pane.host=self
		pane.index=index
		panel_view.add_child(pane)
		panels.append(pane)
		var display := TextureRect.new()
		display.position=Vector2((index%3)*640,(index/3)*540)
		display.size=Vector2(640,540)
		display.texture=panel_view.get_texture()
		viewport.add_child(display)
	for n in FRAMES:
		frame=n
		if frame==PAUSE_FROM:
			pause_state=state()
			assert(models.any(func(m):return not m.projectiles.is_empty()))
		if frame==PAUSE_TO:assert(pause_state==state())
		if frame<PAUSE_FROM or frame>=PAUSE_TO:
			elapsed+=1.0/60.0
			for index in 6:
				var m = models[index]
				if m.phase==Match.PHASE_FLIGHT:m.advance_projectiles(1.0/60.0)
				arts[index].tick(1.0/60.0,m)
				for effect in effects[index]:effect.age+=1.0/60.0
				for event in m.events:
					arts[index].react(event,m,sound)
					if event.type=="explosion" and int(event.get("vehicle",0))==2:
						counts[index]+=1
						journal.append({"panel":index,"frame":frame,"tick":m.spark_tick,"position":[event.position.x,event.position.y],"removed":event.removed})
						effects[index].append({"pos":event.position,"weapon":event.weapon,"age":0.0,"angle":event.angle})
				m.events.clear()
		for pane in panels:pane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		if frame>=PAUSE_FROM and frame<PAUSE_TO:
			var context := HashingContext.new()
			context.start(HashingContext.HASH_SHA256)
			context.update(image.get_data())
			var hash_value := context.finish().hex_encode()
			if frame==PAUSE_FROM:pause_hash=hash_value
			assert(hash_value==pause_hash)
		image.save_png(output+"/%03d.png"%frame)
		if frame in [30,90,150,240,300]:image.save_png("res://docs/bigfoot-native/%s-%03d.png"%[mode,frame])
	var file := FileAccess.open("res://docs/bigfoot-native/"+mode+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":FRAMES,"size":[1920,1080],"pause":[PAUSE_FROM,PAUSE_TO-1],"pause_rgba_sha256":pause_hash,"counts":counts,"impacts":journal,"remaining":models.map(func(m):return m.projectiles.size())},"  "))
	print("BIGFOOT GPU ",mode," frames=",FRAMES," counts=",counts," pause=30 identical RGBA/model states")
	quit()
