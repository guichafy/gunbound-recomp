extends SceneTree
## Temporal GPU QA of the real model + original renderer; no player profile.
const Match = preload("res://scripts/match.gd")
const Sprite = preload("res://scripts/classic_sprite.gd")
const OUT := "res://docs/turtle-projectiles/"
const FRAMES := "res://.tools/turtle-fix/gpu-frames/"
var models: Array = []
var impacts: Array = []
var centers: Array = []
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
		draw_string(font,Vector2(35,42),"Turtle 0.20.1 | modelo real + renderer original | 60 FPS",HORIZONTAL_ALIGNMENT_LEFT,-1,28)
		draw_string(font,Vector2(35,77),"t=%.2fs  %s | T1/T2: faixa contínua; SS: normal → abertura → 6 bolhas" % [host.elapsed,"PAUSA" if host.capture_paused else "VOO"],HORIZONTAL_ALIGNMENT_LEFT,-1,22)
		for index in host.models.size():
			var model = host.models[index]
			var weapon := int(index/2)
			var panel := Vector2((index%2)*960,110+weapon*320)
			draw_line(panel+Vector2(20,300),panel+Vector2(940,300),Color("345061"),1)
			draw_string(font,panel+Vector2(30,30),"%s | %s | %d projéteis" % [["T1","T2","SS"][weapon],"direita" if index%2 == 0 else "esquerda",model.projectiles.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,22)
			if not model.projectiles.is_empty():
				host.centers[index] = model.projectiles[0].hit_pos
			var offset: Vector2 = panel+Vector2(480,160)-host.centers[index]
			for source in model.projectiles:
				var shot: Dictionary = source.duplicate()
				var blend := clampf(float(model.accumulator)/0.05,0,1)
				shot.draw_fraction = blend
				shot.hit_pos = Vector2(shot.previous_hit_pos).lerp(shot.hit_pos,blend)
				shot.pos = Vector2(shot.previous_draw_pos).lerp(shot.pos,blend)
				host.sprite.draw_projectile(self,shot,weapon,offset)
			for effect in host.impacts[index]:
				host.sprite.draw_effect(self,effect,offset)
			if weapon == 2 and not model.projectiles.is_empty():
				var shot: Dictionary = model.projectiles[0]
				draw_string(font,panel+Vector2(30,278),"estado=%s  tick=%d  change=%d" % ["filho" if shot.get("child",false) else shot.ss_state,shot.flight_ticks,shot.ss_state_tick],HORIZONTAL_ALIGNMENT_LEFT,-1,18)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	sprite = Sprite.new()
	sprite.setup("turtle")
	for weapon in 3:
		for facing in [1,-1]:
			var model = Match.new()
			model.start(12,1,42,"","original")
			model.weather.columns.clear()
			model.weather.thor.active = false
			model.wind = Vector2.ZERO
			model.terrain.cells.fill(0)
			model.actors[0].pos = Vector2(100 if facing == 1 else 1180,650)
			model.actors[0].facing = facing
			model.actors[1].pos = Vector2(640,790)
			model.actors[0].ss_lock = 0
			model.fire(50,80,weapon)
			model.events.clear()
			models.append(model)
			impacts.append([])
			centers.append(model.projectiles[0].hit_pos)
	capture_view = SubViewport.new()
	capture_view.size = Vector2i(1920,1080)
	capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_view)
	board = Board.new()
	board.host = self
	capture_view.add_child(board)
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
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := capture_view.get_texture().get_image()
		picture.save_png(FRAMES+"%03d.png" % frame)
		if frame in [90,145,179,195,209,230]:
			picture.save_png(OUT+"time-%03d.png" % frame)
	print("TURTLE GPU CAPTURE:270 frames,1920x1080;30 capture_paused;no profile")
	quit()
