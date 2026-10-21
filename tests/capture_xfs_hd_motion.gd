extends SceneTree
class Preview extends Node2D:
	var sprites: Array=[]
	var animation=load("res://scripts/battle_art.gd").new()
	var clock := 0.0
	var pose := "idle"
	var pose_age := 0.0
	var paused := false
	var sets: Array=[
		{"0":"xfs:0:0:8","1":"xfs:0:1:8","2":"xfs:0:2:9","3":"xfs:2:3:171"},
		{"0":"xfs:1:0:15","1":"xfs:1:1:7","2":"xfs:1:2:16","3":"xfs:2:3:132"},
		{"0":"xfs:0:0:71","1":"xfs:0:1:72","2":"xfs:0:2:0","3":"xfs:2:3:161"},
		{"0":"xfs:1:0:22","1":"xfs:1:1:21","2":"xfs:1:2:7","3":"xfs:2:3:15"}]
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("182b40"))
		var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(35,36),"Avatares XFS HD vestidos · "+("PAUSA" if paused else pose)+" · 60 fps",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
		for col in range(4):
			draw_string(font,Vector2(160+col*480,70),("Mage" if col%2==0 else "Bigfoot")+(" →" if col<2 else " ←"),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("a7d1e3"))
		for row in range(4):
			for col in range(4):
				var index:=row*4+col
				var sprite=sprites[index]
				var pos:=Vector2(240+col*480,250+row*242)
				animation.motion[index].pose=pose
				animation.motion[index].pose_age=pose_age
				var state: Dictionary=animation.presentation(index,sprite.hd_rig,clock,2)
				var facing:=1 if col<2 else -1
				sprite.draw(self,pos,120,facing,deg_to_rad(8*facing),0,Color.WHITE,pose,pose_age,2,false,clock*3,{"equipment":sets[row],"age":clock,"rig_state":state})
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var view:=Preview.new()
	var actors: Array=[]
	for i in range(16):
		view.sprites.append(load("res://scripts/mage_sprite.gd" if i%2==0 else "res://scripts/bigfoot_sprite.gd").new())
		actors.append({"vehicle":1 if i%2==0 else 2,"pos":Vector2.ZERO})
	view.animation.reset(actors)
	root.add_child(view)
	var folder:="res://.tools/xfs-hd-motion"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var frozen: PackedByteArray=[]
	for frame in range(360):
		view.paused=frame>=180 and frame<210
		var time:=mini(frame,179) if frame<210 else frame-30
		var pose: String=["idle","moving","charging_2","recoil","hurt","idle"][mini(5,int(time/60))]
		var clock_time:=float(time)/60.0
		if pose!=view.pose:
			view.pose_age=0.0
		else:
			view.pose_age+=clock_time-view.clock
		view.pose=pose
		view.clock=clock_time
		view.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		var capture:=root.get_texture().get_image()
		if frame==180:
			frozen=capture.get_data()
		elif view.paused:
			assert(capture.get_data()==frozen,"Pause must freeze anatomy, effects and pose transitions")
		assert(capture.save_png(folder+"/%04d.png" % frame)==OK)
	view.queue_free()
	await process_frame
	print("XFS HD MOTION GPU: 360 frames / 60 fps / 1920x1080 / four outfits x both mobiles x both directions / frozen pause confirmed")
	quit()
