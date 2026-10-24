extends SceneTree
const SpritePose = preload("res://scripts/sprite_pose.gd")
class Gallery extends Node2D:
	var catalog=load("res://scripts/avatar_catalog.gd").new()
	var hd=load("res://scripts/avatar_art.gd").new()
	var native=load("res://scripts/avatar_art.gd").new(false)
	var sprites=[load("res://scripts/mage_sprite.gd").new(),load("res://scripts/bigfoot_sprite.gd").new()]
	var rows: Array=[]
	var age:=0.0
	var frame:=0
	func _init() -> void:
		for item in catalog.entries.values():
			if item.get("source")=="xfs" and int(item.category)==0 and item.get("layers",[]).size()==2:
				rows.append(item)
		rows.sort_custom(func(a,b): return str(a.key)<str(b.key))
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("123242"))
		var font:=ThemeDB.fallback_font
		for i in range(rows.size()):
			var item: Dictionary=rows[i]
			var p:=Vector2(i%4,int(i/4))*Vector2(480,216)
			draw_rect(Rect2(p,Vector2(479,215)),Color("17394a"))
			draw_string(font,p+Vector2(8,19),str(item.name)+" · "+str(item.key),HORIZONTAL_ALIGNMENT_LEFT,-1,14)
			var gear: Dictionary=catalog.defaults(int(item.gender))
			gear["0"]=item.key
			var facing:=1 if frame<180 else -1
			var scale:=Vector2(-facing*2.4,2.4)
			var angle:=deg_to_rad(8*sin(age))
			native.draw(self,gear,Transform2D(angle,scale,0,p+Vector2(85,160)),age,Color.WHITE)
			hd.draw(self,gear,Transform2D(angle,scale,0,p+Vector2(250,160)),age,Color.WHITE)
			var sprite=sprites[(frame/90)%2]
			var pose: String="moving" if frame<120 else ("charging" if frame<240 else "recoil")
			sprite.draw(self,SpritePose.new(p+Vector2(392,148),86,facing,{"rotation":angle,"frame":12,"pose":pose,"age":age,"weapon":int(age),"wheel_phase":age*10,"avatar_context":{"equipment":gear,"age":age,"motion_age":age}}))
			draw_string(font,p+Vector2(8,207),"Nativo Normal       HD vestido          HD no mobile",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("a8cddd"))
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var gallery:=Gallery.new()
	assert(gallery.rows.size()==20)
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.add_child(gallery)
	DirAccess.make_dir_recursive_absolute("res://.tools/avatar-effect-frames")
	DirAccess.make_dir_recursive_absolute("res://docs/avatar-effects")
	var paused: Image
	for frame in range(360):
		gallery.frame=frame
		gallery.age=(179.0 if frame>=180 and frame<210 else float(frame))/60.0
		# Keep the same presentation during the pause as well as the clock.
		if frame>=180 and frame<210:
			gallery.frame=179
		gallery.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		var image:=root.get_texture().get_image()
		assert(image.get_size()==Vector2i(1920,1080))
		if frame==180:
			paused=image
		elif frame>180 and frame<210:
			assert(image.get_data()==paused.get_data(),"Pause must freeze every effect and attachment")
		assert(image.save_png("res://.tools/avatar-effect-frames/%04d.png" % frame)==OK)
		if frame in [0,90,179,210,270,359]:
			assert(image.save_png("res://docs/avatar-effects/%04d.png" % frame)==OK)
	print("AVATAR EFFECT GPU:20 heads;1920x1080;360frames at60fps;30 identical pause frames")
	quit()
