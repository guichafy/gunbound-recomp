extends RefCounted
## Pure quads from Force471550/Electric46e020/Tornado4ac760, same client PE.
## Tick is the object's native Animate counter; the caller owns time/pause.
## Dispatcher4508a0: Force/Tornado19=5,20=6; Electric19=5,20=2.
const Integer = preload("res://scripts/classic_ballistics.gd")
const TEXTURES := {"force":"FirewallTexture","electricity":"LightningTexture","tornado":"TornadoTexture"}
var textures: Dictionary = {}
var additive := CanvasItemMaterial.new()
var canvases: Dictionary = {}

func _init() -> void:
	additive.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for kind in TEXTURES:
		textures[kind]=load("res://assets/openbound/weather/native/%s.png"%TEXTURES[kind])

func draw(view: Node2D, columns: Array, ages: Dictionary, offset: Vector2, height: float) -> void:
	var id:=view.get_instance_id()
	var canvas: RID
	if canvases.has(id):canvas=canvases[id]
	else:
		canvas=RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(canvas,view.get_canvas_item())
		RenderingServer.canvas_item_set_material(canvas,additive.get_rid())
		RenderingServer.canvas_item_set_draw_index(canvas,-200)
		canvases[id]=canvas
	RenderingServer.canvas_item_clear(canvas)
	for column in columns:
		var texture: Texture2D=textures.get(str(column.type))
		if texture==null:continue
		var tick:=floori((float(ages.get(int(column.id),0.0))+0.000001)*20.0)
		for quad in quads(column,tick,height):
			var points: PackedVector2Array=quad.points.duplicate()
			for vertex in 4:points[vertex]+=offset
			if str(quad.blend)=="mix":
				view.draw_polygon(points,PackedColorArray([Color.WHITE]),quad.uv,texture)
			else:
				RenderingServer.canvas_item_add_triangle_array(canvas,PackedInt32Array([0,1,2,0,2,3]),points,PackedColorArray([Color.WHITE]),quad.uv,PackedInt32Array(),PackedFloat32Array(),texture.get_rid())

func clear() -> void:
	for canvas in canvases.values():RenderingServer.canvas_item_clear(canvas)

func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE:
		for canvas in canvases.values():RenderingServer.free_rid(canvas)

static func quads(column: Dictionary, tick: int, world_height: float) -> Array:
	var kind := str(column.get("type",""))
	if not TEXTURES.has(kind):return []
	var clock := maxi(0,tick)
	var half := Integer.quot(int(column.get("native_width",128)),2)
	var center := int(column.x)
	var left := center-half
	var right := center+half-1
	var y := -(clock%64)*6 if kind=="tornado" else -(clock%32)*2
	var frame := clock%8
	var result: Array = []
	while float(y)<world_height:
		var u := float(frame%2)*0.5
		var v := float(Integer.quot(frame,2))*0.25
		var u1 := u+0.5
		var v1: float
		if kind=="force":
			u+=0.00001
			v+=0.00001
			u1=u+0.5-0.00004
			v1=v+0.25-0.00004
		else:
			v+=0.001
			v1=v+0.248
		result.append({"points":PackedVector2Array([Vector2(left,y),Vector2(right,y),Vector2(right,y+64),Vector2(left,y+64)]),
			"uv":PackedVector2Array([Vector2(u,v),Vector2(u1,v),Vector2(u1,v1),Vector2(u,v1)]),
			"color":Color.WHITE,"blend":"add" if kind=="electricity" else "mix",
			"texture":"res://assets/openbound/weather/native/%s.png"%TEXTURES[kind]})
		y+=64
		frame=(frame+1)%8
	return result
