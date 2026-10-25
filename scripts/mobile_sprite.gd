extends RefCounted
## Shared source-atlas renderer: animation, original rider offsets and pixel filtering.
## Reference data: OpenBound; notices in assets/openbound/ATTRIBUTION.md.

const COLUMNS := 20
# Shot/impact sound suffixes and explosion sheet numbers, by weapon slot.
const SHOT_KEYS := ["S1", "S2", "SS"]
# The original default rider (body + head) ships once, in the Bigfoot folder.
const LEGACY_RIDER := "res://assets/openbound/bigfoot/"
const EFFECT_FPS := 30.0
var original_art := false
var native_animation := false
var cell: Vector2
var pivot: Vector2
var hull_width: float
var contact_y: float
var sequences: Dictionary
var texture: Texture2D
var paint_texture: CanvasTexture
# Texels per native atlas pixel; only source rectangles use it (ADR-115).
var density := 1.0
var rider_body: CanvasTexture
var rider_head: CanvasTexture
var rider_offsets: Array = []
const HDSheet = preload("res://scripts/hd_sheet.gd")
var hd_rig
const MobileRig = preload("res://scripts/mobile_rig.gd")
# Filled by load_shot_assets(): original sounds and explosion sheets per weapon.
var shoot_sounds: Array[AudioStream] = []
var blast_sounds: Array[AudioStream] = []
var effects: Array[Texture2D] = []
const ProjectileArt = preload("res://scripts/projectile_art.gd")
# HD shots/impacts (GPT Images derivatives); null for a mobile without HD.
var projectile_art
var hd_shots
var hd_effects
var effect_sizes: Array[Vector2] = []

func configure(folder: String, frame_size: Vector2, anchor: Vector2, animations: Dictionary, hull: float, ground_contact: float, presentation_kind: String = "") -> void:
	cell = frame_size
	pivot = anchor
	sequences = animations
	hull_width = hull
	contact_y = ground_contact
	texture = load(folder + "/CharacterSpritesheet.png")
	paint_texture = pixel_texture(texture)
	rider_body = pixel_texture(load(LEGACY_RIDER + "RiderBody.png"))
	rider_head = pixel_texture(load(LEGACY_RIDER + "RiderHead.png"))
	var text := FileAccess.get_file_as_string(folder + "/RiderPivot.json").strip_edges()
	text = text.trim_suffix("]").strip_edges().trim_suffix(",") + "]"
	rider_offsets = JSON.parse_string(text)
	hd_rig = MobileRig.new(presentation_kind if not presentation_kind.is_empty() else folder.get_file())
	hd_rig.register_avatar(rider_offset(0),contact_y-pivot.y,hull_width)

## Shared loading step of every mobile: Shoot/Blast S1/S2/SS sounds and the
## Flame1..3 explosion sheets of its folder.
func load_shot_assets(folder: String) -> void:
	for key in SHOT_KEYS:
		shoot_sounds.append(load("%s/Shoot%s.mp3" % [folder, key]))
		blast_sounds.append(load("%s/Blast%s.mp3" % [folder, key]))
	for number in range(1, SHOT_KEYS.size() + 1):
		effects.append(pixel_texture(load("%s/Flame%d.png" % [folder, number])))

## HD shots and impacts shared by the mobiles with approved derivatives. The
## original explosion occupancy is measured once to keep its size in HD.
func load_hd_shots() -> void:
	projectile_art = ProjectileArt.new()
	hd_shots = projectile_art.sheet
	hd_effects = HDSheet.new("res://assets/hd/effects.png", 6, 6)
	for weapon in range(effects.size()):
		effect_sizes.append(ProjectileArt.effect_size(effects[weapon], effect_cell(weapon)))

## Explosion cell of a weapon on a regular grid sheet (subclasses with grids).
func effect_cell(_weapon: int) -> Vector2:
	return Vector2.ZERO

