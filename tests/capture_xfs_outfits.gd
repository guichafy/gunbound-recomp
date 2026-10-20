extends SceneTree
class Preview extends Node2D:
	var sprites: Array=[]
	var outfits: Array=[]
	var age := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("182b40"))
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(35,45),"XFS — montagem real em Mage / Bigfoot, dois sentidos e inclinação",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color.WHITE)
		for row in range(2):
			for col in range(4):
				var sprite=sprites[row]
				var pos := Vector2(240+col*480,330+row*470)
				var facing := 1 if col%2==0 else -1
				sprite.draw(self,pos,180,facing,deg_to_rad(-12 if col%2==0 else 12),0,Color.WHITE,"idle",age,0,false,0,{"equipment":outfits[col],"age":age})
				draw_string(font,pos+Vector2(-190,135),["Marine / HD aprovado","Pucca / peças XFS","Ghost / camada L","Óculos de 44 quadros"][col],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var preview := Preview.new()
	preview.sprites=[load("res://scripts/mage_sprite.gd").new(),load("res://scripts/bigfoot_sprite.gd").new()]
	preview.outfits=[
		{"0":"xfs:0:0:1","1":"xfs:0:1:1","2":"xfs:0:2:2","3":"xfs:2:3:1"},
		{"0":"xfs:1:0:6","1":"xfs:1:1:4","2":"xfs:1:2:0","3":"xfs:2:3:1"},
		{"0":"xfs:0:0:7","1":"xfs:0:1:4","2":"xfs:0:2:0","3":"xfs:2:3:132"},
		{"0":"xfs:1:0:9","1":"xfs:1:1:6","2":"xfs:1:2:19","3":"xfs:2:3:3"}
	]
	root.add_child(preview)
	for frame in [0,16,43]:
		preview.age=frame/10.0
		preview.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		assert(root.get_texture().get_image().save_png("res://docs/avatar-shop-xfs/outfits-%02d.png" % frame)==OK)
	preview.queue_free()
	await process_frame
	print("XFS OUTFIT GPU: three poses, four outfits, two mobiles, 1920x1080")
	quit()
