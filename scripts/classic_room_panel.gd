extends Panel
signal cancelled
## Classic dialog frame composed from clean native corners/edges.
## Avoids stretching the ROOMTITLE and TitleName baked into the source window.
var texture: Texture2D
const K := 1.6

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode==KEY_ESCAPE or event.keycode==KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		cancelled.emit()

func patch(target: Rect2, source: Rect2) -> void:
	var density := texture.get_width()/313.0
	draw_texture_rect_region(texture,target,Rect2(source.position*density,source.size*density))

func _draw() -> void:
	if texture==null:
		return
	var edge := 12*K
	var header := 24*K
	var bottom := 12*K
	# Native body colour is sampled without touching the source's baked input.
	patch(Rect2(edge,header,size.x-2*edge,size.y-header-bottom),Rect2(200,100,1,1))
	patch(Rect2(0,0,edge,header),Rect2(0,0,12,24))
	patch(Rect2(edge,0,size.x-2*edge,header),Rect2(200,0,1,24))
	patch(Rect2(size.x-edge,0,edge,header),Rect2(301,0,12,24))
	patch(Rect2(0,header,edge,size.y-header-bottom),Rect2(0,100,12,1))
	patch(Rect2(size.x-edge,header,edge,size.y-header-bottom),Rect2(301,100,12,1))
	patch(Rect2(0,size.y-bottom,edge,bottom),Rect2(0,148,12,12))
	patch(Rect2(edge,size.y-bottom,size.x-2*edge,bottom),Rect2(200,148,1,12))
	patch(Rect2(size.x-edge,size.y-bottom,edge,bottom),Rect2(301,148,12,12))
