extends SceneTree
## Source rendering evidence only; the native client is not executed.
const Mobiles = preload("res://scripts/mobiles.gd")
const SpritePose = preload("res://scripts/sprite_pose.gd")
var scene
var canvas
var capture_view: SubViewport

class Board extends Node2D:
	var host
	var mode := 0
	var font: Font = ThemeDB.fallback_font
	func text_at(point: Vector2, text: String, size: int = 23, color: Color = Color.WHITE) -> void:
		draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
	func _draw() -> void:
		draw_rect(Rect2(0,0,1920,1080),Color("152331"))
		if mode == 0:
			text_at(Vector2(45,50),"Composição original: Turtle × Armor | estados Boomer SS",32)
			text_at(Vector2(45,88),"Mesmo corpo PNG na fonte; Turtle S1/S2 substitui a cabeça pela faixa WaterEffect.",22)
			for entry in [[4,0,Vector2(70,255),"Armor S1"],[12,0,Vector2(700,255),"Turtle S1"],[12,1,Vector2(1330,255),"Turtle S2"]]:
				text_at(entry[2]-Vector2(0,95),entry[3],26)
				var sprite = host.sprite_for(entry[0])
				sprite.draw(self,SpritePose.new(entry[2],100.0,1))
				for component in (2 if entry[1] == 1 else 1):
					var trail: Array = []
					for i in 16:
						trail.append(entry[2]+Vector2(160+i*20,-35+(sin(i*.45+component*PI)*20 if entry[1] == 1 else 0)))
					var shell := {"launched":true,"pos":trail[-1],"hit_pos":trail[-1],"velocity":Vector2(400,0),"age":0.6,"flight_ticks":12,"trail":trail}
					sprite.draw_projectile(self,shell,entry[1])
				var impact := {"pos":entry[2]+Vector2(470,115),"weapon":entry[1],"age":0.2,"angle":0.0}
				sprite.draw_effect(self,impact)
			text_at(Vector2(45,560),"Boomer SS: mesmo age=99s; o estado vem do modelo, nunca da idade visual.",23)
			for i in 3:
				var state: String = ["normal","change","cnormal"][i]
				var pos := Vector2(300+i*620,715)
				text_at(pos-Vector2(120,70),state+" / tick0",27)
				host.sprite_for(6).draw_projectile(self,{"launched":true,"pos":pos,"hit_pos":pos,"velocity":Vector2(300,0),"age":99.0,"ss_state":state,"ss_state_tick":0},2)
			text_at(Vector2(45,880),"Registro de contato importado: os 13 mobiles clássicos usam metadados; PCK não precisa do PNG cru.",22)
			for i in 13:
				var id := i+4
				var sprite = host.sprite_for(id)
				var pos := Vector2(90+i*143,1000)
				sprite.draw(self,SpritePose.new(pos,72.0,1))
				draw_line(pos+Vector2(-40,1),pos+Vector2(40,1),Color("4dc6b1"),1)
		else:
			text_at(Vector2(40,48),"MainAction + EPA | 20 Hz | um marcador / som por grupo de spawn",30)
			for weapon in 3:
				text_at(Vector2(320+weapon*530,90),["S1","S2","SS"][weapon],26)
			for id in range(1,17):
				var y := 137.0+(id-1)*55
				text_at(Vector2(35,y),Mobiles.definition(id).name,22)
				for weapon in 3:
					var row := Mobiles.ShotTiming.shot(id,weapon)
					var x := 290.0+weapon*530
					draw_rect(Rect2(x,y-20,int(row.pose_ticks)*15,23),Color("2b596e"))
					for group in row.spawn_ticks.size():
						var tick := int(row.spawn_ticks[group])
						draw_line(Vector2(x+tick*15,y-28),Vector2(x+tick*15,y+6),Color("ffca75"),3)
						text_at(Vector2(x+tick*15+3,y+22),str(tick)+"×"+str(int(row.components_per_spawn[group])),13,Color("ffca75"))
			text_at(Vector2(40,1060),"Barra azul = duração EPA; marcador amarelo = tick × componentes. Aduka SS emite no tick10, mesmo no fim da pose.",20)

func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/classic-capture-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.hide()
	scene.sound.muted = true
	canvas = Board.new()
	canvas.host = scene
	# A fixed GPU render target also works when the editor embeds the game
	# in a larger Retina window and overrides the root Window dimensions.
	capture_view = SubViewport.new()
	capture_view.size = Vector2i(1920,1080)
	capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_view)
	capture_view.add_child(canvas)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/classic-shots"))
	for mode in 2:
		canvas.mode = mode
		canvas.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://docs/classic-shots/" + ("composition.png" if mode == 0 else "timeline.png")
		capture_view.get_texture().get_image().save_png(path)
	print("CLASSIC CAPTURE: composition + timeline 1920x1080")
	quit()
