extends RefCounted
## Small UI factory keeps presentation styling separate from gameplay.

const INK := Color("112b38")
const CREAM := Color("f7f0df")
const MUTED := Color("a1b6b9")
const TEAL := Color("8de0d2")
var font: SystemFont
var bold: SystemFont

func _init() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Avenir Next", "Trebuchet MS", "Noto Sans"])
	font.font_weight = 500
	bold = SystemFont.new()
	bold.font_names = font.font_names
	bold.font_weight = 800

func box(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func panel(parent: Node, position: Vector2, size: Vector2, color: Color = INK, radius: int = 14) -> Panel:
	var node := Panel.new()
	node.position = position
	node.size = size
	node.add_theme_stylebox_override("panel", box(color, radius))
	parent.add_child(node)
	return node

func label(parent: Node, text: String, position: Vector2, size: Vector2, font_size: int = 18, color: Color = CREAM, strong: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.position = position
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font", bold if strong else font)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func button(parent: Node, text: String, position: Vector2, size: Vector2, callback: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.position = position
	node.size = size
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", bold)
	node.add_theme_font_size_override("font_size", 17)
	var bg := TEAL if primary else Color("24444e")
	node.add_theme_stylebox_override("normal", box(bg, 9, Color("47626a") if not primary else TEAL))
	node.add_theme_stylebox_override("hover", box(bg.lightened(0.13), 9, TEAL))
	node.add_theme_stylebox_override("pressed", box(bg.darkened(0.15), 9, TEAL))
	node.add_theme_stylebox_override("disabled", box(Color("20343f"), 9))
	node.add_theme_color_override("font_color", INK if primary else CREAM)
	node.add_theme_color_override("font_hover_color", INK if primary else CREAM)
	node.add_theme_color_override("font_pressed_color", INK if primary else CREAM)
	node.add_theme_color_override("font_disabled_color", Color("657a83"))
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func slider(parent: Node, position: Vector2, size: Vector2, minimum: float, maximum: float, value: float, callback: Callable) -> HSlider:
	var node := HSlider.new()
	node.position = position
	node.size = size
	node.min_value = minimum
	node.max_value = maximum
	node.step = 1.0
	node.value = value
	node.focus_mode = Control.FOCUS_NONE
	node.add_theme_stylebox_override("slider", box(Color("3a535c"), 3))
	node.add_theme_stylebox_override("grabber_area", box(TEAL, 3))
	node.add_theme_stylebox_override("grabber_area_highlight", box(TEAL.lightened(0.15), 3))
	node.value_changed.connect(callback)
	parent.add_child(node)
	return node
