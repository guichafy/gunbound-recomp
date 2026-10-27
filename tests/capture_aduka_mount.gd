extends SceneTree
## GPU composition QA, active catalog, isolated in-memory profile.
const Game = preload("res://scripts/game.gd")
const Pose = preload("res://scripts/sprite_pose.gd")
const OUT := "res://docs/aduka-center/"
const FRAMES := "res://.tools/aduka-center/frames/"
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
		draw_string(font,Vector2(40,45),"Aduka | piloto centralizado +8px | orientação aprovada | escala 2x",HORIZONTAL_ALIGNMENT_LEFT,-1,28)
		for row in 4:
			var facing := 1 if row%2 == 0 else -1
			var y := 225.0+row*245
			draw_string(font,Vector2(35,y-115),("PADRÃO" if row<2 else "EQUIPADO HD")+ (" / TIRO direita / PILOTO esquerda" if facing==1 else " / TIRO esquerda / PILOTO direita (referência A)"),HORIZONTAL_ALIGNMENT_LEFT,-1,22)
			for column in 6:
				var pose: String = ["idle","moving","charging","recoil","hurt","using_item"][column]
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
	sprite = Game.build_sprites()[16]
	equipment = load("res://scripts/profile.gd").new("res://.tools/aduka-rider/unused-profile.json").equipped_set()
	target = SubViewport.new()
	target.size = Vector2i(1920,1080)
	target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(target)
	board = Board.new()
	board.host = self
	target.add_child(board)
	var paused: Image
	for frame in 150:
		if frame<60 or frame>=90:
			clock += 1.0/60.0
		board.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := target.get_texture().get_image()
		picture.save_png(FRAMES+"frame%04d.png"%frame)
		if frame==0:
			picture.save_png(OUT+"arena-directions.png")
		if frame==60:
			paused = picture
		elif frame>60 and frame<90 and paused.get_data()!=picture.get_data():
			push_error("Aduka mount changed during pause")
			quit(1)
			return
		if frame==120:
			picture.save_png(OUT+"moving.png")
	print("ADUKA CENTER GPU: 1920x1080;6poses;2shot_directions;legacy/HD;150frames;pause60..89 identical")
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/aduka-rider/room-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.scale = Vector2.ONE*1.35
	scene.position = Vector2(96,0)
	scene.show_menu()
	scene.select_vehicle(16)
	scene.select_cpu_vehicle(16)
	scene.elapsed = 0
	var mobile = scene.sprite_for(16)
	var correction: Vector2 = mobile.rider_adjust
	mobile.rider_adjust = Vector2.ZERO
	await snap_room(scene,"before-default.png")
	mobile.rider_adjust = correction
	await snap_room(scene,"room-default.png")
	# Reference character head; isolated fixture, never the user's real profile.
	scene.profile.equipped["0"]["0"] = "xfs:0:0:71"
	mobile.rider_adjust = Vector2.ZERO
	var before := await snap_room(scene,"before-great-devil.png")
	mobile.rider_adjust = correction
	var after := await snap_room(scene,"room-great-devil.png")
	var crop := Rect2i(310,140,225,200)
	after.get_region(crop).save_png(OUT+"side-a.png")
	var comparison := Image.create(450,200,false,Image.FORMAT_RGBA8)
	comparison.blit_rect(before,crop,Vector2i.ZERO)
	comparison.blit_rect(after,crop,Vector2i(225,0))
	comparison.save_png(OUT+"before-after.png")
	print("ADUKA CENTER ROOM GPU: actual scene;A/B;before/after;default/GreatDevil;orientation preserved")
	scene.free()
	quit()

func snap_room(scene, name: String) -> Image:
	scene.queue_redraw()
	scene.menu.figures.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png(OUT+name)
	return picture