## Frames in the explosion sheet; grid sheets count whole cells.
func effect_capacity(weapon: int) -> int:
	var size := effect_cell(weapon)
	return int(effects[weapon].get_width() / size.x) * int(effects[weapon].get_height() / size.y)

## Source rectangle of a grid explosion frame.
func effect_source(weapon: int, frame: int) -> Rect2:
	var size := effect_cell(weapon)
	var columns := int(effects[weapon].get_width() / size.x)
	return Rect2(Vector2(frame % columns, int(frame / columns)) * size, size)

func rider_offset(frame: int) -> Vector2:
	var point: Array = rider_offsets[clampi(frame, 0, rider_offsets.size() - 1)]
	return Vector2(point[0], point[1])

func pixel_texture(source: Texture2D) -> CanvasTexture:
	var result := CanvasTexture.new()
	result.diffuse_texture = source
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return result

func frame_index(pose: String, age: float, weapon: int, low_health: bool) -> int:
	var key := pose
	if pose in ["charging", "recoil"]:
		key += "_" + str(clampi(weapon, 0, 2))
	elif low_health and pose in ["idle", "moving"]:
		key += "_low"
	var sequence: Array = sequences.get(key, sequences.idle)
	var count := int(sequence[1]) - int(sequence[0]) + 1
	var step := maxi(0, int(floor(age * float(sequence[2]) + 0.00001)))
	return int(sequence[0]) + (step % count if sequence[3] else mini(step, count - 1))

func frame_rect(index: int) -> Rect2:
	return Rect2(Vector2(index % COLUMNS, int(index / COLUMNS)) * cell * density, cell * density)

## `request` is a SpritePose: position, width, facing and the animation state.
func draw(view: Node2D, request) -> void:
	if not original_art and hd_rig.draw(view, request):
		return
	var pos: Vector2 = request.pos
	var width: float = request.width
	var facing: int = request.facing
	var rotation: float = request.rotation
	var frame: int = request.frame
	var color: Color = request.color
	var age: float = request.age
	var avatar_context: Dictionary = request.avatar_context
	# Native artwork faces left. Scale the configured alpha hull around its
	# original pivot and ground contact, without editing the source pixels.
	var amount := width / hull_width
	var ground := 24.0 if width < 150.0 else width * 0.23
	view.draw_set_transform(pos, rotation, Vector2(-facing, 1))
	var rect := Rect2(Vector2(-pivot.x * amount, ground - contact_y * amount), cell * amount)
	var rider := rider_offset(frame)
	var origin := Vector2(0, ground - (contact_y - pivot.y) * amount)
	if not avatar_context.is_empty():
		var assembled = hd_rig.avatars
		var transform := Transform2D(rotation,Vector2(-facing*amount,amount),0,pos) * Transform2D(0,origin/amount+rider)
		# Rider coordinates are native; translation is in scaled mobile space.
		if assembled.draw(view,avatar_context.get("equipment",{}),transform,float(avatar_context.get("age",age)),color):
			view.draw_set_transform(pos,rotation,Vector2(-facing,1))
			view.draw_texture_rect_region(paint_texture,rect,frame_rect(frame),color)
			view.draw_set_transform(Vector2.ZERO)
			return
	view.draw_set_transform(pos,rotation,Vector2(-facing,1))
	view.draw_texture_rect_region(paint_texture,rect,frame_rect(frame),color)
	var avatar_frame := int(age * 10.0) % 11
	var body_rect := Rect2(origin + (rider - Vector2(22, 12)) * amount, Vector2(44, 28) * amount)
	var head_rect := Rect2(origin + (rider + Vector2(7, -17) - Vector2(25, 12)) * amount, Vector2(38, 24) * amount)
	var body_source := Rect2(avatar_frame * 44, 0, 44, 28)
	var head_source := Rect2((11 + avatar_frame) * 38, 0, 38, 24)
	view.draw_texture_rect_region(rider_body, body_rect, body_source, color)
	view.draw_texture_rect_region(rider_head, head_rect, head_source, color)
	view.draw_set_transform(Vector2.ZERO)
