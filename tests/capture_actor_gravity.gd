extends SceneTree
## Directed impact fixture: real masks/craters, BattleArt and original sprites.
## GPU 1920x1080/60Hz, both directions; pause30 must be pixel-identical.
const Match = preload("res://scripts/match.gd")
const Shell = preload("res://scripts/shell_state.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Art = preload("res://scripts/battle_art.gd")
const Game = preload("res://scripts/game.gd")
const OUT := "res://.tools/gravity-during-shots/gpu/"
var sprites
var models: Array = []
var arts: Array = []
var panels: Array = []
var elapsed := 0.0
var capture_paused := false
var view: SubViewport
var board
var shadow := StyleBoxFlat.new()

class Board extends Node2D:
	var host
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("142331"))
		draw_string(ThemeDB.fallback_font,Vector2(30,42),"Gravidade durante tiros | t=%.2fs | %s" % [host.elapsed,"PAUSA" if host.capture_paused else "AÇÃO"],HORIZONTAL_ALIGNMENT_LEFT,-1,28)
		draw_string(ThemeDB.fallback_font,Vector2(30,77),"Fixture de impactos dirigidos · máscara e colisão reais · linha azul: apoio inicial · render BattleArt",HORIZONTAL_ALIGNMENT_LEFT,-1,22)

class Lane extends Node2D:
	var host
	var index: int
	func _draw() -> void:
		var model = host.models[index]
		var offset := Vector2(-180,90)
		draw_rect(Rect2(0,0,960,900),Color("18313c"))
		draw_texture_rect(model.terrain.texture,Rect2(offset,Vector2(1280,800)),false)
		var target: Dictionary = model.actors[1]
		draw_line(Vector2(target.pos.x-70,375)+offset,Vector2(target.pos.x+70,375)+offset,Color("76c6ff"),2)
		for actor in 2:
			var ctx := {"charging":false,"cpu_charging":false,"player_weapon":0,"cpu_weapon":0,"elapsed":host.elapsed,"atlas":host.sprites[2],"shadow":host.shadow}
			host.arts[index].draw_actor(self,model,actor,offset,ctx)
		for source in model.projectiles:
			if not bool(source.launched): continue
			var shot: Dictionary = source.duplicate()
			shot.draw_fraction = clampf(float(model.accumulator)/0.05,0,1)
			host.sprites[2].draw_projectile(self,shot,0,offset)
		draw_string(ThemeDB.fallback_font,Vector2(30,32),"%s | %s | y modelo=%.1f / visual=%.1f" % ["DIREITA" if index==0 else "ESQUERDA",model.phase,target.pos.y,host.arts[index].motion[1].pos.y],HORIZONTAL_ALIGNMENT_LEFT,-1,22)

func fixture(facing: int):
	var model = Match.new()
	model.start(2,1,42,"","original",null,[],[],[],0,2)
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.terrain.cells.fill(0)
	model.terrain.image.fill(Color.TRANSPARENT)
	for y in range(200,320):
		for x in range(30,610):
			model.terrain.cells[y*640+x]=1
			model.terrain.image.set_pixel(x,y,Color("685741") if y>200 else Color("cdbd88"))
	model.terrain.texture.update(model.terrain.image)
	for i in 2:
		model.actors[i].pos=Vector2(300+i*400,400-model.stance_of(i))
		model.actors[i].facing=facing
	model.stamp_tilt()
	model.events.clear()
	var shots: Array=[]
	for delay in [0.5,1.5,3.5]:
		shots.append(Shell.create(Vector2(700,399),Vector2(0,200),delay,{"damage":0,"radius":45.0},0,0))
	Snapshot.arm(model,0,0,shots)
	return model

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	sprites=Game.build_sprites()
	shadow.bg_color=Color(0.02,0.04,0.1,0.28)
	view=SubViewport.new(); view.size=Vector2i(1920,1080)
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	board=Board.new(); board.host=self; view.add_child(board)
	for i in 2:
		var model=fixture(1 if i==0 else -1)
		models.append(model)
		var art=Art.new(); art.bind_sprites(sprites); art.reset(model.actors); arts.append(art)
		var panel_view=SubViewport.new(); panel_view.size=Vector2i(960,900)
		panel_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(panel_view)
		var lane=Lane.new(); lane.host=self; lane.index=i; panel_view.add_child(lane); panels.append(lane)
		var display=TextureRect.new(); display.texture=panel_view.get_texture(); display.position=Vector2(i*960,110); display.size=Vector2(960,900); view.add_child(display)
	# Warm up nested viewports before capturing the first frame.
	for warmup in 2:
		await process_frame
		await RenderingServer.frame_post_draw
	var reference:=PackedByteArray()
	var identical:=true
	var records:Array=[]
	for frame in 180:
		capture_paused=frame>=60 and frame<90
		if not capture_paused:
			elapsed+=1.0/60
			for i in 2:
				models[i].tick(1.0/60)
				for event in models[i].events: arts[i].react(event)
				models[i].events.clear()
				arts[i].tick(models[i],1.0/60)
		board.queue_redraw()
		for lane in panels: lane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture:=view.get_texture().get_image()
		picture.save_png(OUT+"%03d.png"%frame)
		if frame==60: reference=picture.get_data()
		elif capture_paused: identical=identical and picture.get_data()==reference
		records.append({"frame":frame,"time":elapsed,"capture_paused":capture_paused,"model_y":models[0].actors[1].pos.y,"visual_y":arts[0].motion[1].pos.y,"phase":models[0].phase})
	var file:=FileAccess.open(OUT+"frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"pause30_identical":identical,"frames":records},"  "));file.close()
	print("GRAVITY GPU:180 frames1920x1080; pause30_identical=",identical," final_y=",models[0].actors[1].pos.y," phase=",models[0].phase)
	quit(0 if identical and models[0].actors[1].pos.y>420 and models[0].phase==Match.PHASE_FLIGHT else 1)
