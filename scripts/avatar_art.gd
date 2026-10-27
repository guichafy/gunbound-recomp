extends RefCounted
## Original rider pieces. Source pivots and depth order remain stable over time.
## ADR-130: the shop, room and battle draw the native XFS pieces by default;
## the 0.17 HD masters stay available only when requested explicitly.
const HD = preload("res://scripts/avatar_hd.gd")
const XfsHD = preload("res://scripts/avatar_xfs_hd.gd")
var hd = HD.new()
var xfs_hd = XfsHD.new()
var use_hd := false
func _init(prefer_hd: bool = false) -> void:
	use_hd = prefer_hd
const Catalog = preload("res://scripts/avatar_catalog.gd")
static var catalog = Catalog.new()
static var textures := {}
const XFS_HD_ALIASES := {
	"xfs:0:0:0":"0:0:0","xfs:0:0:1":"0:0:1","xfs:0:0:2":"0:0:2","xfs:0:0:3":"0:0:3",
	"xfs:1:0:0":"1:0:0","xfs:0:1:0":"0:1:0","xfs:0:1:1":"0:1:1","xfs:0:1:2":"0:1:2",
	"xfs:0:1:3":"0:1:3","xfs:1:1:0":"1:1:0","xfs:0:2:2":"0:2:1","xfs:2:3:1":"2:3:1"
}
func hd_key(key: String) -> String:
	return XFS_HD_ALIASES.get(key,key)
func sample_xfs(item: Dictionary, age: float, staring: bool) -> Array:
	var result: Array=[]
	for layer in item.get("layers",[]):
		if not textures.has(layer.atlas):
			if not ResourceLoader.exists(layer.atlas):
				return []
			textures[layer.atlas]=load(layer.atlas)
		var count: int=layer.frames.size()
		var start := 0
		var length := count
		var effect: bool=str(layer.source).to_lower().ends_with("l.img")
		if count in [22,44]:
			length=count/2
			start=length if int(item.category)!=1 and not staring else 0
		var step := int(maxf(0.0,age)*10.0)%(length*2)
		var index := start+(step if step<length else 2*length-1-step)
		var frame: Dictionary=layer.frames[index]
		var source := Rect2(frame.region[0],frame.region[1],frame.region[2],frame.region[3])
		# IMG offsets share one body origin. Register it once to the existing rig.
		var target := Rect2(Vector2(frame.offset[0],frame.offset[1])+Vector2(-5,-5),source.size)
		result.append({"category":int(item.category),"frame":index,"texture":textures[layer.atlas],"source":source,"target":target,"hd":false,"blend_light":effect,"light_key":str(layer.atlas)+":"+str(index)})
	return result
func sample(equipment: Dictionary, age: float, staring: bool = false) -> Array:
	var result: Array = []
	for category in [3,0,2,1]:
		var item: Dictionary = catalog.find(str(equipment.get(str(category),"")))
		if item.is_empty():
			return []
		if item.get("source")=="xfs":
			if use_hd and xfs_hd.complete(item):
				var hd_group: Array=[]
				for index in range(item.layers.size()):
					var data: Dictionary=xfs_hd.piece(item.key,index)
					var part: Dictionary={"category":category,"frame":0,"texture":data.paint,"source":data.source,"target":data.target,"hd":true,"effect":data.effect,"opacity":data.opacity,"xfs_layer":index}
					if data.has("mesh"):part.mesh=data.mesh
					if data.draw_behind:
						hd_group.push_front(part)
					else:
						hd_group.append(part)
				result.append_array(hd_group)
				continue
			var alias: String=hd_key(item.key)
			if use_hd and not hd.piece(alias,0).is_empty() and catalog.entries.has(alias):
				# HD alias is based on verified visual identity, never the numeric ID.
				item=catalog.find(alias)
			else:
				result.append_array(sample_xfs(item,age,staring))
				continue
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
		var target := Rect2(anchor-Vector2(float(item.pivot[0]),float(item.pivot[1])),size)
		var data: Dictionary = hd.piece(item.key,frame) if use_hd else {}
		if not data.is_empty():
			# Keep the native registration window; only artwork density changes.
			target = Rect2(target.position+data.native.position,data.native.size)
			result.append({"category":category,"frame":frame,"texture":data.paint,"source":data.source,"target":target,"hd":true})
		else:
			result.append({"category":category,"frame":frame,"texture":texture,"source":Rect2(origin,size),"target":target,"hd":false})
	return result
func draw(view: Node2D, equipment: Dictionary, transform: Transform2D, age: float, tint: Color) -> bool:
	var pieces := sample(equipment,age)
	if pieces.is_empty():
		return false
	view.draw_set_transform_matrix(transform)
	for piece in pieces:
		var piece_tint:=tint
		piece_tint.a*=float(piece.get("opacity",1.0))
		if piece.get("effect",false):
			piece_tint.a*=0.8+0.2*sin(age*TAU/1.1)
		var paint: Texture2D=piece.texture
		var source: Rect2=piece.source
		if piece.get("blend_light",false):
			var light: Dictionary=XfsHD.light_layer(paint,source,piece.light_key)
			paint=light.paint
			source=light.source
		if piece.has("mesh"):
			view.draw_mesh(piece.mesh,paint,Transform2D.IDENTITY,piece_tint)
		else:
			view.draw_texture_rect_region(paint,piece.target,source,piece_tint)
	view.draw_set_transform(Vector2.ZERO)
	return true
