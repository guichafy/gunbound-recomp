extends SceneTree
## GPU evidence through active sprites and real Match flight, no player save.
const Match = preload("res://scripts/match.gd")
const Game = preload("res://scripts/game.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const OUT := "res://docs/mage-review/"
const FRAMES := "res://.tools/mage-audit/frames/"
var sprites: Dictionary
var models: Array = []
var effects: Array = []
var centers: Array = []
var impacts: Array = []
var panes: Array = []
var target: SubViewport
var board
var elapsed := 0.0
var is_paused := false
var facing := 1
var equipment: Dictionary

class ShotPanel extends Node2D:
	var host
	var index: int
	func _draw() -> void:
		var model = host.models[index]
		var weapon := index/2
		draw_rect(Rect2(0,0,960,275),Color("23364a") if index%2==0 else Color("a6bed0"))
		var first: Dictionary = {}
		for shell in model.projectiles:
			if bool(shell.launched):first=shell;break
		if not first.is_empty():
			host.centers[index] = Vector2(first.previous_hit_pos).lerp(first.hit_pos,clampf(model.accumulator/0.05,0,1))
		var offset: Vector2 = Vector2(480,135)-host.centers[index]
		for column in model.weather.columns:
			var at := float(column.x)+offset.x
			draw_rect(Rect2(at-32,0,64,275),Color(0.25,0.5,0.8,0.18))
		for source in model.projectiles:
			var shot: Dictionary = source.duplicate(true)
			shot.draw_fraction = clampf(model.accumulator/0.05,0,1)
			shot.hit_pos = Vector2(shot.previous_hit_pos).lerp(shot.hit_pos,shot.draw_fraction)
			shot.pos = Vector2(shot.previous_draw_pos).lerp(shot.pos,shot.draw_fraction)
			host.sprites[1].draw_projectile(self,shot,weapon,offset)
		for effect in host.effects[index]:
			host.sprites[1].draw_effect(self,effect,offset)
		draw_string(ThemeDB.fallback_font,Vector2(18,30),["T1","T2","SS"][weapon]+(" / sem coluna" if index%2==0 else " / vento(27,-12) + tornado + Force")+" / impactos%d"%host.impacts[index],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE if index%2==0 else Color("162b43"))

class Board extends Node2D:
	var host
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("142535"))
		draw_string(ThemeDB.fallback_font,Vector2(25,35),"Mage | T1/T2/SS originais | "+("direita" if host.facing==1 else "esquerda")+" | t=%.2f | "%host.elapsed+("PAUSA" if host.is_paused else "20Hz / apresentação60Hz"),HORIZONTAL_ALIGNMENT_LEFT,-1,24)
		for index in 8:
			var pose: String = ["idle","moving","charging","recoil","hurt","hurt_2","shock","destroyed"][index]
			var age := fmod(host.elapsed,1.25)
			var frame: int = host.sprites[1].frame_index(pose,age,1,false)
			var at := Vector2(120+index*240,995)
			host.sprites[1].draw(self,Pose.new(at,60,host.facing,{"frame":frame,"age":age,"pose":pose,"weapon":1,"rotation":deg_to_rad(15) if index==4 else 0.0,"avatar_context":{"equipment":host.equipment,"age":host.elapsed}}))
			draw_string(ThemeDB.fallback_font,at+Vector2(-65,64),pose,HORIZONTAL_ALIGNMENT_LEFT,-1,18)

func _initialize() -> void:
	call_deferred("run")

func reset_models() -> void:
	models.clear(); effects.clear(); centers.clear(); impacts.clear()
	for weapon in 3:
		for climate in 2:
			var model = Match.new()
			model.start(1,1,42,"")
			model.weather.columns.clear(); model.weather.thor.active=false
			model.terrain.cells.fill(0)
			for y in range(175,400):
				for x in 640:model.terrain.cells[y*640+x]=1
			model.terrain.native_cells=PackedByteArray(); model.terrain.enable_native()
			model.actors[0].pos=Vector2(350 if facing==1 else 930,300)
			model.actors[0].facing=facing
			model.actors[1].pos=Vector2(100,740)
			model.wind=Vector2.ZERO if climate==0 else Vector2(27,-12)
			if climate==1:
				var at: Vector2=model.shot_shells(0,35,25,weapon)[0].pos
				model.weather.add_column("tornado",at.x+facing*45,1.0)
				model.weather.add_column("force",at.x+facing*100,1.0)
			assert(model.fire(35,25,weapon))
			models.append(model); effects.append([]); centers.append(model.projectiles[0].hit_pos); impacts.append(0)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	root.size=Vector2i(1920,1080)
	sprites=Game.build_sprites()
	equipment=load("res://scripts/profile.gd").new("res://.tools/mage-audit/unused-capture-profile.json").equipped_set()
	target=SubViewport.new(); target.size=Vector2i(1920,1080); target.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(target)
	board=Board.new(); board.host=self; target.add_child(board)
	for index in 6:
		var viewport=SubViewport.new(); viewport.size=Vector2i(960,275); viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		target.add_child(viewport)
		var panel=ShotPanel.new(); panel.host=self; panel.index=index; viewport.add_child(panel); panes.append(panel)
		var display=TextureRect.new(); display.texture=viewport.get_texture(); display.position=Vector2(index%2*960,55+int(index/2)*275)
		target.add_child(display)
	var pause_hash := ""
	var report: Array = []
	var began := Time.get_ticks_msec()
	for frame in 480:
		var local_frame:=frame%240
		if local_frame==0:
			facing=1 if frame==0 else -1
			elapsed=0; reset_models()
		is_paused=local_frame>=120 and local_frame<150
		if not is_paused:
			elapsed+=1.0/60
			for index in models.size():
				models[index].tick(1.0/60)
				for effect in effects[index]:effect.age+=1.0/60
				for event in models[index].events:
					if event.type=="explosion":
						effects[index].append({"pos":event.position,"weapon":event.weapon,"age":0.0,"angle":event.angle})
						impacts[index]+=1
				models[index].events.clear()
		board.queue_redraw()
		for pane in panes:pane.queue_redraw()
		await process_frame
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		var picture:=target.get_texture().get_image()
		picture.save_png(FRAMES+"frame%04d.png"%frame)
		if local_frame in [20,55,90,119,120,149,180,210,239]:picture.save_png(OUT+"time-%03d.png"%frame)
		var hash:=picture.get_data().hex_encode().sha256_text()
		if local_frame==120:pause_hash=hash
		if is_paused:assert(hash==pause_hash,"Mage GPU pause must preserve all layers")
		if local_frame==239:
			report.append({"facing":facing,"impacts":impacts.duplicate(),"pause_30_identical":true})
			assert(impacts==[1,1,2,2,1,1],"Every Mage component must reach an impact")
	var output:=FileAccess.open(OUT+"gpu-validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"size":[1920,1080],"frames":480,"clock_hz":60,"capture_write_seconds":(Time.get_ticks_msec()-began)/1000.0,"directions":report},"\t"));output.close()
	print("MAGE GPU REVIEW: 480frames1920x1080,6real-flight panels,2directions,30frame pauses identical: ",report)
	sprites.clear(); target.free()
	quit()
