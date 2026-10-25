extends SceneTree
## Native Turtle T2 QA: ordinary shots, minimum power and tornado adapter.
const Match = preload("res://scripts/match.gd")
const Sprite = preload("res://scripts/classic_sprite.gd")
const OUT := "res://docs/turtle-t2/"
const FRAMES := "res://.tools/turtle-t2/gpu-frames/"
var models: Array = []
var impacts: Array = []
var centers: Array = []
var panels: Array = []
var sprite
var board
var capture_view: SubViewport
var elapsed := 0.0
var capture_paused := false

class Board extends Node2D:
	var host
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("142331"))
		draw_string(font,Vector2(30,38),"Turtle T2 %s | hélice nativa | normal / força mínima / Tornado (adaptado)" % ProjectSettings.get_setting("application/config/version"),HORIZONTAL_ALIGNMENT_LEFT,-1,27)
		draw_string(font,Vector2(30,76),"t=%.2fs  %s | amplitude e rotação variáveis; duas fases opostas; largura±10" % [host.elapsed,"PAUSA" if host.capture_paused else "VOO"],HORIZONTAL_ALIGNMENT_LEFT,-1,21)

class ShotPanel extends Node2D:
	var host
	var index := 0
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		var model = host.models[index]
		draw_rect(Rect2(0,0,960,320),Color("142331"))
		if not model.projectiles.is_empty():
			var lead: Dictionary = model.projectiles[0]
			host.centers[index] = Vector2(lead.previous_hit_pos).lerp(lead.hit_pos,clampf(float(model.accumulator)/0.05,0,1))
		var offset: Vector2 = Vector2(480,160)-host.centers[index]
		for source in model.projectiles:
			var shot: Dictionary = source.duplicate()
			var blend := clampf(float(model.accumulator)/0.05,0,1)
			shot.draw_fraction = blend
			shot.hit_pos = Vector2(shot.previous_hit_pos).lerp(shot.hit_pos,blend)
			shot.pos = Vector2(shot.previous_draw_pos).lerp(shot.pos,blend)
			host.sprite.draw_projectile(self,shot,1,offset)
		for effect in host.impacts[index]:
			host.sprite.draw_effect(self,effect,offset)
		draw_line(Vector2(20,315),Vector2(940,315),Color("345061"),1)
		draw_string(font,Vector2(30,30),"%s | %s | %d projéteis" % [["T2 normal","T2 força mínima P1","T2 Tornado"][int(index/2)],"direita" if index%2 == 0 else "esquerda",model.projectiles.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,22)
		if not model.projectiles.is_empty():
			var shot: Dictionary = model.projectiles[0]
			draw_string(font,Vector2(30,299),"fase=%d°  A=%.2fpx  avanço=%d°/tick  tick=%d" % [shot.wave_phase,shot.wave_amplitude/100.0,shot.wave_step,shot.wave_counter],HORIZONTAL_ALIGNMENT_LEFT,-1,18)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	sprite = Sprite.new()
	sprite.setup("turtle")
	capture_view = SubViewport.new()
	capture_view.size = Vector2i(1920,1080)
	capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_view)
	board = Board.new()
	board.host = self
	capture_view.add_child(board)
	for variant in 3:
		for facing in [1,-1]:
			var model = Match.new()
			model.start(12,1,42,"","original")
			model.weather.columns.clear()
			model.weather.thor.active = false
			model.wind = Vector2.ZERO
			model.terrain.WIDTH = 2000
			model.terrain.HEIGHT = 1000
			model.terrain.cells.resize(model.terrain.WIDTH*model.terrain.HEIGHT)
			model.terrain.cells.fill(0)
			model.actors[0].pos = Vector2(500 if facing == 1 else 3500,300 if variant == 1 else 650)
			model.actors[0].facing = facing
			model.actors[1].pos = Vector2(2000,1900)
			model.fire(25 if variant == 1 else 45,0 if variant == 1 else 60,1)
			if variant == 2:
				model.weather.add_column("tornado",model.projectiles[0].pos.x+facing*100,1.0)
			model.events.clear()
			models.append(model)
			impacts.append([])
			centers.append(model.projectiles[0].hit_pos)
			var panel_view := SubViewport.new()
			panel_view.size = Vector2i(960,320)
			panel_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			capture_view.add_child(panel_view)
			var pane := ShotPanel.new()
			pane.host = self
			pane.index = panels.size()
			panel_view.add_child(pane)
			panels.append(pane)
			var display := TextureRect.new()
			display.texture = panel_view.get_texture()
			display.position = Vector2((pane.index%2)*960,110+int(pane.index/2)*320)
			display.size = Vector2(960,320)
			capture_view.add_child(display)
	for frame in 270:
		capture_paused = frame >= 150 and frame < 180
		if not capture_paused:
			elapsed += 1.0/60
			for index in models.size():
				models[index].tick(1.0/60)
				for effect in impacts[index]:
					effect.age += 1.0/60
				for event in models[index].events:
					if event.type == "explosion":
						impacts[index].append({"pos":event.position,"weapon":event.weapon,"child":event.get("child",false),"ss_state":event.get("ss_state","normal"),"age":0.0,"angle":event.angle})
				models[index].events.clear()
		board.queue_redraw()
		for pane in panels:
			pane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := capture_view.get_texture().get_image()
		picture.save_png(FRAMES+"%03d.png" % frame)
		if frame in [30,90,149,179,209,230]:
			picture.save_png(OUT+"time-%03d.png" % frame)
	print("TURTLE T2 GPU CAPTURE:270 frames,1920x1080;30 paused;no profile")
	quit()
