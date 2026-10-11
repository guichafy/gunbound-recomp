extends RefCounted
## Small UI factory keeps presentation styling separate from gameplay.

const INK := Color("0b1b2e")
const CREAM := Color("edf5ff")
const MUTED := Color("afc8df")
const TEAL := Color("6fdbef")
const STEEL := Color("91b4d8")
const AMBER := Color("ffc760")
var font: SystemFont
var bold: SystemFont
var metal_styles: Dictionary = {}

func _init() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Trebuchet MS", "Avenir Next", "Noto Sans"])
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

func metal_box(color: Color = Color("284c72"), edge: Color = STEEL) -> StyleBoxTexture:
	var key := color.to_html() + ":" + edge.to_html()
	if metal_styles.has(key):
		return metal_styles[key]
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.035, 0.12, 0.55, 0.96, 1.0])
	gradient.colors = PackedColorArray([edge, color.lightened(0.2), color, color.darkened(0.2), color.darkened(0.4), edge.darkened(0.35)])
	var texture := GradientTexture2D.new()
	texture.width = 32
	texture.height = 128
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	texture.gradient = gradient
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 2
	style.texture_margin_right = 2
	style.texture_margin_top = 3
	style.texture_margin_bottom = 3
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	metal_styles[key] = style
	return style

func metal_panel(parent: Node, position: Vector2, size: Vector2, color: Color = Color("284c72")) -> Panel:
	var node := Panel.new()
	node.position = position
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", metal_box(color))
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
	var bg := AMBER if primary else Color("315880")
	node.add_theme_stylebox_override("normal", metal_box(bg, AMBER if primary else STEEL))
	node.add_theme_stylebox_override("hover", metal_box(bg.lightened(0.16), AMBER))
	node.add_theme_stylebox_override("pressed", metal_box(bg.darkened(0.2), AMBER))
	node.add_theme_stylebox_override("disabled", metal_box(Color("20354d"), Color("48617e")))
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
