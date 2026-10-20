extends StyleBox
## Registered slices keep borders and price-band details independent of HD density.
var skin: AtlasTexture
var density := 1.0
const BORDERS := Vector4(6,22,6,6) # left, top, right, bottom, in UI pixels.
const PRICE_COLOR := Color("799fd3")
func _init(texture: AtlasTexture, scale: float) -> void:
	skin = texture
	density = scale
	content_margin_left = 0
	content_margin_top = 0
	content_margin_right = 0
	content_margin_bottom = 0
func _draw(canvas: RID, area: Rect2) -> void:
	var source := skin.region
	var sx := [source.position.x,source.position.x+BORDERS.x*density,source.end.x-BORDERS.z*density,source.end.x]
	var dx := [area.position.x,area.position.x+BORDERS.x,area.end.x-BORDERS.z,area.end.x]
	# Header, white portrait panel, its lower rim, integrated blue price band,
	# then the native bottom finish. Keep screws/corners in the last nine pixels.
	var rows := [[0,22,0,22],[22,71,22,107],[71,75,107,111],[75,76,111,138],[74,83,138,147]]
	for row in rows:
		for x in range(3):
			var target := Rect2(dx[x],area.position.y+row[2],dx[x+1]-dx[x],row[3]-row[2])
			if row[2]==111 and x==1:
				# A four-pixel texture strip enlarged to 27 UI pixels smears its
				# highlights. Draw the center sharply; keep the surrounding chrome.
				RenderingServer.canvas_item_add_rect(canvas,target,PRICE_COLOR)
				continue
			var region := Rect2(sx[x],source.position.y+row[0]*density,sx[x+1]-sx[x],(row[1]-row[0])*density)
			RenderingServer.canvas_item_add_texture_rect_region(canvas,target,skin.atlas.get_rid(),region,Color.WHITE,false,true)
