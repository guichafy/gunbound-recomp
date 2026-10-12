extends RefCounted
## Original rider pieces. Source pivots and depth order remain stable over time.
const Catalog = preload("res://scripts/avatar_catalog.gd")
static var catalog = Catalog.new()
static var textures := {}
func sample(equipment: Dictionary, age: float, staring: bool = false) -> Array:
	var result: Array = []
	for category in [3,0,2,1]:
		var item: Dictionary = catalog.find(str(equipment.get(str(category),"")))
		if item.is_empty():
			return []
		if item.atlas.is_empty():
			continue
		if not textures.has(item.atlas):
			if not ResourceLoader.exists(item.atlas):
				return []
			textures[item.atlas] = load(item.atlas)
		var texture = textures[item.atlas]
		var cell := Vector2(float(item.frame_size[0]),float(item.frame_size[1]))
		var columns := maxi(1,int(texture.get_width()/cell.x))
		var frame := int(floor(maxf(0.0,age)*10.0)) % 11 + (11 if category != 1 and not staring else 0)
		var origin := Vector2(frame%columns,int(frame/columns))*cell
		var size := Vector2(minf(cell.x,texture.get_width()-origin.x),minf(cell.y,texture.get_height()-origin.y))
		if size.x <= 0 or size.y <= 0:
			return []
		var anchor: Vector2 = {0:Vector2(7,-17),1:Vector2.ZERO,2:Vector2(9,-17),3:Vector2(11,-17)}[category]
		result.append({"category":category,"frame":frame,"texture":texture,"source":Rect2(origin,size),"target":Rect2(anchor-Vector2(float(item.pivot[0]),float(item.pivot[1])),size)})
	return result
func draw(view: Node2D, equipment: Dictionary, transform: Transform2D, age: float, tint: Color) -> bool:
	var pieces := sample(equipment,age)
	if pieces.is_empty():
		return false
	view.draw_set_transform_matrix(transform)
	for piece in pieces:
		view.draw_texture_rect_region(piece.texture,piece.target,piece.source,tint)
	view.draw_set_transform(Vector2.ZERO)
	return true
