extends Control
## PopupGameOptions.cs (PopupMenu, SliderBar, RadioButtonSet) with the original
## Interface/Popup/Blue/Options sprites. Offsets are the C# ones, relative to the
## popup centre on the 800×500 virtual screen, scaled by K = 1.6. HD sprites
## (assets/hd/hud, 3× GPT Images remaster) fall back to the originals; frame
## regions are in original pixels and scale by each texture's density. Values
## live in options.gd; game.gd applies them. Controls with no equivalent in this
## game are drawn with the original default and disabled.

signal changed
signal accepted

const K := 1.6
const SIZE := Vector2(323, 328)
const TITLE_HEIGHT := 30.0
const FONT_SIZE := 19  # Consolas 10 pt ≈ 7.3 px advance × 1.6 in a monospace font
const CATEGORY := Color8(255, 172, 17)
const SUB_CATEGORY := Color8(205, 206, 150)
const ELEMENT := Color8(205, 206, 205)
const DISABLED := Color(1, 1, 1, 0.38)
const BAR_SIZE := Vector2(145, 3)
const SLIDER_AREA := Vector2(145, 20)
const TEXTS := [
	["Gameplay", Vector2(-120, -120), CATEGORY], ["Aiming Mode", Vector2(-110, -100), SUB_CATEGORY],
	["Scroll Speed", Vector2(-110, -80), ELEMENT], ["Mouse Speed", Vector2(-110, -60), ELEMENT],
	["Sound", Vector2(-120, -40), CATEGORY], ["BGM", Vector2(-110, -20), ELEMENT], ["SFX", Vector2(-110, 0), ELEMENT],
	["Miscelaneous", Vector2(-120, 20), CATEGORY], ["Background", Vector2(-110, 40), SUB_CATEGORY],
	["Interface", Vector2(-110, 60), SUB_CATEGORY]]
const SLIDERS := {"scroll": Vector2(60, -73), "mouse": Vector2(60, -53), "bgm": Vector2(60, -13), "sfx": Vector2(60, 7)}
const RADIOS := {
	"aiming": {"labels": ["Drag", "Slice"], "centers": [Vector2(10, -94), Vector2(80, -94)]},
	"background": {"labels": ["On", "Off"], "centers": [Vector2(10, 46), Vector2(80, 46)]},
	"interface": {"labels": ["Classic", "TH Blue", "TH White", "OpenBound"],
		"centers": [Vector2(-90, 86), Vector2(30, 86), Vector2(-90, 106), Vector2(30, 106)]}}
# Only these exist in this game; the rest keep the C# defaults, disabled.
const ENABLED := ["aiming", "scroll", "sfx", "bgm", "background"]
# TODO(Mouse Speed): enable this slider and scale the Drag aiming distance
# (game.gd DRAG_FULL_POWER) by it; kept disabled at the C# default for now.
# Interface: only the Blue skin exists in this game (user decision, ADR-056).
const FIXED := {"mouse": 50, "interface": 1}
const ACCEPT_OFFSET := Vector2(130, 144)
const PAUSE_OFFSET := Vector2(-112, 144)

var options
var textures := {}
var originals := {}
var font: SystemFont
var accept_button: TextureButton
var drag_slider := ""
var drag_window := false
var drag_start := Vector2.ZERO

func _init(values = null) -> void:
	options = values
	size = SIZE * K
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Menlo", "Monaco", "DejaVu Sans Mono", "monospace"])
	for name in ["OptionsBackground.png", "OptionsBar.png", "OptionsBarFrame.bmp", "OptionsBarIntensityPointer.png", "OptionsRadioButton.png", "PopupAccept.png"]:
		originals[name] = load("res://assets/openbound/hud/" + name)
		# The HD remaster is always PNG (the original BarFrame is a BMP).
		var hd_path: String = "res://assets/hd/hud/" + name.get_basename() + ".png"
		textures[name] = load(hd_path) if ResourceLoader.exists(hd_path) else originals[name]
	# Button.cs Accept preset: 20×25 frames normal, hover, clicked, disabled.
	accept_button = TextureButton.new()
	accept_button.ignore_texture_size = true
	accept_button.stretch_mode = TextureButton.STRETCH_SCALE
	accept_button.focus_mode = Control.FOCUS_NONE
	accept_button.size = Vector2(20, 25) * K
	accept_button.position = point(ACCEPT_OFFSET) - accept_button.size * 0.5
	accept_button.tooltip_text = "Accept (ESC)"
	style_accept()
	accept_button.pressed.connect(func(): accepted.emit())
	add_child(accept_button)
	center_on(Vector2(640, 400))

func style_accept() -> void:
	var frames: Array[AtlasTexture] = []
	for frame in range(4):
		var region := AtlasTexture.new()
		region.atlas = textures["PopupAccept.png"]
		region.region = scaled("PopupAccept.png", Rect2(frame * 20, 0, 20, 25))
		frames.append(region)
	accept_button.texture_normal = frames[0]
	accept_button.texture_hover = frames[1]
	accept_button.texture_pressed = frames[2]
	accept_button.texture_disabled = frames[3]

## HD pixels per original pixel (1 when the original is used).
func density(name: String) -> float:
	return float(textures[name].get_width()) / float(originals[name].get_width())

func scaled(name: String, source: Rect2) -> Rect2:
	var d := density(name)
	return Rect2(source.position * d, source.size * d)

