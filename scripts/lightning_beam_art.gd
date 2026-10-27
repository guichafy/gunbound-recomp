extends RefCounted
## Exact native tile quads482130/4a6b10 and alpha4a6aa0. Variants use a
## presentation-local RNG; they do not consume the simulation's random stream.
var texture: Texture2D
var material:=CanvasItemMaterial.new()
var canvases: Dictionary={}

func _init() -> void:
	texture=load("res://assets/openbound/lightning/Lightning.png")
	material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED

static func quads(effect: Dictionary, tick: int) -> Array:
	if tick<0 or tick>=10:return []
	var direction:=int(effect.direction)
	var at:=Vector2(effect.position)
	var local: PackedVector2Array
	if direction==0:
		local=PackedVector2Array([Vector2(-32,-256),Vector2(31,-256),Vector2(31,0),Vector2(-32,0)])
	elif direction>0:
		local=PackedVector2Array([Vector2(-279,-233),Vector2(-234,-278),Vector2(22,-22),Vector2(-23,23)])
	else:
		local=PackedVector2Array([Vector2(233,-279),Vector2(278,-234),Vector2(22,22),Vector2(-23,-23)])
	var result: Array=[]
	var random:=RandomNumberGenerator.new()
	random.seed=hash(str([effect.position,direction,int(tick/3)]))
	# Native has eight texture indices, sufficient for the native map height.
	for tile in 8:
		if at.y<=0:break
		var points:=local.duplicate()
		for vertex in 4:points[vertex]+=at
		var u:=float(random.randi_range(0,3))*0.25
		result.append({"points":points,"uv":PackedVector2Array([Vector2(u,0),Vector2(u+0.25,0),Vector2(u+0.25,1),Vector2(u,1)]),"alpha":float(255-24*tick)/255.0})
		at-=Vector2(direction*256,256)
	return result

func draw(view: Node2D, effects: Array, offset: Vector2) -> void:
	var id:=view.get_instance_id()
	var canvas: RID
	if canvases.has(id):canvas=canvases[id]
	else:
		canvas=RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(canvas,view.get_canvas_item())
		RenderingServer.canvas_item_set_material(canvas,material.get_rid())
		RenderingServer.canvas_item_set_draw_index(canvas,-100)
		canvases[id]=canvas
	RenderingServer.canvas_item_clear(canvas)
	var points:=PackedVector2Array()
	var uv:=PackedVector2Array()
	var colors:=PackedColorArray()
	var indices:=PackedInt32Array()
	for effect in effects:
		var tick:=int(floor((float(effect.get("age",0.0))+0.000001)*20.0))
		for quad in quads(effect,tick):
			var base:=points.size()
			for vertex in quad.points:points.append(vertex+offset)
			uv.append_array(quad.uv)
			for vertex in 4:colors.append(Color(1,1,1,quad.alpha))
			indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))
	if texture!=null and not points.is_empty():
		RenderingServer.canvas_item_add_triangle_array(canvas,indices,points,colors,uv,PackedInt32Array(),PackedFloat32Array(),texture.get_rid())

func clear() -> void:
	for canvas in canvases.values():RenderingServer.canvas_item_clear(canvas)

func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE:
		for canvas in canvases.values():RenderingServer.free_rid(canvas)
