extends "res://scripts/mobile_sprite.gd"
## Original client atlas (tankN.img / .epa) for a mobile without an HD rig.
## scripts/import_classic_mobiles.py writes frames.json. Pose lists are the
## .epa frame indices, the same state names Nak already maps onto the flipbook.

const SHOT_FPS := 20.0
var meta: Dictionary = {}
var mobile_kind := ""
var placed: Dictionary = {}
var bullets: Array = []
var lights: Array = []
var rear := false

func setup(kind: String) -> void:
	mobile_kind = kind
	var folder := "res://assets/openbound/" + kind
	meta = JSON.parse_string(FileAccess.get_file_as_string(folder + "/frames.json"))
	var cell := Vector2(meta.cell[0], meta.cell[1])
	var pivot := Vector2(meta.origin[0], meta.origin[1])
	var idle: Array = meta.poses.get("idle", [0])
	# Battle draws every mobile at width 60. A shared hull keeps one source
	# pixel at one screen pixel, so a narrow body stays narrower than Trico.
	# The idle frame's opaque bottom is the ground contact.
	var feet := _opaque_feet(folder + "/CharacterSpritesheet.png", cell, int(meta.columns), int(idle[0]), pivot)
	configure(folder, cell, pivot, {
		"idle": [0, 0, 19.0, true]
	}, 60.0, pivot.y + feet)
	load_sounds(folder)
	for name in ["Bullet1", "Bullet2", "Bullet3"]:
		bullets.append(_optional(folder, name))
		lights.append(_optional(folder, name + "Light"))

## Pixels from the hotspot down to the lowest opaque pixel of the idle frame.
func _opaque_feet(path: String, cell: Vector2, columns: int, frame: int, pivot: Vector2) -> float:
	var image := Image.new()
	if image.load(path) != OK:
		return 0.0
	var width := int(cell.x)
	var height := int(cell.y)
	var origin := Vector2i((frame % columns) * width, int(frame / columns) * height)
	var bottom := int(pivot.y)
	for y in height:
		for x in width:
			if image.get_pixel(origin.x + x, origin.y + y).a > 8.0 / 255.0:
				bottom = maxi(bottom, y)
	return float(bottom - int(pivot.y))

func _optional(folder: String, name: String) -> CanvasTexture:
	var path := "%s/%s.png" % [folder, name]
	if not ResourceLoader.exists(path):
		return null
	return pixel_texture(load(path))

func load_sounds(folder: String) -> void:
	for key in SHOT_KEYS:
		var shot := "%s/Shoot%s.mp3" % [folder, key]
		var blast := "%s/Blast%s.mp3" % [folder, key]
		shoot_sounds.append(load(shot) if ResourceLoader.exists(shot) else AudioStreamWAV.new())
		blast_sounds.append(load(blast) if ResourceLoader.exists(blast) else AudioStreamWAV.new())
	for number in range(1, 4):
		var flame := "%s/Flame%d.png" % [folder, number]
		effects.append(pixel_texture(load(flame)) if ResourceLoader.exists(flame) else pixel_texture(texture))

func frame_index(pose: String, age: float, weapon: int, low_health: bool) -> int:
	var key := pose
	if pose in ["charging", "recoil"]:
		key += "_" + str(clampi(weapon, 0, 2))
	elif low_health and pose in ["idle", "moving"]:
		key += "_low"
	var frames: Array = meta.poses.get(key, meta.poses.get("idle", [0]))
	if frames.is_empty():
		return 0
	var looping := key in ["idle", "idle_low", "moving", "moving_low", "charging_0", "charging_1", "charging_2", "unable"]
	var step := maxi(0, int(floor(age * 19.0)))
	return int(frames[step % frames.size() if looping else mini(step, frames.size() - 1)])

func draw(view: Node2D, request) -> void:
	super.draw(view, request.mirrored() if rear else request)

func sheet(name: String) -> Dictionary:
	return meta.sheets.get(name, {})

## Boomer SS (bullet6p) plays normal, then change, then cnormal. Each .epa
## frame is one tick at the shot rate. Other sheets stay on "normal".
static func bullet_state(info: Dictionary, age: float) -> Dictionary:
	var states: Dictionary = info.get("states", {})
	var normal: Array = states.get("normal", [])
	if not states.has("cnormal") or normal.is_empty():
		return {"frames": normal, "age": age}
	var change: Array = states.get("change", [])
	var opened: Array = states.get("cnormal", [])
	var normal_end := float(normal.size()) / SHOT_FPS
	var change_end := normal_end + float(change.size()) / SHOT_FPS
	if age < normal_end:
		return {"frames": normal, "age": age}
	if age < change_end:
		return {"frames": change, "age": age - normal_end}
	return {"frames": opened, "age": age - change_end}

