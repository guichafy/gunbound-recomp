extends SceneTree
## GPU sequence and storyboard of the actual articulated renderer.
class Preview extends Node2D:
	var elapsed := 0.0
	var sprites := []
	var phase := "idle"
	var age := 0.0
	var weapon := 0
	var wheel := 0.0
	var storyboard := true
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1920, 1080), Color("15263b"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(40, 55), "Brisa de Aço — animações HD consistentes 0.6.1", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		var poses := ["idle", "moving", "charging", "recoil", "hurt", "destroyed"]
		var labels := ["Repouso", "Movimento", "Carga SS", "Disparo SS", "Dano", "Destruição"]
		for row in range(2):
			draw_string(font, Vector2(40, 125 + row * 450), "BIGFOOT" if row == 0 else "MAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("76c6ff"))
			for column in range(6 if storyboard else 1):
				var center := Vector2(175 + column * 312 if storyboard else 960, 390 + row * 450)
				draw_line(center + Vector2(-90, 24), center + Vector2(90, 24), Color("486880"), 2)
				var pose: String = poses[column] if storyboard else phase
				var time := 0.5 if storyboard else age
				var frame: int = sprites[row].frame_index(pose, time, 2, false)
				sprites[row].draw(self, center, 120, 1, 0, frame, Color.WHITE, pose, time, 2 if storyboard else weapon, false, wheel)
				draw_string(font, center + Vector2(-80, 95), labels[column] if storyboard else phase, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
var preview
func _initialize() -> void:
	call_deferred("run")
func snap(path: String) -> void:
	preview.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	assert(error == OK)
func run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/animation-frames"))
	preview = Preview.new()
	preview.sprites = [load("res://scripts/bigfoot_sprite.gd").new(), load("res://scripts/mage_sprite.gd").new()]
	root.add_child(preview)
	await snap("res://docs/animation/storyboard.png")
	preview.storyboard = false
	var poses := ["idle", "moving", "charging", "recoil", "hurt", "destroyed"]
	var count := 0
	for pose in poses:
		preview.phase = pose
		for tick in range(36):
			preview.age = tick / 24.0
			preview.elapsed = count / 24.0
			preview.weapon = 2
			if pose == "moving":
				preview.wheel += 0.16
			await snap("res://.tools/animation-frames/frame%04d.png" % count)
			count += 1
	preview.queue_free()
	await process_frame
	print("ANIMATION GPU CAPTURES SAVED: ", count, " frames and storyboard")
	quit()
