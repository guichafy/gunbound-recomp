extends SceneTree
## GPU composition QA, active catalog, isolated in-memory profile.
const Game = preload("res://scripts/game.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const OUT := "res://docs/lightning-review/poses/"
const FRAMES := "res://.tools/lightning-review/pose-frames/"
var sprite
var equipment: Dictionary
var clock := 0.0
var board
var target: SubViewport

class Board extends Node2D:
	var host
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("182a3a"))
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(40,45),"Lightning | EPA e montagem nativos | avatar oculto na morte | escala 2x",HORIZONTAL_ALIGNMENT_LEFT,-1,28)
		for row in 4:
			var facing := 1 if row%2 == 0 else -1
			var y := 225.0+row*245
			draw_string(font,Vector2(35,y-115),("PADRÃO" if row<2 else "EQUIPADO HD")+ (" / direita" if facing==1 else " / esquerda"),HORIZONTAL_ALIGNMENT_LEFT,-1,22)
			for column in 6:
				var pose: String = ["idle","charging","recoil","hurt","using_item","destroyed"][column]
				var at := Vector2(150+310*column,y)
				var rotation := deg_to_rad(15) if column == 4 else 0.0
				var context: Dictionary = {"equipment":host.equipment,"age":host.clock} if row>=2 else {}
				var frame: int = host.sprite.frame_index(pose,host.clock,1,false)
				host.sprite.draw(self,Pose.new(at,120,facing,{"frame":frame,"age":host.clock,"pose":pose,"rotation":rotation,"weapon":1,"avatar_context":context}))
				draw_line(at+Vector2(0,-110),at+Vector2(0,40),Color(1,1,1,.25),1)
				draw_string(font,at+Vector2(-70,75),pose,HORIZONTAL_ALIGNMENT_LEFT,-1,20)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	sprite = Game.build_sprites()[8]
	var profile=load("res://scripts/profile.gd").new("res://.tools/lightning-review/unused-profile.json")
	profile.equipped["0"]["0"]="xfs:0:0:71"
	equipment=profile.equipped_set()
	target = SubViewport.new()
	target.size = Vector2i(1920,1080)
	target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(target)
	board = Board.new()
	board.host = self
	target.add_child(board)
	var paused: Image
	var dead_identical:=true
	for frame in 150:
		if frame<60 or frame>=90:
			clock += 1.0/60.0
		board.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		var picture := target.get_texture().get_image()
		var dead_a:=picture.get_region(Rect2i(1570,125,260,180))
		var dead_b:=picture.get_region(Rect2i(1570,615,260,180))
		dead_identical=dead_identical and dead_a.get_data()==dead_b.get_data()
		picture.save_png(FRAMES+"frame%04d.png"%frame)
		if frame==0:
			picture.save_png(OUT+"arena-directions.png")
		if frame==60:
			paused = picture
		elif frame>60 and frame<90 and paused.get_data()!=picture.get_data():
			push_error("Lightning poses changed during pause")
			quit(1)
			return
		if frame==120:
			picture.save_png(OUT+"moving.png")
	print("LIGHTNING POSES GPU: 1920x1080;6poses;2shot_directions;legacy/HD;150frames;pause60..89 identical")
	var manifest:=FileAccess.open(OUT+"poses-qa.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"resolution":[1920,1080],"frames":150,"pause_frames":[60,89],"pause30_identical":true,"poses":["idle","charging","recoil","hurt","using_item","destroyed"],"directions":[1,-1],"avatars":["default","Great Devil HD"],"dead_avatar_hidden_pixels":dead_identical},"\t")+"\n")
	assert(dead_identical)
	quit()
