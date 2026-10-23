extends RefCounted
## Cached rendering effect derived from the selected HD horn's own pixels.
## No independent glow silhouette, anatomical offset, or generated frame cycle.
static var cache: Dictionary={}
static func build(texture: Texture2D, region: Rect2, profile, identity: String) -> Dictionary:
	if not profile is Dictionary or not profile.get("uv_region") is Array or profile.uv_region.size()!=4:
		return {}
	for value in profile.uv_region+[profile.get("radius",12),profile.get("sigma",3.25),profile.get("strength",0.65)]:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):
			return {}
	var uv:=Rect2(profile.uv_region[0],profile.uv_region[1],profile.uv_region[2],profile.uv_region[3])
	var radius:=int(profile.get("radius",12))
	var sigma:=float(profile.get("sigma",3.25))
	var strength:=float(profile.get("strength",0.65))
	if not uv.has_area() or not Rect2(0,0,1,1).encloses(uv) or radius<1 or radius>24 or sigma<=0 or sigma>radius or strength<=0 or strength>1:
		return {}
	var key:=identity+str(region)+JSON.stringify(profile)
	if cache.has(key):return cache[key]
	var original:=texture.get_image()
	if original.is_compressed():original.decompress()
	if not Rect2(Vector2.ZERO,original.get_size()).encloses(region):return {}
	var source:=original.get_region(Rect2i(region))
	var size:=source.get_size()+Vector2i.ONE*radius*2
	var distance:=PackedFloat32Array()
	distance.resize(size.x*size.y)
	distance.fill(radius*2.0)
	var seeds:=0
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			if not uv.has_point(Vector2(x,y)/Vector2(source.get_size())):continue
			var color:=source.get_pixel(x,y)
			# Select dense warm gold in the fixed horn window. Hair/face are
			# excluded; dark segment lines remain in the opaque head drawn above.
			var chroma:=color.r-color.b
			var gold_hue: float=(color.g-color.b)/chroma if chroma>.03 else 0.0
			if color.a>.8 and color.g>.12 and color.g>=color.r*.65 and color.r>=color.g*.9 and gold_hue>.62 and gold_hue<1.05:
				distance[(y+radius)*size.x+x+radius]=0.0
				seeds+=1
	if seeds<32:return {}
	# Two-pass chamfer distance, bounded to this small cached source window.
	for y in range(size.y):
		for x in range(size.x):
			var i:=y*size.x+x
			if x>0:distance[i]=minf(distance[i],distance[i-1]+1.0)
			if y>0:
				distance[i]=minf(distance[i],distance[i-size.x]+1.0)
				if x>0:distance[i]=minf(distance[i],distance[i-size.x-1]+1.414214)
				if x+1<size.x:distance[i]=minf(distance[i],distance[i-size.x+1]+1.414214)
	for y in range(size.y-1,-1,-1):
		for x in range(size.x-1,-1,-1):
			var i:=y*size.x+x
			if x+1<size.x:distance[i]=minf(distance[i],distance[i+1]+1.0)
			if y+1<size.y:
				distance[i]=minf(distance[i],distance[i+size.x]+1.0)
				if x>0:distance[i]=minf(distance[i],distance[i+size.x-1]+1.414214)
				if x+1<size.x:distance[i]=minf(distance[i],distance[i+size.x+1]+1.414214)
	var image:=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(size.y):
		for x in range(size.x):
			var d:=distance[y*size.x+x]
			if d<=radius:image.set_pixel(x,y,Color(1.0,.97,.74,strength*exp(-.5*d*d/(sigma*sigma))))
	var used:=image.get_used_rect()
	if not used.has_area():return {}
	image=image.get_region(used)
	image.generate_mipmaps()
	var paint:=CanvasTexture.new()
	paint.diffuse_texture=ImageTexture.create_from_image(image)
	paint.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	cache[key]={"paint":paint,"source":Rect2(Vector2.ZERO,image.get_size()),"pixel_offset":Vector2(used.position-Vector2i.ONE*radius),"pixel_size":Vector2(used.size),"seed_count":seeds}
	return cache[key]
