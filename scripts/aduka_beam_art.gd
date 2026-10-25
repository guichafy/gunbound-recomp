extends RefCounted
## Private additive CanvasItem: never changes the game view's material.
## Native beam geometry/alpha/LUT/UV are isolated from collision and clocks.
const Aduka = preload("res://scripts/aduka_effect.gd")
var texture: Texture2D
var material := CanvasItemMaterial.new()
var canvases := {}

func _init() -> void:
	texture = load("res://assets/openbound/aduka/ThorEffect.png")
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

static func triangle_data(effects: Array, offset: Vector2 = Vector2.ZERO) -> Dictionary:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for effect in effects:
		var tick_value := int(effect.get("tick",floor(float(effect.get("age",0.0))*20.0)))
		if tick_value < 0 or tick_value > 19:
			continue
		for quad in Aduka.beam_quads(effect,tick_value):
			var base := points.size()
			for point in quad.points:
				points.append(Vector2(point)+offset)
			uv.append_array(quad.uv)
			for _vertex in 4:
				colors.append(quad.color)
			indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))
	return {"points":points,"uv":uv,"colors":colors,"indices":indices}

func draw(view: Node2D, effects: Array, offset: Vector2 = Vector2.ZERO) -> void:
	var id := view.get_instance_id()
	var canvas: RID
	if canvases.has(id):
		canvas = canvases[id]
	else:
		canvas = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(canvas,view.get_canvas_item())
		RenderingServer.canvas_item_set_material(canvas,material.get_rid())
		RenderingServer.canvas_item_set_draw_index(canvas,-100)
		canvases[id] = canvas
	RenderingServer.canvas_item_clear(canvas)
	if texture == null:
		return
	var data := triangle_data(effects,offset)
	if data.points.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(canvas,data.indices,data.points,data.colors,data.uv,PackedInt32Array(),PackedFloat32Array(),texture.get_rid())

func clear() -> void:
	for canvas in canvases.values():
		RenderingServer.canvas_item_clear(canvas)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for canvas in canvases.values():
			RenderingServer.free_rid(canvas)
