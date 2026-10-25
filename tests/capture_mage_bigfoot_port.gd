extends Node
## Real shot models + active original sprites; no live player profile.
const Match = preload("res://scripts/match.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const OUT := "res://docs/mobile-animation-port/"
const FRAMES := "res://.tools/mobile-animation-port/gpu-frames/"
var capture_root: Window
var scene
var models: Array = []
var effects: Array = []
var centers: Array = []
var panes: Array = []
var target: SubViewport
var board
var elapsed := 0.0
var paused := false
var facing := 1

class ShotPanel extends Node2D:
	var host
	var index := 0
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		var model = host.models[index]
		var id := 1 if index%2 == 0 else 2
		var weapon := int(index/2)
		var sprite = host.scene.sprite_for(id)
		draw_rect(Rect2(0,0,960,270),Color("172c3c"))
		var first: Dictionary = {}
		for shell in model.projectiles:
			if shell.launched:
				first = shell
				break
		if not first.is_empty():
			host.centers[index] = Vector2(first.previous_hit_pos).lerp(first.hit_pos,clampf(float(model.accumulator)/0.05,0,1))
		var offset: Vector2 = Vector2(480,140)-host.centers[index]
		for source in model.projectiles:
			var shot: Dictionary = source.duplicate()
			var blend := clampf(float(model.accumulator)/0.05,0,1)
			shot.draw_fraction = blend
			shot.hit_pos = Vector2(shot.previous_hit_pos).lerp(shot.hit_pos,blend)
			shot.pos = Vector2(shot.previous_draw_pos).lerp(shot.pos,blend)
			sprite.draw_projectile(self,shot,weapon,offset)
		for effect in host.effects[index]:
			sprite.draw_effect(self,effect,offset)
		draw_string(font,Vector2(20,30),("Mage" if id == 1 else "Bigfoot")+" "+["T1","T2","SS"][weapon]+" | "+("direita" if host.facing == 1 else "esquerda")+" | %d projéteis"%model.projectiles.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,22)
		draw_line(Vector2(10,268),Vector2(950,268),Color("365160"),1)

class Board extends Node2D:
	var host
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("142331"))
		draw_string(font,Vector2(25,32),"Bigfoot / Mage0.20.4 | tiros reais + atlas, faixas e poses do cliente",HORIZONTAL_ALIGNMENT_LEFT,-1,26)
		draw_string(font,Vector2(25,65),"Relógio60Hz | t=%.2f | %s | escala nativa de batalha; nenhum rastro HD"%[host.elapsed,"PAUSA" if host.paused else "ANIMAÇÃO"],HORIZONTAL_ALIGNMENT_LEFT,-1,20)
		for id in [1,2]:
			var sprite = host.scene.sprite_for(id)
			var left: int = (id-1)*960
			for index in 8:
				var pose: String = ["idle","moving","charging","recoil","hurt","falling","shock","destroyed"][index]
				var age := fmod(host.elapsed,2.2)
				var point := Vector2(left+60+index*116,995)
				if pose != "destroyed" or age < sprite.pose_duration(pose,1,false):
					sprite.draw(self,Pose.new(point,60,host.facing,{"frame":sprite.frame_index(pose,age,1,false),"age":age,"pose":pose,"weapon":1,"avatar_context":{"equipment":host.scene.profile.equipped_set(),"age":host.elapsed}}))
				draw_string(font,point+Vector2(-45,58),pose,HORIZONTAL_ALIGNMENT_LEFT,-1,16)

func _ready() -> void:
	capture_root = get_tree().root
	call_deferred("run")

func reset_models() -> void:
	models.clear(); effects.clear(); centers.clear()
	for weapon in 3:
		for id in [1,2]:
			var model = Match.new()
			model.start(id,1,42,"","original")
			model.weather.columns.clear(); model.weather.thor.active = false
			model.wind = Vector2.ZERO
			model.terrain.WIDTH = 1200; model.terrain.HEIGHT = 500
			model.terrain.cells.resize(1200*500); model.terrain.cells.fill(0)
			for row in range(350,500):
				for column in 1200:
					model.terrain.cells[row*1200+column] = 1
			model.actors[0].pos = Vector2(400 if facing == 1 else 2000,300)
			model.actors[0].facing = facing
			model.actors[1].pos = Vector2(1200,675)
			model.fire(35,60,weapon)
			models.append(model); effects.append([]); centers.append(model.projectiles[0].hit_pos)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/mobile-animation-port/capture-profile.json")
	capture_root.add_child(scene); scene.set_process(false); scene.hide(); scene.sound.muted = true
	target = SubViewport.new(); target.size = Vector2i(1920,1080); target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_root.add_child(target)
	board = Board.new(); board.host = self; target.add_child(board)
	for index in 6:
		var panel_view := SubViewport.new(); panel_view.size = Vector2i(960,270); panel_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		target.add_child(panel_view)
		var pane = ShotPanel.new(); pane.host = self; pane.index = index; panel_view.add_child(pane); panes.append(pane)
		var display := TextureRect.new(); display.texture = panel_view.get_texture(); display.position = Vector2((index%2)*960,80+int(index/2)*270); display.size = Vector2(960,270)
		target.add_child(display)
	for frame in 420:
		if frame%210 == 0:
			facing = 1 if frame == 0 else -1
			reset_models()
		paused = frame%210 >= 150 and frame%210 < 180
		if not paused:
			elapsed += 1.0/60.0
			for index in models.size():
				models[index].tick(1.0/60.0)
				for effect in effects[index]:
					effect.age += 1.0/60.0
				for event in models[index].events:
					if event.type == "explosion":
						effects[index].append({"pos":event.position,"weapon":event.weapon,"age":0.0,"angle":event.angle})
				models[index].events.clear()
		board.queue_redraw()
		for pane in panes: pane.queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var picture := target.get_texture().get_image()
		picture.save_png(FRAMES+"%03d.png"%frame)
		if frame in [45,90,149,179,205,255,300,359,389,419]:
			picture.save_png(OUT+"time-%03d.png"%frame)
	# The actual screen flows use a separate render target and the same isolated scene.
	var game_view := SubViewport.new(); game_view.size = Vector2i(1280,800); game_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_root.add_child(game_view); scene.reparent(game_view); scene.show()
	for id in [1,2]:
		scene.show_menu(); scene.select_vehicle(id)
		await snap_screen(game_view,"menu-%d.png"%id)
		scene.opening = 0; scene.match_seed = 1; scene.start_match()
		await snap_screen(game_view,"battle-%d.png"%id)
		scene.show_menu(); scene.show_shop()
		await snap_screen(game_view,"shop-%d.png"%id)
	print("MAGE/BIGFOOT GPU:420frames1920x1080,60Hz,2x30pause; actual menu/battle/shop1280x800")
	scene.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func snap_screen(view: SubViewport, name: String) -> void:
	scene.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png(OUT+name)
