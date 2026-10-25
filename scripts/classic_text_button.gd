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
