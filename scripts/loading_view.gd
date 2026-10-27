extends Control
## Bottom band of the original loading screen: load_back under the room,
## the selected stage, and the two names on the ground mask.

const Loading = preload("res://scripts/match_loading.gd")
const NAME_FONT = preload("res://assets/classic/room/settings/room_text.fnt")
## load_back.img is 800×244. The header groove (y 5–26) holds the red bar.
## The map hole starts at (28, 30) and is 741×207; the stage is 748×209 and
## is centered inside that hole so it does not cover the frame or the bar.
const PANEL := Vector2(0, 356)
const HOLE_POS := Vector2(28, 30)
const HOLE_SIZE := Vector2(741, 207)
const STAGE_SIZE := Vector2(748, 209)
const STAGE_ORIGIN := Vector2(24.5, 385)
const BAR := Vector2(608, 363)
## The mask pixel is the dark outline above the snow bank. The 8×12 font
## needs this extra drop to sit on the bank instead of in the gap.
const SURFACE_SINK := 20.0
const TEAM_A := Color("f4f7ff")
const TEAM_B := Color("ff4e3c")

var progress := 0.0
var _panel: Texture2D
var _stage: Texture2D
var _bar: Texture2D
var _rows := PackedInt32Array()

func _init() -> void:
	name = "MatchLoading"
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 5
	size = Vector2(800, 600)
	_panel = load("res://assets/classic/loading/load_back.png")
	_stage = load("res://assets/classic/loading/miramo_town.png")
	_bar = load("res://assets/classic/loading/load_bar.png")
	_rows = Loading.ground_rows()
	var hole := Control.new()
	hole.name = "MapHole"
	hole.position = PANEL + HOLE_POS
	hole.size = HOLE_SIZE
	hole.clip_contents = true
	hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := TextureRect.new()
	picture.texture = _stage
	picture.position = (HOLE_SIZE - STAGE_SIZE) * 0.5
	picture.size = STAGE_SIZE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hole.add_child(picture)
	add_child(hole)

func show_marks(world_width: int, points: Array, names: PackedStringArray) -> void:
	var colors := [TEAM_A, TEAM_B]
	for index in mini(points.size(), names.size()):
		var spawn := Vector2(points[index])
		var local := Loading.point(int(spawn.x), world_width, _rows)
		var text := names[index]
		var text_size := NAME_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		var origin := STAGE_ORIGIN + local - Vector2(text_size.x * 0.5, -SURFACE_SINK)
		var mark := ColorRect.new()
		mark.color = colors[index]
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.position = origin - Vector2(7, -3)
		mark.size = Vector2(4, 4)
		add_child(mark)
		var label := Label.new()
		label.text = text
		label.position = origin
		label.custom_minimum_size = text_size
		label.size = text_size
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		label.add_theme_font_override("font", NAME_FONT)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", colors[index])
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", Color("140806"))
		add_child(label)
		label.name = "SpawnName%d" % index

func _draw() -> void:
	if _panel != null:
		draw_texture(_panel, PANEL)
	if _bar != null and progress > 0.0:
		var width := maxi(1, int(round(_bar.get_width() * clampf(progress, 0.0, 1.0))))
		draw_texture_rect_region(_bar, Rect2(BAR, Vector2(width, _bar.get_height())), Rect2(0, 0, width, _bar.get_height()))
