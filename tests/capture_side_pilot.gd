extends SceneTree
## GPU captures of the assembled pilot/mobile, in both directions and on slopes.
class Preview extends Node2D:
	var elapsed := 0.0
	var sprites := []
	var age := 0.0
	var animated := false
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1600, 1080), Color("172b40"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(40, 55), "Gunbound Recomp 0.7.0 — piloto em perfil / perna distante oculta", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		for row in range(2):
			draw_string(font, Vector2(40, 120 + row * 500), "BIGFOOT" if row == 0 else "MAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("76c6ff"))
			for column in range(3):
				var pos := Vector2(290 + column * 520, 390 + row * 500)
				var facing := -1 if column == 1 else 1
				var rotation := deg_to_rad(-30.0 if column == 2 else 0.0)
				var pose: String = "idle" if not animated else ["idle", "moving", "charging", "recoil", "hurt", "destroyed"][mini(5, int(age))]
				var time := fmod(age, 1.0) if animated else 0.0
				var frame: int = sprites[row].frame_index(pose, time, 2, false)
				sprites[row].draw(self, pos, 210, facing, rotation, frame, Color.WHITE, pose, time, 2, false, age * 4 if pose == "moving" else 0)
				draw_string(font, pos + Vector2(-150, 130), ["Perfil / direita", "Perfil / esquerda", "Encosta −30°"][column], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
var preview
func _initialize() -> void:
	call_deferred("run")
func snap(path: String) -> void:
	preview.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
func run() -> void:
	root.size = Vector2i(1600, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/occlusion"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/side-pilot-frames"))
	preview = Preview.new()
	preview.sprites = [load("res://scripts/bigfoot_sprite.gd").new(), load("res://scripts/mage_sprite.gd").new()]
	root.add_child(preview)
	await snap("res://docs/occlusion/pilot-mobiles.png")
	preview.animated = true
	for tick in range(144):
		preview.age = tick / 24.0
		await snap("res://.tools/side-pilot-frames/frame%04d.png" % tick)
	preview.queue_free()
	await process_frame
	print("SIDE PILOT GPU CAPTURES SAVED: 144 frames + both mobiles / directions / slope")
	quit()