func cell_frame(name: String, index: int) -> Array:
	var info := sheet(name)
	if info.is_empty():
		return [Rect2(), Rect2()]
	var cell := Vector2(info.cell[0], info.cell[1])
	var columns := int(info.columns)
	return [Rect2(Vector2(index % columns, int(index / columns)) * cell, cell), Rect2(-Vector2(info.origin[0], info.origin[1]), cell)]

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	if not projectile.get("launched", true) or weapon < 0 or weapon >= bullets.size() or bullets[weapon] == null:
		return
	var name := "Bullet%d.png" % (weapon + 1)
	var info := sheet(name)
	if info.is_empty():
		return
	var played := bullet_state(info, float(projectile.age))
	var frames: Array = played.frames
	var step := int(played.age * SHOT_FPS)
	var index := int(frames[step % frames.size()]) if not frames.is_empty() else step % int(info.frames)
	var position: Vector2 = projectile.get("hit_pos", projectile.pos) + offset
	view.draw_set_transform(position, Vector2(projectile.velocity).angle())
	if lights[weapon] != null:
		var light := cell_frame(name.replace(".png", "Light.png"), index)
		view.draw_texture_rect_region(lights[weapon], light[1], light[0], Color(1, 1, 1, 0.75))
	var body := cell_frame(name, index)
	view.draw_texture_rect_region(bullets[weapon], body[1], body[0])
	view.draw_set_transform(Vector2.ZERO)
	# Dragon S1/S2 (bullet14, FUN_00436fd0) scatter a spark each step,
	# offset by -4 + rand%9 on both axes.
	if mobile_kind == "dragon" and weapon < 2:
		var trail: Array = projectile.get("trail", [])
		for point_index in trail.size():
			var spark: Vector2 = Vector2(trail[point_index]) + offset + spark_offset(point_index)
			view.draw_rect(Rect2(spark - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.55, 0.2, 0.85))

## Stable stand-in for `_rand() % 9` in FUN_00436fd0: the span is -4..+4.
static func spark_offset(index: int) -> Vector2:
	return Vector2(-4 + (index * 3) % 9, -4 + (index * 5) % 9)

func _placed_texture(name: String) -> CanvasTexture:
	if not placed.has(name):
		var path := "res://assets/openbound/raon/" + name
		placed[name] = pixel_texture(load(path)) if ResourceLoader.exists(path) else null
	return placed[name]

## S2 mine: dormant "normal" beyond 90 px, "active" inside that range (the C#
## flipbook). SS plays "move" while it still has steps. The crystal stays on
## the "normal" state SpawnCrystalShot selects.
static func placed_state(mine: Dictionary, actors: Array) -> String:
	if bool(mine.get("crystal", false)):
		return "normal"
	if bool(mine.get("crawl", false)) and int(mine.get("steps", 0)) > 0:
		return "move"
	var here := Vector2(mine.get("pos", Vector2.ZERO))
	for actor in actors:
		if int(actor.get("hp", 0)) <= 0:
			continue
		if Vector2(actor.pos).distance_to(here) <= 90.0:
			return "active"
	return "normal"

## Original crystal.img, rayonmine.img and srayonmine.img.
func draw_placed(view: Node2D, mines: Array, actors: Array, offset: Vector2) -> void:
	var clock := int(Time.get_ticks_msec() / 50)
	for mine in mines:
		var file := "crystal.png" if bool(mine.get("crystal", false)) else ("MineSS.png" if bool(mine.get("crawl", false)) else "Mine.png")
		var state := placed_state(mine, actors)
		var info: Dictionary = sheet(file)
		var texture: CanvasTexture = _placed_texture(file)
		if info.is_empty() or texture == null:
			continue
		var frames: Array = info.get("states", {}).get(state, [])
		if frames.is_empty():
			frames = info.get("states", {}).get("normal", [])
		if frames.is_empty():
			continue
		var index := int(frames[clock % frames.size()])
		var parts := cell_frame(file, index)
		view.draw_set_transform(Vector2(mine.pos) + offset)
		if file == "Mine.png":
			var glow: CanvasTexture = _placed_texture("MineLight.png")
			if glow != null and sheet("MineLight.png").has("cell"):
				var light := cell_frame("MineLight.png", mini(index, int(sheet("MineLight.png").frames) - 1))
				view.draw_texture_rect_region(glow, light[1], light[0], Color(1, 1, 1, 0.75))
		view.draw_texture_rect_region(texture, parts[1], parts[0])
	view.draw_set_transform(Vector2.ZERO)

func effect_capacity(weapon: int) -> int:
	var info := sheet("Flame%d.png" % (weapon + 1))
	return int(info.get("frames", 1))

func draw_effect(view: Node2D, effect: Dictionary, offset: Vector2 = Vector2.ZERO) -> void:
	var weapon: int = effect.weapon
	if weapon < 0 or weapon >= effects.size():
		return
	var frame := int(float(effect.age) * EFFECT_FPS)
	if frame >= effect_capacity(weapon):
		return
	var parts := cell_frame("Flame%d.png" % (weapon + 1), frame)
	if parts[0].size == Vector2.ZERO:
		return
	view.draw_set_transform(Vector2(effect.pos) + offset)
	view.draw_texture_rect_region(effects[weapon], parts[1], parts[0])
	view.draw_set_transform(Vector2.ZERO)
