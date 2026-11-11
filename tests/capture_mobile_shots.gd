extends SceneTree
## Shot QA (ADR-154): T1 / T2 / SS of one mobile flying over a flat floor, each
## panel following its lead shell. 1920x1080, 60 Hz presentation over the 20 Hz
## model, isolated from the profile. Usage:
##   Godot --path . --script tests/capture_mobile_shots.gd -- <id> [tag] [dark]
## writes docs/mobile-shots/<kind>[-tag]-<frame>.png at a few fixed frames.
const Match = preload("res://scripts/match.gd")
const Looks = preload("res://scripts/mobile_looks.gd")
const OUT := "res://docs/mobile-shots/"
const STILLS := [12, 24, 36, 48, 60, 90, 120, 150, 180, 210, 240]
const FLOOR_Y := 700.0
var models: Array = []
var impacts: Array = []
var centers: Array = []
var panels: Array = []
var sprite
var vehicle := 3
var capture_view: SubViewport
var sparks: Array = []
var armor_capture := false
var armor_journal: Array = [[],[],[]]
var armor_pause_state: Array = []
var sky := Color("6f9cc8")

class ShotPanel extends Node2D:
	var host
	var index := 0
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		var model = host.models[index]
		if host.armor_capture:
			draw_armor(model)
			return
		# Miramo-like sky: a mid tone shows both a dark veil and a missing glow.
		draw_rect(Rect2(0, 0, 640, 480), host.sky)
		var blend := clampf(float(model.accumulator) / 0.05, 0, 1)
		if not model.projectiles.is_empty():
			var lead: Dictionary = model.projectiles[0]
			host.centers[index] = Vector2(lead.get("previous_hit_pos", lead.hit_pos)).lerp(lead.hit_pos, blend)
		var offset: Vector2 = Vector2(320, 240) - host.centers[index]
		draw_rect(Rect2(Vector2(-4000, FLOOR_Y) + offset, Vector2(8000, 400)), Color("4b5d3a"))
		if host.sprite.has_method("begin_satellites"):
			host.sprite.begin_satellites(self)
			for satellite in model.satellites.values():
				host.sprite.draw_satellite(self, satellite, offset, blend)
		if host.sprite.has_method("begin_projectiles"):
			host.sprite.begin_projectiles(self)
		for source in model.projectiles:
			var shot: Dictionary = source.duplicate()
			if not bool(shot.get("launched", true)):
				continue
			shot.draw_fraction = blend
			shot.hit_pos = Vector2(shot.get("previous_hit_pos", shot.hit_pos)).lerp(shot.hit_pos, blend)
			shot.pos = Vector2(shot.get("previous_draw_pos", shot.pos)).lerp(shot.pos, blend)
			host.sprite.draw_projectile(self, shot, int(shot.get("weapon", index)), offset)
		draw_set_transform(Vector2.ZERO)
		host.sparks[index].draw(self, offset)
		for effect in host.impacts[index]:
			host.sprite.draw_effect(self, effect, offset)
		draw_set_transform(Vector2.ZERO)
		draw_string(font, Vector2(16, 28), "%s %s | %d projéteis" % [Looks.look(host.vehicle).kind, ["T1", "T2", "SS"][index], model.projectiles.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 22)

	func draw_armor(model) -> void:
		draw_rect(Rect2(0,0,640,1080),Color("101820"))
		draw_string(font,Vector2(22,40),"Armor %s — issue #27"%["T1","T2","SS"][index],HORIZONTAL_ALIGNMENT_LEFT,-1,25)
		draw_set_transform(Vector2.ZERO)
		var offset:=Vector2(120,100)
		draw_rect(Rect2(offset,Vector2(400,300)),host.sky)
		# Render actual collision cells, including both physical craters.
		for y in model.terrain.HEIGHT:
			var start: int=-1
			for x in range(model.terrain.WIDTH+1):
				var solid: bool=x<model.terrain.WIDTH and model.terrain.cells[y*model.terrain.WIDTH+x]!=0
				if solid and start<0:start=x
				if not solid and start>=0:
					draw_rect(Rect2(offset+Vector2(start*2,y*2),Vector2((x-start)*2,2)),Color("4b5d3a"))
					start=-1
		var blend:=clampf(float(model.accumulator)/0.05,0,1)
		for source in model.projectiles:
			var shot: Dictionary=source.duplicate()
			shot.draw_fraction=blend
			shot.hit_pos=Vector2(shot.previous_hit_pos).lerp(shot.hit_pos,blend)
			shot.pos=Vector2(shot.previous_draw_pos).lerp(shot.pos,blend)
			host.sprite.draw_projectile(self,shot,index,offset)
		for effect in host.impacts[index]:host.sprite.draw_effect(self,effect,offset)
		draw_set_transform(Vector2.ZERO)
		draw_string(font,Vector2(22,610),"Um shell · %d ativos · %d impactos"%[model.projectiles.size(),host.armor_journal[index].size()],HORIZONTAL_ALIGNMENT_LEFT,-1,22)
		for row in host.armor_journal[index].size():
			draw_string(font,Vector2(22,660+row*38),str(host.armor_journal[index][row]),HORIZONTAL_ALIGNMENT_LEFT,-1,19)
		draw_string(font,Vector2(22,830),"Modelo20Hz / apresentação60Hz",HORIZONTAL_ALIGNMENT_LEFT,-1,20)
		draw_string(font,Vector2(22,875),"Pausa: quadros30–59 (estado congelado)",HORIZONTAL_ALIGNMENT_LEFT,-1,19)

func _initialize() -> void:
	call_deferred("run")

func floor_model():
	var model = Match.new()
	model.start(vehicle, 1, 42, "", "original")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.WIDTH = 2000
	model.terrain.HEIGHT = 1000
	model.terrain.cells.resize(model.terrain.WIDTH * model.terrain.HEIGHT)
	model.terrain.cells.fill(0)
	model.terrain.image = null
	model.terrain.texture = null
	model.terrain.visual = null
	model.terrain.visual_texture = null
	model.terrain.native_cells = PackedByteArray()
	model.terrain.enable_native()
	var width: int = model.terrain.WIDTH * model.terrain.SCALE
	for y in range(int(FLOOR_Y), model.terrain.HEIGHT * model.terrain.SCALE):
		for x in width:
			model.terrain.native_cells[y * width + x] = 1
	for y in range(int(FLOOR_Y / 2), model.terrain.HEIGHT):
		for x in model.terrain.WIDTH:
			model.terrain.cells[y * model.terrain.WIDTH + x] = 1
	model.actors[0].pos = Vector2(400, FLOOR_Y - 10)
	model.actors[0].facing = 1
	model.actors[1].pos = Vector2(3900, 1900)
	return model

func run() -> void:
	var args := OS.get_cmdline_user_args()
	vehicle = int(args[0]) if args.size() > 0 else 3
	armor_capture=vehicle==4 and args.size()>1 and args[1]=="two-impacts"
	var tag := ("-" + args[1]) if args.size() > 1 else ""
	if args.size() > 2 and args[2] == "dark":
		sky = Color("101820")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var look: Dictionary = Looks.look(vehicle)
	sprite = load(look.sprite).new()
	if sprite.has_method("setup"):
		sprite.setup(look.kind)
	capture_view = SubViewport.new()
	capture_view.size = Vector2i(1920, 1080 if armor_capture else 480)
	capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_view)
	for weapon in 3:
		var model = floor_model()
		if armor_capture:
			model.terrain.WIDTH=200
			model.terrain.HEIGHT=150
			model.terrain.cells.resize(30000)
			model.terrain.cells.fill(0)
			for y in range(75,150):
				for x in 200:model.terrain.cells[y*200+x]=1
			model.terrain.native_cells=PackedByteArray()
			model.terrain.enable_native()
			model.actors[0].pos=Vector2(40,125)
			model.actors[1].pos=Vector2(360,125)
		model.fire(55, 70, weapon)
		if armor_capture:
			var shell: Dictionary=model.projectiles[0]
			shell.launched=true
			load("res://scripts/classic_ballistics.gd").seed(shell,Vector2i(200*256,100*256),Vector2i(128,1280),Vector2i(0,64))
			shell.hit_pos=shell.pos
			shell.age=0.5
		model.events.clear()
		models.append(model)
		impacts.append([])
		sparks.append(load("res://scripts/dragon_sparks.gd").new())
		centers.append(Vector2(model.actors[0].pos))
		var panel_view := SubViewport.new()
		panel_view.size = Vector2i(640, 1080 if armor_capture else 480)
		panel_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_view.add_child(panel_view)
		var pane := ShotPanel.new()
		pane.host = self
		pane.index = weapon
		panel_view.add_child(pane)
		panels.append(pane)
		var display := TextureRect.new()
		display.texture = panel_view.get_texture()
		display.position = Vector2(weapon * 640, 0)
		display.size = Vector2(640, 1080 if armor_capture else 480)
		capture_view.add_child(display)
	for frame in range(STILLS.back() + 1):
		if armor_capture and frame==30:
			assert(models[1].projectiles.size()==1 and int(models[1].projectiles[0].armor_phase)==1)
			armor_pause_state=models.map(func(m):return [m.projectiles.duplicate(true),m.terrain.native_cells.duplicate(),m.actors.duplicate(true),m.spark_tick,m.accumulator])
		if armor_capture and frame==60:
			assert(armor_pause_state==models.map(func(m):return [m.projectiles.duplicate(true),m.terrain.native_cells.duplicate(),m.actors.duplicate(true),m.spark_tick,m.accumulator]))
			print("ARMOR ACTIVE PAUSE:30 identical model states; phase1 shell preserved")
		for index in models.size():
			if armor_capture and frame>=30 and frame<60:continue
			models[index].tick(1.0 / 60)
			for effect in impacts[index]:
				effect.age += 1.0 / 60
			for event in models[index].events:
				if event.type == "dragon_spark_sweep":
					sparks[index].accept(event)
				if event.type == "explosion":
					if armor_capture:armor_journal[index].append("tick%d: (%d,%d), raio%s"%[models[index].spark_tick,event.position.x,event.position.y,event.radius])
					impacts[index].append({"pos": event.position, "weapon": event.weapon, "child": event.get("child", false), "ss_state": event.get("ss_state", "normal"), "age": 0.0, "angle": event.get("angle", 0.0)})
			models[index].events.clear()
			sparks[index].sync(int(models[index].spark_tick))
		for pane in panels:
			pane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		if armor_capture:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/armor-t2/frames"))
			capture_view.get_texture().get_image().save_png("res://.tools/armor-t2/frames/%03d.png"%frame)
		if frame in STILLS:
			capture_view.get_texture().get_image().save_png(OUT + "%s%s-%03d.png" % [look.kind, tag, frame])
	if armor_capture:assert(armor_journal[1].size()==2 and models[1].projectiles.is_empty())
	print("MOBILE SHOTS CAPTURE: %s%s %d stills" % [look.kind, tag, STILLS.size()])
	quit()
