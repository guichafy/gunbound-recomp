extends "res://scripts/mobile_sprite.gd"
## Original client atlas (tankN.img / .epa) for a mobile without an HD rig.
## scripts/import_classic_mobiles.py writes frames.json. Pose lists are the
## .epa frame indices, the same state names Nak already maps onto the flipbook.

const SHOT_FPS := 20.0
const Timing = preload("res://scripts/classic_shot_timing.gd")
const ClassicProjectileArt = preload("res://scripts/classic_projectile_art.gd")
const SmoothArt = preload("res://scripts/mobile_smooth_art.gd")
var classic_art = ClassicProjectileArt.new()
var meta: Dictionary = {}
var mobile_kind := ""
var asset_folder := ""
var placed: Dictionary = {}
# Texels per native pixel of each validated4× sheet (ADR-104).
var sheet_density: Dictionary = {}
var bullets: Array = []
var lights: Array = []
var rear := false
var satellite_art
var satellite_sounds: Array = []

func setup(kind: String) -> void:
	mobile_kind = kind
	if kind == "asate":
		satellite_art = preload("res://scripts/asate_art.gd").new()
		for number in range(1,4):
			var audio_path := "res://assets/openbound/asate/Satellite%d.wav" % number
			satellite_sounds.append(load(audio_path) if ResourceLoader.exists(audio_path) else AudioStreamWAV.new())
	original_art = true
	native_animation = bool(preload("res://scripts/mobile_looks.gd").by_kind(kind).get("native_animation",false))
	var folder := str(preload("res://scripts/mobile_looks.gd").by_kind(kind).get("assets", "res://assets/openbound/" + kind))
	asset_folder = folder
	meta = JSON.parse_string(FileAccess.get_file_as_string(folder + "/frames.json"))
	var cell := Vector2(meta.cell[0], meta.cell[1])
	var pivot := Vector2(meta.origin[0], meta.origin[1])
	# Battle draws every mobile at width 60. A shared hull keeps one source
	# pixel at one screen pixel, so a narrow body stays narrower than Trico.
	# The idle frame's opaque bottom is the ground contact.
	var feet := float(meta.get("contact_feet", 0.0))
	configure(folder, cell, pivot, {
		"idle": [0, 0, 19.0, true]
	}, 60.0, pivot.y + feet, kind)
	load_sounds("res://assets/openbound/" + kind)
	for name in ["Bullet1", "Bullet2", "Bullet3"]:
		bullets.append(_optional(folder, name))
		lights.append(_optional(folder, name + "Light"))
	load_smooth(str(preload("res://scripts/mobile_looks.gd").by_kind(kind).get("smooth", "")))

## Swap in the validated4× sheets; geometry stays in native pixels.
func load_smooth(root: String) -> void:
	if root.is_empty():
		return
	var native := {SmoothArt.ATLAS: texture}
	for name in meta.get("sheets", {}):
		var path := "%s/%s" % [asset_folder, name]
		if ResourceLoader.exists(path):
			native[name] = load(path)
	var sheets := SmoothArt.load_sheets(root, mobile_kind, asset_folder, meta, native)
	for name in sheets:
		if name == SmoothArt.ATLAS:
			texture = sheets[name]
			paint_texture = pixel_texture(texture)
			density = SmoothArt.DENSITY
		else:
			placed[name] = pixel_texture(sheets[name])
			sheet_density[name] = SmoothArt.DENSITY

func _optional(folder: String, name: String) -> CanvasTexture:
	var path := "%s/%s.png" % [folder, name]
	if not ResourceLoader.exists(path):
		return null
	return pixel_texture(load(path))

func load_sounds(folder: String) -> void:
	var vehicle_id := preload("res://scripts/mobile_looks.gd").id_of(mobile_kind)
	# MobileLooks maps folder identity to the stable playable ID.
	for weapon in range(3):
		shoot_sounds.append(Timing.stream(vehicle_id,weapon,"fire"))
		blast_sounds.append(Timing.stream(vehicle_id,weapon,"blast"))
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
	var durations: Array = meta.get("pose_durations", {}).get(key, [])
	return Timing.frame(frames, durations, age, looping)

