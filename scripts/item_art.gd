extends RefCounted
## Item presentation (EquippedButtonBar.cs, Button.cs presets, TeleportationBeacon,
## SpecialEffectBuilder.TeleportFlame1/2). Reads events and model state only.
## HD derivatives (assets/hd/items, GPT Images) fall back to the originals.
## Reference logic: OpenBound, Copyright (C) 2020, Carlos H.M.S.; GPL-3.0-or-later.

const Items = preload("res://scripts/items.gd")

const ORIGINALS := "res://assets/openbound/items/"
const HD := "res://assets/hd/items/"
# Button.cs SelectItem presets: Normal, Hoover, Clicked, Disabled; Activated = Clicked.
const BUTTON_HEIGHT := 36
const FRAME_NORMAL := 0
const FRAME_HOVER := 1
const FRAME_CLICKED := 2
const FRAME_DISABLED := 3
# TeleportationBeacon flipbook: 12 frames of 43×39, pivot (30, 18), 20 fps.
const BEACON_CELL := Vector2(43, 39)
const BEACON_PIVOT := Vector2(30, 18)
const BEACON_FPS := 20.0
# TeleportFlame1/2: 19 frames of 190×192, pivot (95, 100), 30 fps, random rotation.
const FLAME_CELL := Vector2(190, 192)
const FLAME_PIVOT := Vector2(95, 100)
const FLAME_FRAMES := 19
const FLAME_FPS := 30.0
# Keyframes kept in the HD sheet (build_items_hd.py FLAME_KEYS).
const FLAME_KEYS := [0, 2, 4, 6, 8, 11, 14, 18]
# The HD MatchStatus keeps only the ITEM LOCKED frame (217 of the 868 px sheet).
const HD_SOURCE_WIDTH := {"MatchStatus.png": 217.0}
# MobileFlipbook UsingItem: 20 frames at 19 fps. Sheets are 5×4 cells.
# Bigfoot cell 129×130 (frames 234–253); Mage cell 109×150 (frames 243–262).
const USING_FPS := 19.0
const USING_FRAMES := 20
const USING_COLUMNS := 5
const USING_CELL := {"bigfoot": Vector2(129, 130), "mage": Vector2(109, 150)}

var textures := {}
var originals := {}
var shoot_sound: AudioStream
var blast_sound: AudioStream
var flames: Array = []
var using_textures := {}
var rng := RandomNumberGenerator.new()

func _init() -> void:
	var names: Array = ["MatchStatus.png", "SelectItemBackground.png", "TabIndex.png", "TeleportBullet.png", "Teleport1.png"]
	for id in Items.ORDER:
		names.append(button_file(id))
	for name in names:
		originals[name] = load(ORIGINALS + name)
		textures[name] = load(HD + name) if ResourceLoader.exists(HD + name) else originals[name]
	if ResourceLoader.exists(HD + "TeleportFlame.png"):
		textures["TeleportFlame.png"] = load(HD + "TeleportFlame.png")
	shoot_sound = load(ORIGINALS + "ShootTeleport.mp3")
	blast_sound = load(ORIGINALS + "BlastTeleport.mp3")
	_load_using("bigfoot", "UsingItemBigfoot.png")
	_load_using("mage", "UsingItemMage.png")
	rng.randomize()

func _load_using(kind: String, file_name: String) -> void:
	var hd_path := HD + file_name
	var original_path := ORIGINALS + file_name
	if ResourceLoader.exists(hd_path):
		using_textures[kind] = load(hd_path)
	elif ResourceLoader.exists(original_path):
		var canvas := CanvasTexture.new()
		canvas.diffuse_texture = load(original_path)
		canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		using_textures[kind] = canvas

static func button_file(id: String) -> String:
	return "Item%s.png" % Items.definition(id).file

## Original button width: 73 for 2-slot items, 37 for 1-slot items.
static func button_width(id: String) -> float:
	return 73.0 if Items.slots(id) == 2 else 37.0

## HD pixels per original pixel (1 when the original is used).
func density(name: String) -> float:
	if textures[name] == originals[name]:
		return 1.0
	return float(textures[name].get_width()) / float(HD_SOURCE_WIDTH.get(name, originals[name].get_width()))

