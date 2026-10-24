extends SceneTree
const SpritePose = preload("res://scripts/sprite_pose.gd")
class Gallery extends Node2D:
	var art
	var mobile
	var catalog
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("152b40"))
		var font := ThemeDB.fallback_font
		var sets := [["Basic masculino","0:0:0","0:1:0",0],["Space Marine","0:0:1","0:1:1",0],["Basic feminino","1:0:0","1:1:0",1],["Miner","0:0:2","0:1:2",0],["Punk","0:0:3","0:1:3",0],["Kappa","0:0:138","0:1:0",0]]
		for index in range(6):
			var entry: Array = sets[index]
			var origin := Vector2((index%3)*640,int(index/3)*540)
			var gear: Dictionary = catalog.defaults(entry[3])
			gear["0"] = entry[1]
			gear["1"] = entry[2]
			if index==1:
				gear["2"] = "0:2:1"
				gear["3"] = "2:3:1"
			draw_string(font,origin+Vector2(30,45),entry[0],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
			art.draw(self,gear,Transform2D(0,Vector2(-2.4,2.4),0,origin+Vector2(210,200)),0.0,Color.WHITE)
			mobile.draw(self,SpritePose.new(origin+Vector2(350,385),150,1,{"avatar_context":{"equipment":gear,"age":0.0}}))
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var gallery := Gallery.new()
	gallery.art = load("res://scripts/avatar_art.gd").new()
	gallery.mobile = load("res://scripts/bigfoot_sprite.gd").new()
	gallery.catalog = load("res://scripts/avatar_catalog.gd").new()
	root.add_child(gallery)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/avatar-shop/hd-roster.png") == OK)
	gallery.queue_free()
	await process_frame
	print("AVATAR HD ROSTER GPU SAVED")
	quit()