## EPA ticks control action lifetimes as well as source frames.
func pose_duration(pose: String, weapon: int = 0, low_health: bool = false) -> float:
	var key := pose
	if pose in ["charging","recoil"]:
		key += "_"+str(clampi(weapon,0,2))
	elif low_health and pose in ["idle","moving"]:
		key += "_low"
	var ticks := 0
	for duration in meta.get("pose_durations",{}).get(key,[]):
		ticks += maxi(1,int(duration))
	return float(ticks if ticks > 0 else meta.poses.get(key,[]).size())*Timing.STEP

func draw(view: Node2D, request) -> void:
	super.draw(view, request.mirrored() if rear else request)

func sheet(name: String) -> Dictionary:
	return meta.sheets.get(name, {})

## Simulation owns SS state. A long trajectory cannot open the visual early.
static func bullet_state(info: Dictionary, age: float, state: String = "normal", state_tick: int = 0) -> Dictionary:
	var states: Dictionary = info.get("states", {})
	# Turtle's EPA ends at change: after the model hold, retain its terminal
	# frame instead of reverting to normal or inventing a cnormal sequence.
	if state == "cnormal" and not states.has("cnormal") and states.has("change"):
		var ticks := 0
		for duration in info.get("durations", {}).get("change", []):
			ticks += int(duration)
		return {"frames":states.change, "age":maxi(ticks, states.change.size())*Timing.STEP, "state":"change"}
	var key := state if states.has(state) else "normal"
	return {"frames":states.get(key, []), "age":state_tick * Timing.STEP if key != "normal" else age, "state":key}

func projectile_frame(info: Dictionary, projectile: Dictionary) -> int:
	var played := bullet_state(info,float(projectile.age),str(projectile.get("ss_state","normal")),int(projectile.get("ss_state_tick",0)))
	return Timing.frame(played.frames, info.get("durations",{}).get(played.state,[]), played.age, played.state != "change")

func cell_frame(name: String, index: int) -> Array:
	var info := sheet(name)
	if info.is_empty():
		return [Rect2(), Rect2()]
	var cell := Vector2(info.cell[0], info.cell[1])
	var columns := int(info.columns)
	var texels := float(sheet_density.get(name, 1.0))
	return [Rect2(Vector2(index % columns, int(index / columns)) * cell * texels, cell * texels), Rect2(-Vector2(info.origin[0], info.origin[1]), cell)]

func projectile_sheet(projectile: Dictionary, weapon: int) -> String:
	if mobile_kind in ["turtle","dragon"] and bool(projectile.get("child",false)):
		return "SSChild.png"
	return "Bullet%d.png" % (weapon+1)

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	if not projectile.get("launched", true) or weapon < 0 or weapon >= bullets.size():
		return
	if mobile_kind == "asate" and bool(projectile.get("child",false)):
		satellite_art.draw_child(view,projectile,weapon,offset)
		return
	if mobile_kind == "turtle" and weapon < 2:
		classic_art.draw_water(view,projectile,offset)
		return
	# Missing Dragon primary body must not suppress its particles.
	if mobile_kind == "dragon" and weapon < 2:
		var trail: Array = projectile.get("trail", [])
		view.draw_set_transform(offset)
		for point_index in trail.size():
			var spark: Vector2 = Vector2(trail[point_index]) + spark_offset(point_index)
			view.draw_rect(Rect2(spark - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.55, 0.2, 0.85))
		view.draw_set_transform(Vector2.ZERO)
		return
	var name := projectile_sheet(projectile,weapon)
	var info := sheet(name)
	if info.is_empty():
		return
	var index := projectile_frame(info,projectile)
	var position: Vector2 = projectile.get("hit_pos", projectile.pos) + offset
	view.draw_set_transform(position, Vector2(projectile.velocity).angle())
	var light_name := name.replace(".png","Light.png")
	var light_info := sheet(light_name)
	if not light_info.is_empty():
		var light := cell_frame(light_name, projectile_frame(light_info,projectile))
		view.draw_texture_rect_region(_optional_cached(light_name), light[1], light[0])
	var body := cell_frame(name, index)
	view.draw_texture_rect_region(_optional_cached(name), body[1], body[0])
	view.draw_set_transform(Vector2.ZERO)