func region(name: String, source: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = textures[name]
	var d := density(name)
	texture.region = Rect2(source.position * d, source.size * d)
	return texture

func button_frame(id: String, frame: int) -> AtlasTexture:
	var width := button_width(id)
	return region(button_file(id), Rect2(frame * width, 0, width, BUTTON_HEIGHT))

## Button.ChangeButtonState: activated keeps the clicked face, also on hover.
func style_button(button: TextureButton, id: String, activated: bool) -> void:
	button.texture_normal = button_frame(id, FRAME_CLICKED if activated else FRAME_NORMAL)
	button.texture_hover = button_frame(id, FRAME_CLICKED if activated else FRAME_HOVER)
	button.texture_pressed = button_frame(id, FRAME_CLICKED)
	button.texture_disabled = button_frame(id, FRAME_CLICKED if activated else FRAME_DISABLED)
	button.set_meta("activated", activated)

# ---------------------------------------------------------------- events

func react(event: Dictionary, sound) -> void:
	match event.type:
		"projectile_launch":
			# TeleportationBeacon.PlayLaunchSFX: pitch −0.5 (half an octave down).
			if bool(event.get("beacon", false)) and sound != null:
				sound.play("fire", shoot_sound, pow(2.0, -0.5))
		"teleport":
			# TeleportationBeacon.Explode: Flame1 at the landing, Flame2 at the old place.
			add_flame(Vector2(event.position), false)
			add_flame(Vector2(event.from), true)
			if sound != null:
				sound.play("explosion", blast_sound, pow(2.0, 0.5))
		"item":
			# Team Teleport without a teammate: both flames on the mobile and the sound.
			if event.item == "team_teleport":
				add_flame(Vector2(event.position), false)
				add_flame(Vector2(event.position), true)
				if sound != null:
					sound.play("explosion", blast_sound, pow(2.0, 0.5))

## Teleport2 is Teleport1 played backwards (pixel identical frames).
func add_flame(position: Vector2, reverse: bool) -> void:
	flames.append({"pos": position, "age": 0.0, "reverse": reverse, "rotation": rng.randf() * TAU})

func tick(delta: float) -> void:
	for i in range(flames.size() - 1, -1, -1):
		flames[i].age += delta
		if flames[i].age >= FLAME_FRAMES / FLAME_FPS:
			flames.remove_at(i)

func clear() -> void:
	flames.clear()

# ---------------------------------------------------------------- drawing

func draw_beacon(view: CanvasItem, projectile: Dictionary, offset: Vector2) -> void:
	var frame := int(float(projectile.age) * BEACON_FPS) % 12
	var name := "TeleportBullet.png"
	var d := density(name)
	view.draw_set_transform(Vector2(projectile.get("hit_pos", projectile.pos)) + offset, Vector2(projectile.velocity).angle())
	view.draw_texture_rect_region(textures[name], Rect2(-BEACON_PIVOT, BEACON_CELL), Rect2(Vector2(frame * BEACON_CELL.x, 0) * d, BEACON_CELL * d))
	view.draw_set_transform(Vector2.ZERO)

## Original frame position (0–18) of a flame at this age.
static func flame_position(age: float, reverse: bool) -> float:
	var position := clampf(age * FLAME_FPS, 0.0, FLAME_FRAMES - 1.0)
	return FLAME_FRAMES - 1.0 - position if reverse else position

## Two HD keyframes around an original frame position and the blend between them.
static func flame_keys(position: float) -> Dictionary:
	for index in range(FLAME_KEYS.size() - 1):
		var start: float = FLAME_KEYS[index]
		var finish: float = FLAME_KEYS[index + 1]
		if position <= finish:
			return {"first": index, "second": index + 1, "blend": clampf((position - start) / (finish - start), 0.0, 1.0)}
	return {"first": FLAME_KEYS.size() - 1, "second": FLAME_KEYS.size() - 1, "blend": 0.0}

func draw_flames(view: CanvasItem, offset: Vector2) -> void:
	for flame in flames:
		var position := flame_position(float(flame.age), bool(flame.reverse))
		view.draw_set_transform(Vector2(flame.pos) + offset, float(flame.rotation))
		var target := Rect2(-FLAME_PIVOT, FLAME_CELL)
		if textures.has("TeleportFlame.png"):
			var sheet: Texture2D = textures["TeleportFlame.png"]
			var key_size := Vector2(sheet.get_width() / float(FLAME_KEYS.size()), sheet.get_height())
			var keys := flame_keys(position)
			for entry in [[keys.first, 1.0 - float(keys.blend)], [keys.second, float(keys.blend)]]:
				if float(entry[1]) <= 0.0:
					continue
				view.draw_texture_rect_region(sheet, target, Rect2(Vector2(int(entry[0]) * key_size.x, 0), key_size), Color(1, 1, 1, float(entry[1])))
		else:
			var frame := int(position)
			view.draw_texture_rect_region(originals["Teleport1.png"], target, Rect2(Vector2(frame % 10, int(frame / 10)) * FLAME_CELL, FLAME_CELL))
	view.draw_set_transform(Vector2.ZERO)

## Frame of the 20-frame UsingItem aura (holds the last frame).
static func using_frame(age: float) -> int:
	return mini(USING_FRAMES - 1, maxi(0, int(floor(age * USING_FPS + 0.00001))))

func using_density(kind: String) -> float:
	var texture: Texture2D = using_textures.get(kind)
	if texture == null:
		return 1.0
	var cell_width: float = USING_CELL[kind].x
	return float(texture.get_width()) / (cell_width * float(USING_COLUMNS))

## Green diamonds and beams over the mobile. Same cell, pivot and ground
## contact as the original atlas, so the aura sits on the character.
func draw_using(view: CanvasItem, body, state: Dictionary, facing: int, offset: Vector2) -> void:
	var kind: String = body.hd_rig.kind
	var texture: Texture2D = using_textures.get(kind)
	if texture == null:
		return
	var cell: Vector2 = body.cell
	var amount: float = 60.0 / float(body.hull_width)
	var ground := 24.0
	var frame := using_frame(float(state.pose_age))
	var density := using_density(kind)
	var source_cell := cell * density
	view.draw_set_transform(Vector2(state.pos) + offset, float(state.rotation), Vector2(-facing, 1))
	var pivot_x: float = body.pivot.x
	var contact_y: float = body.contact_y
	var target := Rect2(Vector2(-pivot_x * amount, ground - contact_y * amount), cell * amount)
	var column := frame % USING_COLUMNS
	var row := int(frame / USING_COLUMNS)
	view.draw_texture_rect_region(texture, target, Rect2(Vector2(column, row) * source_cell, source_cell))
	view.draw_set_transform(Vector2.ZERO)
