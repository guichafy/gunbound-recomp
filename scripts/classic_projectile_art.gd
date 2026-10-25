extends RefCounted
## Client WaterEffect composition. Geometry reads immutable 20Hz history;
## interpolation affects presentation only. PE 0x4b2aa0 / 0x4c480c.
const Timing = preload("res://scripts/classic_shot_timing.gd")
var water: Texture2D

func _init() -> void:
	water = load("res://assets/openbound/classic/WaterEffect.png")

static func water_segments(projectile: Dictionary) -> Array:
	var history: Array = projectile.get("trail", []).duplicate()
	var sides: Array = projectile.get("water_sides",[]).duplicate()
	var native_sections := not sides.is_empty() and sides.size() == history.size()
	if native_sections:
		# Native Turtle S2 anchors each section to hit_fp >>8 (arithmetic floor).
		# The section orientation comes from the carrier, not the wave tangent.
		for index in history.size():
			history[index] = Vector2(history[index]).floor()
	if projectile.has("draw_fraction"):
		var fraction := clampf(float(projectile.draw_fraction),0.0,1.0)
		for index in range(history.size()-1,0,-1):
			history[index] = Vector2(history[index-1]).lerp(history[index],fraction)
			if native_sections:
				sides[index] = Vector2(sides[index-1]).lerp(sides[index],fraction)
	var position := Vector2(projectile.get("hit_pos", projectile.pos))
	if history.is_empty():
		return []
	# History already contains the latest simulation point. Interpolate its head
	# in place, avoiding another physics sample or any change to the model.
	if not native_sections:
		history[-1] = position
	# One cross-section per historical point. Adjacent quads reuse exactly
	# the same two edge vertices, including on the two curved S2 traces.
	if not native_sections:
		for index in history.size():
			var tangent: Vector2 = Vector2(history[index])-Vector2(history[maxi(0,index-1)])
			if tangent == Vector2.ZERO and index+1 < history.size():
				tangent = Vector2(history[index+1])-Vector2(history[index])
			sides.append(tangent.normalized().orthogonal()*16.0)
	var segments: Array = []
	var count := mini(15, history.size()-1)
	var phase := posmod(int(projectile.get("flight_ticks", floor((float(projectile.age)+0.000001)/Timing.STEP))),8)
	for index in count:
		var newer := Vector2(history[history.size()-1-index])
		var older := Vector2(history[history.size()-2-index])
		var newer_side: Vector2 = sides[history.size()-1-index]
		var older_side: Vector2 = sides[history.size()-2-index]
		if newer.is_equal_approx(older):
			continue
		var uv := Vector2(phase/8.0,index/16.0)
		segments.append({"points":PackedVector2Array([newer-newer_side,newer+newer_side,older+older_side,older-older_side]),
			"uv":PackedVector2Array([uv, uv+Vector2(1.0/8,0),uv+Vector2(1.0/8,1.0/16),uv+Vector2(0,1.0/16)]),
			"alpha":float(255-16*index)/255.0})
	return segments

func triangle_data(projectile: Dictionary) -> Dictionary:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for segment in water_segments(projectile):
		var base := points.size()
		points.append_array(segment.points)
		uv.append_array(segment.uv)
		for vertex in 4:
			colors.append(Color(1,1,1,segment.alpha))
		indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))
	return {"points":points,"uv":uv,"colors":colors,"indices":indices}

func draw_water(view: Node2D, projectile: Dictionary, offset: Vector2) -> void:
	view.draw_set_transform(offset)
	if not projectile.get("water_sides",[]).is_empty():
		# Native0x4ed5a0 emits two triangles even when the carrier turns a
		# section into a crossed quad. Polygon ear-clipping rejects that shape.
		var data := triangle_data(projectile)
		if not data.points.is_empty():
			RenderingServer.canvas_item_add_triangle_array(view.get_canvas_item(),data.indices,data.points,data.colors,data.uv,PackedInt32Array(),PackedFloat32Array(),water.get_rid())
	else:
		# Keep the approved T1 presentation unchanged.
		for segment in water_segments(projectile):
			view.draw_polygon(segment.points,PackedColorArray([Color(1,1,1,segment.alpha)]),segment.uv,water)
	view.draw_set_transform(Vector2.ZERO)
