extends StyleBox
## store_avatar.img geometry, redrawn at framebuffer resolution.
var skin: AtlasTexture
var density := 1.0
const PRICE_COLOR := Color("0083b3")
func _init(texture: AtlasTexture, scale: float) -> void:
	skin = texture
	density = scale
	set_content_margin_all(0)
func rect(canvas: RID, area: Rect2, color: Color) -> void:
	RenderingServer.canvas_item_add_rect(canvas,area,color)
func _draw(canvas: RID, area: Rect2) -> void:
	var p := area.position
	var w := area.size.x
	var h := area.size.y
	var state := int(round(skin.region.position.x/(105*density)))
	rect(canvas,area,Color("001722"))
	rect(canvas,area.grow(-1),Color("b2e3ee"))
	rect(canvas,area.grow(-3),Color("003445"))
	rect(canvas,Rect2(p+Vector2(6,21),Vector2(88,81)),Color("d7e2df"))
	rect(canvas,Rect2(p+Vector2(6,102),Vector2(w-12,h-108)),PRICE_COLOR)
	var points := PackedVector2Array([p+Vector2(2,1),p+Vector2(w-2,1)])
	for step in range(81):
		var x := (w-4)*(1.0-step/80.0)
		points.append(p+Vector2(2+x,20+4*absf(sin(x/(w-4)*PI*5))))
	RenderingServer.canvas_item_add_polygon(canvas,points,PackedColorArray([Color("05bce8") if state==0 else (Color("46d8f4") if state==1 else Color("20a6d7"))]))
	var line := PackedVector2Array(points)
	line.append(points[0])
	RenderingServer.canvas_item_add_polyline(canvas,line,PackedColorArray([Color("002b42")]),1,true)

	rect(canvas,Rect2(p+Vector2(4,3),Vector2(w-8,1)),Color("74e8ff"))
	rect(canvas,Rect2(p+Vector2(4,h-5),Vector2(w-8,1)),Color("26b4db"))
