extends SceneTree
## GPU comparisons of the six audited consumers. Manual60Hz, no real profile.
const Match = preload("res://scripts/match.gd")
const Classic = preload("res://scripts/classic_sprite.gd")
const IDS := [4,2,5,9,10,11]
const KINDS := ["armor","bigfoot","trico","jd","asate","ice"]
const FRAMES := 361
const PAUSE_FROM := 65
const PAUSE_TO := 95
var models: Array = []
var sprites: Array = []
var legacy: Array = []
var effects: Array = []
var centers: Array = []
var panels: Array = []
var journal: Array = []
var viewport: SubViewport
var sky := Color("c8d9e8")
var tag := "light"
var frame := 0

class Legacy extends "res://scripts/classic_sprite.gd":
	# Exact pre-issue32 path, used only to compare the same unchanged assets.
	func begin_projectiles(_view: Node2D) -> void:
		pass
	func _draw_bullet(view, name, index, light_name, light_index, at, angle, alpha, mirror = false):
		view.draw_set_transform(at,angle,Vector2(1,-1) if mirror else Vector2.ONE)
		if light_index>=0:
			var light := cell_frame(light_name,light_index)
			view.draw_texture_rect_region(_optional_cached(light_name),light[1],light[0],Color(1,1,1,alpha))
		var body := cell_frame(name,index)
		view.draw_texture_rect_region(_optional_cached(name),body[1],body[0],Color(1,1,1,alpha))

class ShotPane extends Node2D:
	var host
	var index: int
	var old := false
	func _draw() -> void:
		var model = host.models[index]
		var sprite = host.legacy[index/6] if old else host.sprites[index/6]
		draw_rect(Rect2(0,0,160,180),host.sky)
		var offset: Vector2 = Vector2(80,100)-host.centers[index]
		draw_rect(Rect2(Vector2(-4000,600)+offset,Vector2(8000,800)),Color("675b41"))
		sprite.begin_projectiles(self)
		var blend := clampf(float(model.accumulator)/0.05,0,1)
		for original in model.projectiles:
			var shell: Dictionary = original.duplicate()
			shell.hit_pos=Vector2(shell.get("previous_hit_pos",shell.hit_pos)).lerp(shell.hit_pos,blend)
			shell.pos=Vector2(shell.get("previous_draw_pos",shell.pos)).lerp(shell.pos,blend)
			sprite.draw_projectile(self,shell,int(shell.weapon),offset)
		for effect in host.effects[index]:
			sprite.draw_effect(self,effect,offset)
		draw_set_transform(Vector2.ZERO)
		var text := "%s T%d %s"%[host.KINDS[index/6],index%3+1,"L" if index%6>=3 else "R"]
		draw_string(ThemeDB.fallback_font,Vector2(5,18),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.BLACK if host.tag=="light" else Color.WHITE)
		draw_string(ThemeDB.fallback_font,Vector2(5,36),"legacy" if old else "alpha + add",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.BLACK if host.tag=="light" else Color.WHITE)

class Probe extends Node2D:
	var sprite
	var bg: Color
	var alpha := 1.0
	var enabled := true
	func _draw():
		draw_rect(Rect2(0,0,16,16),bg)
		sprite.begin_projectiles(self)
		if enabled:sprite._draw_bullet(self,"Bullet1.png",0,"Bullet1Light.png",-1 if sprite.mobile_kind=="jd" else 0,Vector2(8,8),0.0,alpha)

class UnlitProbe extends Node2D:
	var sprite
	var bg: Color
	var weapon: int
	var direction := 1
	func _draw():
		draw_rect(Rect2(0,0,160,180),bg)
		sprite.begin_projectiles(self)
		var shell := {"pos":Vector2(80.123,90.234),"hit_pos":Vector2(80.123,90.234),"velocity":Vector2(31*direction,17),"age":0.6,"launched":true}
		sprite.draw_projectile(self,shell,weapon)

func probe_unlit() -> void:
	var vp := SubViewport.new()
	vp.size=Vector2i(160,180)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var pane := UnlitProbe.new()
	pane.bg=sky
	vp.add_child(pane)
	for pair in [["armor",2],["bigfoot",1],["asate",2]]:
		var old = Legacy.new()
		old.setup(pair[0])
		var current = Classic.new()
		current.setup(pair[0])
		pane.weapon=pair[1]
		for direction in [1,-1]:
			pane.direction=direction
			for method in ["legacy","current"]:
				pane.sprite=old if method=="legacy" else current
				pane.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				vp.get_texture().get_image().save_png("res://docs/projectile-light/unlit-%s-%s-%d-%s.png"%[tag,pair[0],direction,method])
		pane.sprite=null
	vp.free()

func _initialize():
	call_deferred("run")

func state() -> Array:
	return models.map(func(m):return [m.projectiles.duplicate(true),m.actors.duplicate(true),m.accumulator]) + [effects.duplicate(true)]

