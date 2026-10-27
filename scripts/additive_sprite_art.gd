extends RefCounted
## A private additive pass. begin() clears old commands even with no new sprites.
var material := CanvasItemMaterial.new()
var canvases := {}

func _init() -> void:
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

func begin(view: Node2D) -> RID:
	var key := view.get_instance_id()
	if not canvases.has(key):
		var canvas := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(canvas,view.get_canvas_item())
		RenderingServer.canvas_item_set_material(canvas,material.get_rid())
		canvases[key] = canvas
	var result: RID = canvases[key]
	RenderingServer.canvas_item_clear(result)
	return result

func draw(view: Node2D, texture: Texture2D, target: Rect2, source: Rect2, transform: Transform2D, color: Color = Color.WHITE) -> void:
	var key := view.get_instance_id()
	var canvas: RID = canvases[key] if canvases.has(key) else begin(view)
	RenderingServer.canvas_item_add_set_transform(canvas,transform)
	RenderingServer.canvas_item_add_texture_rect_region(canvas,target,texture.get_rid(),source,color)

func clear() -> void:
	for canvas in canvases.values():
		RenderingServer.canvas_item_clear(canvas)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for canvas in canvases.values():
			RenderingServer.free_rid(canvas)
