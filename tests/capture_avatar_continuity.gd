extends SceneTree
class Preview extends Node2D:
	var sprites: Array = []
	var animation = load("res://scripts/battle_art.gd").new()
	var clock := 0.0
	var pose := "idle"
	var pose_age := 0.0
	var sets := [
		{"0":"0:0:1","1":"0:1:1","2":"0:2:1","3":"2:3:1"},
		{"0":"0:0:2","1":"0:1:2","2":"2:2:0","3":"2:3:1"},
		{"0":"1:0:0","1":"1:1:0","2":"2:2:0","3":"2:3:1"}]
	func _draw() -> void:
		draw_rect(Rect2(0,0,1600,1080),Color("182b40"))
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(40,42),"Avatar unido · poses contínuas · "+pose,HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color.WHITE)
		for row in range(3):
			for col in range(2):
				var index := row*2+col
				var sprite = sprites[index]
				var pos := Vector2(430+col*800,290+row*340)
				animation.motion[index].pose = pose
				animation.motion[index].pose_age = pose_age
				var state: Dictionary = animation.presentation(index,sprite.hd_rig,clock,2)
				var facing := 1 if col == 0 else -1
				sprite.draw(self,pos,180,facing,0,0,Color.WHITE,pose,pose_age,2,false,clock*3.0,{"equipment":sets[row],"age":clock,"rig_state":state})
				var breathing := Transform2D(sin(clock*TAU*1.5)*0.014,Vector2.ZERO)
				sprite.hd_rig.avatars.draw(self,sets[row],Transform2D(0,Vector2(-2,2),0,pos+Vector2(-245,-30))*breathing,clock,Color.WHITE)
				draw_string(font,pos+Vector2(-100,90),["Mage","Bigfoot"][col],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1600,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var preview := Preview.new()
	var actors: Array = []
	for i in range(6):
		preview.sprites.append(load("res://scripts/mage_sprite.gd" if i%2 == 0 else "res://scripts/bigfoot_sprite.gd").new())
		actors.append({"vehicle":1 if i%2 == 0 else 2,"pos":Vector2.ZERO})
	preview.animation.reset(actors)
	root.add_child(preview)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/avatar-motion"))
	for frame in range(360):
		preview.clock = float(frame)/60.0
		var pose: String = ["idle","moving","charging_2","recoil","hurt","idle"][int(preview.clock)]
		if frame > 0 and pose == preview.pose:
			preview.pose_age += 1.0/60.0
		else:
			preview.pose_age = 0.0
		preview.pose = pose
		preview.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://.tools/avatar-motion/%04d.png" % frame) == OK)
	preview.queue_free()
	await process_frame
	print("AVATAR CONTINUITY GPU: 360 frames at 60 fps")
	quit()
