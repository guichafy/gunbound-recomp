extends SceneTree
class ProjectileDemo extends Node2D:
	var mobile
	var kind := "bigfoot"
	var weapon := 0
	var age := 0.0
	var impact := false
	var elapsed := 0.0
	func _draw() -> void:
		if impact:
			var duration: float = mobile.effect_capacity(weapon) / 30.0
			mobile.draw_effect(self, {"pos": Vector2.ZERO, "age": fmod(age, duration + 0.15), "weapon": weapon})
		else:
			var trail := []
			for index in range(18):
				trail.append(Vector2(-40 + index * 2, sin(index * 0.35 + age * 7.0) * 4 if kind == "mage" and weapon == 1 else 0))
			var shot := {"pos": Vector2.ZERO, "hit_pos": Vector2.ZERO, "age": age, "velocity": Vector2(100, 0), "trail": trail, "phase": 0.0, "launched": true}
			mobile.draw_projectile(self, shot, weapon)
			if kind == "mage" and weapon == 1:
				shot.phase = PI
				shot.hit_pos = Vector2(0, -9)
				for index in range(trail.size()):
					trail[index] = Vector2(trail[index].x, -trail[index].y - 9)
				mobile.draw_projectile(self, shot, weapon)
class Gallery extends Node2D:
	var elapsed := 0.0
	var mobiles := []
	var pilots := false
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1920, 1080), Color("172b40"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(45, 60), "Brisa de Aço 0.6.2 — " + ("piloto coeso em apoio inclinado" if pilots else "tiros e impactos contínuos"), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
		for row in range(2):
			draw_string(font, Vector2(45, 120 + row * 450), "BIGFOOT" if row == 0 else "MAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("76c6ff"))
			for column in range(4 if pilots else 3):
				var center := Vector2(250 + column * 470 if pilots else 320 + column * 620, 390 + row * 450)
				if pilots:
					var slope: float = [-30.0, 0.0, 30.0, -15.0][column]
					var facing := -1 if column == 3 else 1
					var pose := "recoil" if column == 3 else "idle"
					var frame: int = mobiles[row].frame_index(pose, 0.15, 2, false)
					mobiles[row].draw(self, center, 150, facing, deg_to_rad(slope), frame, Color.WHITE, pose, 0.15, 2)
					draw_string(font, center + Vector2(-100, 120), ("Recuo / esquerda" if column == 3 else "Apoio %+.0f°" % slope), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
				else:
					draw_string(font, center + Vector2(-230, 150), ["T1", "T2", "SS"][column] + " — voo (4×) e impacto", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
var gallery
var demos := []
func _initialize() -> void:
	call_deferred("run")
func snap(path: String) -> void:
	gallery.queue_redraw()
	for demo in demos:
		demo.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
func run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools/pilot-shots-frames"))
	gallery = Gallery.new()
	gallery.mobiles = [load("res://scripts/bigfoot_sprite.gd").new(), load("res://scripts/mage_sprite.gd").new()]
	root.add_child(gallery)
	gallery.pilots = true
	await snap("res://docs/projectiles/pilot-poses.png")
	gallery.pilots = false
	for row in range(2):
		for weapon in range(3):
			for impact in [false, true]:
				var demo := ProjectileDemo.new()
				demo.mobile = gallery.mobiles[row]
				demo.kind = "bigfoot" if row == 0 else "mage"
				demo.weapon = weapon
				demo.impact = impact
				demo.position = Vector2((480 if impact else 200) + weapon * 620, 380 + row * 450)
				demo.scale = Vector2.ONE * (1.15 if impact else 4.0)
				gallery.add_child(demo)
				demos.append(demo)
	for demo in demos:
		demo.age = 0.18
	await snap("res://docs/projectiles/shots-storyboard.png")
	for tick in range(72):
		for demo in demos:
			demo.age = tick / 24.0
		await snap("res://.tools/pilot-shots-frames/frame%04d.png" % tick)
	gallery.queue_free()
	await process_frame
	print("PILOT/SHOTS GPU CAPTURES SAVED: 72 frames + two storyboards")
	quit()
