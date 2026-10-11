extends SceneTree
## Real GPU comparison and slope/pose coverage, without writing the user profile.
class Preview extends Node2D:
	var elapsed := 0.0
	var sprites := []
	var animated := false
	var age := 0.0
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1600, 1080), Color("172b40"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(40, 55), "Gunbound Recomp 0.7.0 — composição piloto / mobile", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		for row in range(2):
			var y := 340.0 + row * 510.0
			draw_string(font, Vector2(40, y - 220), "BIGFOOT" if row == 0 else "MAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("76c6ff"))
			for column in range(4):
				var pos := Vector2(210 + column * 390, y)
				var original := column == 0
				var facing := -1 if column == 3 else 1
				var slope: float = [-0.0, 0.0, -30.0, 30.0][column]
				var pose := "idle"
				var time := 0.0
				if animated and not original:
					pose = ["idle", "moving", "charging", "recoil", "hurt"][mini(4, int(age))]
					time = fmod(age, 1.0)
				var frame: int = sprites[row].frame_index(pose, time, 2, false)
				var texture = sprites[row].hd_rig.sheet.texture
				if original:
					sprites[row].hd_rig.sheet.texture = null
				sprites[row].draw(self, pos, 150, facing, deg_to_rad(slope), frame, Color.WHITE, pose, time, 2, false, age * 4 if pose == "moving" else 0)
				sprites[row].hd_rig.sheet.texture = texture
				draw_string(font, pos + Vector2(-150, 140), ["Original — referência", "HD — composição corrigida", "HD — encosta −30°", "HD — virado / +30°"][column], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/composition"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/composition-frames"))
	preview = Preview.new()
	preview.sprites = [load("res://scripts/bigfoot_sprite.gd").new(), load("res://scripts/mage_sprite.gd").new()]
	root.add_child(preview)
	await snap("res://docs/composition/comparison.png")
	preview.animated = true
	for tick in range(120):
		preview.age = tick / 24.0
		await snap("res://.tools/composition-frames/frame%04d.png" % tick)
	preview.queue_free()
	await process_frame
	print("COMPOSITION GPU CAPTURES SAVED: comparison +120frames")
	quit()
