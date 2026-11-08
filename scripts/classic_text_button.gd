extends TextureButton
## Native shell and native raster lettering. No replacement system typeface.
var text := ""
var word_frames: Array[Texture2D] = []
var word_size := Vector2(81,17)
var lettering_frames: Array[Texture2D] = []

func patch(skin: Texture2D, target: Rect2, source: Rect2) -> void:
	var density := skin.get_width()/107.0
	draw_texture_rect_region(skin,target,Rect2(source.position*density,source.size*density))

func _draw() -> void:
	var state := 0
	if disabled:state = 3
	elif is_pressed():state = 2
	elif is_hovered():state = 1
	# TextureButton itself draws the alpha-clean shell. The unmodified source
	# remains separate and supplies only START's already approved lettering.
	if text=="START" and lettering_frames.size()==4:
		patch(lettering_frames[state],Rect2((size.x-49)*0.5,14,49,19),Rect2(40,14,49,19))
		return
	if word_frames.size()==4 and word_frames[state]!=null:
		draw_texture_rect(word_frames[state],Rect2(Vector2(floorf((size.x-word_size.x)*0.5),13),word_size),false)

static func create(parent: Control, text: String, at: Vector2, chrome, paint) -> TextureButton:
	var button = load("res://scripts/classic_text_button.gd").new()
	button.text = text
	if text=="SETTINGS":
		var cell: Array = paint.records.room_settings_word.frame_size
		button.word_size = Vector2(cell[0],cell[1])
		for state in 4:button.word_frames.append(paint.frame("room_settings_word",state))
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = at
	button.custom_minimum_size = Vector2(107,45)
	for state in 4:button.lettering_frames.append(chrome.frame("b_ready_startgame",state))
	button.texture_normal = paint.frame("room_footer_shell",0)
	button.texture_hover = paint.frame("room_footer_shell",1)
	button.texture_pressed = paint.frame("room_footer_shell",2)
	button.texture_disabled = paint.frame("room_footer_shell",3)
	parent.add_child(button)
	button.size = Vector2(107,45)
	return button
