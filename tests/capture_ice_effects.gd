extends SceneTree
## Scripted impacts through real Match.explode. GPU60Hz manual stepping,
## no native-client execution or real-time performance claim.
const Match = preload("res://scripts/match.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const FRAMES := 451
const PAUSE_FROM := 45
const PAUSE_TO := 75
var models: Array = []
var arts: Array = []
var sprites: Dictionary = {}
var panels: Array = []
var effects: Array = []
var hit_counts: Array = []
var journal: Array = []
var elapsed := 0.0
var pause_state: Array = []
var pause_bytes := PackedByteArray()
var viewport: SubViewport
var frame := 0

class IceWorld extends Node2D:
	var host
	var index: int
	func _draw() -> void:
		var model = host.models[index]
		for actor in 2:
			var state: Dictionary = host.arts[index].motion[actor]
			var vehicle: int = model.actors[actor].vehicle
			host.sprites[vehicle].draw(self,Pose.new(model.actors[actor].pos,60,int(model.actors[actor].facing),{"pose":state.pose,"age":state.pose_age,"weapon":1}))
		for effect in host.effects[index]:
			host.sprites[11].draw_effect(self,effect)

class IcePanel extends Node2D:
	var host
	var index: int
	func _draw() -> void:
		var model = host.models[index]
		var side: int = model.actors[0].facing
		draw_rect(Rect2(0,0,640,540),Color("7ea4b4"))
		draw_rect(Rect2(0,390,640,150),Color("695f43"))
		draw_rect(Rect2(0,0,640,92),Color("10212b"))
		draw_string(ThemeDB.fallback_font,Vector2(18,30),["T2 / Bigfoot","SS / Ice","11 T2 + SS / Bigfoot"][index%3]+("  →" if side>0 else "  ←"),HORIZONTAL_ALIGNMENT_LEFT,-1,23)
		draw_string(ThemeDB.fallback_font,Vector2(18,59),"vulnerability: "+str(model.actors[1].native_resistance),HORIZONTAL_ALIGNMENT_LEFT,-1,21)
		draw_string(ThemeDB.fallback_font,Vector2(18,83),"%d impacts · pose %s" % [host.hit_counts[index],host.arts[index].motion[1].pose],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
		draw_line(Vector2(0,539),Vector2(640,539),Color.WHITE,2)

func _initialize() -> void:
	call_deferred("run")

func state() -> Array:
	var result: Array = []
	for i in models.size():
		result.append([models[i].actors.duplicate(true),arts[i].motion.duplicate(true),effects[i].duplicate(true)])
	return result

func impact(index: int, weapon: int) -> void:
	var model = models[index]
	model.shot_weapon = weapon
	var shell: Dictionary = model.projectile_parameters(0,30,50,weapon)[0]
	model.explode(Vector2(Shared.center(model.actors[1])),1,shell)
	hit_counts[index] += 1
	arts[index].react({"type":"fire","actor":0,"vehicle":11,"weapon":weapon})
	for event in model.events:
		arts[index].react(event)
		if event.type=="explosion":
			effects[index].append({"pos":event.position,"weapon":weapon,"age":0.0,"angle":event.angle})
	model.events.clear()
	journal.append({"frame":frame,"panel":index,"weapon":weapon,"values":model.actors[1].native_resistance.duplicate(),"hp":model.actors[1].hp})

func run() -> void:
	var output := "res://.tools/ice-29/frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/ice-native"))
	for kind in ["ice","bigfoot"]:
		var sprite = load("res://scripts/classic_sprite.gd").new()
		sprite.setup(kind)
		sprites[11 if kind=="ice" else 2] = sprite
	viewport = SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for i in 6:
		var model = Match.new()
		var target := 11 if i%3==1 else 2
		model.start(11,1,29,"","wind",null,[],[],[],0,target)
		model.actors[0].pos = Vector2(180 if i<3 else 340,210)
		model.actors[1].pos = Vector2(340 if i<3 else 180,210)
		model.actors[0].facing = 1 if i<3 else -1
		model.actors[1].facing = -model.actors[0].facing
		model.actors[0].invulnerable = true
		model.actors[1].shield = 100000
		model.actors[0].turns = 3
		model.shot_actor = 0
		model.weather.columns.clear()
		model.events.clear()
		models.append(model)
		var art = load("res://scripts/battle_art.gd").new()
		art.reset(model.actors)
		arts.append(art)
		effects.append([])
		hit_counts.append(0)
		var pane := IcePanel.new()
		pane.host = self
		pane.index = i
		var panel_view := SubViewport.new()
		panel_view.size = Vector2i(640,540)
		panel_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.add_child(panel_view)
		panel_view.add_child(pane)
		panels.append(pane)
		var world := IceWorld.new()
		world.host = self
		world.index = i
		world.scale = Vector2(2,2)
		world.position = Vector2(-160,-80)
		pane.add_child(world)
		panels.append(world)
		var display := TextureRect.new()
		display.position = Vector2((i%3)*640,(i/3)*540)
		display.size = Vector2(640,540)
		display.texture = panel_view.get_texture()
		viewport.add_child(display)
	for n in FRAMES:
		frame = n
		if n==PAUSE_FROM:
			pause_state = state()
		if n==PAUSE_TO:
			assert(state()==pause_state)
		if n<PAUSE_FROM or n>=PAUSE_TO:
			elapsed += 1.0/60.0
			for i in 6:
				arts[i].tick(models[i],1.0/60.0)
				for effect in effects[i]:
					effect.age += 1.0/60.0
				if n>=30 and n<=360 and n%30==0:
					impact(i,2 if i%3==1 else 1)
				if n==360 and i%3==2:
					impact(i,2)
		for pane in panels:
			pane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		assert(image.get_size()==Vector2i(1920,1080))
		if n>=PAUSE_FROM and n<PAUSE_TO:
			if n==PAUSE_FROM:
				pause_bytes = image.get_data()
			assert(image.get_data()==pause_bytes)
		image.save_png(output+"/%03d.png"%n)
		if n in [0,30,44,45,74,75,330,360,420,450]:
			image.save_png("res://docs/ice-native/ice-%03d.png"%n)
	var manifest := {"frames":FRAMES,"resolution":[1920,1080],"pause":[PAUSE_FROM,PAUSE_TO],"pause_identical":true,"journal":journal,"final":models.map(func(m):return m.actors[1].native_resistance.duplicate())}
	var file := FileAccess.open("res://docs/ice-native/capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	print("ICE GPU frames=",FRAMES," pause_identical=true")
	viewport.queue_free()
	await process_frame
	quit()