## Local point of a PopupGameOptions offset (relative to the popup centre).
func point(offset: Vector2) -> Vector2:
	return (SIZE * 0.5 + offset) * K

func center_on(screen_point: Vector2) -> void:
	position = (screen_point - size * 0.5).round()

func value_of(key: String) -> int:
	if FIXED.has(key):
		return FIXED[key]
	if key == "background":
		return 0 if options.background else 1
	return int(options.get(key))

func slider_rect(key: String) -> Rect2:
	var center := point(SLIDERS[key])
	return Rect2(center - SLIDER_AREA * K * 0.5, SLIDER_AREA * K)

func radio_rect(key: String, index: int) -> Rect2:
	# RadioButtonSet.UpdateButtonPosition: from the 12 px sprite to the text end.
	var center := point(RADIOS[key].centers[index])
	var text_end: float = center.x + 11.0 * K + font.get_string_size(RADIOS[key].labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	return Rect2(center.x - 6.0 * K, center.y - 6.0 * K, text_end - center.x + 6.0 * K, 12.0 * K)

## SliderBar.OnBeingDragged: intensity = (x − start) × 100 / 145, clamped.
func set_slider_from_local(key: String, x: float) -> void:
	if not ENABLED.has(key):
		return
	var start := point(SLIDERS[key]).x - BAR_SIZE.x * K * 0.5
	var value := clampi(int((x - start) * 100.0 / (BAR_SIZE.x * K)), 0, 100)
	if int(options.get(key)) != value:
		options.set(key, value)
		changed.emit()
	queue_redraw()

func select_radio(key: String, index: int) -> void:
	if not ENABLED.has(key):
		return
	if key == "background" and options.background != (index == 0):
		options.background = index == 0
		changed.emit()
	elif key == "aiming" and options.aiming != index:
		options.aiming = index
		changed.emit()
	queue_redraw()

func pointer_down(local: Vector2) -> void:
	if local.y < TITLE_HEIGHT * K:
		drag_window = true
		drag_start = local
		return
	for key in SLIDERS:
		if ENABLED.has(key) and slider_rect(key).has_point(local):
			drag_slider = key
			set_slider_from_local(key, local.x)
			return
	for key in RADIOS:
		for index in range(RADIOS[key].labels.size()):
			if radio_rect(key, index).has_point(local):
				select_radio(key, index)
				return

func pointer_move(local: Vector2) -> void:
	if drag_slider != "":
		set_slider_from_local(drag_slider, local.x)
	elif drag_window:
		# PopupMenu.OnBeingDragged keeps the whole window on the screen.
		var target := position + local - drag_start
		position = Vector2(clampf(target.x, 0.0, 1280.0 - size.x), clampf(target.y, 0.0, 800.0 - size.y)).round()

func pointer_up() -> void:
	drag_slider = ""
	drag_window = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_down(event.position)
		else:
			pointer_up()
		accept_event()
	elif event is InputEventMouseMotion:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			pointer_up()
		else:
			pointer_move(event.position)
		accept_event()

func draw_text(text: String, top_left: Vector2, color: Color) -> void:
	draw_string(font, Vector2(top_left.x, top_left.y + font.get_ascent(FONT_SIZE)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)

func _draw() -> void:
	draw_texture_rect(textures["OptionsBackground.png"], Rect2(Vector2.ZERO, size), false)
	for row in TEXTS:
		draw_text(row[0], point(row[1]), row[2])
	# DepthParameter order: frame and pointer (buttons) below the bar (text).
	for key in SLIDERS:
		var tint := Color.WHITE if ENABLED.has(key) else DISABLED
		var center := point(SLIDERS[key])
		var value := value_of(key)
		draw_texture_rect(textures["OptionsBarFrame.bmp"], Rect2(center - Vector2(147, 5) * K * 0.5, Vector2(147, 5) * K), false, tint)
		var filled := float(int(value * BAR_SIZE.x / 100.0))
		if filled > 0.0:
			draw_texture_rect_region(textures["OptionsBar.png"], Rect2(center - BAR_SIZE * K * 0.5, Vector2(filled, BAR_SIZE.y) * K), scaled("OptionsBar.png", Rect2(0, 0, filled, BAR_SIZE.y)), tint)
		var pointer := center + Vector2(-BAR_SIZE.x * 0.5 + float(int(value * BAR_SIZE.x / 100.0)), -5) * K
		draw_texture_rect(textures["OptionsBarIntensityPointer.png"], Rect2(pointer - Vector2(9, 6) * K * 0.5, Vector2(9, 6) * K), false, tint)
	for key in RADIOS:
		var tint := Color.WHITE if ENABLED.has(key) else DISABLED
		var selected := value_of(key)
		for index in range(RADIOS[key].labels.size()):
			var center := point(RADIOS[key].centers[index])
			var source := Rect2(12, 0, 11, 12) if index == selected else Rect2(0, 0, 12, 12)
			draw_texture_rect_region(textures["OptionsRadioButton.png"], Rect2(center - Vector2(6, 6) * K, source.size * K), scaled("OptionsRadioButton.png", source), tint)
			var text_size := font.get_string_size(RADIOS[key].labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
			draw_text(RADIOS[key].labels[index], Vector2(center.x + 11.0 * K, center.y + K - int(text_size.y * 0.5)), Color(ELEMENT, tint.a))
