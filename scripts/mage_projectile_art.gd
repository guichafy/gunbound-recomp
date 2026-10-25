extends RefCounted
## Mage native LaserEffect ribbon: PE4c45e4/4c47aa/4c490c. Normal alpha blend,
## 16 UV columns, shared cross-sections, two explicit triangles per quad.
var texture: Texture2D

func _init() -> void:
	texture = load("res://assets/openbound/mage/original/LaserEffect.png")

static func segments(shot: Dictionary, weapon: int) -> Array:
	var history: Array = shot.get("trail",[]).slice(-16).duplicate()
	var sides: Array = shot.get("laser_sides",[]).slice(-16).duplicate()
	if history.size() < 2:
		return []
	# Legacy capture fixtures can omit native sections; real shots carry them.
	if sides.size() != history.size():
		sides.clear()
		for index in history.size():
			var tangent := Vector2(history[index])-Vector2(history[maxi(0,index-1)])
			if tangent == Vector2.ZERO and index+1 < history.size():
				tangent = Vector2(history[index+1])-Vector2(history[index])
			sides.append(tangent.normalized().orthogonal()*8.0)
	for index in history.size():
		history[index] = Vector2(history[index]).floor()
	if shot.has("draw_fraction"):
		var blend := clampf(float(shot.draw_fraction),0,1)
		for index in range(history.size()-1,0,-1):
			history[index] = Vector2(history[index-1]).lerp(history[index],blend)
			sides[index] = Vector2(sides[index-1]).lerp(sides[index],blend)
	var phase := posmod(int(shot.get("flight_ticks",0)),8)+(8 if weapon == 1 else 0)
	var component := int(shot.get("mage_component",1 if float(shot.get("phase",0.0)) >= PI else 0))
	var result: Array = []
	for index in mini(15,history.size()-1):
		var newer := history.size()-1-index
		var older := newer-1
		var uv := Vector2(phase/16.0,index/16.0)
		var color := Color8(255,128,255,255-16*index) if weapon == 1 and component == 1 else Color8(128,255,255,255-16*index)
		result.append({"points":PackedVector2Array([history[newer]-sides[newer],history[newer]+sides[newer],history[older]+sides[older],history[older]-sides[older]]),
			"uv":PackedVector2Array([uv,uv+Vector2(1.0/16,0),uv+Vector2(1.0/16,1.0/16),uv+Vector2(0,1.0/16)]),"color":color})
	return result

static func triangle_data(shot: Dictionary, weapon: int) -> Dictionary:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for segment in segments(shot,weapon):
		var base := points.size()
		points.append_array(segment.points); uv.append_array(segment.uv)
		for vertex in 4:
			colors.append(segment.color)
		indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))
	return {"points":points,"uv":uv,"colors":colors,"indices":indices}

func draw(view: Node2D, shot: Dictionary, weapon: int, offset: Vector2) -> void:
	var data := triangle_data(shot,weapon)
	if data.points.is_empty():
		return
	view.draw_set_transform(offset)
	RenderingServer.canvas_item_add_triangle_array(view.get_canvas_item(),data.indices,data.points,data.colors,data.uv,PackedInt32Array(),PackedFloat32Array(),texture.get_rid())
	view.draw_set_transform(Vector2.ZERO)
