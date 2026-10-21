extends SceneTree
var scene
class Poses extends Node2D:
	var equipment: Dictionary
	var sprites: Array = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1200),Color("13243b"))
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(60,60),"Avatar equipado · Mage / Bigfoot · sentidos e encosta",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)
		for row in range(2):
			for column in range(3):
				var pos := Vector2(300+column*630,400+row*570)
				var sprite = sprites[row]
				var pose: String = ["idle","recoil","hurt"][column]
				var facing := -1 if column==1 else 1
				var slope := deg_to_rad(-30.0) if column==2 else 0.0
				sprite.draw(self,pos,210,facing,slope,sprite.frame_index(pose,0.3,2,false),Color.WHITE,pose,0.3,2,false,1.0,{"equipment":equipment,"age":0.3})
				draw_string(font,pos+Vector2(-200,155),["Direita / idle","Esquerda / recuo","Encosta / dano"][column],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	if name == "shop":
		var color := screenshot.get_pixel(1600,800)
		assert(color.b > color.r+0.1, "Original blue background texture must remain alive through GPU draw")
	assert(screenshot.save_png("res://docs/avatar-shop/"+name+".png") == OK)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/avatar-shop"))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/avatar-capture.json")
	scene.profile.xp = 3600
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	root.size = Vector2i(1920,1200)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene.scale = Vector2.ONE*1.5
	scene.show_shop()
	await snap("shop")
	scene.shop.model.select("0:0:1")
	scene.shop.refresh(0,0)
	scene.shop.open_buy()
	await snap("purchase")
	scene.shop.close_buy()
	for key in ["0:0:1","0:1:1","0:2:1","2:3:1"]:
		scene.profile.purchase(key,"gold")
		scene.profile.equip(key)
	scene.shop.model.reset_preview()
	scene.shop.switch_tab(true)
	await snap("inventory")
	scene.shop.model.draft_attributes = [30,50,20,30,20,10,20,0]
	scene.shop.update_attributes()
	await snap("attributes")
	scene.profile.commit_attributes(scene.shop.model.draft_attributes)
	for mobile in [1,2]:
		scene.vehicle = mobile
		scene.opening = 0
		scene.start_match()
		scene.model.phase = "aim"
		scene.model.active = 0
		scene.queue_redraw()
		await snap("battle-"+str(mobile))
	var gear: Dictionary = scene.profile.equipped_set()
	scene.queue_free()
	await process_frame
	var poses := Poses.new()
	poses.equipment = gear
	poses.sprites = [load("res://scripts/mage_sprite.gd").new(),load("res://scripts/bigfoot_sprite.gd").new()]
	root.add_child(poses)
	await snap("poses")
	poses.queue_free()
	await process_frame
	for path in ["res://.tools/avatar-capture.json","res://.tools/avatar-capture-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("AVATAR SHOP GPU CAPTURES SAVED")
	quit()
