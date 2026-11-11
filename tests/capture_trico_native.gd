extends SceneTree
## Deterministic GPU sequence. Manual60Hz, not a performance benchmark.
const Match = preload("res://scripts/match.gd")
const Sprite = preload("res://scripts/classic_sprite.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const FRAMES := 421
const PAUSE_FROM := 100
const PAUSE_TO := 130
var models: Array = []
var sprites: Dictionary = {}
var panels: Array = []
var effects: Array = []
var journal: Array = []
var impact_counts: Array = [0,0,0,0,0,0]
var viewport: SubViewport
var frame := 0
var pause_state: Array = []
var pause_bytes := PackedByteArray()

class TricoPanel extends Node2D:
	var host
	var index: int
	func _draw() -> void:
		var model = host.models[index]
		draw_rect(Rect2(0,0,640,540),Color("14212a"))
		draw_string(ThemeDB.fallback_font,Vector2(18,31),["Trico T2 / calm","Trico T2 / wind + slope","Trico SS / native actions"][index%3]+(" / right" if index<3 else " / left"),HORIZONTAL_ALIGNMENT_LEFT,-1,22)
		var state := "pending"
		if not model.projectiles.is_empty():
			var shell: Dictionary = model.projectiles[0]
			state="tick%d phase%d radius%d SS%d" % [int(shell.flight_ticks),int(shell.trico_phase),int(shell.trico_radius),int(shell.trico_ss_tick)]
		draw_string(ThemeDB.fallback_font,Vector2(18,62),state+" / blasts%d"%int(host.impact_counts[index]),HORIZONTAL_ALIGNMENT_LEFT,-1,18)
		draw_string(ThemeDB.fallback_font,Vector2(18,90),"frame%d / manual60Hz%s" % [mini(host.frame,PAUSE_FROM) if host.frame<PAUSE_TO else host.frame," / PAUSED" if host.frame>=PAUSE_FROM and host.frame<PAUSE_TO else ""],HORIZONTAL_ALIGNMENT_LEFT,-1,17)

class TricoWorld extends Node2D:
	var host
	var index: int
	func _draw() -> void:
		var model = host.models[index]
		draw_rect(Rect2(0,0,1280,800),Color("81a7b7"))
		draw_texture_rect(model.terrain.texture,Rect2(0,0,1280,800),false)
		for actor in 2:
			var a: Dictionary = model.actors[actor]
			if a.pos.x<1280:
				host.sprites[int(a.vehicle)].draw(self,Pose.new(a.pos,60,int(a.facing),{"pose":"idle","age":0.0,"weapon":1,"rotation":float(a.tilt)}))
		for shell in model.projectiles:
			host.sprites[5].draw_projectile(self,shell,int(shell.weapon))
		for effect in host.effects[index]:
			host.sprites[5].draw_effect(self,effect)
		draw_set_transform(Vector2.ZERO)

func _initialize() -> void:
	call_deferred("run")

func state() -> Array:
	var result: Array=[]
	for i in models.size():
		result.append([models[i].projectiles.duplicate(true),models[i].actors.duplicate(true),models[i].terrain.native_cells.duplicate(),effects[i].duplicate(true)])
	return result

func floor_y(x: int, slope: bool) -> int:
	return 540+int((x-640)*0.12) if slope else 540

func run() -> void:
	var output := "res://.tools/trico-30/frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/trico-native"))
	for pair in [[5,"trico"],[2,"bigfoot"]]:
		var sprite = Sprite.new()
		sprite.setup(pair[1])
		sprites[pair[0]]=sprite
	viewport=SubViewport.new()
	viewport.size=Vector2i(1920,1080)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for i in 6:
		var model = Match.new()
		model.start(5,2,30,"","wind",null,[],[],[],0,2)
		model.weather.columns.clear()
		model.weather.thor.active=false
		model.wind=Vector2(20,-8) if i%3==1 else Vector2.ZERO
		var slope := i%3==1
		model.terrain.cells.fill(0)
		model.terrain.native_cells.fill(0)
		model.terrain.image.fill(Color.TRANSPARENT)
		for y in model.terrain.HEIGHT:
			for x in model.terrain.WIDTH:
				if y*2>=floor_y(x*2,slope):
					model.terrain.cells[y*model.terrain.WIDTH+x]=1
					model.terrain.image.set_pixel(x,y,Color("776244"))
		model.terrain.texture.update(model.terrain.image)
		for y in 800:
			for x in 1280:
				if y>=floor_y(x,slope):
					model.terrain.native_cells[y*1280+x]=1
		var x := 180 if i<3 else 1100
		model.actors[0].pos=Vector2(x,floor_y(x,slope)-25)
		model.actors[0].facing=1 if i<3 else -1
		model.actors[0].turns=3
		model.actors[1].pos=Vector2(3000,500)
		model.stamp_tilt()
		assert(model.fire(40,30,2 if i%3==2 else 1))
		models.append(model)
		effects.append([])
		var pane=TricoPanel.new()
		pane.host=self
		pane.index=i
		pane.position=Vector2((i%3)*640,(i/3)*540)
		viewport.add_child(pane)
		panels.append(pane)
		var world=TricoWorld.new()
		world.host=self
		world.index=i
		world.position=Vector2(24,122)
		world.scale=Vector2(0.46,0.46)
		pane.add_child(world)
		panels.append(world)
	for n in FRAMES:
		frame=n
		if n==PAUSE_FROM:
			pause_state=state()
		if n==PAUSE_TO:
			assert(state()==pause_state)
		if n<PAUSE_FROM or n>=PAUSE_TO:
			for i in 6:
				for effect in effects[i]:
					effect.age+=1.0/60.0
				models[i].advance_projectiles(1.0/60.0)
				for event in models[i].events:
					if event.type in ["explosion","trico_ss_start"]:
						effects[i].append({"pos":event.position,"weapon":event.weapon,"age":0.0,"angle":float(event.get("angle",0)),"ss_state":"trico_start" if event.type=="trico_ss_start" else "normal","child":bool(event.get("child",false))})
						impact_counts[i]+=int(event.type=="explosion")
						journal.append({"frame":n,"panel":i,"type":event.type,"position":[event.position.x,event.position.y]})
				models[i].events.clear()
		for pane in panels:
			pane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		assert(image.get_size()==Vector2i(1920,1080))
		# Labels use a frozen frame during the pause, so compare actual RGBA.
		if n>=PAUSE_FROM and n<PAUSE_TO:
			var stable := image
			if n==PAUSE_FROM:
				pause_bytes=stable.get_data()
			assert(stable.get_data()==pause_bytes)
		image.save_png(output+"/%03d.png"%n)
		if n in [0,30,60,89,95,99,100,129,130,137,167,182,330,420]:
			image.save_png("res://docs/trico-native/trico-%03d.png"%n)
	var manifest := {"frames":FRAMES,"resolution":[1920,1080],"pause":[PAUSE_FROM,PAUSE_TO],"pause_rgba_identical":true,"impact_counts":impact_counts,"journal":journal,"remaining":models.map(func(m):return m.projectiles.size())}
	var file := FileAccess.open("res://docs/trico-native/capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	print("TRICO GPU frames=",FRAMES," impacts=",impact_counts)
	viewport.queue_free()
	await process_frame
	quit()
