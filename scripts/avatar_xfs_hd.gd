extends RefCounted
const ContourGlow = preload("res://scripts/avatar_contour_glow.gd")
## Masters of equipped XFS pieces. Separate from shop-only portrait assets.
var sheets: Dictionary={}
var layers: Dictionary={}
var portraits: Dictionary={}
var textures: Dictionary={}
var paints: Dictionary={}
var curved_lights: Dictionary={}
static var light_textures: Dictionary={}
static func light_layer(texture: Texture2D, region: Rect2, identity: String) -> Dictionary:
	# XFS L layers encode emitted light: black contributes no light. Convert
	# that blending convention in memory; source/generated PNGs stay intact.
	if not light_textures.has(identity):
		var image:=texture.get_image()
		if image.is_compressed():
			image.decompress()
		image=image.get_region(Rect2i(region))
		image.convert(Image.FORMAT_RGBA8)
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color:=image.get_pixel(x,y)
				color.a*=maxf(color.r,maxf(color.g,color.b))
				image.set_pixel(x,y,color)
		image.generate_mipmaps()
		var paint:=CanvasTexture.new()
		paint.diffuse_texture=ImageTexture.create_from_image(image)
		paint.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		light_textures[identity]={"paint":paint,"source":Rect2(Vector2.ZERO,image.get_size())}
	return light_textures[identity]
func _init(path: String = "res://assets/hd/avatars/xfs/catalog.json") -> void:
	if not FileAccess.file_exists(path):
		return
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version")!=1 or not data.get("sheets") is Dictionary or not data.get("layers") is Dictionary or not data.get("portraits") is Dictionary:
		return
	sheets=data.sheets
	layers=data.layers
	portraits=data.portraits
func rectangle(values) -> Rect2:
	if not values is Array or values.size()!=4:
		return Rect2()
	for value in values:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):
			return Rect2()
	return Rect2(values[0],values[1],values[2],values[3])
func registered(entry: Dictionary) -> Dictionary:
	var sheet=sheets.get(entry.get("sheet",""))
	if not sheet is Dictionary or not sheet.get("size") is Array or sheet.size.size()!=2:
		return {}
	var path: String=str(sheet.get("file",""))
	if not textures.has(path):
		if not ResourceLoader.exists(path):
			return {}
		var texture=load(path)
		if not texture is Texture2D or texture.get_size()!=Vector2(sheet.size[0],sheet.size[1]):
			return {}
		textures[path]=texture
		var paint:=CanvasTexture.new()
		paint.diffuse_texture=texture
		paint.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		paints[path]=paint
	var source:=rectangle(entry.get("region"))
	if not source.has_area() or not Rect2(Vector2.ZERO,textures[path].get_size()).encloses(source):
		return {}
	return {"texture":textures[path],"paint":paints[path],"source":source}
