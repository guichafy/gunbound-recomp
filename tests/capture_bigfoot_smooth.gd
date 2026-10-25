extends Node
## ADR-104 GPU evidence: native Bigfoot sheets (top) and the4x finish (bottom)
## with the same SpritePose, both facings, slopes, shots, impacts and a pause.
const Pose = preload("res://scripts/sprite_pose.gd")
const Classic = preload("res://scripts/classic_sprite.gd")
const OUT := "res://docs/bigfoot-smooth-4x/"
const FRAMES := "res://.tools/bigfoot-smooth/frames/"
var native_sprite
var smooth_sprite
var board
var target: SubViewport
var clock := 0.0
var demos: Array = []

class Board extends Node2D:
	var host
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("182a3a"))
		draw_string(font,Vector2(35,45),"Bigfoot | folhas originais do cliente | acabamento BICUBIC 4× por quadro (ADR-104)",HORIZONTAL_ALIGNMENT_LEFT,-1,27)
		draw_string(font,Vector2(35,80),"Mesma pose, pivô, contato e avatar; só a densidade da textura muda. Alpha/silhueta nativos.",HORIZONTAL_ALIGNMENT_LEFT,-1,20)
		for row in 2:
			var sprite = host.native_sprite if row == 0 else host.smooth_sprite
			var base_y := 290.0+row*420
			draw_string(font,Vector2(35,base_y-160),"NATIVO (1×)" if row == 0 else "SUAVIZADO (4×)",HORIZONTAL_ALIGNMENT_LEFT,-1,24)
			for column in 6:
				var pose: String = ["idle","moving","charging","recoil","hurt","idle"][column]
				var facing := 1 if column%2 == 0 else -1
				var position := Vector2(150+column*310,base_y)
				var frame: int = sprite.frame_index(pose,host.clock,1,column == 5)
				var request = Pose.new(position,180.0,facing,{"rotation":deg_to_rad(-15 if column == 1 else 15 if column == 4 else 0),"frame":frame,"pose":pose,"age":host.clock,"weapon":1,"avatar_context":{}})
				sprite.draw(self,request)
				draw_string(font,position+Vector2(-90,95),pose+(" low" if column == 5 else "")+" "+("→" if facing == 1 else "←"),HORIZONTAL_ALIGNMENT_LEFT,-1,20)
			for weapon in 3:
				var position := Vector2(200+weapon*610,base_y+175)
				var demo = host.demos[row*3+weapon]
				demo.position = position
				demo.sprite = sprite
				demo.shot = {"pos":Vector2.ZERO,"hit_pos":Vector2.ZERO,"velocity":Vector2(200 if weapon%2 == 0 else -200,-20),"age":host.clock,"trail":[],"launched":true}
				demo.weapon = weapon
				demo.clock = host.clock
				demo.queue_redraw()

class Demo extends Node2D:
	var sprite
	var weapon := 0
	var clock := 0.0
	var shot: Dictionary = {}
	func _draw() -> void:
		if sprite == null:
			return
		sprite.draw_projectile(self,shot,weapon)
		sprite.draw_effect(self,{"pos":Vector2(60,0),"weapon":weapon,"age":fmod(clock,1.2)})

func _ready() -> void:
	call_deferred("run")

func native_bigfoot():
	var sprite = Classic.new()
	sprite.setup("bigfoot")
	# Drop the validated4x sheets: the same renderer at density 1.
	sprite.texture = load("res://assets/openbound/bigfoot/original/CharacterSpritesheet.png")
	sprite.paint_texture = sprite.pixel_texture(sprite.texture)
	sprite.density = 1.0
	sprite.sheet_density = {}
	sprite.placed = {}
	return sprite

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	native_sprite = native_bigfoot()
	smooth_sprite = load("res://scripts/game.gd").build_sprites()[2]
	target = SubViewport.new()
	target.size = Vector2i(1920,1080)
	target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(target)
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
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var picture := target.get_texture().get_image()
		picture.save_png(FRAMES+"frame%04d.png"%frame)
		if frame == 60:
			picture.save_png(OUT+"composition.png")
	print("BIGFOOT SMOOTH GPU: 1920x1080 / 60Hz clock / 210frames / pause120..149 / density=", smooth_sprite.density)
	get_tree().quit()
