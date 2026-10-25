extends Node
## Native sprites via Game's active catalog. GPU only, isolated profile.
const Pose = preload("res://scripts/sprite_pose.gd")
const OUT := "res://docs/original-mobiles/"
const FRAMES := "res://.tools/original-mobiles/frames/"
var scene
var board
var target: SubViewport
var clock := 0.0

class Board extends Node2D:
	var host
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("182a3a"))
		draw_string(font,Vector2(35,45),"Bigfoot e Mage | arte original do cliente | 0.20.3",HORIZONTAL_ALIGNMENT_LEFT,-1,29)
		draw_string(font,Vector2(35,82),"Atlas/EPA nativos; avatares preservados | tiros e impactos em escala original (painel ampliado 2x)",HORIZONTAL_ALIGNMENT_LEFT,-1,21)
		for row in 2:
			var id := 2 if row == 0 else 1
			var sprite = host.scene.sprite_for(id)
			var base_y := 260.0+row*450
			draw_string(font,Vector2(35,base_y-130),"BIGFOOT" if id == 2 else "MAGE",HORIZONTAL_ALIGNMENT_LEFT,-1,26)
			for column in 6:
				var pose: String = ["idle","moving","charging","recoil","hurt","using_item"][column]
				var facing := 1 if column%2 == 0 else -1
				var position := Vector2(150+column*310,base_y)
				var frame: int = sprite.frame_index(pose,host.clock,1,false)
				var equipment: Dictionary = host.scene.profile.equipped_set()
				var request = Pose.new(position,120.0,facing,{"rotation":deg_to_rad(-15 if column == 1 else 15 if column == 4 else 0),"frame":frame,"pose":pose,"age":host.clock,"weapon":1,"avatar_context":{"equipment":equipment,"age":host.clock}})
				sprite.draw(self,request)
				draw_string(font,position+Vector2(-90,90),pose+" "+("→" if facing == 1 else "←"),HORIZONTAL_ALIGNMENT_LEFT,-1,20)
			for weapon in 3:
				var position := Vector2(180+weapon*610,base_y+165)
				var trail: Array = []
				for j in 16:
					trail.append(Vector2(-120+j*8,sin(j*.45+host.clock*4)*7 if id == 1 and weapon == 1 else 0))
				var shot := {"pos":Vector2.ZERO,"hit_pos":Vector2.ZERO,"velocity":Vector2(200 if weapon%2 == 0 else -200,-20),"age":host.clock,"trail":trail,"launched":true}
				# Source pixel art enlargement is presentation only.
				var demo = host.demos[row*3+weapon]
				demo.position = position
				demo.sprite = sprite
				demo.shot = shot
				demo.weapon = weapon
				demo.clock = host.clock
				demo.queue_redraw()
				draw_string(font,position+Vector2(-120,90),["T1","T2","SS"][weapon]+" / voo e impacto",HORIZONTAL_ALIGNMENT_LEFT,-1,20)

class Demo extends Node2D:
	var sprite
	var weapon := 0
	var clock := 0.0
	var shot: Dictionary = {}
	func _draw() -> void:
		if sprite == null:
			return
		sprite.draw_projectile(self,shot,weapon)
		sprite.draw_effect(self,{"pos":Vector2(120,0),"weapon":weapon,"age":fmod(clock,1.8)})

var demos: Array = []
var root: Window:
	get: return get_tree().root
var process_frame: Signal:
	get: return get_tree().process_frame
func quit() -> void:
	get_tree().quit()
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/original-mobiles/capture-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.hide()
	scene.sound.muted = true
	target = SubViewport.new()
	target.size = Vector2i(1920,1080)
	target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(target)
	board = Board.new()
	board.host = self
	target.add_child(board)
	for index in 6:
		var demo = Demo.new()
		demo.scale = Vector2(2,2)
		board.add_child(demo)
		demos.append(demo)
	for frame in 210:
		if frame < 120 or frame >= 150:
			clock += 1.0/60.0
		board.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := target.get_texture().get_image()
		picture.save_png(FRAMES+"frame%04d.png"%frame)
		if frame == 60:
			picture.save_png(OUT+"composition.png")
	# Also capture the actual menu, shop and battle via an isolated scene.
	var game_view := SubViewport.new()
	game_view.size = Vector2i(1280,800)
	game_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(game_view)
	scene.reparent(game_view)
	scene.show()
	for id in [2,1]:
		scene.show_menu()
		scene.select_vehicle(id)
		await snap_game(game_view,"menu-%d.png" % id)
		scene.opening = 0
		scene.match_seed = 1
		scene.start_match()
		await snap_game(game_view,"battle-%d.png" % id)
		scene.show_menu()
		scene.show_shop()
		await snap_game(game_view,"shop-%d.png" % id)
	print("ORIGINAL MOBILES GPU: 1920x1080 / 60Hz clock / 210frames / pause120..149")
	scene.queue_free()
	await process_frame
	quit()

func snap_game(view: SubViewport, name: String) -> void:
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png(OUT+name)