func _optional_cached(name: String) -> CanvasTexture:
	if not placed.has(name):
		placed[name] = _optional(asset_folder,name.trim_suffix(".png"))
	return placed[name]

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
	if mine.has("state"):
		return str(mine.state)
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
		var age := float(mine.get("state_age",mine.get("age",0.0)))
		var index := Timing.frame(frames,info.get("durations",{}).get(state,[]),age,true)
		var parts := cell_frame(file, index)
		var facing := -1.0 if float(mine.get("dir",1.0)) < 0.0 else 1.0
		view.draw_set_transform(Vector2(mine.pos) + offset,0.0,Vector2(facing,1))
		if file == "Mine.png":
			var glow: CanvasTexture = _placed_texture("MineLight.png")
			if glow != null and sheet("MineLight.png").has("cell"):
				var light := cell_frame("MineLight.png", mini(index, int(sheet("MineLight.png").frames) - 1))
				view.draw_texture_rect_region(glow, light[1], light[0], Color(1, 1, 1, 0.75))
		view.draw_texture_rect_region(texture, parts[1], parts[0])
	view.draw_set_transform(Vector2.ZERO)

func effect_capacity(weapon: int) -> int:
	var info := sheet("Flame%d.png" % (weapon + 1))
	var durations: Array = info.get("durations", {}).get("flame",[])
	var total := 0
	for duration in durations:
		total += int(duration)
	return total if total > 0 else int(info.get("frames", 1))

func effect_sheets(effect: Dictionary) -> Array:
	var weapon := int(effect.weapon)
	var name := "Flame%d.png" % (weapon+1)
	# Turtle's unsplit SS calls the common flame123 and its extra ssflame12
	# stage. A bullet12c fragment only calls flame123 (PE 0x432b5c).
	if mobile_kind == "turtle" and weapon == 2 and not bool(effect.get("child",false)) and str(effect.get("ss_state","normal")) == "normal":
		return [name,"SSFlame.png"]
	# Existing special detonation paths with no primary flame have their own
	# secondary resource. Never overlay both stages automatically.
	if sheet(name).is_empty() and weapon == 2 and mobile_kind in ["lightning", "ice", "mage"]:
		name = "SSFlame.png"
	return [name]

func draw_effect(view: Node2D, effect: Dictionary, offset: Vector2 = Vector2.ZERO) -> void:
	if int(effect.weapon) < 0 or int(effect.weapon) >= effects.size():
		return
	for name in effect_sheets(effect):
		draw_effect_sheet(view,effect,str(name),offset)

func draw_effect_sheet(view: Node2D, effect: Dictionary, name: String, offset: Vector2) -> void:
	var info := sheet(name)
	if info.is_empty():
		return
	var frame := Timing.frame(info.get("states",{}).get("flame",[]),info.get("durations",{}).get("flame",[]),float(effect.age),false)
	var ticks := 0
	for duration in info.get("durations",{}).get("flame",[]):
		ticks += int(duration)
	if float(effect.age) >= (float(ticks)*Timing.STEP if ticks > 0 else float(info.frames)*Timing.STEP):
		return
	var parts := cell_frame(name, frame)
	if parts[0].size == Vector2.ZERO:
		return
	view.draw_set_transform(Vector2(effect.pos) + offset, float(effect.get("angle",0.0)) if mobile_kind == "turtle" else 0.0)
	view.draw_texture_rect_region(_optional_cached(name), parts[1], parts[0])
	view.draw_set_transform(Vector2.ZERO)
