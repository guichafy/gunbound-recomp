extends SceneTree
## GPU QA of Raon placed mines (ADR-117) on a sloped fixture: catalog S2/SS
## shells planted through ClassicFlight, slope rotation and facing, a crater
## under a mine (fall/bounce), the supermine crawling over the hill and a
## mobile walking onto a mine. Match clock 20Hz, presentation 60Hz, frames
## 90-119 paused (must hash identical). No profile or input.
## Args after "--": out_dir [frames].
const Match = preload("res://scripts/match.gd")
const Game = preload("res://scripts/game.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const ClassicFlight = preload("res://scripts/classic_flight.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
var sprites
var model
var impacts: Array = []
var elapsed := 0.0

class Lane extends Node2D:
	var host
	func _draw() -> void:
		var model = host.model
		var sprite = host.sprites[7]
		draw_rect(Rect2(0,0,1280,800),Color("18313c"))
		draw_texture_rect(model.terrain.texture,Rect2(0,0,1280,800),false)
		for i in 2:
			var actor: Dictionary = model.actors[i]
			var body = host.sprites[int(actor.vehicle)]
			body.draw(self,host.Pose.new(actor.pos,60,int(actor.facing),{"frame":body.frame_index("idle",host.elapsed,0,false),"age":host.elapsed,"pose":"idle","weapon":0}))
		sprite.draw_placed(self,model.mines,model.actors,Vector2.ZERO)
		for effect in host.impacts:
			sprite.draw_effect(self,effect,Vector2.ZERO)

func _initialize() -> void:
	call_deferred("run")

func ground(x: float) -> float:
	if x < 300.0: return 600.0
	if x < 500.0: return 600.0-(x-300.0)*0.4
	if x < 700.0: return 520.0
	if x < 900.0: return 520.0+(x-700.0)*0.4
	return 600.0

func plant(weapon: int, x: float, right: bool) -> void:
	var shell: Dictionary = model.shot_shells(0,45,50,weapon)[0].duplicate(true)
	shell.fp_ready = true
	shell.fp_velocity = Vector2i(256 if right else -256,0)
	ClassicFlight.plant_mine(model,shell,Vector2(x,model.terrain.surface_at(x,0.0)))

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var frames := int(args[1]) if args.size() > 1 else 330
	sprites = Game.build_sprites()
	var view := SubViewport.new(); view.size = Vector2i(1280,800)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var lane := Lane.new(); lane.host = self; view.add_child(lane)
	model = Match.new()
	model.start(7,1,42,"","original",null,[],[],[],0,1)
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active = false
	var terrain = model.terrain
	terrain.WIDTH = 640; terrain.HEIGHT = 400
	terrain.cells.resize(640*400); terrain.cells.fill(0)
	terrain.image = Image.create(640,400,false,Image.FORMAT_RGBA8)
	terrain.image.fill(Color.TRANSPARENT)
	for x in 640:
		var top := int(ground(x*2.0)/2.0)
		for y in range(top,400):
			terrain.cells[y*640+x] = 1
			terrain.image.set_pixel(x,y,Color("cdbd88") if y == top else Color("685741"))
	terrain.texture = ImageTexture.create_from_image(terrain.image)
	terrain.visual = null
	var stances := [float(Mobiles.definition(7).stance),0.0]
	model.actors[0].pos = Vector2(150,ground(150)-stances[0]); model.actors[0].facing = 1
	stances[1] = float(Mobiles.definition(int(model.actors[1].vehicle)).stance)
	model.actors[1].pos = Vector2(1180,ground(1180)-stances[1]); model.actors[1].facing = -1
	model.actors[1].hp = 10000; model.actors[1].max_hp = 10000
	model.active = 0
	model.phase = Match.PHASE_AIM
	plant(1,400,true)
	plant(1,800,false)
	plant(1,1040,false)
	plant(2,560,true)
	model.events.clear()
	DirAccess.make_dir_recursive_absolute(out)
	var hashes: Array = []
	var log_lines: Array = []
	for frame in frames:
		var paused := frame >= 90 and frame < 120
		if not paused:
			elapsed += 1.0/60
			if frame == 30:
				terrain.carve(Vector2(1040,600),40.0)
			if frame >= 150 and int(model.actors[1].hp) > 0:
				var x: float = float(model.actors[1].pos.x)-1.0
				model.actors[1].pos = Vector2(x,float(terrain.surface_at(x,0.0))-stances[1])
			model.turn_time = Match.TURN_TIME
			model.tick(1.0/60)
			for effect in impacts:
				effect.age += 1.0/60
			for event in model.events:
				if str(event.type) == "explosion":
					impacts.append({"pos":event.position,"weapon":event.weapon,"child":false,"ss_state":"normal","age":0.0,"angle":0.0,"raon_mine":true})
					print(frame," explosion ",event.position)
			model.events.clear()
		lane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := view.get_texture().get_image()
		hashes.append(Marshalls.raw_to_base64(picture.get_data()).sha256_text())
		if frame % 3 == 0:
			picture.save_png(out+"/%03d.png"%frame)
		var marks := []
		for mine in model.mines:
			marks.append([mine.pos.x,mine.pos.y,mine.slope,mine.dir,mine.falling,mine.state])
		log_lines.append(JSON.stringify({"f":frame,"m":marks,"cpu":[model.actors[1].pos.x,model.actors[1].pos.y]}))
	var same := true
	for i in range(91,120):
		same = same and hashes[i] == hashes[90]
	print("PAUSE30_IDENTICAL=",same," RESUME_CHANGES=",hashes[120] != hashes[119])
	var f := FileAccess.open(out+"/log.jsonl",FileAccess.WRITE)
	f.store_string("\n".join(log_lines))
	f.close()
	quit()
