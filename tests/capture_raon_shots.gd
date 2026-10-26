extends SceneTree
## GPU QA of Raon T1/T2/SS (ADR-116): real Match flight, native 1:1 sprites,
## 1280x800 flat fixture, 60Hz presentation over the 20Hz model, frames
## 90-119 paused (must hash identical) then resumed. No profile or input.
## Args after "--": weapon out_dir [angle power frames facing vehicle];
## vehicle defaults to Raon (7) and covers the other mobiles' trails (ADR-119).
const Match = preload("res://scripts/match.gd")
const Game = preload("res://scripts/game.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
var OUT := ""
var sprites
var models: Array = []
var impacts: Array = []
var elapsed := 0.0
var weapon_sel := 0
var vehicle := 7
var log_lines: Array = []
var lingering: Array = []
class Lane extends Node2D:
	var host
	func _draw() -> void:
		var model = host.models[0]
		var sprite = host.sprites[host.vehicle]
		draw_rect(Rect2(0,0,1280,800),Color("18313c"))
		draw_texture_rect(model.terrain.texture,Rect2(0,0,1280,800),false)
		for i in 2:
			var actor: Dictionary = model.actors[i]
			var body = host.sprites[int(actor.vehicle)]
			body.draw(self,host.Pose.new(actor.pos,60,int(actor.facing),{"frame":body.frame_index("idle",host.elapsed,0,false),"age":host.elapsed,"pose":"idle","weapon":0}))
		for ghost in host.lingering:
			sprite.draw_lingering(self,ghost,Vector2.ZERO)
		for source in model.projectiles:
			var shot: Dictionary = source.duplicate()
			var blend := clampf(float(model.accumulator)/0.05,0,1)
			shot.draw_fraction = blend
			shot.hit_pos = Vector2(shot.get("previous_hit_pos",shot.hit_pos)).lerp(shot.hit_pos,blend)
			shot.pos = Vector2(shot.get("previous_draw_pos",shot.pos)).lerp(shot.pos,blend)
			sprite.draw_projectile(self,shot,int(shot.weapon),Vector2.ZERO)
		sprite.draw_placed(self,model.mines,model.actors,Vector2.ZERO)
		for effect in host.impacts:
			sprite.draw_effect(self,effect,Vector2.ZERO)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	weapon_sel = int(args[0]); OUT = args[1]
	var angle := float(args[2]) if args.size() > 2 else 45.0
	var power := float(args[3]) if args.size() > 3 else 60.0
	var frames := int(args[4]) if args.size() > 4 else 240
	var facing := int(args[5]) if args.size() > 5 else 1
	vehicle = int(args[6]) if args.size() > 6 else 7
	sprites = Game.build_sprites()
	var view := SubViewport.new(); view.size = Vector2i(1280,800)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var lane := Lane.new(); lane.host = self; view.add_child(lane)
	var model = Match.new()
	model.start(vehicle,1,42,"","original",null,[],[],[],0,1 if vehicle != 1 else 2)
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active = false
	var terrain = model.terrain
	terrain.WIDTH = 640; terrain.HEIGHT = 400
	terrain.cells.resize(640*400); terrain.cells.fill(0)
	terrain.image = Image.create(640,400,false,Image.FORMAT_RGBA8)
	terrain.image.fill(Color.TRANSPARENT)
	for y in range(300,400):
		for x in 640:
			terrain.cells[y*640+x] = 1
			terrain.image.set_pixel(x,y,Color("685741") if y > 300 else Color("cdbd88"))
	terrain.texture = ImageTexture.create_from_image(terrain.image)
	terrain.visual = null
	model.actors[0].pos = Vector2(250 if facing > 0 else 1030,595); model.actors[0].facing = facing
	model.actors[1].pos = Vector2(1000 if facing > 0 else 280,595); model.actors[1].facing = -facing
	model.actors[1].hp = 10000; model.actors[1].max_hp = 10000
	model.active = 0
	model.phase = Match.PHASE_AIM
	print("fire=",model.fire(angle,power,weapon_sel), " shells=",model.projectiles.size())
	for p in model.projectiles:
		print(" shell comp=",p.get("raon_component",-1)," spawn=",p.spawn_at," vel=",p.velocity, " flight=",p.get("flight",""))
	models.append(model)
	DirAccess.make_dir_recursive_absolute(OUT)
	var hashes: Array = []
	for frame in frames:
		var paused := frame >= 90 and frame < 120
		if paused:
			lane.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			hashes.append(Marshalls.raw_to_base64(view.get_texture().get_image().get_data()).sha256_text())
			continue
		elapsed += 1.0/60
		var before: Array = model.projectiles.duplicate()
		if model.phase == Match.PHASE_FLIGHT:
			model.advance_projectiles(1.0/60)
		else:
			model.tick(1.0/60)
		for e in impacts: e.age += 1.0/60
		for ghost in lingering: ghost.age += 1.0/60
		for shell in before:
			if bool(shell.get("launched",false)) and not model.projectiles.any(func(live): return is_same(live,shell)):
				lingering.append({"shell":shell.duplicate(true),"age":0.0})
		for event in model.events:
			if str(event.type) == "explosion":
				impacts.append({"pos":event.position,"weapon":event.weapon,"child":event.get("child",false),"ss_state":event.get("ss_state","normal"),"age":0.0,"angle":event.get("angle",0.0),"raon_mine":event.get("raon_mine",false)})
			if str(event.type) in ["explosion","mine_plant","projectile_launch"]:
				print(frame," ",event.type," ",event.get("position",""), " w=",event.get("weapon",""))
		model.events.clear()
		lane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		hashes.append(Marshalls.raw_to_base64(view.get_texture().get_image().get_data()).sha256_text())
		if frame % 2 == 0:
			view.get_texture().get_image().save_png(OUT+"/%03d.png"%frame)
			var pts := []
			for p in model.projectiles:
				pts.append([p.hit_pos.x,p.hit_pos.y,p.pos.x,p.pos.y,p.get("raon_phase",-1),bool(p.get("launched",true))])
			var mp := []
			for m in model.mines:
				mp.append([m.pos.x,m.pos.y,m.get("state",""),m.get("state_age",0.0)])
			log_lines.append(JSON.stringify({"f":frame,"p":pts,"m":mp,"phase":model.phase,"active":model.active}))
	var same := true
	for i in range(91,120):
		same = same and hashes[i] == hashes[90]
	print("PAUSE30_IDENTICAL=",same," RESUME_CHANGES=",hashes[120] != hashes[119])
	var f := FileAccess.open(OUT+"/log.jsonl",FileAccess.WRITE)
	f.store_string("\n".join(log_lines))
	f.close()
	quit()
