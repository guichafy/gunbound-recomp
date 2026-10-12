extends SceneTree
class Compare extends Node2D:
	var sprites: Array
	var equipment: Dictionary
	var saved: Array
	func _draw() -> void:
		draw_rect(Rect2(0,0,1600,1080),Color("182b40"))
		var font := ThemeDB.fallback_font
		for row in range(2):
			for col in range(2):
				var sprite = sprites[row]
				if col == 0:
					sprite.hd_rig.sheet.catalog_valid = false
				else:
					sprite.hd_rig.sheet.catalog_valid = saved[row]
				sprite.hd_rig.avatars.use_hd = col == 1
				var pos := Vector2(350+col*850,330+row*540)
				sprite.draw(self,pos,180,1,0,0,Color.WHITE,"idle",0,0,false,0,{"equipment":equipment,"age":0.0})
				draw_string(font,pos+Vector2(-250,120),["Referência original C#","Mobile HD + avatar"][col],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
			sprites[row].hd_rig.sheet.catalog_valid = saved[row]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1600,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var preview := Compare.new()
	preview.sprites = [load("res://scripts/bigfoot_sprite.gd").new(),load("res://scripts/mage_sprite.gd").new()]
	preview.saved = [preview.sprites[0].hd_rig.sheet.catalog_valid,preview.sprites[1].hd_rig.sheet.catalog_valid]
	preview.equipment = {"0":"0:0:1","1":"0:1:1","2":"0:2:1","3":"2:3:1"}
	root.add_child(preview)
	await process_frame
	await RenderingServer.frame_post_draw
	var target := "res://.tools/avatar-mount-compare.png"
	assert(root.get_texture().get_image().save_png(target) == OK)
	preview.queue_free()
	await process_frame
	print("AVATAR MOUNT COMPARISON SAVED")
	quit()
