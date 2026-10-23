extends StyleBox
## Reconstructed XFS cyan chrome in logical pixels; no enlarged raster borders.
var kind := "panel"
var state := 0
func _init(surface: String = "panel", button_state: int = 0) -> void:
	kind = surface
	state = button_state
	set_content_margin_all(0)
func box(canvas: RID, area: Rect2, fill: Color, border: Color, width: int = 1, radius: int = 5) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.draw(canvas,area)
func _draw(canvas: RID, area: Rect2) -> void:
	if kind == "well":
		box(canvas,area,Color("063343"),Color("001820"),2,2)
		return
	box(canvas,area,Color("193e52"),Color("001723"),2,7)
	box(canvas,area.grow(-2),Color("aad3df"),Color("5a889f"),1,5)
	box(canvas,area.grow(-4),Color("067fac"),Color("00364e"),1,3)
	if kind == "panel":
		box(canvas,area.grow(-6),Color("0488b5"),Color("25c6e8"),1,2)
		return
	var fill := Color("20a8d4")
	var light := Color("c2f1ff")
	if state == 1:
		fill=Color("4cc9ee")
	elif state == 2:
		fill=Color("eba73e")
		light=Color("fff3b6")
	elif state == 3:
		fill=Color("858c8b")
		light=Color("c2c8c4")
	box(canvas,area.grow(-4),fill,Color("376a80"),1,4)
	box(canvas,Rect2(area.position+Vector2(5,4),Vector2(area.size.x-10,maxf(3,area.size.y*0.44))),light,light,0,3)
	RenderingServer.canvas_item_add_line(canvas,area.position+Vector2(6,area.size.y-5),area.end-Vector2(6,5),Color("00557b") if state!=3 else Color("5d6463"),1,true)