func probe() -> void:
	var vp := SubViewport.new()
	vp.size=Vector2i(16,16)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var sprite = Classic.new()
	sprite.mobile_kind="armor"
	var info := {"cell":[8,8],"origin":[4,4],"columns":1,"frames":1}
	sprite.meta={"sheets":{"Bullet1.png":info,"Bullet1Light.png":info}}
	for pair in [["Bullet1.png",Color(0.4,0.2,0.1,0.5)],["Bullet1Light.png",Color(0.1,0.3,0.5,0.25)]]:
		var image := Image.create(8,8,false,Image.FORMAT_RGBA8)
		image.fill(pair[1])
		sprite.placed[pair[0]]=sprite.pixel_texture(ImageTexture.create_from_image(image))
	var pane := Probe.new()
	pane.sprite=sprite
	pane.bg=sky
	vp.add_child(pane)
	for kind in ["armor","jd"]:
		sprite.mobile_kind=kind
		for alpha in [1.0,0.5]:
			pane.alpha=alpha
			pane.enabled=true
			pane.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var first := vp.get_texture().get_image()
			first.save_png("res://docs/projectile-light/probe-%s-%s-%s.png"%[tag,kind,str(alpha)])
			pane.enabled=false
			pane.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var empty := vp.get_texture().get_image()
			empty.save_png("res://docs/projectile-light/empty-%s-%s-%s.png"%[tag,kind,str(alpha)])
			pane.enabled=true
			pane.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			assert(vp.get_texture().get_image().get_data()==first.get_data())

	vp.free()

func run() -> void:
	if "dark" in OS.get_cmdline_user_args():
		tag="dark"
		sky=Color("101820")
	var output := "res://.tools/projectile-light/frames-"+tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/projectile-light"))
	await probe()
	await probe_unlit()
	if "probe" in OS.get_cmdline_user_args():
		quit()
		return
	viewport=SubViewport.new()
	viewport.size=Vector2i(1920,1080)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for kind in KINDS:
		var sprite = Classic.new()
		sprite.setup(kind)
		sprites.append(sprite)
		var old = Legacy.new()
		old.setup(kind)
		legacy.append(old)
	for index in 36:
		var model = Match.new()
		model.start(IDS[index/6],2,32,"","wind",null,[],[],[],0,2)
		model.weather.columns.clear()
		model.weather.thor.active=false
		model.wind=Vector2.ZERO
		model.terrain.cells.fill(0)
		model.terrain.native_cells.fill(0)
		# Both active collision masks have the same native floor.
		for y in range(300,model.terrain.HEIGHT):
			for x in model.terrain.WIDTH:model.terrain.cells[y*model.terrain.WIDTH+x]=1
		var width: int=model.terrain.WIDTH*2
		for y in range(600,model.terrain.HEIGHT*2):
			for x in width:model.terrain.native_cells[y*width+x]=1
		var facing := 1 if index%6<3 else -1
		model.actors[0].pos=Vector2(280 if facing==1 else 1000,574)
		model.actors[0].facing=facing
		model.actors[0].turns=3
		model.actors[1].pos=Vector2(3000,500)
		model.stamp_tilt()
		assert(model.fire(40,28,index%3))
		model.events.clear()
		models.append(model)
		effects.append([])
		centers.append(model.actors[0].pos)
		for old in [true,false]:
			var clip := Control.new()
			clip.position=Vector2((index%6*2+int(not old))*160,(index/6)*180)
			clip.size=Vector2(160,180)
			clip.clip_contents=true
			viewport.add_child(clip)
			var pane := ShotPane.new()
			pane.host=self
			pane.index=index
			pane.old=old
			clip.add_child(pane)
			panels.append(pane)
	var pause: Array=[]
	var paused_pixels := PackedByteArray()
	var impacts := 0
	for n in FRAMES:
		frame=n
		if n==PAUSE_FROM:pause=state()
		if n==PAUSE_TO:assert(state()==pause)
		if n<PAUSE_FROM or n>=PAUSE_TO:
			for i in models.size():
				var model = models[i]
				for effect in effects[i]:effect.age+=1.0/60
				model.advance_projectiles(1.0/60)
				for event in model.events:
					if event.type=="explosion":
						impacts+=1
						effects[i].append({"pos":event.position,"weapon":event.weapon,"age":0.0,"angle":0.0})
						journal.append({"frame":n,"panel":i,"type":event.type})
				model.events.clear()
				var blend := clampf(float(model.accumulator)/0.05,0,1)
				if not model.projectiles.is_empty():
					var lead: Dictionary=model.projectiles[0]
					if lead.launched:centers[i]=Vector2(lead.get("previous_hit_pos",lead.hit_pos)).lerp(lead.hit_pos,blend)
		for pane in panels:pane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		assert(image.get_size()==Vector2i(1920,1080))
		if n>=PAUSE_FROM and n<PAUSE_TO:
			if n==PAUSE_FROM:paused_pixels=image.get_data()
			assert(image.get_data()==paused_pixels)
		image.save_png(output+"/%03d.png"%n)
		if n in [12,36,64,65,94,95,120,180,240,300,360]:image.save_png("res://docs/projectile-light/%s-%03d.png"%[tag,n])
	var final_pixels := viewport.get_texture().get_image().get_data()
	for sprite in sprites:sprite.clear_projectiles()
	for pane in panels:pane.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().get_data()==final_pixels)
	var remaining := models.map(func(m):return m.projectiles.size())
	assert(remaining.all(func(n):return n==0))
	var file := FileAccess.open("res://docs/projectile-light/capture-%s.json"%tag,FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":FRAMES,"resolution":[1920,1080],"pause":[PAUSE_FROM,PAUSE_TO],"pause_rgba_identical":true,"empty_after_clear_identical":true,"impacts":impacts,"journal":journal,"remaining":remaining},"\t"))
	file.close()
	print("PROJECTILE LIGHT GPU ",tag," frames=",FRAMES," impacts=",impacts," remaining=",remaining)
	viewport.free()
	await process_frame
	quit()
