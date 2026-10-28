extends SceneTree
## Grub QA (issue #8): T1 / T2 / SS in both directions, ricochet, impact, pause and
## resume. 1920x1080, 60 Hz presentation over the 20 Hz native model.
const Match = preload("res://scripts/match.gd")
const Sprite = preload("res://scripts/grub_sprite.gd")
const OUT := "res://docs/grub/"
const FRAMES := "res://.tools/grub/gpu-frames/"
const PAUSE_FROM := 150
const PAUSE_TO := 180
const FLOOR_Y := 700.0
var models: Array = []
var impacts: Array = []
var centers: Array = []
var panels: Array = []
var sprite
var board
var capture_view: SubViewport
var elapsed := 0.0
var capture_paused := false

class Board extends Node2D:
	var host
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1920, 1080), Color("142331"))
		draw_string(font, Vector2(30, 34), "Grub (ID 13 / type 12) %s | T1 · T2 (4 corpos, ricochete) · SS (ricochete, dano por quadro) | direita e esquerda" % ProjectSettings.get_setting("application/config/version"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		draw_string(font, Vector2(30, 58), "t=%.2fs  %s" % [host.elapsed, "PAUSA" if host.capture_paused else "VOO"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20)

class ShotPanel extends Node2D:
	var host
	var index := 0
	var font := ThemeDB.fallback_font
	func _draw() -> void:
		var model = host.models[index]
		draw_rect(Rect2(0, 0, 960, 340), Color("142331"))
		if not model.projectiles.is_empty():
			var lead: Dictionary = model.projectiles[0]
			host.centers[index] = Vector2(lead.previous_hit_pos).lerp(lead.hit_pos, clampf(float(model.accumulator) / 0.05, 0, 1))
		var offset: Vector2 = Vector2(480, 170) - host.centers[index]
		var weapon := int(index / 2)
		var blend := clampf(float(model.accumulator) / 0.05, 0, 1)
		host.sprite.begin_projectiles(self)
		for source in model.projectiles:
			var shot: Dictionary = source.duplicate()
			shot.draw_fraction = blend
			shot.hit_pos = Vector2(shot.previous_hit_pos).lerp(shot.hit_pos, blend)
			shot.pos = Vector2(shot.previous_draw_pos).lerp(shot.pos, blend)
			host.sprite.draw_projectile(self, shot, weapon, offset)
		for effect in host.impacts[index]:
			host.sprite.draw_effect(self, effect, offset)
		draw_line(Vector2(0, FLOOR_Y) + offset, Vector2(960, FLOOR_Y) + offset - Vector2(0, 0), Color("345061"), 1)
		draw_rect(Rect2(Vector2(-4000, FLOOR_Y) + offset, Vector2(8000, 400)), Color(0.12, 0.2, 0.26, 0.9))
		draw_line(Vector2(20, 336), Vector2(940, 336), Color("345061"), 1)
		draw_string(font, Vector2(30, 30), "%s | %s | %d projéteis" % [["T1", "T2", "SS"][weapon], "direita" if index % 2 == 0 else "esquerda", model.projectiles.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		if not model.projectiles.is_empty() and model.projectiles[0].has("g_ctr"):
			var shot: Dictionary = model.projectiles[0]
			draw_string(font, Vector2(30, 322), "contador=%d  v=(%d,%d)" % [shot.g_ctr, shot.fp_velocity.x, shot.fp_velocity.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 18)

func _initialize() -> void:
	call_deferred("run")

func floor_model(facing: int):
	var model = Match.new()
	model.start(13, 1, 42, "", "original")
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.wind = Vector2.ZERO
	model.terrain.WIDTH = 2000
	model.terrain.HEIGHT = 1000
	model.terrain.cells.resize(model.terrain.WIDTH * model.terrain.HEIGHT)
	model.terrain.cells.fill(0)
	# The 2000-wide fixture has no raster to repaint: carve_native only edits the masks.
	model.terrain.image = null
	model.terrain.texture = null
	model.terrain.visual = null
	model.terrain.visual_texture = null
	model.terrain.native_cells = PackedByteArray()
	model.terrain.enable_native()
	var width: int = model.terrain.WIDTH * model.terrain.SCALE
	for y in range(int(FLOOR_Y), model.terrain.HEIGHT * model.terrain.SCALE):
		for x in width:
			model.terrain.native_cells[y * width + x] = 1
	for y in range(int(FLOOR_Y / 2), model.terrain.HEIGHT):
		for x in model.terrain.WIDTH:
			model.terrain.cells[y * model.terrain.WIDTH + x] = 1
	model.actors[0].pos = Vector2(400 if facing == 1 else 3500, FLOOR_Y - 10)
	model.actors[0].facing = facing
	model.actors[1].pos = Vector2(3900, 1900)
	return model

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES))
	sprite = Sprite.new()
	sprite.setup("grub")
	capture_view = SubViewport.new()
	capture_view.size = Vector2i(1920, 1080)
	capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_view)
	board = Board.new()
	board.host = self
	capture_view.add_child(board)
	for weapon in 3:
		for facing in [1, -1]:
			var model = floor_model(facing)
			model.fire(45, 35, weapon)
			model.events.clear()
			models.append(model)
			impacts.append([])
			centers.append(Vector2(model.actors[0].pos))
			var panel_view := SubViewport.new()
			panel_view.size = Vector2i(960, 340)
			panel_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			capture_view.add_child(panel_view)
			var pane := ShotPanel.new()
			pane.host = self
			pane.index = panels.size()
			panel_view.add_child(pane)
			panels.append(pane)
			var display := TextureRect.new()
			display.texture = panel_view.get_texture()
			display.position = Vector2((pane.index % 2) * 960, 70 + int(pane.index / 2) * 340)
			display.size = Vector2(960, 340)
			capture_view.add_child(display)
	var reference := PackedByteArray()
	var paused_equal := true
	var ricochets := 0
	for frame in 270:
		capture_paused = frame >= PAUSE_FROM and frame < PAUSE_TO
		if not capture_paused:
			elapsed += 1.0 / 60
			for index in models.size():
				models[index].tick(1.0 / 60)
				for effect in impacts[index]:
					effect.age += 1.0 / 60
				for event in models[index].events:
					if event.type == "explosion":
						impacts[index].append({"pos": event.position, "weapon": event.weapon, "child": event.get("child", false), "ss_state": event.get("ss_state", "normal"), "age": 0.0, "angle": event.angle})
					elif event.type == "ricochet":
						ricochets += 1
				models[index].events.clear()
		board.queue_redraw()
		for pane in panels:
			pane.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := capture_view.get_texture().get_image()
		picture.save_png(FRAMES + "%03d.png" % frame)
		if frame == PAUSE_FROM:
			reference = picture.get_data()
		elif frame > PAUSE_FROM and frame < PAUSE_TO:
			paused_equal = paused_equal and picture.get_data() == reference
		if frame in [30, 70, 110, 149, 179, 209, 249]:
			picture.save_png(OUT + "time-%03d.png" % frame)
	print("GRUB GPU CAPTURE:270 frames,1920x1080;pause %d..%d identical=%s;ricochets=%d" % [PAUSE_FROM, PAUSE_TO - 1, str(paused_equal), ricochets])
	quit()
