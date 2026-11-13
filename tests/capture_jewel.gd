extends SceneTree
## GPU native art/tick capture. Manual60Hz, full1920x1080; no realtimeFPS claim.
const Rules=preload("res://scripts/jewel_rules.gd")
const Art=preload("res://scripts/jewel_art.gd")
const Terrain=preload("res://scripts/terrain.gd")
const FRAMES:=210
var viewport: SubViewport
var models: Array=[]
var arts: Array=[]
var effects: Array=[]
var panels: Array=[]
var frame:=0
var pause_pixels:=PackedByteArray()
var pause_state: Array=[]
var failures:=0
var checks:=0

class World extends Node2D:
	var host
	var index:int
	func _draw() -> void:
		var state: Dictionary=host.models[index]
		draw_rect(Rect2(0,0,320,270),Color("426883") if index<3 else Color("132033"))
		draw_rect(Rect2(0,205,320,65),Color("636b44"))
		draw_string(ThemeDB.fallback_font,Vector2(12,24),["normal / EPA","drop / wind","damage / score","shock / no credit","body + additive light","removal / Jflame"][index],HORIZONTAL_ALIGNMENT_LEFT,-1,14)
		host.arts[index].draw(self,state.entities)
		host.arts[index].draw_lights(self,state.entities)
		host.arts[index].draw_effects(self,host.effects[index])
		host.arts[index].score_digits(self,int(state.scores[0]),Vector2(12,45))
		host.arts[index].score_digits(self,int(state.scores[1]),Vector2(160,45))
		draw_set_transform(Vector2.ZERO)
		draw_string(ThemeDB.fallback_font,Vector2(12,250),"A %d / B %d" % state.scores,HORIZONTAL_ALIGNMENT_LEFT,-1,14)

class Ground extends Terrain:
	func native_surface_at(_x: int, y: int = 0) -> int:
		return 205 if y<=205 else 10000
	func native_solid(point: Vector2i) -> bool:
		return point.y>=205

var terrain=Ground.new()
func _initialize() -> void:
	call_deferred("run")

func verify(ok:bool,label:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/jewel-implementation/frames"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/jewel-implementation/gpu"))
	viewport=SubViewport.new()
	viewport.size=Vector2i(1920,1080)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for index in 6:
		var state:=Rules.create(terrain,46+index)
		state.wind=20 if index==1 else 0
		state.wind_angle=0
		for kind in 4:
			Rules.spawn(state,terrain,55+kind*65,[0,15,40,80][kind],index==1)
			if index==1:state.entities[kind].pos.y=70
			if index==3:state.entities[kind].pose="shock"
		models.append(state)
		arts.append(Art.new())
		effects.append([])
		var panel:=World.new()
		panel.host=self
		panel.index=index
		panel.position=Vector2((index%3)*640,(index/3)*540)
		panel.scale=Vector2(2,2)
		viewport.add_child(panel)
		panels.append(panel)
	for count in FRAMES:
		frame=count
		var paused:=count>=60 and count<90
		if not paused:
			if count in [30,105,150]:
				for index in [2,5]:
					var entity: Dictionary=models[index].entities[(count/15)%4]
					var p:=Vector2i(entity.pos)-Vector2i(0,10)
					Rules.blast(models[index],p,{"power":[220,220,220],"dimension":[44,44,44],"aspect":[120,120,120],"owner":index%2})
			for index in 6:
				Rules.tick(models[index],terrain,1.0/60.0)
				for event in models[index].events:
					if event.type=="jewel_removed" and bool(event.effect):effects[index].append({"kind":event.kind,"pos":event.position,"age":0.0})
				models[index].events.clear()
				for effect in effects[index]:effect.age+=1.0/60.0
		for panel in panels:panel.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var buffer:=viewport.get_texture().get_image()
		verify(buffer.get_size()==Vector2i(1920,1080),"FullHD capture")
		if count==60:
			pause_pixels=buffer.get_data()
			pause_state=models.duplicate(true)
		if paused:
			verify(buffer.get_data()==pause_pixels,"Pause exact RGBA")
			verify(models==pause_state,"Pause model freeze")
		if count==93:verify(buffer.get_data()!=pause_pixels,"Animation resumes")
		buffer.save_png("res://.tools/jewel-implementation/frames/%03d.png" % count)
		if count in [0,35,60,110,155,209]:buffer.save_png("res://docs/jewel-implementation/gpu/%03d.png" % count)
	for art in arts:art.glow.clear()
	viewport.queue_free()
	await process_frame
	await process_frame
	print("JEWEL GPU CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