func piece(key: String, index: int) -> Dictionary:
	var entry=layers.get(key+"|layer:"+str(index))
	if not entry is Dictionary:
		return {}
	var data:=registered(entry)
	var native:=rectangle(entry.get("native_rect"))
	if data.is_empty() or not native.has_area():
		return {}
	# A single reference window fixes registration for all poses and clocks.
	# Never recenter anatomy using the original per-frame alpha bounds.
	var fitted: Vector2=data.source.size*minf(native.size.x/data.source.size.x,native.size.y/data.source.size.y)
	var registration := -native.position/native.size
	data.target=Rect2(-fitted*registration,fitted)
	if entry.has("attachment"):
		# Light attachment is measured on the selected HD anatomy, not the
		# alpha center of an unrelated frontal frame or a changing silhouette.
		var attachment=entry.attachment
		if not attachment is Dictionary or index<=0 or not attachment.get("base_uv") is Array or not attachment.get("effect_uv") is Array:
			return {}
		if attachment.base_uv.size()!=2 or attachment.effect_uv.size()!=2:
			return {}
		for value in attachment.base_uv+attachment.effect_uv+[attachment.get("scale",1.0)]:
			if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):
				return {}
		for value in attachment.base_uv+attachment.effect_uv:
			if float(value)<0.0 or float(value)>1.0:
				return {}
		var factor: float=float(attachment.get("scale",1.0))
		if factor<=0.0 or factor>2.0:
			return {}
		var base:=piece(key,0)
		if base.is_empty():
			return {}
		fitted*=factor
		var anchor: Vector2=base.target.position+base.target.size*Vector2(attachment.base_uv[0],attachment.base_uv[1])
		data.target=Rect2(anchor-fitted*Vector2(attachment.effect_uv[0],attachment.effect_uv[1]),fitted)
	data.effect=bool(entry.get("pulsate",false))
	data.draw_behind=bool(entry.get("draw_behind",false))
	# Native glass/glows are translucent; a generated opaque dark center must
	# not hide the face. Preserve the source material's average opacity.
	var native_opacity: float=float(entry.get("native_mean_opacity",1.0))
	var generated_opacity: float=float(entry.get("generated_mean_opacity",1.0))
	var translucent: bool=bool(entry.get("effect",false)) or int(key.get_slice(":",2))==2
	data.opacity=minf(1.0,native_opacity/maxf(0.01,generated_opacity)) if translucent else 1.0
	if entry.has("contour_glow"):
		if index<=0 or not data.draw_behind:return {}
		var base:=piece(key,0)
		if base.is_empty():return {}
		var glow:=ContourGlow.build(base.texture,base.source,entry.contour_glow,key+str(layers[key+"|layer:0"].sheet))
		if glow.is_empty():return {}
		var scale: Vector2=base.target.size/base.source.size
		data.paint=glow.paint
		data.source=glow.source
		data.target=Rect2(base.target.position+glow.pixel_offset*scale,glow.pixel_size*scale)
		data.opacity=1.0
		data.contour_derived=true
	elif bool(entry.get("effect",false)):
		var light:=light_layer(data.texture,data.source,"hd:"+key+":"+str(index)+":"+str(entry.sheet))
		data.paint=light.paint
		data.source=light.source
	if entry.has("light_curve"):
		if index<=0 or data.draw_behind or not data.effect:return {}
		var base:=piece(key,0)
		if base.is_empty():return {}
		var curved:=curve_light(base.target,entry.light_curve)
		if curved.is_empty():return {}
		data.mesh=curved.mesh
		data.target=curved.bounds
	return data
func curve_light(base: Rect2, knots) -> Dictionary:
	# Fixed UV strips bend the existing luminous master onto the horn.
	# Texture, material opacity, animation clock and anatomy stay unchanged.
	if not knots is Array or knots.size()<2 or knots.size()>32:return {}
	var last_v: float=-1.0
	var last_y: float=-1.0
	for knot in knots:
		if not knot is Array or knot.size()!=5:return {}
		for value in knot:
			if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):return {}
		if knot[0]<=last_v or knot[0]<0 or knot[0]>1 or knot[1]<0 or knot[1]>1 or knot[2]<-.5 or knot[2]>1.5 or knot[3]<=last_y or knot[3]<-.5 or knot[3]>1.5 or knot[4]<=0 or knot[4]>2:return {}
		last_v=knot[0]
		last_y=knot[3]
	if knots[0][0]!=0 or knots[-1][0]!=1:return {}
	var identity:=str(base)+JSON.stringify(knots)
	if curved_lights.has(identity):return curved_lights[identity]
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	var bounds:=Rect2()
	var segment:=0
	for row in range(65):
		var v:=row/64.0
		while segment<knots.size()-2 and v>knots[segment+1][0]:segment+=1
		var a: Array=knots[segment]
		var b: Array=knots[segment+1]
		var t: float=(v-a[0])/(b[0]-a[0])
		var source_x: float=lerpf(a[1],b[1],t)
		var target_x: float=lerpf(a[2],b[2],t)
		var target_y: float=lerpf(a[3],b[3],t)
		var width: float=lerpf(a[4],b[4],t)
		for u in [0.0,1.0]:
			var point:=base.position+base.size*Vector2(target_x+(u-source_x)*width,target_y)
			if vertices.is_empty():bounds=Rect2(point,Vector2.ZERO)
			else:bounds=bounds.expand(point)
			vertices.append(Vector3(point.x,point.y,0))
			uvs.append(Vector2(u,v))
		if row<64:
			var i:=row*2
			indices.append_array(PackedInt32Array([i,i+1,i+2,i+1,i+3,i+2]))
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	curved_lights[identity]={"mesh":mesh,"bounds":bounds}
	return curved_lights[identity]
func complete(item: Dictionary) -> bool:
	var native_layers: Array=item.get("layers",[])
	if native_layers.is_empty():
		return false
	for index in range(native_layers.size()):
		if piece(item.key,index).is_empty():
			return false
	return true
func portrait(key: String) -> Texture2D:
	var entry=portraits.get(key)
	if not entry is Dictionary:
		return null
	var data:=registered(entry)
	if data.is_empty():
		return null
	var result:=AtlasTexture.new()
	result.atlas=data.texture
	result.region=data.source
	return result
